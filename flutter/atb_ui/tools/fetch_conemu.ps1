# fetch_conemu.ps1
# 下载 ConEmu 最新发布（优先 zip）并解压到 cmder/vendor/conemu-maximus5
# 使用方法: 在 repo 根或任意位置运行此脚本

param(
    [string]$RepoRoot = 'c:\Users\47268\AllToolBox\flutter\atb_ui'
)

$ErrorActionPreference = 'Stop'
$api = 'https://api.github.com/repos/Maximus5/ConEmu/releases/latest'
Write-Host "Querying GitHub API: $api"
try {
    $rel = Invoke-RestMethod -Uri $api -UseBasicParsing -Headers @{ 'User-Agent' = 'PowerShell' }
} catch {
    Write-Error "无法访问 GitHub API: $_"
    exit 2
}

# 选择优先的 asset: 名称包含 x64 或 64 且为 zip 或 7z
$asset = $rel.assets | Where-Object { ($_.name -match '64' -or $_.name -match 'x64') -and ($_.name -match '\.zip$' -or $_.name -match '\.7z$' -or $_.name -match '\.exe$') } | Select-Object -First 1
if (-not $asset) {
    Write-Warning "未在 release assets 中找到合适的 zip/7z/exe 文件，打开 release 页面供手动下载。"
    Start-Process 'https://github.com/Maximus5/ConEmu/releases'
    exit 3
}

Write-Host "Selected asset: $($asset.name)"
$downloadUrl = $asset.browser_download_url
$temp = [System.IO.Path]::GetTempPath()
$outFile = Join-Path $temp $asset.name
Write-Host "Downloading to $outFile ..."
Invoke-WebRequest -Uri $downloadUrl -OutFile $outFile -UseBasicParsing -Headers @{ 'User-Agent' = 'PowerShell' }
Write-Host "Download complete."

$targetVendor = Join-Path $RepoRoot 'cmder\vendor\conemu-maximus5'
if (-not (Test-Path $targetVendor)) { New-Item -ItemType Directory -Path $targetVendor -Force | Out-Null }

if ($outFile -match '\.zip$') {
    Write-Host "Extracting zip to $targetVendor ..."
    try {
        Expand-Archive -Path $outFile -DestinationPath $targetVendor -Force
    } catch {
        Write-Error "解压失败: $_"
        exit 4
    }
} elseif ($outFile -match '\.7z$') {
    Write-Host "7z archive detected. Looking for 7z.exe in PATH..."
    $seven = Get-Command 7z -ErrorAction SilentlyContinue
    if (-not $seven) {
        Write-Warning "未找到 7z.exe，无法自动解压 .7z。请安装 7-Zip 或手动解压到 $targetVendor"
        Start-Process 'https://www.7-zip.org/download.html'
        exit 5
    }
    & 7z x $outFile -o"$targetVendor" -y
} elseif ($outFile -match '\.exe$') {
    Write-Host "Downloaded an exe; attempting to copy exe and supporting files if embedded"
    Copy-Item -Path $outFile -Destination $targetVendor -Force
} else {
    Write-Warning "未知文件类型： $outFile"
}

Write-Host "注意：仓库策略已禁用将 Cmder/ConEmu 自动复制到发布目录。要包含 ConEmu，请手动复制到项目的发布目录。"
Write-Host "脚本结束（已禁用自动复制）。"

exit 0
