
Write-Host "========== 🗑️ STEP 2: Purging Local Build Folders ==========" -ForegroundColor Cyan
if (Test-Path -Path "gen") {
    Remove-Item -Recurse -Force gen
    Write-Host "✓ Removed local 'gen' directory." -ForegroundColor Green
}
if (Test-Path -Path "mta_archives") {
    Remove-Item -Recurse -Force mta_archives
    Write-Host "✓ Removed local 'mta_archives' directory." -ForegroundColor Green
}

# ADD THIS SECTION
Write-Host "========== 📦 STEP 2.5: Building CAP Project ==========" -ForegroundColor Cyan
cds build --production
if ($LASTEXITCODE -ne 0) {
    Write-Warning "❌ CAP Build failed. Check your CDS files for errors."
    exit 1
}
Write-Host "✓ CAP build completed successfully." -ForegroundColor Green

Write-Host "========== 🏗️ STEP 3: Rebuilding Fresh MTAR Archive ==========" -ForegroundColor Cyan
mbt build

if ($LASTEXITCODE -eq 0) {
    Write-Host "========== 🚀 STEP 4: Deploying Clean Application Bundle ==========" -ForegroundColor Cyan
    cf deploy mta_archives/crm-project_1.0.0.mtar
} else {
    Write-Warning "❌ MBT Build failed. Deployment aborted. Check your file syntax rules above."
}