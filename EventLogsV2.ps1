# ===============================================================
# EventLogsV2.ps1
# Power / GPU / WHEA / Storage Event Export
# ===============================================================


# ---------------------------------------------------------------
# Output File
# ---------------------------------------------------------------

$date = Get-Date -Format "yyyyMMdd"

$index = 1

do {
    $outputPath = ".\EventLogsV2_{0}_{1:D2}.csv" -f $date,$index
    $index++
}
while (Test-Path $outputPath)



# ---------------------------------------------------------------
# Power / Boot / Shutdown
# ---------------------------------------------------------------

$PowerLogs = Get-WinEvent -FilterHashtable @{
    LogName='System'
    Id=12,13,1074,41,6008,6006,6005,6009,1001
} |
Select-Object `
    TimeCreated,
    @{Name='Category';Expression={'Power'}},
    @{Name='Result';Expression={
        switch ($_.Id) {

            12   {'Startup'}
            6005 {'Startup'}
            6009 {'Startup'}

            13   {'Normal'}
            1074 {'Normal'}
            6006 {'Normal'}

            41   {'Abnormal'}
            6008 {'Abnormal'}

            1001 {'BugCheck'}

            default {'Unknown'}
        }
    }},
    ProviderName,
    Id,
    Message



# ---------------------------------------------------------------
# GPU NVIDIA
# ---------------------------------------------------------------

$GpuLogs = Get-WinEvent -FilterHashtable @{
    LogName='System'
    ProviderName='nvlddmkm'
    Id=13,14,153
} -ErrorAction SilentlyContinue |
Select-Object `
    TimeCreated,
    @{Name='Category';Expression={'GPU'}},
    @{Name='Result';Expression={'GPU Driver'}},
    ProviderName,
    Id,
    Message



# ---------------------------------------------------------------
# Hardware WHEA
# ---------------------------------------------------------------

$HardwareLogs = Get-WinEvent -FilterHashtable @{
    LogName='System'
    ProviderName='Microsoft-Windows-WHEA-Logger'
} -ErrorAction SilentlyContinue |
Select-Object `
    TimeCreated,
    @{Name='Category';Expression={'Hardware'}},
    @{Name='Result';Expression={
        switch ($_.Id) {
            17 {'WHEA Corrected'}
            18 {'WHEA Fatal'}
            default {'Hardware Error'}
        }
    }},
    ProviderName,
    Id,
    Message



# ---------------------------------------------------------------
# Storage
# ---------------------------------------------------------------

$StorageLogs = Get-WinEvent -FilterHashtable @{
    LogName='System'
} |
Where-Object {
    $_.ProviderName -match 'disk|stornvme|storahci|ntfs'
} |
Select-Object `
    TimeCreated,
    @{Name='Category';Expression={'Storage'}},
    @{Name='Result';Expression={'Storage Error'}},
    ProviderName,
    Id,
    Message



# ---------------------------------------------------------------
# Export
# ---------------------------------------------------------------

$PowerLogs +
$GpuLogs +
$HardwareLogs +
$StorageLogs |
Sort-Object TimeCreated -Descending |
Export-Csv $outputPath -Encoding UTF8 -NoTypeInformation


Write-Host "Export completed: $outputPath"


# ----------------------------------------------------------------
# イベントログID一覧
# ----------------------------------------------------------------
#
# 【Power / 起動・終了】
#
# ID    種類      意味
# ---------------------------------------------------------------
# 12    起動      OS起動（Kernel-General）
# 6005  起動      EventLogサービス開始（Windows起動）
# 6009  起動      OSバージョン情報記録
#
# 13    正常      OS終了（Kernel-General）
# 1074  正常      ユーザー/プロセスによる再起動・シャットダウン要求
# 6006  正常      EventLogサービス停止（正常終了処理完了）
#
# 41    異常      Kernel-Power（前回正常終了できなかった）
# 6008  異常      予期しないシャットダウン検出
# 1001  異常      BugCheck（ブルースクリーン）
#
#
# 【GPU / NVIDIA】
#
# ID    種類      意味
# ---------------------------------------------------------------
# 13    異常      nvlddmkm ドライバーエラー
# 14    異常      NVIDIA GPU関連エラー
# 153   異常      GPU応答遅延・リセット系
#
#
# 【Hardware / WHEA】
#
# ID    種類      意味
# ---------------------------------------------------------------
# 17    注意      修正済みハードウェアエラー
#                 （PCIe / GPU / NVMe等、訂正可能）
#
# 18    異常      致命的ハードウェアエラー
#                 （CPU / メモリ / PCIe等）
#
#
# 【Storage】
#
# Provider            意味
# ---------------------------------------------------------------
# disk                HDD/SSD ディスクエラー
# stornvme            NVMe SSD コントローラーエラー
# storahci            SATA/AHCI コントローラーエラー
# ntfs                ファイルシステムエラー