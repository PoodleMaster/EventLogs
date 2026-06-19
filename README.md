# Windows EventLogs抽出プログラム
Windows用のイベント・ログの一次解析用プログラム。<BR>
イベント・ログから必要なもののみ抽出します。

# 1．プログラム

Windowsの起動、終了に加えてGPU、Hardware、Storage等基本的なものも抽出します。
* **PowerShell用プログラム**
  * EventLogsV2_PS.bat … 起動用プログラム
  * EventLogsV2.ps1 … 実行プログラム


# 2．抽出するイベントログID
```
# ----------------------------------------------------------------
# イベントログID一覧
# ----------------------------------------------------------------
#
# イベント判定基本:
#
#   LogName + Provider + ID
#
# ID単体では意味が決まらないためProviderも確認する
#
#
# 【Power / 起動・終了】
#
# Provider                              ID      意味
# ---------------------------------------------------------------
# Microsoft-Windows-Kernel-General      12      OS起動
# Microsoft-Windows-Kernel-General      13      OS終了
#
# EventLog                              6005    EventLogサービス開始
# EventLog                              6006    EventLogサービス停止
# EventLog                              6008    予期しないシャットダウン
# EventLog                              6009    OS情報記録
#
# User32                                1074    再起動/シャットダウン要求
#
# Microsoft-Windows-Kernel-Power        41      正常終了できなかった
#
# Microsoft-Windows-WER-SystemErrorReporting
#                                       1001    BugCheck(BSOD)
#
# 【GPU】
# 
# Provider                              ID      意味
# ---------------------------------------------------------------
# Display                               4101    GPU Driver Timeout Recovery
#                                               (NVIDIA / Intel / AMD共通)
#
# 【GPU NVIDIA】
#
# Provider                              ID      意味
# ---------------------------------------------------------------
# nvlddmkm                              13      Driver Error
# nvlddmkm                              14      GPU Hardware Error
# nvlddmkm                              153     GPU Timeout / Reset
#
#
# 【WHEA Hardware】
#
# Provider                              ID      意味
# ---------------------------------------------------------------
# Microsoft-Windows-WHEA-Logger         17      Corrected Hardware Error
#                                               PCIe / GPU / NVMe等
#
# Microsoft-Windows-WHEA-Logger         18      Fatal Hardware Error
#
#
# 【Storage】
#
# Provider                              ID      意味
# ---------------------------------------------------------------
# disk                                  7       Bad Block
# disk                                  51      Disk I/O Warning
# disk                                  153     Disk I/O Retry
#
# stornvme                              11      NVMe Controller Error
# stornvme                              129     NVMe Reset / Timeout
# stornvme                              153     NVMe I/O Retry
#
# storahci                              129     SATA Reset / Timeout
#
# Ntfs                                  55      File System Corruption
#
# ===============================================================
```

# 3．イベントログ例
## ①正常シャットダウンの場合
```
------------------------------------------------------------------
例）正常シャットダウンの場合
------------------------------------------------------------------
1074：誰かが再起動要求
↓
13：OS終了
↓
6006：EventLogサービス停止
↓
起動
↓
12：OS起動
↓
6005：EventLogサービス開始
↓
6009：OS情報記録
```

## ②Windows Updateの場合
```
------------------------------------------------------------------
例）Windows Updateの場合
------------------------------------------------------------------
1074：TrustedInstaller.exe / Windows Update が再起動要求
↓
13：OS終了
↓
6006：EventLogサービス停止
↓
再起動
↓
12：OS起動
↓
6005：EventLogサービス開始
↓
6009：OS情報記録
```


## ③電源断・フリーズの場合
```
------------------------------------------------------------------
例）電源断・フリーズの場合
------------------------------------------------------------------
突然停止

（1074なし）
（13なし）
（6006なしの場合あり）

↓ 起動後

41：Kernel-Power
↓
6008：Unexpected shutdown
↓
12：OS起動
↓
6005：EventLogサービス開始
↓
6009：OS情報記録
```


## ④ブルースクリーンの場合
```
------------------------------------------------------------------
例）ブルースクリーンの場合
------------------------------------------------------------------
1001：BugCheck
↓
41：Kernel-Power
↓
6008：Unexpected shutdown
↓
12：OS起動
↓
6005：EventLogサービス開始
```
