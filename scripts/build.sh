#!/bin/bash
# build.sh - Remote iOS build trigger
# Run this on MacBook Pro, or SSH into it from Mac mini
#
# Usage:
#   ./build.sh          # Pull latest + build
#   ./build.sh archive  # Build + archive for TestFlight/Ad Hoc
#   ./build.sh sim      # Build for simulator

set -e

REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$REPO_DIR"

echo "=== GhosttlyTermLinkkY Build ==="
echo "Branch: $(git branch --show-current)"
echo "Last commit: $(git log -1 --oneline)"
echo ""

# Pull latest
git pull origin main 2>/dev/null || true

MODE="${1:-build}"

case "$MODE" in
    build|sim)
        echo "Building for simulator..."
        swift build 2>&1
        echo ""
        echo "Build complete."
        ;;
    archive)
        echo "Archiving for distribution..."
        xcodebuild -scheme GhosttlyTermLinkkY \
            -configuration Release \
            -archivePath build/GhosttlyTermLinkkY.xcarchive \
            archive 2>&1
        echo ""
        echo "Archive: build/GhosttlyTermLinkkY.xcarchive"
        echo "Ready for TestFlight or Ad Hoc export."
        ;;
    *)
        echo "Usage: $0 [build|sim|archive]"
        exit 1
        ;;
esac
