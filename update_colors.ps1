# Afrobeat Fire Palette Implementation
# Replacing colors in all Dart files

$files = Get-ChildItem 'lib' -Recurse -Filter '*.dart'
$primaryOld = '0xFF00FF88'
$primaryNew = '0xFF1ED760'
$secondaryOld = '0xFFFF0099'
$secondaryNew = '0xFFFF6B35'

$totalFiles = 0
foreach($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $changed = $false
    
    if($content -match $primaryOld) {
        $content = $content -replace $primaryOld, $primaryNew
        $changed = $true
    }
    
    if($content -match $secondaryOld) {
        $content = $content -replace $secondaryOld, $secondaryNew
        $changed = $true
    }
    
    if($changed) {
        Set-Content $file.FullName -Value $content -NoNewline
        $totalFiles++
        Write-Host "Updated: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "
Total files updated: $totalFiles" -ForegroundColor Yellow
