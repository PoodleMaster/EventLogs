# ===============================================================
# EventLogsV2.ps1
# Power / GPU / WHEA / Storage Event Export
# ===============================================================


# ----------------------------------------------------------------
# イベントログID一覧
# ----------------------------------------------------------------
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



# ===============================================================
# 設定
# ===============================================================

$Days = 90
$StartTime = (Get-Date).AddDays(-$Days)
$Result = @()



# ===============================================================
# 共通取得関数
# ===============================================================

function Add-Events {

    param(
        [string]$Type,
        [string]$Provider,
        [int[]]$Ids
    )


    try {

        $Events = Get-WinEvent `
        -FilterHashtable @{
            LogName      = 'System'
            ProviderName = $Provider
            Id           = $Ids
            StartTime    = $StartTime
        } `
        -ErrorAction Stop


        foreach ($e in $Events) {

            $script:Result += [PSCustomObject]@{

                TimeCreated = $e.TimeCreated
                Type        = $Type
                Provider    = $e.ProviderName
                ID          = $e.Id
                Level       = $e.LevelDisplayName
                Message     = $e.Message

            }
        }

    }
    catch {
        # Providerなし、イベントなしは無視
    }

}



# ===============================================================
# Power
# ===============================================================

Add-Events "Power" `
"Microsoft-Windows-Kernel-General" `
@(12,13)


Add-Events "Power" `
"EventLog" `
@(6005,6006,6008,6009)


Add-Events "Power" `
"User32" `
@(1074)


Add-Events "Power" `
"Microsoft-Windows-Kernel-Power" `
@(41)


Add-Events "BSOD" `
"Microsoft-Windows-WER-SystemErrorReporting" `
@(1001)



# ===============================================================
# GPU Common
# ===============================================================

Add-Events "GPU" `
"Display" `
@(4101)



# ===============================================================
# NVIDIA GPU
# ===============================================================

Add-Events "GPU" `
"nvlddmkm" `
@(13,14,153)




# ===============================================================
# WHEA
# ===============================================================

Add-Events "WHEA" `
"Microsoft-Windows-WHEA-Logger" `
@(17,18)




# ===============================================================
# Storage
# ===============================================================

Add-Events "Storage" `
"disk" `
@(7,51,153)


Add-Events "Storage" `
"stornvme" `
@(11,129,153)


Add-Events "Storage" `
"storahci" `
@(129)


Add-Events "Storage" `
"Ntfs" `
@(55)



# ===============================================================
# CSV Export
# ===============================================================

$File = ".\EventLogsV2_{0}.csv" -f `
(Get-Date -Format "yyyyMMdd_HHmmss")


$Result |
Sort-Object TimeCreated -Descending |
Export-Csv `
$File `
-NoTypeInformation `
-Encoding UTF8



Write-Host ""
Write-Host "====================================="
Write-Host " EventLogsV2 Complete"
Write-Host " Output : $File"
Write-Host " Count  : $($Result.Count)"
Write-Host "====================================="