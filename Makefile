.PHONY: build install clean test

build:
	@echo "Building Astra core..."
	cd astra-core && cargo build --release

install:
	@echo "Installing Astra.nvim..."
	mkdir -p ~/.local/share/nvim/site/pack/plugins/start/astra-nvim
	cp -r lua ~/.local/share/nvim/site/pack/plugins/start/astra-nvim/
	mkdir -p ~/.local/share/nvim/astra-core
	cp -r astra-core ~/.local/share/nvim/

install-core: build
	@echo "Installing core binary..."
	mkdir -p ~/.local/share/nvim/astra-core/target/release
	cp astra-core/target/release/astra-core ~/.local/share/nvim/astra-core/target/release/

clean:
	cd astra-core && cargo clean
	rm -rf ~/.local/share/nvim/astra-core

test:
	cd astra-core && cargo test
