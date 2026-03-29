#!/bin/bash
# Script to generate base64-encoded Firebase config for GitHub Secrets
# Run this and copy the output to set up your secrets

set -e

echo "============================================"
echo "Firebase Config for GitHub Secrets"
echo "============================================"
echo ""
echo "Run these commands in your GitHub repo settings:"
echo "Settings > Secrets and variables > Actions > New repository secret"
echo ""
echo "============================================"
echo "1. FIREBASE_JSON"
echo "============================================"
base64 < firebase.json | tr -d '\n'
echo ""
echo ""
echo "============================================"
echo "2. GOOGLE_SERVICES_JSON"
echo "============================================"
base64 < android/app/google-services.json | tr -d '\n'
echo ""
echo ""
echo "============================================"
echo "3. GOOGLE_SERVICE_INFO_PLIST"
echo "============================================"
# Note: This single secret is used for both iOS and macOS in CI
base64 < ios/Runner/GoogleService-Info.plist | tr -d '\n'
echo ""
echo ""
echo "============================================"
echo "Done! Copy each value above to corresponding GitHub Secret"
echo "============================================"
