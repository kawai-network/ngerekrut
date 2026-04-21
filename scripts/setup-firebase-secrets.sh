#!/bin/bash
# Script to generate and optionally set Firebase config as GitHub Secrets
# Requires 'gh' CLI to be installed and authenticated for auto-set mode

set -e

# Check if gh CLI is available
USE_GH=false
if command -v gh &> /dev/null; then
  USE_GH=true
fi

# Parse arguments
AUTO_SET=false
for arg in "$@"; do
  if [ "$arg" = "--auto" ] || [ "$arg" = "-a" ]; then
    AUTO_SET=true
    if [ "$USE_GH" = false ]; then
      echo "❌ Error: 'gh' CLI is not installed or not in PATH"
      echo "   Install: https://cli.github.com/"
      echo "   Or run without --auto to get base64 values manually"
      exit 1
    fi
    break
  fi
done

echo "============================================"
echo "Firebase Config for GitHub Secrets"
echo "============================================"
echo ""

if [ "$AUTO_SET" = true ]; then
  echo "🚀 Auto-set mode: Using 'gh' CLI to update secrets"
  echo ""
else
  echo "Manual mode: Copy the base64 values below to GitHub Secrets"
  echo "Settings > Secrets and variables > Actions > New repository secret"
  echo ""
fi

# 1. GOOGLE_SERVICES_JSON (required for Android, shared across flavors)
if [ -f "android/app/google-services.json" ]; then
  GOOGLE_SERVICES_JSON=$(base64 < android/app/google-services.json | tr -d '\n')
  if [ "$AUTO_SET" = true ]; then
    echo "📝 Setting GOOGLE_SERVICES_JSON secret..."
    gh secret set GOOGLE_SERVICES_JSON --body "$GOOGLE_SERVICES_JSON"
    echo "✅ GOOGLE_SERVICES_JSON set successfully"
  else
    echo "============================================"
    echo "1. GOOGLE_SERVICES_JSON"
    echo "============================================"
    echo "$GOOGLE_SERVICES_JSON"
    echo ""
  fi
  echo ""
else
  echo "❌ ERROR: android/app/google-services.json not found!"
  echo "   This is required for Android builds and should contain recruiter + jobseeker clients."
  exit 1
fi

# 2. GOOGLE_SERVICE_INFO_PLIST_RECRUITER (optional - for iOS recruiter flavor)
if [ -f "ios/Runner/GoogleService-Info-Recruiter.plist" ]; then
  GOOGLE_SERVICE_INFO_PLIST_RECRUITER=$(base64 < ios/Runner/GoogleService-Info-Recruiter.plist | tr -d '\n')
  if [ "$AUTO_SET" = true ]; then
    echo "📝 Setting GOOGLE_SERVICE_INFO_PLIST_RECRUITER secret..."
    gh secret set GOOGLE_SERVICE_INFO_PLIST_RECRUITER --body "$GOOGLE_SERVICE_INFO_PLIST_RECRUITER"
    echo "✅ GOOGLE_SERVICE_INFO_PLIST_RECRUITER set successfully"
  else
    echo "============================================"
    echo "2. GOOGLE_SERVICE_INFO_PLIST_RECRUITER"
    echo "============================================"
    echo "$GOOGLE_SERVICE_INFO_PLIST_RECRUITER"
    echo ""
  fi
  echo ""
else
  echo "⚠️  Skipping GOOGLE_SERVICE_INFO_PLIST_RECRUITER (GoogleService-Info-Recruiter.plist not found)"
  echo ""
fi

# 3. GOOGLE_SERVICE_INFO_PLIST_JOBSEEKER (optional - for iOS jobseeker flavor)
if [ -f "ios/Runner/GoogleService-Info-JobSeeker.plist" ]; then
  GOOGLE_SERVICE_INFO_PLIST_JOBSEEKER=$(base64 < ios/Runner/GoogleService-Info-JobSeeker.plist | tr -d '\n')
  if [ "$AUTO_SET" = true ]; then
    echo "📝 Setting GOOGLE_SERVICE_INFO_PLIST_JOBSEEKER secret..."
    gh secret set GOOGLE_SERVICE_INFO_PLIST_JOBSEEKER --body "$GOOGLE_SERVICE_INFO_PLIST_JOBSEEKER"
    echo "✅ GOOGLE_SERVICE_INFO_PLIST_JOBSEEKER set successfully"
  else
    echo "============================================"
    echo "3. GOOGLE_SERVICE_INFO_PLIST_JOBSEEKER"
    echo "============================================"
    echo "$GOOGLE_SERVICE_INFO_PLIST_JOBSEEKER"
    echo ""
  fi
  echo ""
else
  echo "⚠️  Skipping GOOGLE_SERVICE_INFO_PLIST_JOBSEEKER (GoogleService-Info-JobSeeker.plist not found)"
  echo ""
fi

# 4. ONESIGNAL_APP_ID (for push notifications)
if [ -f ".env" ]; then
  ONESIGNAL_APP_ID=$(grep "^ONESIGNAL_APP_ID=" .env | cut -d'=' -f2)
  if [ -n "$ONESIGNAL_APP_ID" ] && [ "$ONESIGNAL_APP_ID" != "your_onesignal_app_id" ]; then
    if [ "$AUTO_SET" = true ]; then
      echo "📝 Setting ONESIGNAL_APP_ID secret..."
      echo -n "$ONESIGNAL_APP_ID" | gh secret set ONESIGNAL_APP_ID
      echo "✅ ONESIGNAL_APP_ID set successfully"
    else
      echo "============================================"
      echo "4. ONESIGNAL_APP_ID"
      echo "============================================"
      echo "$ONESIGNAL_APP_ID"
      echo ""
    fi
    echo ""
  else
    echo "⚠️  Skipping ONESIGNAL_APP_ID (not set in .env or still using placeholder)"
    echo ""
  fi
else
  echo "⚠️  Skipping ONESIGNAL_APP_ID (.env file not found)"
  echo ""
fi

# 5. ONESIGNAL_API_KEY (for push notifications)
if [ -f ".env" ]; then
  ONESIGNAL_API_KEY=$(grep "^ONESIGNAL_API_KEY=" .env | cut -d'=' -f2)
  if [ -n "$ONESIGNAL_API_KEY" ] && [ "$ONESIGNAL_API_KEY" != "your_onesignal_rest_api_key" ]; then
    if [ "$AUTO_SET" = true ]; then
      echo "📝 Setting ONESIGNAL_API_KEY secret..."
      echo -n "$ONESIGNAL_API_KEY" | gh secret set ONESIGNAL_API_KEY
      echo "✅ ONESIGNAL_API_KEY set successfully"
    else
      echo "============================================"
      echo "5. ONESIGNAL_API_KEY"
      echo "============================================"
      echo "$ONESIGNAL_API_KEY"
      echo ""
    fi
    echo ""
  else
    echo "⚠️  Skipping ONESIGNAL_API_KEY (not set in .env or still using placeholder)"
    echo ""
  fi
else
  echo "⚠️  Skipping ONESIGNAL_API_KEY (.env file not found)"
  echo ""
fi

echo "============================================"
if [ "$AUTO_SET" = true ]; then
  echo "✅ Done! All secrets have been set via 'gh' CLI"
else
  echo "Done! Copy each value above to corresponding GitHub Secret"
fi
echo "============================================"
