#!/usr/bin/env bash
# Release script for Safe-Web
# Usage: ./release.sh <version> "changelog message"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VERSION=${1:-}
CHANGELOG=${2:-"Release v$VERSION"}

if [ -z "$VERSION" ]; then
    echo "Usage: ./release.sh <version> [changelog message]"
    echo "Example: ./release.sh 1.0.8 'Fixed bug in fetch command'"
    exit 1
fi

echo "🚀 Releasing Safe-Web v$VERSION"
echo ""

# Update version in skill.json
echo "📦 Updating skill.json..."
sed -i "s/\"version\": \"[0-9]\+\.[0-9]\+\.[0-9]\+\"/\"version\": \"$VERSION\"/" skill.json

# Stage changes
echo "📋 Staging changes..."
git add .

# Commit
echo "💾 Creating commit..."
git commit -m "v$VERSION - $CHANGELOG" || echo "Nothing to commit"

# Tag
echo "🏷️  Creating Git tag..."
git tag -a "v$VERSION" -m "$CHANGELOG" || {
    echo "Tag v$VERSION already exists. Delete it with: git tag -d v$VERSION"
    exit 1
}

# Push to GitHub
echo "☁️  Pushing to GitHub..."
git push origin main
git push origin "v$VERSION"

echo ""
echo "✅ GitHub release complete!"
echo ""

# Publish to ClawHub
echo "📤 Publishing to ClawHub..."
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
