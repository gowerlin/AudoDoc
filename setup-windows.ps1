#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    AutoDoc Agent Windows 開發環境自動安裝腳本
.DESCRIPTION
    自動安裝 Rust、PostgreSQL 等必要開發工具
.NOTES
    需要系統管理員權限執行部分操作
#>

Write-Host "🚀 AutoDoc Agent 開發環境安裝程式" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# 檢查 PowerShell 版本
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "❌ 需要 PowerShell 7 或更高版本" -ForegroundColor Red
    Write-Host "請執行: winget install Microsoft.PowerShell" -ForegroundColor Yellow
    exit 1
}

# 檢查是否有 winget
$wingetExists = Get-Command winget -ErrorAction SilentlyContinue
if (-not $wingetExists) {
    Write-Host "❌ 找不到 winget。請從 Microsoft Store 安裝 'App Installer'" -ForegroundColor Red
    exit 1
}

# 函數：檢查命令是否存在
function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# 1. 檢查 Node.js
Write-Host "📦 檢查 Node.js..." -ForegroundColor Yellow
if (Test-Command node) {
    $nodeVersion = node --version
    Write-Host "✅ Node.js 已安裝: $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "⚠️  Node.js 未安裝，正在安裝..." -ForegroundColor Yellow
    winget install OpenJS.NodeJS.LTS --silent
    Write-Host "✅ Node.js 安裝完成" -ForegroundColor Green
    Write-Host "⚠️  請關閉並重新開啟終端機以載入環境變數" -ForegroundColor Yellow
}

# 2. 檢查並安裝 Rust
Write-Host ""
Write-Host "🦀 檢查 Rust..." -ForegroundColor Yellow
if (Test-Command rustc) {
    $rustVersion = rustc --version
    Write-Host "✅ Rust 已安裝: $rustVersion" -ForegroundColor Green
} else {
    Write-Host "⚠️  Rust 未安裝，正在安裝..." -ForegroundColor Yellow
    winget install Rustlang.Rustup --silent
    Write-Host "✅ Rust 安裝完成" -ForegroundColor Green
    Write-Host "⚠️  請關閉並重新開啟終端機以載入環境變數" -ForegroundColor Yellow
}

# 3. 檢查並安裝 PostgreSQL
Write-Host ""
Write-Host "🐘 檢查 PostgreSQL..." -ForegroundColor Yellow
if (Test-Command psql) {
    $pgVersion = psql --version
    Write-Host "✅ PostgreSQL 已安裝: $pgVersion" -ForegroundColor Green
} else {
    Write-Host "⚠️  PostgreSQL 未安裝，正在安裝..." -ForegroundColor Yellow
    winget install PostgreSQL.PostgreSQL.14 --silent
    Write-Host "✅ PostgreSQL 安裝完成" -ForegroundColor Green
    Write-Host "ℹ️  預設密碼已在安裝過程中設定，請記住您設定的密碼" -ForegroundColor Cyan
}

# 4. 檢查 Visual C++ Build Tools（Rust 需要）
Write-Host ""
Write-Host "🔧 檢查 Visual C++ Build Tools..." -ForegroundColor Yellow
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsWhere) {
    Write-Host "✅ Visual Studio Build Tools 已安裝" -ForegroundColor Green
} else {
    Write-Host "⚠️  Visual C++ Build Tools 未安裝" -ForegroundColor Yellow
    Write-Host "請手動安裝 Visual Studio Build Tools:" -ForegroundColor Yellow
    Write-Host "  winget install Microsoft.VisualStudio.2022.BuildTools" -ForegroundColor Cyan
    Write-Host "  或下載: https://visualstudio.microsoft.com/downloads/" -ForegroundColor Cyan
}

# 5. 檢查 WebView2 Runtime（Tauri 需要）
Write-Host ""
Write-Host "🌐 檢查 WebView2 Runtime..." -ForegroundColor Yellow
$webview2Path = "${env:ProgramFiles(x86)}\Microsoft\EdgeWebView\Application"
if (Test-Path $webview2Path) {
    Write-Host "✅ WebView2 Runtime 已安裝" -ForegroundColor Green
} else {
    Write-Host "⚠️  WebView2 Runtime 未安裝，正在安裝..." -ForegroundColor Yellow
    winget install Microsoft.EdgeWebView2Runtime --silent
    Write-Host "✅ WebView2 Runtime 安裝完成" -ForegroundColor Green
}

# 6. 安裝專案依賴
Write-Host ""
Write-Host "📦 安裝專案依賴..." -ForegroundColor Yellow

# Backend
if (Test-Path "backend/package.json") {
    Write-Host "  → 安裝 Backend 依賴..." -ForegroundColor Cyan
    Push-Location backend
    npm install
    Pop-Location
    Write-Host "  ✅ Backend 依賴安裝完成" -ForegroundColor Green
}

# Frontend
if (Test-Path "frontend/package.json") {
    Write-Host "  → 安裝 Frontend 依賴..." -ForegroundColor Cyan
    Push-Location frontend
    npm install
    Pop-Location
    Write-Host "  ✅ Frontend 依賴安裝完成" -ForegroundColor Green
}

# Desktop (需要 Rust)
if ((Test-Path "desktop/package.json") -and (Test-Command cargo)) {
    Write-Host "  → 安裝 Desktop 依賴..." -ForegroundColor Cyan
    Push-Location desktop
    npm install
    Pop-Location
    Write-Host "  ✅ Desktop 依賴安裝完成" -ForegroundColor Green
} elseif (Test-Path "desktop/package.json") {
    Write-Host "  ⚠️  無法安裝 Desktop 依賴（Rust 未安裝）" -ForegroundColor Yellow
}

# 7. 設定環境變數檔案
Write-Host ""
Write-Host "⚙️  設定環境變數..." -ForegroundColor Yellow
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "✅ .env 檔案已建立" -ForegroundColor Green

    # 生成安全密鑰
    $jwtSecret = [Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(64))
    $encryptionKey = [Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))

    Write-Host "🔑 已生成安全密鑰，請手動更新 .env 檔案中的以下欄位:" -ForegroundColor Cyan
    Write-Host "JWT_SECRET=$jwtSecret" -ForegroundColor Gray
    Write-Host "ENCRYPTION_KEY=$encryptionKey" -ForegroundColor Gray
} else {
    Write-Host "ℹ️  .env 檔案已存在，跳過" -ForegroundColor Cyan
}

# 8. 完成訊息
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "✅ 安裝完成！" -ForegroundColor Green
Write-Host ""
Write-Host "📋 下一步操作:" -ForegroundColor Yellow
Write-Host "  1. 如果安裝了新軟體，請關閉並重新開啟終端機" -ForegroundColor White
Write-Host "  2. 編輯 .env 檔案並設定必要的環境變數（特別是資料庫和 API 金鑰）" -ForegroundColor White
Write-Host "  3. 初始化 PostgreSQL 資料庫:" -ForegroundColor White
Write-Host "     psql -U postgres -f database/schema.sql" -ForegroundColor Cyan
Write-Host "  4. 啟動開發伺服器:" -ForegroundColor White
Write-Host "     cd backend && npm run dev" -ForegroundColor Cyan
Write-Host "     cd frontend && npm run dev" -ForegroundColor Cyan
Write-Host "     cd desktop && npm run tauri:dev" -ForegroundColor Cyan
Write-Host ""
Write-Host "📚 詳細說明請參考 DEVELOPMENT_SETUP.md" -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Cyan
