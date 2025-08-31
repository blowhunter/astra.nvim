.PHONY: build build-all build-linux build-macos build-windows install install-core install-dev clean test lint format check format-check release release-all release-linux release-macos release-windows upload-release help

# Default target
all: build

# Build targets
build: build-linux

build-all: build-linux build-macos build-windows

build-linux:
	@echo "Building Astra core for Linux (x86_64)..."
	cd astra-core && cargo build --target x86_64-unknown-linux-musl --release

build-macos:
	@echo "Building Astra core for macOS (x86_64)..."
	cd astra-core && cargo build --target x86_64-apple-darwin --release

build-windows:
	@echo "Building Astra core for Windows (x86_64)..."
	cd astra-core && cargo build --target x86_64-pc-windows-msvc --release

# Installation targets
install: install-core
	@echo "Installing Astra.nvim plugin..."
	mkdir -p ~/.local/share/nvim/site/pack/plugins/start/astra-nvim
	cp -r lua ~/.local/share/nvim/site/pack/plugins/start/astra-nvim/

install-core: build-linux
	@echo "Installing core binary..."
	mkdir -p ~/.local/share/nvim/astra-core/target/release
	cp astra-core/target/x86_64-unknown-linux-musl/release/astra-core ~/.local/share/nvim/astra-core/target/release/

install-dev: build
	@echo "Installing development version..."
	mkdir -p ~/.local/share/nvim/site/pack/plugins/start/astra-nvim
	cp -r lua ~/.local/share/nvim/site/pack/plugins/start/astra-nvim/
	mkdir -p ~/.local/share/nvim/astra-core
	cp astra-core/target/debug/astra-core ~/.local/share/nvim/astra-core/target/release/

# Development targets
clean:
	@echo "Cleaning build artifacts..."
	cd astra-core && cargo clean
	rm -rf ~/.local/share/nvim/astra-core
	rm -rf releases/

test:
	@echo "Running tests..."
	cd astra-core && cargo test

lint:
	@echo "Running linter..."
	cd astra-core && cargo clippy -- -D warnings

format:
	@echo "Formatting code..."
	cd astra-core && cargo fmt

format-check:
	@echo "Checking code formatting..."
	cd astra-core && cargo fmt --check

check: format-check lint test
	@echo "All checks passed!"

# Release targets
release: release-linux

release-all: release-linux release-macos release-windows

release-linux: build-linux
	@echo "Creating Linux release..."
	mkdir -p releases/linux
	cp astra-core/target/x86_64-unknown-linux-musl/release/astra-core releases/linux/
	cd releases/linux && tar -czf astra-core-linux-x86_64.tar.gz astra-core

release-macos: build-macos
	@echo "Creating macOS release..."
	mkdir -p releases/macos
	cp astra-core/target/x86_64-apple-darwin/release/astra-core releases/macos/
	cd releases/macos && tar -czf astra-core-macos-x86_64.tar.gz astra-core

release-windows: build-windows
	@echo "Creating Windows release..."
	mkdir -p releases/windows
	cp astra-core/target/x86_64-pc-windows-msvc/release/astra-core.exe releases/windows/
	cd releases/windows && zip astra-core-windows-x86_64.zip astra-core.exe

# GitHub Actions helper targets
setup-cross-compilation:
	@echo "Setting up cross-compilation..."
	rustup target add x86_64-unknown-linux-musl
	rustup target add x86_64-apple-darwin
	rustup target add x86_64-pc-windows-msvc
	# Install musl-tools for Linux builds
	sudo apt-get update && sudo apt-get install -y musl-tools musl-dev

version:
	@echo "Getting version information..."
	cd astra-core && cargo version

help:
	@echo "Astra.nvim Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make build          Build for current platform"
	@echo "  make build-all      Build for all platforms"
	@echo "  make build-linux     Build for Linux"
	@echo "  make build-macos     Build for macOS"
	@echo "  make build-windows   Build for Windows"
	@echo "  make install         Install plugin and binary"
	@echo "  make install-core    Install binary only"
	@echo "  make install-dev     Install development version"
	@echo "  make clean           Clean build artifacts"
	@echo "  make test            Run tests"
	@echo "  make lint            Run linter"
	@echo "  make format          Format code"
	@echo "  make format-check    Check code formatting"
	@echo "  make check           Run all checks"
	@echo "  make release         Create release for current platform"
	@echo "  make release-all     Create releases for all platforms"
	@echo "  make help             Show this help message"
