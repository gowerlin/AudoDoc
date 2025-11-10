# AutoDoc Agent v2.0 - Task 12 詳細實作

## 📋 文檔導航

← [返回概述](v2_desktop_overview.md) | [GUI 設計 →](v2_desktop_gui.md)

---

## Task 12: 桌面應用程式打包與整合

### 概述

**目標**：將 AutoDoc Agent 打包為獨立的桌面應用程式  
**預估時間**：2-3 週  
**複雜度**：Medium-High  
**優先級**：Phase 2  
**依賴**：Task 1-11 完成並穩定

---

## Subtask 12.1: 建立 Tauri 專案結構

### 安裝工具

```bash
# 安裝 Rust (如果尚未安裝)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 安裝 Tauri CLI
cargo install tauri-cli

# 或使用 npm
npm install -g @tauri-apps/cli
```

### 初始化專案

```bash
cd autodoc-agent
mkdir desktop && cd desktop

# 初始化 Tauri 專案
npm create tauri-app@latest

# 選項：
# - App name: autodoc-agent-desktop
# - Window title: AutoDoc Agent
# - Frontend: React + TypeScript
# - Package manager: npm
```

### Tauri 配置檔 (`src-tauri/tauri.conf.json`)

```json
{
  "$schema": "https://schema.tauri.app/config/2.0.0",
  "build": {
    "beforeDevCommand": "npm run dev",
    "beforeBuildCommand": "npm run build",
    "devPath": "http://localhost:5173",
    "distDir": "../dist"
  },
  "package": {
    "productName": "AutoDoc Agent",
    "version": "2.0.0"
  },
  "tauri": {
    "bundle": {
      "active": true,
      "targets": ["nsis", "msi", "dmg", "deb", "appimage"],
      "identifier": "com.autodoc.agent",
      "icon": [
        "icons/32x32.png",
        "icons/128x128.png",
        "icons/128x128@2x.png",
        "icons/icon.icns",
        "icons/icon.ico"
      ],
      "externalBin": [
        "backend-bundle/backend"
      ],
      "resources": [
        "resources/*"
      ],
      "windows": {
        "certificateThumbprint": null,
        "digestAlgorithm": "sha256",
        "timestampUrl": "http://timestamp.digicert.com"
      },
      "macOS": {
        "entitlements": null,
        "exceptionDomain": null,
        "frameworks": [],
        "providerShortName": null,
        "signingIdentity": null
      }
    },
    "security": {
      "csp": "default-src 'self'; connect-src 'self' http://localhost:3000 ws://localhost:3000; style-src 'self' 'unsafe-inline'"
    },
    "allowlist": {
      "all": false,
      "fs": {
        "all": false,
        "readFile": true,
        "writeFile": true,
        "readDir": true,
        "createDir": true,
        "removeDir": true,
        "removeFile": true,
        "exists": true,
        "scope": [
          "$APPDATA/*",
          "$DOCUMENT/*",
          "$HOME/.config/AutoDoc/*",
          "$HOME/Library/Application Support/AutoDoc/*"
        ]
      },
      "dialog": {
        "all": true,
        "open": true,
        "save": true
      },
      "shell": {
        "all": false,
        "sidecar": true,
        "scope": [
          {
            "name": "backend",
            "sidecar": true,
            "args": true
          }
        ]
      },
      "protocol": {
        "asset": true,
        "assetScope": ["$APPDATA/*", "$RESOURCE/*"]
      },
      "http": {
        "all": false,
        "request": true,
        "scope": [
          "http://localhost:3000/*",
          "https://api.anthropic.com/*"
        ]
      }
    },
    "windows": [
      {
        "title": "AutoDoc Agent",
        "width": 1200,
        "height": 800,
        "resizable": true,
        "fullscreen": false,
        "decorations": true,
        "center": true,
        "minWidth": 800,
        "minHeight": 600
      }
    ],
    "systemTray": {
      "iconPath": "icons/icon.png",
      "iconAsTemplate": true,
      "menuOnLeftClick": false
    },
    "updater": {
      "active": true,
      "endpoints": [
        "https://releases.autodoc.app/{{target}}/{{current_version}}"
      ],
      "dialog": true,
      "pubkey": "dW50cnVzdGVkIGNvbW1lbnQ6IG1pbmlzaWduIHB1YmxpYyBrZXk6IDUxQkFFRjI2MTI3QzQ2MkIKUldRUTBhYjU4RjBOTjlNeUFUTzE3WWpIOUdNbjdlNXJyWFFLM1NvSkRvZWsK"
    }
  }
}
```

### Cargo.toml 依賴

```toml
[package]
name = "autodoc-agent-desktop"
version = "2.0.0"
description = "AutoDoc Agent Desktop Application"
authors = ["AutoDoc Team"]
license = "MIT"
repository = "https://github.com/autodoc/agent"
edition = "2021"

[build-dependencies]
tauri-build = { version = "2.0", features = [] }

[dependencies]
tauri = { version = "2.0", features = [
  "updater",
  "dialog-all",
  "fs-all",
  "shell-sidecar",
  "system-tray",
  "protocol-asset",
  "http-request"
] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
confy = "0.5"
dirs = "5.0"
tokio = { version = "1", features = ["full"] }
anyhow = "1.0"
log = "0.4"
env_logger = "0.10"
```

---

## Subtask 12.2: 實作配置管理系統

### Rust 配置管理 (`src-tauri/src/config.rs`)

```rust
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use anyhow::Result;

// ============= 配置結構定義 =============

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AppConfig {
    pub basic: BasicSettings,
    pub auth: AuthSettings,
    pub exploration: ExplorationSettings,
    pub storage: StorageSettings,
    pub advanced: AdvancedSettings,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct BasicSettings {
    pub app_name: String,
    pub language: String,
    pub auto_start: bool,
    pub minimize_to_tray: bool,
    pub check_updates: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AuthSettings {
    pub claude_api_key: String,
    pub claude_model: String,
    pub google_credentials_path: Option<PathBuf>,
    pub google_token_path: Option<PathBuf>,
    pub chrome_mcp_url: String,
    pub chrome_mcp_port: u16,
    pub target_auth_type: String,
    pub target_username: Option<String>,
    pub target_password: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ExplorationSettings {
    pub strategy: String,
    pub max_depth: u32,
    pub max_pages: u32,
    pub screenshot_quality: String,
    pub network_timeout: u32,
    pub wait_for_network_idle: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct StorageSettings {
    pub snapshot_storage_path: PathBuf,
    pub screenshot_storage_path: PathBuf,
    pub database_path: PathBuf,
    pub enable_compression: bool,
    pub auto_cleanup: bool,
    pub retention_days: u32,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AdvancedSettings {
    pub log_level: String,
    pub enable_telemetry: bool,
    pub concurrent_tabs: u32,
    pub api_rate_limit: u32,
    pub proxy_url: Option<String>,
    pub custom_user_agent: Option<String>,
}

// ============= 預設配置 =============

impl Default for AppConfig {
    fn default() -> Self {
        let docs_dir = dirs::document_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("AutoDoc");
        
        AppConfig {
            basic: BasicSettings {
                app_name: "AutoDoc Agent".to_string(),
                language: "zh-TW".to_string(),
                auto_start: false,
                minimize_to_tray: true,
                check_updates: true,
            },
            auth: AuthSettings {
                claude_api_key: String::new(),
                claude_model: "claude-sonnet-4-20250514".to_string(),
                google_credentials_path: None,
                google_token_path: None,
                chrome_mcp_url: "http://localhost".to_string(),
                chrome_mcp_port: 3001,
                target_auth_type: "none".to_string(),
                target_username: None,
                target_password: None,
            },
            exploration: ExplorationSettings {
                strategy: "importance".to_string(),
                max_depth: 5,
                max_pages: 100,
                screenshot_quality: "medium".to_string(),
                network_timeout: 30,
                wait_for_network_idle: true,
            },
            storage: StorageSettings {
                snapshot_storage_path: docs_dir.join("snapshots"),
                screenshot_storage_path: docs_dir.join("screenshots"),
                database_path: docs_dir.join("autodoc.db"),
                enable_compression: true,
                auto_cleanup: false,
                retention_days: 0,
            },
            advanced: AdvancedSettings {
                log_level: "info".to_string(),
                enable_telemetry: false,
                concurrent_tabs: 3,
                api_rate_limit: 20,
                proxy_url: None,
                custom_user_agent: None,
            },
        }
    }
}

// ============= Tauri Commands =============

#[tauri::command]
pub fn load_config() -> Result<AppConfig, String> {
    confy::load("autodoc-agent", "config")
        .map_err(|e| format!("載入配置失敗: {}", e))
}

#[tauri::command]
pub fn save_config(config: AppConfig) -> Result<(), String> {
    confy::store("autodoc-agent", "config", config)
        .map_err(|e| format!("保存配置失敗: {}", e))
}

#[tauri::command]
pub fn validate_config(config: AppConfig) -> Result<Vec<String>, String> {
    let mut errors = Vec::new();
    
    // 驗證 Claude API Key
    if config.auth.claude_api_key.is_empty() {
        errors.push("Claude API Key 不能為空".to_string());
    } else if !config.auth.claude_api_key.starts_with("sk-") {
        errors.push("Claude API Key 格式不正確".to_string());
    }
    
    // 驗證探索設定
    if config.exploration.max_depth == 0 || config.exploration.max_depth > 10 {
        errors.push("最大深度必須在 1-10 之間".to_string());
    }
    
    if config.exploration.max_pages < 10 || config.exploration.max_pages > 1000 {
        errors.push("最大頁面數必須在 10-1000 之間".to_string());
    }
    
    // 驗證儲存路徑
    if !config.storage.snapshot_storage_path.exists() {
        std::fs::create_dir_all(&config.storage.snapshot_storage_path)
            .map_err(|e| format!("無法建立快照目錄: {}", e))?;
    }
    
    if errors.is_empty() {
        Ok(vec!["配置驗證通過".to_string()])
    } else {
        Err(errors.join("; "))
    }
}

#[tauri::command]
pub fn get_default_config() -> AppConfig {
    AppConfig::default()
}

#[tauri::command]
pub fn reset_config() -> Result<(), String> {
    let default_config = AppConfig::default();
    save_config(default_config)
}
```

---

## Subtask 12.3: 實作 Node.js Backend Sidecar

### 打包 Node.js Backend

#### 更新 backend/package.json

```json
{
  "name": "autodoc-agent-backend",
  "version": "2.0.0",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "package:win": "pkg . --targets node18-win-x64 --output ../desktop/backend-bundle/backend-win.exe",
    "package:mac": "pkg . --targets node18-macos-x64,node18-macos-arm64 --output ../desktop/backend-bundle/backend-macos",
    "package:linux": "pkg . --targets node18-linux-x64 --output ../desktop/backend-bundle/backend-linux",
    "package:all": "npm run package:win && npm run package:mac && npm run package:linux"
  },
  "pkg": {
    "assets": [
      "node_modules/**/*",
      "dist/**/*"
    ],
    "targets": ["node18"],
    "outputPath": "../desktop/backend-bundle"
  },
  "dependencies": {
    "express": "^4.18.0",
    "ws": "^8.14.0",
    "dotenv": "^16.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0",
    "pkg": "^5.8.0"
  }
}
```

### Sidecar 管理器 (`src-tauri/src/sidecar.rs`)

```rust
use tauri::api::process::{Command, CommandEvent};
use std::sync::Mutex;
use log::{info, error};

pub struct BackendProcess {
    child: Option<tauri::async_runtime::JoinHandle<()>>,
}

impl BackendProcess {
    pub fn new() -> Self {
        BackendProcess { child: None }
    }
    
    pub fn start(&mut self, port: u16) -> Result<(), String> {
        info!("啟動 Node.js Backend Sidecar on port {}", port);
        
        let (mut rx, child) = Command::new_sidecar("backend")
            .expect("failed to create `backend` binary command")
            .args(&["--port", &port.to_string()])
            .spawn()
            .map_err(|e| format!("啟動後端失敗: {}", e))?;
        
        // 在背景監聽後端輸出
        let handle = tauri::async_runtime::spawn(async move {
            while let Some(event) = rx.recv().await {
                match event {
                    CommandEvent::Stdout(line) => {
                        info!("[Backend] {}", line);
                    }
                    CommandEvent::Stderr(line) => {
                        error!("[Backend Error] {}", line);
                    }
                    CommandEvent::Error(err) => {
                        error!("[Backend Error] {}", err);
                    }
                    CommandEvent::Terminated(payload) => {
                        info!("[Backend] Terminated with code: {:?}", payload.code);
                        break;
                    }
                    _ => {}
                }
            }
        });
        
        self.child = Some(handle);
        
        // 等待後端啟動
        std::thread::sleep(std::time::Duration::from_secs(2));
        
        Ok(())
    }
    
    pub fn stop(&mut self) -> Result<(), String> {
        if let Some(handle) = self.child.take() {
            handle.abort();
            info!("Node.js Backend Sidecar stopped");
        }
        Ok(())
    }
    
    pub fn restart(&mut self, port: u16) -> Result<(), String> {
        self.stop()?;
        std::thread::sleep(std::time::Duration::from_secs(1));
        self.start(port)
    }
}

#[tauri::command]
pub fn check_backend_health() -> Result<bool, String> {
    // 檢查後端是否正常運作
    let client = reqwest::blocking::Client::new();
    match client.get("http://localhost:3000/health").send() {
        Ok(response) => Ok(response.status().is_success()),
        Err(_) => Ok(false)
    }
}
```

---

## Subtask 12.4: 實作系統托盤

### 系統托盤管理 (`src-tauri/src/tray.rs`)

```rust
use tauri::{
    AppHandle, CustomMenuItem, SystemTray, SystemTrayEvent, 
    SystemTrayMenu, SystemTrayMenuItem, Manager
};

pub fn create_tray() -> SystemTray {
    let show = CustomMenuItem::new("show".to_string(), "顯示主視窗");
    let hide = CustomMenuItem::new("hide".to_string(), "隱藏視窗");
    let settings = CustomMenuItem::new("settings".to_string(), "設定");
    let about = CustomMenuItem::new("about".to_string(), "關於");
    let quit = CustomMenuItem::new("quit".to_string(), "退出");
    
    let tray_menu = SystemTrayMenu::new()
        .add_item(show)
        .add_item(hide)
        .add_native_item(SystemTrayMenuItem::Separator)
        .add_item(settings)
        .add_item(about)
        .add_native_item(SystemTrayMenuItem::Separator)
        .add_item(quit);
    
    SystemTray::new().with_menu(tray_menu)
}

pub fn handle_tray_event(app: &AppHandle, event: SystemTrayEvent) {
    match event {
        SystemTrayEvent::LeftClick { .. } => {
            let window = app.get_window("main").unwrap();
            if window.is_visible().unwrap() {
                window.hide().unwrap();
            } else {
                window.show().unwrap();
                window.set_focus().unwrap();
            }
        }
        SystemTrayEvent::RightClick { .. } => {
            // 右鍵點擊顯示選單（預設行為）
        }
        SystemTrayEvent::MenuItemClick { id, .. } => {
            match id.as_str() {
                "show" => {
                    let window = app.get_window("main").unwrap();
                    window.show().unwrap();
                    window.set_focus().unwrap();
                }
                "hide" => {
                    let window = app.get_window("main").unwrap();
                    window.hide().unwrap();
                }
                "settings" => {
                    // 發送事件到前端，開啟設定視窗
                    app.emit_all("open-settings", ()).unwrap();
                }
                "about" => {
                    // 顯示關於對話框
                    tauri::api::dialog::message(
                        Some(&app.get_window("main").unwrap()),
                        "關於 AutoDoc Agent",
                        "AutoDoc Agent v2.0\n智能探索式使用手冊生成器\n\n© 2025 AutoDoc Team"
                    );
                }
                "quit" => {
                    std::process::exit(0);
                }
                _ => {}
            }
        }
        _ => {}
    }
}
```

---

## Subtask 12.5: 實作自動更新

### 更新管理器 (`src-tauri/src/updater.rs`)

```rust
use tauri::updater::builder::UpdaterBuilder;
use tauri::{AppHandle, Manager};
use log::{info, error};

#[tauri::command]
pub async fn check_for_updates(app: AppHandle) -> Result<UpdateInfo, String> {
    info!("檢查更新...");
    
    let updater = app.updater();
    
    match updater.check().await {
        Ok(update) => {
            if update.is_update_available() {
                let version = update.latest_version();
                let body = update.body().unwrap_or("無更新說明");
                let date = update.date().unwrap_or("未知日期");
                
                info!("發現新版本: {}", version);
                
                Ok(UpdateInfo {
                    available: true,
                    version: version.to_string(),
                    body: body.to_string(),
                    date: date.to_string(),
                })
            } else {
                info!("已是最新版本");
                Ok(UpdateInfo {
                    available: false,
                    version: String::new(),
                    body: String::new(),
                    date: String::new(),
                })
            }
        }
        Err(e) => {
            error!("檢查更新失敗: {}", e);
            Err(format!("檢查更新失敗: {}", e))
        }
    }
}

#[tauri::command]
pub async fn install_update(app: AppHandle) -> Result<(), String> {
    info!("開始安裝更新...");
    
    let updater = app.updater();
    
    match updater.check().await {
        Ok(update) => {
            if update.is_update_available() {
                update.download_and_install().await
                    .map_err(|e| format!("安裝更新失敗: {}", e))?;
                
                info!("更新安裝成功，準備重啟...");
                
                // 重啟應用程式
                app.restart();
                
                Ok(())
            } else {
                Err("無可用更新".to_string())
            }
        }
        Err(e) => {
            error!("安裝更新失敗: {}", e);
            Err(format!("安裝更新失敗: {}", e))
        }
    }
}

#[derive(serde::Serialize)]
pub struct UpdateInfo {
    pub available: bool,
    pub version: String,
    pub body: String,
    pub date: String,
}
```

---

## Subtask 12.6: 主程式整合

### main.rs

```rust
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod config;
mod sidecar;
mod tray;
mod updater;

use tauri::Manager;
use log::info;

fn main() {
    env_logger::init();
    
    info!("Starting AutoDoc Agent Desktop...");
    
    tauri::Builder::default()
        .setup(|app| {
            info!("Application setup...");
            
            // 啟動 Node.js Backend Sidecar
            let backend = sidecar::BackendProcess::new();
            app.manage(backend);
            
            // 載入配置
            match config::load_config() {
                Ok(cfg) => {
                    info!("配置載入成功");
                    app.manage(cfg);
                }
                Err(e) => {
                    info!("使用預設配置: {}", e);
                    let default_cfg = config::AppConfig::default();
                    config::save_config(default_cfg.clone()).ok();
                    app.manage(default_cfg);
                }
            }
            
            Ok(())
        })
        .system_tray(tray::create_tray())
        .on_system_tray_event(tray::handle_tray_event)
        .invoke_handler(tauri::generate_handler![
            config::load_config,
            config::save_config,
            config::validate_config,
            config::get_default_config,
            config::reset_config,
            sidecar::check_backend_health,
            updater::check_for_updates,
            updater::install_update,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

---

## 編譯與測試

### 開發模式

```bash
cd desktop

# 安裝前端依賴
npm install

# 開發模式（熱重載）
npm run tauri dev
```

### 打包

```bash
# 打包當前平台
npm run tauri build

# 指定平台
npm run tauri build -- --target x86_64-pc-windows-msvc      # Windows
npm run tauri build -- --target x86_64-apple-darwin          # macOS Intel
npm run tauri build -- --target aarch64-apple-darwin         # macOS Apple Silicon
npm run tauri build -- --target x86_64-unknown-linux-gnu     # Linux
```

### 輸出位置

```
desktop/src-tauri/target/release/
├── bundle/
│   ├── nsis/              # Windows NSIS 安裝程式
│   ├── msi/               # Windows MSI
│   ├── dmg/               # macOS DMG
│   ├── deb/               # Linux DEB
│   └── appimage/          # Linux AppImage
└── autodoc-agent.exe      # Windows 可執行檔
```

---

## 驗收標準

### 功能驗收

- [ ] Tauri 應用程式可正常啟動
- [ ] 配置載入與保存正常運作
- [ ] Node.js Backend Sidecar 正常啟動與停止
- [ ] 系統托盤功能正常
- [ ] 自動更新檢查與安裝正常
- [ ] 所有 Tauri Commands 測試通過

### 性能驗收

- [ ] 啟動時間 < 3 秒
- [ ] 記憶體佔用 < 100MB（閒置）
- [ ] CPU 使用率 < 5%（閒置）

### 跨平台驗收

- [ ] Windows 10/11 測試通過
- [ ] macOS 12+ 測試通過
- [ ] Ubuntu 22.04 測試通過

---

**下一份文檔**: [GUI 設定介面設計 →](v2_desktop_gui.md)
