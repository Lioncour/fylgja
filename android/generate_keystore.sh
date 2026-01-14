#!/bin/bash
# Script to generate Android release keystore for Fylgja
# This will prompt you for keystore password and organization details

echo "========================================"
echo "Fylgja Keystore Generator"
echo "========================================"
echo ""
echo "This will create a keystore file for signing your app for Google Play Store."
echo "You'll be prompted for:"
echo "  - Keystore password (remember this!)"
echo "  - Key password (can be same as keystore password)"
echo "  - Your name and organization details"
echo ""
echo "IMPORTANT: Keep the keystore file and passwords safe!"
echo "           You'll need them for all future app updates."
echo ""
read -p "Press Enter to continue..."

# Generate the keystore
keytool -genkey -v -keystore keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "Keystore generated successfully!"
    echo "========================================"
    echo ""
    echo "Next steps:"
    echo "1. Copy android/key.properties.template to android/key.properties"
    echo "2. Edit android/key.properties and fill in your passwords"
    echo "3. The keystore file is at: android/keystore.jks"
    echo ""
    echo "Remember to keep the keystore and passwords safe!"
else
    echo ""
    echo "========================================"
    echo "Error generating keystore"
    echo "========================================"
    echo "Please check the error messages above."
fi
