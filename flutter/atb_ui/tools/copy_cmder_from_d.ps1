# copy_cmder_from_d.ps1
# Copy D:\cmder to project vendor and build release vendor, then try to launch ConEmu64.exe
$ErrorActionPreference = 'Stop'
$src = 'D:\cmder'
$repoVendor = 'C:\Users\47268\AllToolBox\flutter\atb_ui\cmder\vendor\conemu-maximus5'
$buildVendor = 'C:\Users\47268\AllToolBox\flutter\atb_ui\build\windows\x64\runner\Release\cmder\cmder\vendor\conemu-maximus5'

Write-Host "Source: $src"
if (-not (Test-Path $src)) {
    Write-Error "Source path not found: $src"
    exit 1
}

Write-Host "Ensuring repo vendor: $repoVendor"
New-Item -ItemType Directory -Path $repoVendor -Force | Out-Null
Write-Host "Copying files to repo vendor..."
Copy-Item -Path (Join-Path $src '*') -Destination $repoVendor -Recurse -Force

Write-Host "Ensuring build vendor: $buildVendor"
New-Item -ItemType Directory -Path $buildVendor -Force | Out-Null
Write-Host "Copying files to build vendor..."
Copy-Item -Path (Join-Path $repoVendor '*') -Destination $buildVendor -Recurse -Force

Write-Host '--- Copy complete ---'
Get-ChildItem $buildVendor | Select-Object Name,Length | Format-Table -AutoSize

$exe = Join-Path $buildVendor 'ConEmu64.exe'
if (Test-Path $exe) {
    Write-Host "Starting ConEmu64.exe from: $exe"
    Start-Process -FilePath $exe -WorkingDirectory (Split-Path $exe) -PassThru | Format-List
} else {
    Write-Host 'ConEmu64.exe not found in build vendor'
}
