# Changelog

所有重要的專案變更都會記錄在此檔案中。

本專案遵循 [語義化版本](https://semver.org/lang/zh-TW/)。

## [Unreleased]

### 新增
- 完整的 GitHub Actions 自動化發布流程
- 支援多平台桌面應用構建：
  - Windows (MSI, NSIS)
  - macOS (Intel & Apple Silicon DMG)
  - Linux (AppImage, DEB)
- 發布指南文檔 (RELEASE_GUIDE.md)

### 改進
- 優化構建工作流程
- 改善錯誤處理和日誌記錄

### 修復
- 修正版本號格式問題

---

## 如何維護此 Changelog

### 類別

變更應該歸類到以下類別之一：

- **新增 (Added)** - 新功能
- **改進 (Changed)** - 現有功能的變更
- **棄用 (Deprecated)** - 即將移除的功能
- **移除 (Removed)** - 已移除的功能
- **修復 (Fixed)** - 錯誤修復
- **安全性 (Security)** - 安全性相關修正

### 發布新版本時

1. 將 `[Unreleased]` 部分的變更移到新版本標題下
2. 添加發布日期
3. 創建新的空白 `[Unreleased]` 部分

範例：

```markdown
## [1.0.0-beta1] - 2024-01-15

### 新增
- 功能 A
- 功能 B

### 修復
- 錯誤 X
- 錯誤 Y

## [Unreleased]

(保持此部分為空，等待新的變更)
```
