param(
    [switch]$CreateZip
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$dest = Join-Path $root "EasyEDA_STD_Project_LED"
if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
New-Item -ItemType Directory -Path $dest | Out-Null
Copy-Item -Recurse -Path (Join-Path $root "project_files") -Destination $dest
Copy-Item -Recurse -Path (Join-Path $root "pcb_files") -Destination $dest
Copy-Item -Recurse -Path (Join-Path $root "schematic_files") -Destination $dest
Write-Host "Rebuilt project folder: $dest"
if ($CreateZip) {
    $zipPath = Join-Path $root "HelioZone_v1_LED_MCPCB_EasyEDA_STD.zip"
    if (Test-Path $zipPath) { Remove-Item -Force $zipPath }
    Compress-Archive -Path (Join-Path $dest "*") -DestinationPath $zipPath
    Write-Host "Created zip: $zipPath"
}
