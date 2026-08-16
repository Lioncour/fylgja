# Prepare iOS signing files on Windows for GitHub Actions.
#
# You still need a paid Apple Developer account. This script never talks to Apple;
# it only creates a CSR / encodes the files Apple gives you back.
#
# Usage:
#   .github/scripts/prepare-ios-signing.ps1 -Action Csr
#   .github/scripts/prepare-ios-signing.ps1 -Action EncodeP12 -CerPath .\ios_distribution.cer
#   .github/scripts/prepare-ios-signing.ps1 -Action EncodeProfile -ProfilePath .\Fylgja_App_Store.mobileprovision

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Csr", "EncodeP12", "EncodeProfile")]
    [string]$Action,

    [string]$CerPath = "ios_distribution.cer",
    [string]$ProfilePath = "",
    [string]$OutDir = "ios-signing"
)

$ErrorActionPreference = "Stop"

function Require-OpenSsl {
    $openssl = Get-Command openssl -ErrorAction SilentlyContinue
    if (-not $openssl) {
        throw "openssl was not found. Install Git for Windows (includes openssl) and reopen the terminal."
    }
}

function Ensure-OutDir {
    if (-not (Test-Path $OutDir)) {
        New-Item -ItemType Directory -Path $OutDir | Out-Null
    }
    return (Resolve-Path $OutDir).Path
}

switch ($Action) {
    "Csr" {
        Require-OpenSsl
        $dir = Ensure-OutDir
        $key = Join-Path $dir "ios_distribution.key"
        $csr = Join-Path $dir "ios_distribution.csr"
        openssl genrsa -out $key 2048
        openssl req -new -key $key -out $csr -subj "/CN=Fylgja iOS Distribution/C=NO"
        Write-Host ""
        Write-Host "CSR created: $csr"
        Write-Host "Next:"
        Write-Host "  1. https://developer.apple.com/account/resources/certificates/add"
        Write-Host "  2. Create Apple Distribution, upload the CSR"
        Write-Host "  3. Download the .cer into this folder"
        Write-Host "  4. Run: .github/scripts/prepare-ios-signing.ps1 -Action EncodeP12 -CerPath PATH\TO\distribution.cer"
    }

    "EncodeP12" {
        Require-OpenSsl
        $dir = Ensure-OutDir
        $key = Join-Path $dir "ios_distribution.key"
        if (-not (Test-Path $key)) {
            throw "Missing $key. Run -Action Csr first and keep the key file."
        }
        if (-not (Test-Path $CerPath)) {
            throw "Certificate not found: $CerPath"
        }
        $pem = Join-Path $dir "ios_distribution.pem"
        $p12 = Join-Path $dir "ios_distribution.p12"
        openssl x509 -in $CerPath -inform DER -out $pem
        Write-Host "Choose a password for the .p12 (this becomes GitHub secret IOS_P12_PASSWORD)."
        openssl pkcs12 -export -out $p12 -inkey $key -in $pem
        $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path $p12)))
        $b64Path = Join-Path $dir "IOS_BUILD_CERTIFICATE_BASE64.txt"
        Set-Content -Path $b64Path -Value $b64 -NoNewline
        Write-Host ""
        Write-Host "GitHub secret IOS_BUILD_CERTIFICATE_BASE64 is in:"
        Write-Host "  $b64Path"
        Write-Host "Paste the file contents into the secret. Do not commit $OutDir."
    }

    "EncodeProfile" {
        if (-not $ProfilePath) {
            throw "Pass -ProfilePath to the downloaded .mobileprovision"
        }
        if (-not (Test-Path $ProfilePath)) {
            throw "Profile not found: $ProfilePath"
        }
        $dir = Ensure-OutDir
        $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path $ProfilePath)))
        $b64Path = Join-Path $dir "IOS_PROVISION_PROFILE_BASE64.txt"
        Set-Content -Path $b64Path -Value $b64 -NoNewline
        Write-Host ""
        Write-Host "GitHub secret IOS_PROVISION_PROFILE_BASE64 is in:"
        Write-Host "  $b64Path"
        Write-Host "IOS_PROFILE_NAME must be the profile's name in the Apple Developer portal, e.g. 'Fylgja App Store'."
    }
}
