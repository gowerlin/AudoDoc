# AutoDoc Agent 開發環境設定指南

本文件提供完整的開發環境安裝與設定步驟。

---

## 📋 系統需求

### 必要軟體

1. **Node.js** ≥ 20.0.0
2. **Rust** ≥ 1.75.0（用於 Tauri 桌面應用）
3. **PostgreSQL** ≥ 14.0
4. **Git** ≥ 2.30.0

### 選配軟體

- **Docker** & **Docker Compose**（用於容器化部署）
- **VS Code**（推薦開發工具）
- **Chrome/Edge** 瀏覽器（用於測試）

---

## 🔧 安裝步驟

### 1. Node.js 安裝

#### Windows
```powershell
# 使用 Winget 安裝
winget install OpenJS.NodeJS.LTS

# 或下載安裝程式
# https://nodejs.org/zh-tw/download/
```

#### macOS
```bash
# 使用 Homebrew
brew install node@20

# 使用 nvm (推薦)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 20
nvm use 20
```

#### Linux
```bash
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 使用 nvm (推薦)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 20
nvm use 20
```

#### 驗證安裝
```bash
node --version  # 應顯示 v20.x.x 或更高
npm --version   # 應顯示 9.x.x 或更高
```

✅ **當前狀態**: Node.js v25.1.0 已安裝

---

### 2. Rust 安裝（用於 Tauri 桌面應用）

#### Windows
```powershell
# 下載並執行 rustup-init.exe
# https://rustup.rs/

# 或使用 Winget
winget install Rustlang.Rustup

# 安裝完成後，關閉並重新開啟終端機
```

#### macOS/Linux
```bash
# 使用 rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 安裝完成後，載入環境變數
source $HOME/.cargo/env
```

#### 安裝 Tauri 必要組件

**Windows**:
```powershell
# 安裝 Microsoft Visual C++ Build Tools
# https://visualstudio.microsoft.com/downloads/
# 選擇 "Desktop development with C++"

# 安裝 WebView2 Runtime (通常 Windows 11 已預裝)
winget install Microsoft.EdgeWebView2Runtime
```

**macOS**:
```bash
# Xcode Command Line Tools
xcode-select --install
```

**Linux (Ubuntu/Debian)**:
```bash
sudo apt update
sudo apt install -y \
    libwebkit2gtk-4.1-dev \
    build-essential \
    curl \
    wget \
    file \
    libssl-dev \
    libgtk-3-dev \
    libayatana-appindicator3-dev \
    librsvg2-dev
```

#### 驗證安裝
```bash
rustc --version  # 應顯示 rustc 1.75.0 或更高
cargo --version  # 應顯示 cargo 1.75.0 或更高
```

⚠️ **需要安裝**: Rust 尚未安裝

---

### 3. PostgreSQL 安裝

#### Windows
```powershell
# 使用 Winget
winget install PostgreSQL.PostgreSQL.14

# 或下載安裝程式
# https://www.postgresql.org/download/windows/
```

#### macOS
```bash
# 使用 Homebrew
brew install postgresql@14

# 啟動服務
brew services start postgresql@14
```

#### Linux (Ubuntu/Debian)
```bash
# 安裝 PostgreSQL 14
sudo apt update
sudo apt install -y postgresql-14 postgresql-client-14

# 啟動服務
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### 初始化資料庫
```bash
# 切換到 postgres 使用者
sudo -u postgres psql

# 在 psql 中執行
CREATE DATABASE autodoc;
CREATE USER autodoc_user WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE autodoc TO autodoc_user;
\q
```

#### 驗證安裝
```bash
psql --version  # 應顯示 psql (PostgreSQL) 14.x 或更高

# 測試連線
psql -U autodoc_user -d autodoc -h localhost
```

⚠️ **需要安裝**: PostgreSQL 尚未安裝

---

## 📦 專案依賴安裝

### Backend 依賴
```bash
cd backend
npm install
```

**主要依賴套件**:
- `express`: Web 伺服器框架
- `@anthropic-ai/sdk`: Claude AI API
- `puppeteer-core`: Chrome DevTools Protocol
- `pg`: PostgreSQL 客戶端
- `sharp`: 圖像處理
- `pixelmatch`: 圖像比對
- `typescript`: TypeScript 編譯器

### Frontend 依賴
```bash
cd frontend
npm install
```

**主要依賴套件**:
- `react`: UI 框架
- `vite`: 建置工具
- `axios`: HTTP 客戶端
- `zustand`: 狀態管理
- `tailwindcss`: CSS 框架

### Desktop 依賴
```bash
cd desktop
npm install
```

**主要依賴套件**:
- `@tauri-apps/api`: Tauri API
- `react`: UI 框架
- `antd`: Ant Design 組件庫

**Rust 依賴** (自動安裝):
```bash
cd desktop/src-tauri
cargo fetch
```

---

## ⚙️ 環境設定

### 1. 建立環境變數檔案

```bash
# 複製範本
cp .env.example .env

# 編輯 .env 檔案
```

### 2. 必要的環境變數設定

**資料庫連線**:
```env
DATABASE_URL=postgresql://autodoc_user:your_secure_password@localhost:5432/autodoc
DB_HOST=localhost
DB_PORT=5432
DB_NAME=autodoc
DB_USER=autodoc_user
DB_PASSWORD=your_secure_password
```

**Claude API**:
```env
ANTHROPIC_API_KEY=sk-ant-api03-...
CLAUDE_MODEL=claude-sonnet-4-20250514
```

**安全性** (必須設定):
```bash
# 生成 JWT Secret
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"

# 生成 Encryption Key (至少 32 字元)
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

將生成的密鑰填入 `.env`:
```env
JWT_SECRET=生成的_jwt_secret
ENCRYPTION_KEY=生成的_encryption_key
```

### 3. Google Docs API 設定 (選配)

如需使用 Google Docs 輸出功能:

1. 前往 [Google Cloud Console](https://console.cloud.google.com/)
2. 建立新專案
3. 啟用 Google Docs API
4. 建立 OAuth 2.0 憑證
5. 下載憑證檔案到 `credentials/google-credentials.json`
6. 設定環境變數:

```env
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret
GOOGLE_REDIRECT_URI=http://localhost:3000/auth/google/callback
GOOGLE_CREDENTIALS_PATH=./credentials/google-credentials.json
```

---

## 🗄️ 資料庫初始化

### 方法 1: 使用 SQL 腳本

```bash
# 執行資料庫遷移腳本
psql -U autodoc_user -d autodoc -h localhost -f database/schema.sql
```

### 方法 2: 使用 Docker Compose

```bash
# 啟動 PostgreSQL 容器
docker-compose up -d postgres

# 等待資料庫就緒
sleep 5

# 執行初始化腳本
docker-compose exec postgres psql -U autodoc_user -d autodoc -f /docker-entrypoint-initdb.d/schema.sql
```

---

## 🚀 啟動開發伺服器

### Backend
```bash
cd backend
npm run dev
```
伺服器將運行在 `http://localhost:3000`

### Frontend
```bash
cd frontend
npm run dev
```
前端應用將運行在 `http://localhost:5173`

### Desktop (Tauri)
```bash
cd desktop
npm run tauri:dev
```

---

## ✅ 驗證安裝

### 執行測試套件

```bash
# Backend 測試
cd backend
npm test

# Frontend 測試
cd frontend
npm test

# Desktop 測試
cd desktop
npm test
npm run test:rust
```

### 檢查服務狀態

```bash
# 檢查 Backend API
curl http://localhost:3000/health

# 檢查 Frontend
curl http://localhost:5173
```

---

## 🛠️ 常見問題排除

### Node.js 版本問題

**問題**: `node: command not found`
```bash
# 安裝 nvm 並切換版本
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc  # 或 source ~/.zshrc
nvm install 20
nvm use 20
```

### Rust 編譯錯誤

**問題**: Windows 上找不到 MSVC
```powershell
# 安裝 Visual Studio Build Tools
winget install Microsoft.VisualStudio.2022.BuildTools

# 或下載完整版 Visual Studio Community
# https://visualstudio.microsoft.com/downloads/
```

**問題**: Linux 缺少系統依賴
```bash
# Ubuntu/Debian
sudo apt install -y \
    build-essential \
    libwebkit2gtk-4.1-dev \
    libssl-dev \
    libgtk-3-dev
```

### PostgreSQL 連線問題

**問題**: `FATAL: Peer authentication failed`
```bash
# 編輯 pg_hba.conf
sudo nano /etc/postgresql/14/main/pg_hba.conf

# 將以下行:
# local   all   all   peer
# 改為:
# local   all   all   md5

# 重啟 PostgreSQL
sudo systemctl restart postgresql
```

**問題**: 密碼驗證失敗
```bash
# 重設密碼
sudo -u postgres psql
ALTER USER autodoc_user WITH PASSWORD 'new_password';
\q
```

### 權限問題

**問題**: `EACCES: permission denied`
```bash
# Linux/macOS - 修復 npm 權限
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

---

## 📚 其他資源

- [Node.js 官方文件](https://nodejs.org/docs/)
- [Rust 官方文件](https://www.rust-lang.org/learn)
- [Tauri 官方文件](https://tauri.app/v1/guides/)
- [PostgreSQL 官方文件](https://www.postgresql.org/docs/)
- [專案 README](README.md)
- [桌面應用 README](desktop/README.md)

---

**最後更新**: 2025-11-11
**維護者**: AutoDoc Team
