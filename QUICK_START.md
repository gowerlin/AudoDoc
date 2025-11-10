# AutoDoc Agent 快速開始指南

本指南將協助您快速設定並啟動 AutoDoc Agent 開發環境。

---

## 📋 當前安裝狀態

### ✅ 已完成
- ✅ Node.js v25.1.0 已安裝
- ✅ npm 11.6.2 已安裝
- ✅ Backend 依賴已安裝 (573 packages)
- ✅ Frontend 依賴已安裝 (449 packages)
- ✅ .env 環境設定檔已建立

### ⚠️ 需要手動安裝
- ⚠️  Rust 工具鏈（用於 Tauri 桌面應用）
- ⚠️  PostgreSQL 14+ 資料庫
- ⚠️  Desktop 專案依賴（需先安裝 Rust）

---

## 🚀 快速安裝（Windows）

### 方法 1: 使用自動安裝腳本

```powershell
# 以系統管理員身分執行 PowerShell 7
pwsh -ExecutionPolicy Bypass -File setup-windows.ps1
```

這個腳本會自動安裝:
- Rust 工具鏈
- PostgreSQL 14
- Visual C++ Build Tools
- WebView2 Runtime
- 所有專案依賴

### 方法 2: 手動安裝

#### 1. 安裝 Rust

```powershell
# 使用 winget
winget install Rustlang.Rustup

# 或下載安裝程式
# https://rustup.rs/
```

安裝完成後，**關閉並重新開啟終端機**，然後驗證:
```powershell
rustc --version
cargo --version
```

#### 2. 安裝 PostgreSQL

```powershell
# 使用 winget
winget install PostgreSQL.PostgreSQL.14

# 或下載安裝程式
# https://www.postgresql.org/download/windows/
```

安裝時請記住您設定的密碼（預設使用者: postgres）

驗證安裝:
```powershell
psql --version
```

#### 3. 安裝 Visual C++ Build Tools（Rust 編譯需要）

```powershell
winget install Microsoft.VisualStudio.2022.BuildTools

# 或下載完整版 Visual Studio Community
# https://visualstudio.microsoft.com/downloads/
```

在安裝過程中，請選擇「Desktop development with C++」工作負載。

#### 4. 安裝 WebView2 Runtime（Tauri 需要）

```powershell
winget install Microsoft.EdgeWebView2Runtime
```

#### 5. 安裝 Desktop 專案依賴

```powershell
cd desktop
npm install
```

---

## ⚙️ 環境設定

### 1. 配置 .env 檔案

.env 檔案已建立，請編輯並設定以下必要欄位:

```env
# 資料庫連線（請更新為您的設定）
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/autodoc
DB_PASSWORD=YOUR_PASSWORD

# 安全密鑰（必須設定）
JWT_SECRET=已在 .env.secrets 中生成
ENCRYPTION_KEY=已在 .env.secrets 中生成

# Claude API（必須設定）
ANTHROPIC_API_KEY=sk-ant-api03-YOUR_KEY_HERE
```

**安全密鑰已生成**，請查看 `.env.secrets` 檔案並複製到 `.env`:
```powershell
cat .env.secrets
```

### 2. 初始化資料庫

#### 方法 A: 手動建立（需先安裝 PostgreSQL）

```powershell
# 連線到 PostgreSQL
psql -U postgres

# 在 psql 中執行
CREATE DATABASE autodoc;
CREATE USER autodoc_user WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE autodoc TO autodoc_user;
\q
```

#### 方法 B: 使用 SQL 腳本（如果專案中有 schema.sql）

```powershell
# 檢查是否有資料庫 schema
ls database/

# 如果有 schema.sql
psql -U postgres -d autodoc -f database/schema.sql
```

#### 方法 C: 使用 Docker Compose

```powershell
# 啟動 PostgreSQL 容器
docker-compose up -d postgres

# 等待資料庫就緒
Start-Sleep -Seconds 5

# 執行初始化（如果有腳本）
docker-compose exec postgres psql -U postgres -d autodoc -f /docker-entrypoint-initdb.d/schema.sql
```

---

## 🎯 啟動開發環境

### 啟動 Backend

```powershell
cd backend
npm run dev
```

Backend API 將運行在 `http://localhost:3000`

### 啟動 Frontend

開啟新的終端機視窗:
```powershell
cd frontend
npm run dev
```

Frontend 應用將運行在 `http://localhost:5173`

### 啟動 Desktop 應用（需先安裝 Rust）

開啟新的終端機視窗:
```powershell
cd desktop
npm run tauri:dev
```

---

## ✅ 驗證安裝

### 檢查服務狀態

```powershell
# 檢查 Backend API
curl http://localhost:3000/health

# 檢查 Frontend
curl http://localhost:5173
```

### 執行測試

```powershell
# Backend 測試
cd backend
npm test

# Frontend 測試
cd frontend
npm test

# Desktop 測試（需先安裝 Rust）
cd desktop
npm test
npm run test:rust
```

---

## 🔍 常見問題

### 問題 1: Rust 命令找不到

**解決方案**:
```powershell
# 重新載入環境變數
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# 或關閉並重新開啟終端機
```

### 問題 2: PostgreSQL 連線失敗

**解決方案**:
```powershell
# 檢查 PostgreSQL 服務是否運行
Get-Service -Name postgresql*

# 啟動服務
Start-Service postgresql-x64-14

# 或使用 Docker
docker-compose up -d postgres
```

### 問題 3: npm install 失敗

**解決方案**:
```powershell
# 清除 npm 快取
npm cache clean --force

# 刪除 node_modules 並重新安裝
Remove-Item -Recurse -Force node_modules
npm install
```

### 問題 4: Tauri 編譯錯誤（找不到 MSVC）

**解決方案**:
```powershell
# 確認已安裝 Visual C++ Build Tools
winget list Microsoft.VisualStudio

# 如果未安裝
winget install Microsoft.VisualStudio.2022.BuildTools
```

---

## 📚 下一步

1. 📖 閱讀 [完整開發環境設定指南](DEVELOPMENT_SETUP.md)
2. 📖 閱讀 [專案 README](README.md)
3. 📖 閱讀 [桌面應用文件](desktop/README.md)
4. 🔧 配置 Claude API 金鑰
5. 🔧 設定 Google Docs API（選配）
6. 🚀 開始開發！

---

## 🆘 獲取協助

如果遇到問題:
1. 查看 [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md) 的常見問題排除
2. 檢查 GitHub Issues
3. 查閱專案文檔

---

**最後更新**: 2025-11-11
**適用於**: Windows 10/11
