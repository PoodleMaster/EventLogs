import datetime
import subprocess
from pathlib import Path

date = datetime.datetime.now().strftime("%Y%m%d")

index = 1
while True:
    output_path = Path(f"./EventLogs_{date}_{index:02d}.csv")
    if not output_path.exists():
        break
    index += 1

ps_script = rf"""
Get-WinEvent -FilterHashtable @{{
    LogName='System'
    Id=12,13,1074,41,6008,6006,6005,6009,1001
}} |
Select-Object `
    TimeCreated,
    @{{Name='Result'; Expression={{
        switch ($_.Id) {{
            12   {{ 'Startup' }}
            6005 {{ 'Startup' }}
            6009 {{ 'Startup' }}
            13   {{ 'Normal' }}
            1074 {{ 'Normal' }}
            6006 {{ 'Normal' }}
            41   {{ 'Abnormal' }}
            6008 {{ 'Abnormal' }}
            1001 {{ 'BugCheck' }}
            default {{ 'Unknown' }}
        }}
    }}}},
    ProviderName,
    Id,
    Message |
Sort-Object TimeCreated -Descending |
Export-Csv "{output_path}" -Encoding UTF8 -NoTypeInformation
"""

subprocess.run(
    ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", ps_script],
    check=True
)

print(f"Export completed: .\\{output_path}")


"""
# ------------------------------------------------------------------
# イベントログID
# ------------------------------------------------------------------
# ID    種類    意味
# 12    起動    OS起動（Kernel-General）
# 6005  起動    EventLogサービス開始（Windows起動）
# 6009  起動    OS情報記録

# 13    正常    OS終了（Kernel-General）
# 1074  正常    誰かがシャットダウン/再起動を要求
# 6006  正常    EventLogサービス停止（終了処理完了）

# 41    異常    前回正常終了できなかった（Kernel-Power）
# 6008  異常    予期しないシャットダウンを検出
# 1001  異常    BugCheck（ブルースクリーン）


# ------------------------------------------------------------------
# 例）正常シャットダウンの場合
# ------------------------------------------------------------------
# 1074：誰かが再起動要求
# ↓
# 13：OS終了
# ↓
# 6006：EventLogサービス停止
# ↓
# 起動
# ↓
# 12：OS起動
# ↓
# 6005：EventLogサービス開始
# ↓
# 6009：OS情報記録


# ------------------------------------------------------------------
# 例）Windows Updateの場合
# ------------------------------------------------------------------
# 1074：TrustedInstaller.exe / Windows Update が再起動要求
# ↓
# 13：OS終了
# ↓
# 6006：EventLogサービス停止
# ↓
# 再起動
# ↓
# 12：OS起動
# ↓
# 6005：EventLogサービス開始
# ↓
# 6009：OS情報記録


# ------------------------------------------------------------------
# 例）電源断・フリーズの場合
# ------------------------------------------------------------------
# 突然停止
#
# （1074なし）
# （13なし）
# （6006なしの場合あり）
#
# ↓ 起動後
#
# 41：Kernel-Power
# ↓
# 6008：Unexpected shutdown
# ↓
# 12：OS起動
# ↓
# 6005：EventLogサービス開始
# ↓
# 6009：OS情報記録


# ------------------------------------------------------------------
# 例）ブルースクリーンの場合
# ------------------------------------------------------------------
# 1001：BugCheck
# ↓
# 41：Kernel-Power
# ↓
# 6008：Unexpected shutdown
# ↓
# 12：OS起動
# ↓
# 6005：EventLogサービス開始
"""