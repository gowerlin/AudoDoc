# AutoDoc Agent Release Guide

本指南說明如何為 AutoDoc Agent 創建新的版本發布。

## 📋 前置條件

在創建發布之前，請確保：

1. ✅ 所有新功能和修復都已合併到主分支
2. ✅ 所有測試都通過
3. ✅ 文檔已更新
4. ✅ CHANGELOG.md 已準備好（如果有的話）

## 🚀 發布流程

### 方法 1：自動發布（推薦）

AutoDoc Agent 使用 GitHub Actions 自動化發布流程。當您推送版本標籤時，系統會自動：

1. 創建 GitHub Release
2. 構建所有平台的安裝包：
   - Windows: `.msi` 和 `.exe` 安裝程式
   - macOS (Intel): `.dmg` 安裝映像
   - macOS (Apple Silicon): `.dmg` 安裝映像
   - Linux: `.AppImage` 和 `.deb` 套件
3. 上傳所有構建產物到 Release

#### 步驟：

1. **更新版本號**

   更新以下文件中的版本號：
   
   ```bash
   # 更新 desktop/package.json
   cd desktop
   npm version <new-version> --no-git-tag-version
   
   # 更新 desktop/src-tauri/tauri.conf.json
   # 手動編輯文件，將 "version" 欄位改為新版本號
   ```

2. **提交版本變更**

   ```bash
   git add desktop/package.json desktop/src-tauri/tauri.conf.json
   git commit -m "chore: bump version to v<new-version>"
   git push origin main
   ```

3. **創建並推送標籤**

   ```bash
   # 創建標籤（使用 v 前綴）
   git tag v<new-version>
   
   # 例如：
   git tag v1.0.0-beta1
   
   # 推送標籤到 GitHub
   git push origin v<new-version>
   ```

4. **等待構建完成**

   - 前往 [GitHub Actions](https://github.com/gowerlin/AudoDoc/actions)
   - 找到 "Release" workflow
   - 等待所有構建任務完成（約 30-60 分鐘）

5. **驗證發布**

   - 前往 [Releases 頁面](https://github.com/gowerlin/AudoDoc/releases)
   - 確認所有安裝包都已上傳：
     - `autodoc-agent_v<version>_x64.msi`
     - `autodoc-agent_v<version>_x64.dmg`
     - `autodoc-agent_v<version>_aarch64.dmg`
     - `autodoc-agent_v<version>_amd64.AppImage`
     - 其他額外的套件（.exe, .deb 等）

### 方法 2：手動觸發發布

如果您不想創建標籤，也可以手動觸發發布流程：

1. 前往 [GitHub Actions](https://github.com/gowerlin/AudoDoc/actions)
2. 選擇 "Release" workflow
3. 點擊 "Run workflow"
4. 輸入版本號（例如：`v1.0.0-beta1`）
5. 點擊 "Run workflow" 按鈕

## 📦 測試構建（不發布）

如果您想測試構建過程而不創建正式發布：

1. 前往 [GitHub Actions](https://github.com/gowerlin/AudoDoc/actions)
2. 選擇 "Package" workflow
3. 點擊 "Run workflow"
4. 選擇要構建的目標：
   - `all` - 構建所有平台
   - `desktop-windows` - 僅構建 Windows
   - `desktop-macos` - 僅構建 macOS
   - `desktop-linux` - 僅構建 Linux
   - `backend` - 僅構建後端
   - `frontend` - 僅構建前端
5. 選擇是否上傳 artifacts
6. 點擊 "Run workflow" 按鈕

構建完成後，您可以在 workflow 的 "Artifacts" 部分下載構建產物。

## 📝 版本命名規範

使用語義化版本 (Semantic Versioning)：

- **主版本 (Major)**：`v2.0.0` - 不兼容的 API 變更
- **次版本 (Minor)**：`v1.1.0` - 向後兼容的功能新增
- **修訂版本 (Patch)**：`v1.0.1` - 向後兼容的錯誤修復

對於預發布版本，可以添加後綴：

- Alpha：`v1.0.0-alpha.1`
- Beta：`v1.0.0-beta.1`
- RC：`v1.0.0-rc.1`

## 🔍 構建產物說明

### Desktop 應用

| 平台 | 檔案類型 | 檔名格式 | 說明 |
|------|---------|---------|------|
| Windows | MSI | `autodoc-agent_v<version>_x64.msi` | Windows 安裝程式（推薦） |
| Windows | NSIS | `autodoc-agent_v<version>_x64-setup.exe` | Windows 安裝程式（備選） |
| macOS (Intel) | DMG | `autodoc-agent_v<version>_x64.dmg` | macOS 安裝映像（Intel 處理器） |
| macOS (Apple Silicon) | DMG | `autodoc-agent_v<version>_aarch64.dmg` | macOS 安裝映像（M1/M2 處理器） |
| Linux | AppImage | `autodoc-agent_v<version>_amd64.AppImage` | Linux 通用格式 |
| Linux | DEB | `autodoc-agent_v<version>_amd64.deb` | Debian/Ubuntu 套件 |

### Backend Bundle

| 平台 | 檔名 |
|------|------|
| All | `backend-bundle.tar.gz` |

### Frontend Bundle

| 平台 | 檔名 |
|------|------|
| Web | `frontend-dist.tar.gz` |

## ⚠️ 常見問題

### Q: 為什麼我的 Release 沒有產生安裝包？

A: 請檢查：
1. 標籤格式是否正確（必須是 `v*.*.*` 格式）
2. GitHub Actions 是否有足夠的權限
3. 查看 workflow 日誌，找出具體錯誤

### Q: 構建失敗怎麼辦？

A: 常見原因：
1. 依賴項安裝失敗 - 檢查網路連接
2. 編譯錯誤 - 檢查代碼是否有語法錯誤
3. 簽名失敗 - macOS 和 Windows 可能需要簽名憑證

### Q: 如何創建 Pre-release？

A: 修改 `.github/workflows/release.yml` 中的 `prerelease` 欄位：
```yaml
prerelease: true  # 改為 true
```

或在版本號中使用 alpha/beta 後綴。

### Q: 如何刪除錯誤的 Release？

A:
1. 前往 [Releases 頁面](https://github.com/gowerlin/AudoDoc/releases)
2. 點擊要刪除的 Release
3. 點擊 "Delete" 按鈕
4. 刪除對應的 Git 標籤：
   ```bash
   git tag -d v<version>
   git push origin :refs/tags/v<version>
   ```

## 🎯 示例：發布 v1.0.0-beta1

```bash
# 1. 更新版本號
cd desktop
npm version 1.0.0-beta1 --no-git-tag-version

# 2. 手動更新 desktop/src-tauri/tauri.conf.json
# 將 "version": "2.0.0" 改為 "version": "1.0.0-beta1"

# 3. 提交變更
cd ..
git add desktop/package.json desktop/src-tauri/tauri.conf.json
git commit -m "chore: bump version to v1.0.0-beta1"
git push origin main

# 4. 創建並推送標籤
git tag v1.0.0-beta1
git push origin v1.0.0-beta1

# 5. 前往 GitHub Actions 查看構建進度
# 6. 構建完成後，前往 Releases 頁面驗證
```

## 📚 參考資源

- [Tauri 文檔](https://tauri.app/v1/guides/building/)
- [GitHub Actions 文檔](https://docs.github.com/en/actions)
- [語義化版本](https://semver.org/lang/zh-TW/)

## 🤝 貢獻

如有任何問題或建議，請提交 Issue 或 Pull Request。
