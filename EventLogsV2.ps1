# ===============================================================
# EventLogsV2.ps1
# ===============================================================


# ----------------------------------------------------------------
# イベントログID一覧
# ----------------------------------------------------------------
#
# 【Power / 起動・終了】
#
# ID    種類      意味
# ---------------------------------------------------------------
# 12    起動      OS起動（Kernel-General）
# 6005  起動      EventLogサービス開始
# 6009  起動      OS情報記録
#
# 13    正常      OS終了（Kernel-General）
# 1074  正常      再起動/シャットダウン要求
# 6006  正常      EventLogサービス停止
#
# 41    異常      Kernel-Power
# 6008  異常      予期しないシャットダウン
# 1001  異常      BugCheck(BSOD)
#
#
# 【GPU NVIDIA】
#
# Provider : nvlddmkm
#
# ID
# ---------------------------------------------------------------
# 13    Driver Error
# 14    GPU Hardware Error
# 153   GPU Timeout / Reset
#
#
# 【WHEA】
#
# Provider : Microsoft-Windows-WHEA-Logger
#
# ID
# ---------------------------------------------------------------
# 17    Corrected Hardware Error
#       PCIe / GPU / NVMe等
#
# 18    Fatal Hardware Error
#
#
# 【Storage】
#
# Provider     ID
# ---------------------------------------------------------------
# disk         7      Bad Block
# disk         51     Disk I/O Warning
# disk         153    I/O Retry
#
# stornvme     11     NVMe Controller Error
# stornvme     129    NVMe Reset
#
# storahci     129    SATA Reset
#
# Ntfs         55     File System Corruption
#
# ===============================================================


# ===============================================================
# 設定
# ===============================================================
$Days = 30
$StartTime = (Get-Date).AddDays(-$Days)
$Result = @()


# ===============================================================
# 共通取得関数
# ===============================================================

function Add-Events {

    param(
        [string]$Name,
        [string]$Provider,
        [int[]]$Ids
    )


    try {

        $events = Get-WinEvent `
        -FilterHashtable @{
            LogName      = 'System'
            ProviderName = $Provider
            Id           = $Ids
            StartTime    = $StartTime
        } `
        -ErrorAction Stop


        foreach ($e in $events) {

            $script:Result += [PSCustomObject]@{

                TimeCreated = $e.TimeCreated
                Type        = $Name
                ID          = $e.Id
                Provider    = $e.ProviderName
                Message     = $e.Message

            }

        }

    }
    catch {
        # Provider無し・イベント無しは無視
    }

}



# ===============================================================
# Power / 起動終了
# ===============================================================

Add-Events `
"Power" `
"Microsoft-Windows-Kernel-General" `
@(12,13)


Add-Events `
"Power" `
"Microsoft-Windows-Kernel-Power" `
@(41)


Add-Events `
"Power" `
"EventLog" `
@(6005,6006,6008,6009)


Add-Events `
"Power" `
"User32" `
@(1074)


Add-Events `
"BSOD" `
"Microsoft-Windows-WER-SystemErrorReporting" `
@(1001)




# ===============================================================
# NVIDIA GPU
# ===============================================================

Add-Events `
"GPU" `
"nvlddmkm" `
@(13,14,153)




# ===============================================================
# WHEA Hardware
# ===============================================================

Add-Events `
"WHEA" `
"Microsoft-Windows-WHEA-Logger" `
@(17,18)




# ===============================================================
# Storage White List
# ===============================================================

Add-Events `
"Storage-disk" `
"disk" `
@(7,51,153)


Add-Events `
"Storage-NVMe" `
"stornvme" `
@(11,129)


Add-Events `
"Storage-SATA" `
"storahci" `
@(129)


Add-Events `
"Storage-NTFS" `
"Ntfs" `
@(55)




# ===============================================================
# Export
# ===============================================================

$File = ".\EventLogsV3_{0}.csv" -f `
(Get-Date -Format "yyyyMMdd_HHmmss")


$Result |
Sort-Object TimeCreated -Descending |
Export-Csv `
$File `
-NoTypeInformation `
-Encoding UTF8



Write-Host ""
Write-Host "====================================="
Write-Host " EventLogsV3 Complete"
Write-Host " Output : $File"
Write-Host " Count  : $($Result.Count)"
Write-Host "====================================="

