#!/bin/bash

# Astra.nvim Release Script
# This script automates the release process for Astra.nvim

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_DIR="$PROJECT_ROOT/releases"
VERSION_FILE="$PROJECT_ROOT/astra-core/Cargo.toml"

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get version from Cargo.toml
get_version() {
    grep -m 1 "^version = " "$VERSION_FILE" | sed 's/version = "\(.*\)"/\1/'
}

# Check if working directory is clean
check_clean_repo() {
    if [ -n "$(git status --porcelain)" ]; then
        log_error "Working directory is not clean. Please commit all changes before creating a release."
        exit 1
    fi
}

# Check if on main branch
check_branch() {
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [ "$current_branch" != "main" ]; then
        log_warning "You are not on the main branch (current: $current_branch)"
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Run tests
run_tests() {
    log_info "Running tests..."
    make check
    log_success "All tests passed!"
}

# Build releases
build_releases() {
    log_info "Building releases for all platforms..."
    make release-all
    log_success "Releases built successfully!"
}

# Create GitHub release
create_github_release() {
    local version="$1"
    local release_notes="$2"
    
    log_info "Creating GitHub release..."
    
    # Create a tag
    git tag -a "v$version" -m "Release v$version"
    git push origin "v$version"
    
    # Create release using GitHub CLI if available
    if command -v gh &> /dev/null; then
        gh release create "v$version" \
            --title "Astra.nvim v$version" \
            --notes "$release_notes" \
            releases/linux/astra-core-linux-x86_64.tar.gz \
            releases/macos/astra-core-macos-x86_64.tar.gz \
            releases/windows/astra-core-windows-x86_64.zip
        
        log_success "GitHub release created successfully!"
    else
        log_warning "GitHub CLI not found. Please create release manually."
        log_info "Release files are available in: $RELEASE_DIR"
    fi
}

# Generate release notes
generate_release_notes() {
    local version="$1"
    local previous_version="$2"
    
    cat << EOF
# Astra.nvim v$version Release Notes

## What's New

### Features
- Enhanced CLI with support for direct file path arguments
- Improved path handling for local and remote file synchronization
- Multi-platform build support (Linux, macOS, Windows)
- GitHub Actions CI/CD pipeline
- Docker containerization support

### Bug Fixes
- Fixed tilde (~) expansion in remote paths
- Improved error handling and reporting
- Enhanced path generation logic for better file mapping

### Performance Improvements
- Optimized file synchronization algorithms
- Better caching mechanisms
- Reduced memory usage during file operations

## Installation

### Using Neovim plugin manager
\`\`\`lua
use {
    "your-username/astra.nvim",
    config = function()
        require("astra").setup()
    end
}
\`\`\`

### Manual Installation
1. Download the appropriate binary for your platform:
   - Linux: \`astra-core-linux-x86_64.tar.gz\`
   - macOS: \`astra-core-macos-x86_64.tar.gz\`
   - Windows: \`astra-core-windows-x86_64.zip\`

2. Extract and place the binary in your PATH
3. Copy the \`lua\` directory to your Neovim configuration

### Docker
\`\`\`bash
docker run -it astranvim/astra-core:latest
\`\`\`

## Configuration

See the [README](README.md) for detailed configuration instructions.

## Support

If you encounter any issues, please report them on our [GitHub Issues](https://github.com/your-username/astra.nvim/issues).

---

*Release generated on $(date)*
EOF
}

# Main release process
main() {
    log_info "Starting Astra.nvim release process..."
    
    # Get version
    local version=$(get_version)
    log_info "Release version: $version"
    
    # Check preconditions
    check_clean_repo
    check_branch
    
    # Run tests
    run_tests
    
    # Build releases
    build_releases
    
    # Generate release notes
    local release_notes=$(generate_release_notes "$version")
    
    # Show release notes for review
    log_info "Release notes preview:"
    echo "================================"
    echo "$release_notes"
    echo "================================"
    
    # Ask for confirmation
    read -p "Do you want to proceed with creating the release? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Release cancelled."
        exit 0
    fi
    
    # Create release
    create_github_release "$version" "$release_notes"
    
    log_success "Release process completed successfully!"
    log_info "Don't forget to:"
    echo "  1. Update documentation if needed"
    echo "  2. Announce the release to users"
    echo "  3. Monitor for any post-release issues"
}

# Check for help
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    cat << EOF
Astra.nvim Release Script

Usage: $0 [OPTIONS]

Options:
  -h, --help          Show this help message
  --version-only      Only build releases, don't create GitHub release
  --test-only         Only run tests, don't build releases

Examples:
  $0                  # Full release process
  $0 --test-only      # Only run tests
  $0 --version-only   # Only build releases

Environment Variables:
  GITHUB_TOKEN        GitHub token for creating releases (optional)
EOF
    exit 0
fi

# Handle command line arguments
case "$1" in
    --test-only)
        run_tests
        ;;
    --version-only)
        check_clean_repo
        run_tests
        build_releases
        ;;
    *)
        main
        ;;
esac