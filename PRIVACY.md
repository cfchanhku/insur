# Privacy Policy

**Effective date:** 2026-10-20  
**Status:** Draft for maintainer and legal review before public distribution.

## Summary

Insurance Policy Manager is designed for local use. The application code in
this repository does not implement account, cloud-sync, analytics, advertising,
or crash-report upload services. Records and exports are handled on the
device, and backups are written to a location selected by the user.

This description is not a substitute for checking the final distributed
build, its operating-system services, and the privacy requirements of the
distribution channel.

## Information stored on your device

Depending on what you enter, the application can store client names, contact
details, dates of birth, policy identifiers, insurer and coverage information,
and notes. The local database is configured to use SQLCipher. Selected fields
are additionally protected with AES-256-GCM. A passphrase-derived Argon2id key
wraps a randomly generated master key.

The application may also create encrypted backup files and password-protected
PDF exports at a destination you select. These files may contain sensitive
information. You are responsible for securing the destination, the files, and
their passwords.

## Information not collected by the application

The application does not include product analytics, advertising, tracking, or
cloud synchronization features. The project has no application server for
receiving your records. Network behavior of the operating system, app stores,
or third-party platform components is outside the application's local data
handling and may be governed by their own policies.

## Your choices and responsibilities

- Choose a strong vault passphrase and keep your recovery key in a separate,
  secure offline location.
- Create encrypted backups regularly and verify that you can restore them.
- Use the application's record-management controls to archive, restore, or
  permanently delete records.
- Understand that uninstalling an application does not necessarily erase every
  platform backup or exported file associated with it.
- The maintainers cannot recover vault data if you lose both the passphrase and
  recovery key.

## Third-party components

The application uses third-party libraries for PDF encryption, secure-storage
integration, biometric enrollment, and database access. They run as part of
the application; this repository does not configure them to transmit policy
records to the maintainers. Platform services may handle operating-system
credentials or distribution diagnostics according to the platform provider's
terms.

Biometric enrollment is currently a preference only. Biometric unlock is not
available in this release.

## Children

This application is designed for insurance record management and is not
directed to children.

## Policy changes and contact

This draft must be updated with the responsible publisher's legal name,
jurisdiction, privacy contact, and any legally required data-subject
information before public release. Until then, there is no verified public
privacy contact to provide.

---

## 繁體中文

# 隱私政策

**生效日期：** 2026-10-20  
**狀態：** 草稿，公開發布前須由維護者及法律顧問審閱。

## 摘要

保單管理系統旨在供本機使用。本儲存庫中的應用程式程式碼沒有實作帳戶、
雲端同步、分析、廣告或當機報告上傳服務。記錄及匯出檔案均在裝置上處理，
備份則寫入使用者選擇的位置。

此說明不能取代對最終發布版本、作業系統服務及發行平台私隱要求的檢查。

## 儲存在裝置上的資料

視乎使用者輸入的內容，應用程式可能儲存客戶姓名、聯絡資料、出生日期、
保單識別資料、承保公司及保障資料，以及備註。本機資料庫設定為使用
SQLCipher 加密；指定欄位會額外使用 AES-256-GCM 保護。由密碼衍生的
Argon2id 金鑰會包裝隨機產生的主金鑰。

應用程式亦可能在使用者選擇的位置建立加密備份及受密碼保護的 PDF 匯出檔。
這些檔案可能包含敏感資料。使用者有責任保護儲存位置、檔案及其密碼。

## 應用程式不會收集的資料

應用程式不包含產品分析、廣告、追蹤或雲端同步功能。本專案沒有接收記錄的
應用程式伺服器。作業系統、應用程式商店或第三方平台元件的網絡行為，屬於
應用程式本機資料處理範圍以外，並可能受其自身政策規管。

## 您的選擇及責任

- 設定強密碼，並將復原金鑰存放在另一個安全的離線位置。
- 定期建立加密備份，並確認能夠還原。
- 使用應用程式的記錄管理功能封存、還原或永久刪除記錄。
- 解除安裝應用程式未必會刪除與其相關的所有平台備份或匯出檔案。
- 若您同時遺失密碼及復原金鑰，維護者無法復原保險庫資料。

## 第三方元件

應用程式使用第三方函式庫處理 PDF 加密、安全儲存整合、生物辨識登記及
資料庫存取。本儲存庫沒有設定這些函式庫將保單資料傳送給維護者。平台服務
可能按平台供應商的條款處理作業系統憑證或發行診斷資料。

目前的生物辨識登記只會儲存偏好設定；本版本不提供生物辨識解鎖功能。

## 兒童

本應用程式為保險記錄管理而設，並非以兒童為對象。

## 政策更新及聯絡方式

公開發布前，須補上負責發布者的法律名稱、司法管轄區、私隱聯絡方式，以及
任何法律要求的資料當事人資訊。完成前，尚未核實可供公眾使用的私隱聯絡
方式。
