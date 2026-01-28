#!/bin/bash
# Deploy GhosttlyTermLinkkY to physical iPhone via devicectl
# Requires: Xcode with valid Apple Development signing, connected device
set -e

DEVICE_ID="${1:-00008150-0008155C3C41401C}"
PROFILE_DIR="/Users/jeff/Library/Developer/Xcode/UserData/Provisioning Profiles"
APP_DIR="/Users/jeff/Library/Developer/Xcode/DerivedData"

echo "=== Building for device $DEVICE_ID ==="
xcodebuild \
  -scheme GhosttlyTermLinkkY \
  -destination "id=$DEVICE_ID" \
  -configuration Debug \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  build \
  DEVELOPMENT_TEAM=K993U8H5GX \
  CODE_SIGN_IDENTITY="Apple Development"

# Find the built .app
APP=$(find "$APP_DIR" -path "*/Debug-iphoneos/GhosttlyTermLinkkY.app" -type d | head -1)
if [ -z "$APP" ]; then
  echo "ERROR: Could not find built .app"
  exit 1
fi
echo "Built app: $APP"

# Find team provisioning profile (wildcard)
PROFILE=$(find "$PROFILE_DIR" -name "*.mobileprovision" -exec sh -c '
  security cms -D -i "$1" 2>/dev/null | grep -q "K993U8H5GX" && echo "$1"
' _ {} \; | head -1)

if [ -z "$PROFILE" ]; then
  echo "ERROR: No team provisioning profile found"
  exit 1
fi
echo "Using profile: $PROFILE"

# Extract entitlements from profile
ENTITLEMENTS=$(mktemp /tmp/entitlements.XXXXX.plist)
security cms -D -i "$PROFILE" 2>/dev/null | python3 -c "
import sys, plistlib
data = sys.stdin.buffer.read()
start = data.find(b'<?xml')
end = data.find(b'</plist>') + len(b'</plist>')
plist = plistlib.loads(data[start:end])
with open('$ENTITLEMENTS', 'wb') as f:
    plistlib.dump(plist.get('Entitlements', {}), f)
"

# Embed profile and sign
cp "$PROFILE" "$APP/embedded.mobileprovision"
codesign -f -s "Apple Development" --entitlements "$ENTITLEMENTS" "$APP/GhosttlyTermLinkkY"
codesign -f -s "Apple Development" --entitlements "$ENTITLEMENTS" "$APP"
rm -f "$ENTITLEMENTS"

# Install and launch
echo "=== Installing on device ==="
xcrun devicectl device install app --device "$DEVICE_ID" "$APP"

echo "=== Launching ==="
BUNDLE_ID=$(python3 -c "
import plistlib
with open('$APP/Info.plist', 'rb') as f:
    print(plistlib.load(f)['CFBundleIdentifier'].replace('\$(PRODUCT_BUNDLE_IDENTIFIER)', 'ghosttlytermlinkky.GhosttlyTermLinkkY'))
")
xcrun devicectl device process launch --device "$DEVICE_ID" "ghosttlytermlinkky.GhosttlyTermLinkkY"

echo ""
echo "=== App deployed and launched ==="
