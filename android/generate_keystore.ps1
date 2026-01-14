# Script to generate Android release keystore for Fylgja
# This will prompt you for keystore password and organization details

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fylgja Keystore Generator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will create a keystore file for signing your app for Google Play Store."
Write-Host "You'll be prompted for:"
Write-Host "  - Keystore password (remember this!)"
Write-Host "  - Key password (can be same as keystore password)"
Write-Host "  - Your name and organization details"
Write-Host ""
Write-Host "IMPORTANT: Keep the keystore file and passwords safe!" -ForegroundColor Yellow
Write-Host "           You'll need them for all future app updates." -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to continue"

# Generate the keystore
# Note: This will prompt interactively for all information
keytool -genkey -v -keystore keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Keystore generated successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. Copy android/key.properties.template to android/key.properties"
    Write-Host "2. Edit android/key.properties and fill in your passwords"
    Write-Host "3. The keystore file is at: android/keystore.jks"
    Write-Host ""
    Write-Host "Remember to keep the keystore and passwords safe!" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Error generating keystore" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Please check the error messages above."
}

Read-Host "Press Enter to exit"
