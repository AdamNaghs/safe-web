#!/usr/bin/env bash
# Release script for Safe-Web
# Usage: ./release.sh <version> "changelog message"
# This script copies files to a temp location to avoid polluting the workspace repo

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VERSION=${1:-}
CHANGELOG=${2:-"Release v$VERSION"}

if [ -z "$VERSION" ]; then
    echo "Usage: ./release.sh <version> [changelog message]"
    echo "Example: ./release.sh 1.0.7 'Fixed bug in fetch command'"
    exit 1
fi

echo "🚀 Releasing Safe-Web v$VERSION"
echo ""

# Create temp directory for clean repo
TEMP_DIR=$(mktemp -d)
echo "📁 Working in temp directory: $TEMP_DIR"

# Copy only the files we want to release
cp README.md "$TEMP_DIR/"
cp SKILL.md "$TEMP_DIR/"
cp skill.json "$TEMP_DIR/"
mkdir -p "$TEMP_DIR/scripts"
cp scripts/safe-web.py "$TEMP_DIR/scripts/"

# If release.sh exists, copy it too (self-reference)
if [ -f release.sh ]; then
    cp release.sh "$TEMP_DIR/"
fi

# Initialize git repo in temp directory
cd "$TEMP_DIR"
git init
git remote add origin git@github.com:AdamNaghs/safe-web.git
# Fetch existing history to allow non-force push if possible
git fetch origin main 2>/dev/null || true

# Update version in skill.json
sed -i "s/\"version\": \"[0-9]\+\.[0-9]\+\.[0-9]\+\"/\"version\": \"$VERSION\"/" skill.json

# Stage and commit
git add .
git commit -m "v$VERSION - $CHANGELOG"

# Tag
echo "🏷️  Creating Git tag..."
git tag -a "v$VERSION" -m "$CHANGELOG" || {
    echo "Tag v$VERSION already exists on remote. Delete it with: git tag -d v$VERSION"
    rm -rf "$TEMP_DIR"
    exit 1
}

# Push to GitHub
echo "☁️  Pushing to GitHub..."
git push origin main --force
git push origin "v$VERSION" --force

echo ""
echo "✅ GitHub release complete!"
echo ""

# Cleanup
rm -rf "$TEMP_DIR"

# Publish to ClawHub from original location
echo "📤 Publishing to ClawHub..."
cd "$SCRIPT_DIR"
clawhub publish . \
  --slug safe-web \
  --name "Safe-Web" \
  --version "$VERSION" \
  --changelog "$CHANGELOG"

echo ""
echo "✅ Release v$VERSION complete!"
echo ""
echo "GitHub: https://github.com/AdamNaghs/safe-web/releases/tag/v$VERSION"
echo "ClawHub: Updated safe-web to v$VERSION"
echo ""
echo "Users can update with:"
echo "  clawhub update safe-web"
