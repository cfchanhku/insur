# Insurance Policy Manager — UI Specifications

| Document version | 1.0 |
|---|---|
| Updated | 2026-10-19 |
| Product | Insurance Policy Manager (`insur`) |
| Classification | Proprietary — Internal Use Only |
| Locales | Traditional Chinese (`zh-Hant`), English (`en`) |

These specifications describe the intended interface and behavior for design and implementation. They are not a substitute for usability, accessibility, security, or bilingual review. All sample data in prototypes must be fictional and non-identifying.

## How to use

1. Create a team-owned Figma file named `insur — Insurance Policy Manager`.
2. Add pages using [Figma File Structure](#6-figma-file-structure); keep source components and screen flows separated.
3. Configure page-level variables for light/dark color, typography, spacing, radius, and elevation tokens in Section 1. Use semantic aliases in components rather than literal color values.
4. Enable Auto Layout on components and content groups. Use the specified constraints, variants, states, and minimum touch targets.
5. Create separate frames for each platform class and locale: mobile (390 × 844 baseline), tablet (834 × 1112 baseline), desktop (1440 × 900 baseline), with additional narrow/wide checks.
6. Duplicate key frames for `zh-Hant` and `en`; do not overlay languages in a single UI frame. Use variable text content per locale and review Traditional Chinese glyph/font coverage.
7. Prototype keyboard, focus, loading, empty, validation, destructive confirmation, lock, and error states. Do not add real customer, policy, or recovery-key material to the file.
8. Add annotations for responsive changes, accessibility semantics, data sensitivity, and approval-required actions. Export only approved non-sensitive design assets.

## 1. Design Tokens

Token values are initial design baselines. Confirm contrast, platform conventions, and color-vision accessibility before release. Never use color alone to communicate status.

### Color tokens

| Semantic token | Light | Dark | Use |
|---|---|---|---|
| `color.background` | `#F7F8FA` | `#11151B` | App canvas |
| `color.surface` | `#FFFFFF` | `#1B222B` | Cards, panels, dialogs |
| `color.surfaceVariant` | `#EEF1F5` | `#27313D` | Input fill, secondary containers |
| `color.textPrimary` | `#182230` | `#F4F6F8` | Main content |
| `color.textSecondary` | `#526174` | `#BCC6D1` | Supporting text |
| `color.textDisabled` | `#8994A2` | `#778493` | Disabled text |
| `color.outline` | `#AAB4C0` | `#566271` | Borders and dividers |
| `color.primary` | `#145C74` | `#67C4D8` | Primary actions and selected controls |
| `color.onPrimary` | `#FFFFFF` | `#08212A` | Text/icons on primary |
| `color.secondary` | `#4D6279` | `#A9BDD2` | Secondary action |
| `color.success` | `#216B4A` | `#75C99C` | Success with icon/label |
| `color.warning` | `#875400` | `#F0BB62` | Warning with icon/label |
| `color.error` | `#B3261E` | `#FF8A80` | Error/destructive state |
| `color.info` | `#315E9A` | `#91B8F2` | Informational state |
| `color.scrim` | `#000000` at 40% | `#000000` at 60% | Modal background |

### Typography tokens

| Token | Typeface guidance | Size / line height | Weight | Use |
|---|---|---:|---:|---|
| `type.display` | Platform sans; Traditional Chinese fallback | 32 / 40 px | 600 | Rare onboarding hero |
| `type.headline` | Platform sans; full CJK coverage | 24 / 32 px | 600 | Screen headings |
| `type.title` | Platform sans | 20 / 28 px | 600 | Section titles |
| `type.subtitle` | Platform sans | 16 / 24 px | 600 | Card / dialog headings |
| `type.body` | Platform sans | 16 / 24 px | 400 | Main labels and paragraphs |
| `type.bodySmall` | Platform sans | 14 / 20 px | 400 | Supporting copy |
| `type.label` | Platform sans | 14 / 20 px | 500 | Buttons and field labels |
| `type.caption` | Platform sans | 12 / 16 px | 400 | Metadata, never critical instructions alone |
| `type.numeric` | Tabular numeral feature where supported | 16 / 24 px | 500 | Policy identifiers/amounts |

Use scalable text styles and support system font scaling. Do not shrink text to fit; allow wrapping, scrolling, or responsive rearrangement. Verify fonts render Traditional Chinese characters consistently on all platforms.

### Spacing, radius, elevation, breakpoints

| Spacing token | Value |
|---|---:|
| `space.0` | 0 px |
| `space.1` | 4 px |
| `space.2` | 8 px |
| `space.3` | 12 px |
| `space.4` | 16 px |
| `space.5` | 24 px |
| `space.6` | 32 px |
| `space.7` | 40 px |
| `space.8` | 48 px |

| Radius token | Value | Use |
|---|---:|---|
| `radius.xs` | 4 px | Chips, compact controls |
| `radius.sm` | 8 px | Inputs, buttons |
| `radius.md` | 12 px | Cards |
| `radius.lg` | 20 px | Sheets, large panels |
| `radius.full` | 999 px | Pills, avatars |

| Elevation token | Shadow baseline | Use |
|---|---|---|
| `elevation.0` | None | Flat surfaces |
| `elevation.1` | 0 1px 3px / 10% | Cards |
| `elevation.2` | 0 4px 12px / 14% | Menus, floating controls |
| `elevation.3` | 0 12px 32px / 20% | Dialogs and overlays |

| Breakpoint | Width | Layout |
|---|---:|---|
| Mobile | `<600 px` | One primary content column; bottom navigation; full-width forms |
| Tablet | `600–1024 px` | Wider margins; adaptive navigation rail; two columns only for related summaries |
| Desktop | `>1024 px` | Persistent navigation rail/sidebar; centered bounded content or master-detail |

Respect safe areas, keyboard insets, minimum interactive target of 48 × 48 px, visible focus, and reduced-motion settings.

## 2. Component Library

All components use semantic color/type/spacing tokens, Auto Layout, and accessible labels. `Fill` means horizontal resizing behavior within the parent; fixed controls must have a maximum width where appropriate.

| Component | Variants / Auto Layout | Fill and text | States |
|---|---|---|---|
| Button / Primary | `default`, `compact`, `icon`; horizontal, centered | Hug content; optional leading/trailing icon; label | enabled, hover, focus, pressed, loading, disabled |
| Button / Secondary | `outlined`, `tonal`; horizontal | Hug; label + optional icon | enabled, hover, focus, pressed, disabled |
| Button / Text | `default`, `icon`; horizontal | Hug; label or accessible icon label | enabled, hover, focus, pressed, disabled |
| Button / Danger | `filled`, `outlined`; horizontal | Hug; explicit destructive verb | enabled, focus, pressed, loading, disabled |
| TextField / Outlined | `single-line`, `multiline`, `password`, `search`; vertical label/input/helper | Fill width; label, input, optional helper/error; trailing action | empty, focused, filled, invalid, disabled, obscured |
| Dropdown / Select | `standard`, `searchable`; vertical label/control | Fill width; selected value and chevron | closed, open, selected, invalid, disabled, empty |
| Checkbox | `standard`, `indeterminate`; horizontal label | Hug; label wraps | unchecked, checked, mixed, focus, disabled |
| Radio | `standard`; horizontal label | Hug; label wraps | unselected, selected, focus, disabled |
| Switch | `standard`; horizontal label/description | Fill row; label and optional supporting text | off, on, focus, disabled |
| Card / Base | `plain`, `outlined`, `interactive`; vertical | Fill width; title/content/actions slots | default, hover, focus, selected, disabled |
| ListItem / Base | `one-line`, `two-line`, `with-leading`, `with-trailing`; horizontal | Fill width; title, subtitle, optional metadata | default, hover, focus, selected, disabled |
| AppBar / Base | `mobile`, `desktop`; horizontal | Fill width; title + leading/back and trailing actions | default, scrolled, contextual |
| BottomNav / Base | `3–5 destinations`; horizontal | Fill width; icon + short label | selected/unselected, focus |
| Snackbar / Base | `info`, `success`, `warning`, `error`; horizontal | Hug/Fill by viewport; message + optional action | visible, dismissing; timeout must not hide critical error |
| Dialog / Base | `standard`, `confirmation`, `sensitive`; vertical | Bounded width; title, body, actions | open, validation error, busy |
| Banner / Warning | `warning`, `error`, `info`; horizontal | Fill width; icon, title/message, optional action | persistent/dismissible according to severity |
| Progress / Linear | `determinate`, `indeterminate`; horizontal | Fill width; accessible progress label | active, complete, error |
| Stepper / Setup | `horizontal`, `vertical`; responsive | Fill; step labels and current state | pending, current, completed, error |
| Icon / Set | `outline`, `filled`; 20/24/32 px | Fixed; semantic accessible name | default, selected, disabled |
| LanguageToggle | `segmented`, `menu`; horizontal | Hug; localized names “繁體中文” / “English” | current, focus, disabled |

Button text must describe an action; destructive actions use a distinct Danger style and confirmation. Inputs display persistent labels, not placeholder-only labels. Error/helper text must be associated programmatically and remain visible long enough to understand.

## 3. Screen Specifications

### Shared screen rules

- Mobile baseline: 390 × 844 logical px; tablet: 834 × 1112; desktop: 1440 × 900. Adapt to actual viewport and system insets.
- Use a consistent scaffold: background → app bar/navigation → scrollable content → primary action region → overlays/snackbars. On mobile, primary actions stay visible above the keyboard when feasible.
- All entity lists support loading, empty, error, populated, and archived/filtered states. Keep errors actionable and do not reveal sensitive values unnecessarily.
- Apply strings below as initial localization copy; translate remaining supporting/help/error text in both ARB files. String IDs are descriptive design references, not mandated code identifiers.
- Sample client and policy content must be synthetic. Mask high-risk identifiers by default in overview UI.

#### S1 — Splash

- **Frames:** Mobile 390 × 844; tablet/desktop centered adaptive launch frame.
- **Layout:** Center app mark and name; subtle loading indicator at lower center.
- **Layers:** `Scaffold / Background / BrandMark / AppName / Progress / Semantics`.
- **States:** launching, secure store unavailable, migration required, startup error (safe message plus retry).
- **Strings:** `appName` — 繁體中文「保險保單管理」 / English “Insurance Policy Manager”; `loading` — 「正在載入…」 / “Loading…”.

#### S2 — Setup Wizard

- **Frames:** Mobile 390 × 844; desktop 720 × 760 centered wizard.
- **Layout:** Stepper, intro, master passphrase fields, strength guidance, confirmation, primary Continue, privacy/security summary.
- **Layers:** `AppBar / Stepper / Intro / PassphraseField / ConfirmField / Guidance / Error / PrimaryAction / PrivacyNote`.
- **States:** first launch, validation error, weak passphrase, busy key derivation, setup failure. Never show or log entered secrets.
- **Strings:** `setupTitle` — 「設定保險資料庫」 / “Set up your secure vault”; `masterPassphrase` — 「主密碼」 / “Master passphrase”; `continue` — 「繼續」 / “Continue”; `localOnly` — 「資料只儲存在此裝置」 / “Your data stays on this device”.

##### S2b — Recovery Key

- **Frames:** Same wizard frame; recovery content uses a high-contrast warning region.
- **Layout:** One-time generated key shown only after secure generation; explicit save/print instruction, copy action with clipboard warning, confirmation challenge before proceeding.
- **Layers:** `Stepper / RecoveryWarning / KeyReveal / CopyAction / ConfirmationPrompt / ContinueDisabledUntilConfirmed`.
- **States:** key revealed, copied, hidden/expired, confirmation mismatch, confirmed. Do not include a real key in design files or analytics; reveal only for the intended setup step.
- **Strings:** `recoveryKeyTitle` — 「保存復原金鑰」 / “Save your recovery key”; `recoveryKeyWarning` — 「此金鑰無法重新顯示。請離線妥善保存。」 / “This key cannot be shown again. Store it safely offline.”; `confirmSaved` — 「我已安全保存」 / “I have stored it safely”.

##### S2c — Biometric

- **Frames:** Wizard frame; platform-specific permission/availability states annotated.
- **Layout:** Biometric illustration/icon, concise explanation, Enable and Skip actions; passphrase remains the fallback.
- **Layers:** `Stepper / BiometricIcon / Explanation / EnableButton / SkipButton / PlatformStatus`.
- **States:** available, permission prompt, enabled, declined, unavailable, error. Do not claim biometrics encrypt or replace the vault key.
- **Strings:** `biometricTitle` — 「啟用生物認證」 / “Enable biometric unlock”; `biometricBody` — 「可用指紋或臉部認證快速解鎖。主密碼仍可使用。」 / “Use biometrics for convenient unlocking. Your master passphrase remains available.”; `skip` — 「稍後設定」 / “Set up later”.

#### S3 — Login

- **Frames:** Mobile, tablet, desktop centered dialog/card.
- **Layout:** App name, passphrase entry, optional biometric action, unlock button, recovery link, lockout/help notice.
- **Layers:** `Brand / PassphraseField / RevealToggle / BiometricAction / Unlock / RecoveryLink / AttemptStatus`.
- **States:** locked, validating, incorrect credential (generic message), throttled/temporarily locked, database unavailable, unlocked transition. Never reveal whether a user or vault exists.
- **Strings:** `loginTitle` — 「解鎖保險資料庫」 / “Unlock your vault”; `unlock` — 「解鎖」 / “Unlock”; `incorrectCredential` — 「無法解鎖。請檢查資料後重試。」 / “Unable to unlock. Check your details and try again.”; `useRecoveryKey` — 「使用復原金鑰」 / “Use recovery key”.

#### S4 — Recovery

- **Frames:** Mobile and desktop narrow form.
- **Layout:** Explanation, recovery-key input, new passphrase and confirmation, irreversible warning, Recover action.
- **Layers:** `AppBar / RecoveryExplanation / KeyInput / NewPassphrase / Confirmation / Warning / RecoverAction`.
- **States:** input, validating, wrong key, recovery success, corrupt/unrecoverable backup, failure. Never echo the key in errors.
- **Strings:** `recoveryTitle` — 「復原資料庫」 / “Recover your vault”; `recoveryKeyInput` — 「復原金鑰」 / “Recovery key”; `recoveryWarning` — 「復原後請重新保存新的復原資訊。」 / “After recovery, securely store the replacement recovery information.”; `recover` — 「復原」 / “Recover”.

#### S5 — Home

- **Frames:** Mobile with bottom nav; tablet/desktop with navigation rail/sidebar and bounded content.
- **Layout:** Greeting without PII, quick search, count summaries, recent policies, expiring/attention section, add-client action.
- **Layers:** `AppShell / Navigation / Header / Search / SummaryCards / AttentionList / RecentPolicies / AddAction`.
- **States:** populated, first-use empty, no search results, loading, database error, privacy lock overlay. Avoid exposing full policy identifiers in cards.
- **Strings:** `homeTitle` — 「總覽」 / “Overview”; `clients` — 「客戶」 / “Clients”; `policies` — 「保單」 / “Policies”; `noPolicies` — 「尚未新增保單」 / “No policies added yet”; `addClient` — 「新增客戶」 / “Add client”.

#### S6 — Client Detail

- **Frames:** Mobile single-column; desktop master-detail or bounded detail with back navigation.
- **Layout:** Client name and masked identifiers, contact summary only if required, linked policy list, archive/edit actions.
- **Layers:** `AppBar / ClientHeader / MaskedSensitiveFields / PolicySection / EmptyState / EditAction / OverflowMenu`.
- **States:** view, edit, no policies, archived, validation, load error, confirm archive. Restrict sensitive fields to authorized unlocked session.
- **Strings:** `clientDetails` — 「客戶資料」 / “Client details”; `edit` — 「編輯」 / “Edit”; `archive` — 「封存」 / “Archive”; `linkedPolicies` — 「相關保單」 / “Related policies”.

#### S7 — Policy Detail

- **Frames:** Mobile and desktop detail.
- **Layout:** Provider/policy label, masked policy number, status and dates, policy holder/insured relationships, plan list, audit-relevant actions.
- **Layers:** `AppBar / PolicySummary / StatusChip / SensitiveNumberMasked / DateRows / PlanList / Actions`.
- **States:** active, pending, lapsed, archived, missing data, error, confirm archive. Do not infer coverage or give financial advice from display status.
- **Strings:** `policyDetails` — 「保單資料」 / “Policy details”; `policyNumber` — 「保單號碼」 / “Policy number”; `plans` — 「計劃」 / “Plans”; `archivePolicy` — 「封存保單」 / “Archive policy”.

#### S8 — Plan Form

- **Frames:** Mobile scroll form; desktop centered form with bounded width.
- **Layout:** Category selector first; selected category determines available plan dropdown; plan selection then reveals category-specific fields. Preserve prior input when changing category only when still valid; warn before discarding incompatible values.
- **Layers:** `AppBar / CategorySelect / PlanSelectDisabledUntilCategory / DynamicFields / Validation / SaveCancel`.
- **States:** create/edit, no category, loading options, no matching plan, validation, unsaved changes, save failure.
- **Strings:** `planTitle` — 「計劃資料」 / “Plan details”; `category` — 「計劃類別」 / “Plan category”; `selectCategoryFirst` — 「請先選擇計劃類別」 / “Select a category first”; `selectPlan` — 「選擇計劃」 / “Select a plan”; `save` — 「儲存」 / “Save”.

#### S9 — Rider Form

- **Frames:** Mobile and desktop form.
- **Layout:** Parent plan context, rider name/type, optional identifier, coverage/date fields as applicable, notes with sensitivity guidance.
- **Layers:** `AppBar / ParentPlanCard / RiderFields / DateFields / Validation / SaveCancel`.
- **States:** create/edit, parent missing, invalid dates, save error, unsaved changes.
- **Strings:** `riderTitle` — 「附加保障」 / “Rider”; `riderName` — 「附加保障名稱」 / “Rider name”; `parentPlan` — 「所屬計劃」 / “Parent plan”; `saveRider` — 「儲存附加保障」 / “Save rider”.

#### S10 — Archive

- **Frames:** Mobile list; tablet/desktop list with detail panel.
- **Layout:** Archive explanation, search/filter, archived clients/policies list, restore action, permanent-erasure action only if approved policy exists.
- **Layers:** `AppBar / RetentionNotice / SearchFilter / ArchivedList / RestoreAction / EmptyState`.
- **States:** empty, filtered, restoring, restored, retention warning, load error. Archive is reversible and does not mean secure deletion.
- **Strings:** `archiveTitle` — 「封存項目」 / “Archived items”; `restore` — 「還原」 / “Restore”; `archiveEmpty` — 「沒有封存項目」 / “No archived items”; `archiveNotice` — 「封存不會立即刪除資料。」 / “Archiving does not immediately erase data.”

#### S11 — Backup

- **Frames:** Mobile and desktop; file picker is native per platform.
- **Layout:** Last backup status, destination chooser, encryption/security explanation, password confirmation or approved key workflow, Create encrypted backup action.
- **Layers:** `AppBar / BackupStatus / SecurityBanner / Destination / CredentialEntry / Progress / BackupAction`.
- **States:** never backed up, ready, in progress, complete, insufficient storage, cancelled, wrong credentials, failure. Do not show secret values.
- **Strings:** `backupTitle` — 「加密備份」 / “Encrypted backup”; `createBackup` — 「建立加密備份」 / “Create encrypted backup”; `backupNotice` — 「備份包含敏感資料，請妥善保管。」 / “Backups contain sensitive data. Store them safely.”; `backupComplete` — 「備份已完成」 / “Backup complete”.

#### S12 — Restore

- **Frames:** Mobile and desktop guided flow.
- **Layout:** Choose backup, verify format/integrity, credential entry, preview metadata without exposing records, explicit destination/overwrite warning, restore progress.
- **Layers:** `AppBar / SelectBackup / ValidationStatus / CredentialField / OverwriteWarning / RestoreAction / Progress`.
- **States:** invalid file, unsupported version, wrong key, integrity failure, conflict/overwrite confirmation, restoring, success, recoverable error. Never replace current data before validated atomic restore.
- **Strings:** `restoreTitle` — 「還原備份」 / “Restore backup”; `chooseBackup` — 「選擇備份檔案」 / “Choose backup file”; `overwriteWarning` — 「還原可能取代目前資料。請先確認已有安全備份。」 / “Restore may replace current data. Confirm you have a safe backup first.”; `restore` — 「開始還原」 / “Restore”.

#### S13 — Export PDF

- **Frames:** Mobile, tablet, desktop preview with responsive toolbar.
- **Layout:** Select client/policy scope, field inclusion and masking controls, date range, preview, export destination, warning that exported files leave app-managed encryption boundary.
- **Layers:** `AppBar / ScopeSelection / DataOptions / MaskingSwitch / Preview / ExportWarning / Destination / ExportAction`.
- **States:** no selectable data, preview, generating, destination cancelled, success, failure. Require explicit confirmation before including sensitive identifiers.
- **Strings:** `exportTitle` — 「匯出 PDF」 / “Export PDF”; `includeSensitive` — 「包含完整敏感資料」 / “Include full sensitive details”; `exportWarning` — 「匯出檔案不再受應用程式保護。」 / “Exported files are no longer protected by the app.”; `export` — 「匯出」 / “Export”.

#### S14 — Settings

- **Frames:** Mobile grouped list; desktop sidebar + content.
- **Layout:** Language, appearance, biometric option, auto-lock duration, backup/audit shortcuts, security information, app version.
- **Layers:** `AppShell / SettingsNavigation / Preferences / SecurityGroup / About / Version`.
- **States:** default, preference saved, biometric unavailable, save error. Security-affecting changes require reauthentication where appropriate.
- **Strings:** `settingsTitle` — 「設定」 / “Settings”; `language` — 「語言」 / “Language”; `appearance` — 「外觀」 / “Appearance”; `autoLock` — 「自動鎖定」 / “Auto-lock”; `security` — 「安全性」 / “Security”.

#### S15 — Audit Log

- **Frames:** Mobile list; desktop filterable table/list with detail panel.
- **Layout:** Tamper-evident status, date/event filters, event list with safe summaries, event detail excluding sensitive payloads, retention explanation.
- **Layers:** `AppBar / IntegrityStatus / Filters / AuditList / EventDetail / RetentionNote`.
- **States:** verified, verification failed, empty, filtering, unavailable. Verification failure must be prominent and actionable; do not imply the chain proves all tampering impossible.
- **Strings:** `auditTitle` — 「活動記錄」 / “Activity log”; `integrityVerified` — 「記錄完整性已驗證」 / “Log integrity verified”; `integrityFailed` — 「無法驗證記錄完整性」 / “Log integrity could not be verified”; `retention` — 「記錄保留兩年」 / “Records are retained for two years”.

#### S16 — Lock

- **Frames:** Mobile overlay/screen; desktop lock window.
- **Layout:** Brand, locked status, unlock action, optional reason that does not reveal data, emergency quit action where platform appropriate.
- **Layers:** `OpaqueLockSurface / Brand / LockedLabel / UnlockAction / SafeStatus`.
- **States:** auto-locked, manually locked, app backgrounded, reauthentication required, secure database close failure. App content must be obscured immediately when locked or backgrounded.
- **Strings:** `lockedTitle` — 「資料庫已鎖定」 / “Vault locked”; `unlockToContinue` — 「請重新認證以繼續」 / “Authenticate to continue”; `unlock` — 「解鎖」 / “Unlock”.

## 4. Responsive Behavior Rules

| Viewport | Navigation | Content | Forms / detail |
|---|---|---|---|
| Mobile `<600 px` | Bottom navigation (primary destinations) and app-bar back; secondary actions in menus | Single column, edge-safe insets, scrollable lists | Full-width controls; dialogs become sheets/full-screen where space is constrained |
| Tablet `600–1024 px` | Navigation rail or adaptive drawer | Bounded wider content; two columns only for related summary cards | Center forms; master-detail where useful; preserve touch targets |
| Desktop `>1024 px` | Persistent navigation rail/sidebar with labels/tooltips | Bounded reading width or master-detail layout | Keyboard-operable controls, visible focus, sensible max widths, non-modal file workflow |

Across all sizes:

- Never clip localized text, critical warnings, or controls. Use wrapping and scrolling.
- Account for software keyboard and safe area; ensure focused fields and submit actions remain reachable.
- Preserve logical focus order and screen-reader semantics after responsive rearrangement.
- Respect system text scale and reduced motion. Provide keyboard shortcuts only with discoverable accessible alternatives.
- Do not depend on hover alone; expose action menus and focus states on touch devices.
- Mask sensitive identifiers consistently; user preference to reveal must be explicit and temporary.

## 5. Prototype Flow

```text
S1 Splash
  ├── first launch → S2 Setup Wizard → S2b Recovery Key → S2c Biometric → S5 Home
  └── existing vault → S3 Login ── unlock ──► S5 Home
                                  └─ recovery ─► S4 Recovery ─► S3 Login

S5 Home → S6 Client Detail → S7 Policy Detail → S8 Plan Form → S9 Rider Form
   │              └── archive → S10 Archive ← restore ──────────────┘
   ├── S11 Backup → S12 Restore
   ├── S13 Export PDF
   ├── S14 Settings → language / biometric / auto-lock / S15 Audit Log
   └── inactivity/manual lock → S16 Lock → re-authenticate → prior safe route
```

Use confirmation nodes for archive/restore overwrite/exporting full identifiers, and error nodes for failed authentication, invalid backup, audit verification failure, and database errors. Do not prototype a route that silently discards data or bypasses reauthentication.

## 6. Figma File Structure

Recommended Figma pages:

1. `00 Cover & Readme` — ownership, version, classification, change log, do-not-use-real-data notice.
2. `01 Foundations` — variables, color/type/spacing/radius/elevation tokens, accessibility samples.
3. `02 Components` — component sets, variants, interaction states, annotations.
4. `03 Mobile — zh-Hant`
5. `04 Mobile — en`
6. `05 Desktop — zh-Hant`
7. `06 Desktop — en`
8. `07 Tablet & Responsive`
9. `08 Prototype Flows`
10. `09 Archive — Approved` — superseded designs only; clearly dated and never confused with current specs.

Name frames with stable screen identifiers (`S1`, `S2`, … `S16`) plus locale, viewport, and state (for example `S11-backup__en__mobile__progress`). Mark approved components and screens with owner/date; retain a decision log for security-sensitive UX changes.

## 7. Design Handoff Notes

- Handoff includes source Figma link, approved revision, token definitions, asset licenses, screen/state inventory, responsive behavior, and per-locale string sheet.
- Include behavior for focus, keyboard, accessibility labels, reduced motion, validation, offline operation, lock timeout, and platform-native pickers.
- Pair every destructive or security-sensitive operation with its precise confirmation, error, cancellation, and audit behavior.
- Product and security reviewers approve key/recovery, biometric, backup/restore, export, lock, and audit flows before implementation.
- Engineering maps text to localization resources; Figma copy does not authorize hardcoded runtime strings.
- Check contrast against WCAG 2.2 AA targets where applicable, touch target sizes, screen reader reading order, and text scaling on each platform.
- Provide empty/loading/error/success variants for every data-driven screen; do not use blank states as success fallbacks.
- The app is local-only: do not design cloud sync, analytics consent, online account, remote recovery, or network-dependent status.
- Keep prototypes and exported assets free of real customer data, credential values, QR payloads, and production backup screenshots.
- Record unresolved questions instead of guessing policy/business rules, especially data retention, recovery, permanent erasure, and disclosure of full identifiers.
