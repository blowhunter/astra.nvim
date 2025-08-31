# Contributing to Astra.nvim

Thank you for your interest in contributing to Astra.nvim! This document provides guidelines and instructions for contributing to the project.

## Table of Contents
- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Testing](#testing)
- [Code Style](#code-style)
- [Submitting Changes](#submitting-changes)
- [Reporting Issues](#reporting-issues)
- [Feature Requests](#feature-requests)

## Code of Conduct

This project follows a standard code of conduct. Please be respectful and inclusive in all interactions.

## Getting Started

### Prerequisites
- Rust 1.75 or higher
- Neovim 0.8 or higher
- Git
- Make (for build automation)

### Setup
1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/your-username/astra.nvim.git
   cd astra.nvim
   ```
3. Add the original repository as upstream:
   ```bash
   git remote add upstream https://github.com/original-username/astra.nvim.git
   ```
4. Install development dependencies:
   ```bash
   make setup-cross-compilation
   ```

### Building
```bash
# Build for current platform
make build

# Build for all platforms
make build-all

# Build in development mode
make build-dev
```

## Development Workflow

### 1. Create a Branch
```bash
git checkout -b feature/your-feature-name
```

### 2. Make Changes
- Follow the code style guidelines
- Write tests for new functionality
- Update documentation as needed

### 3. Test Your Changes
```bash
# Run all checks
make check

# Run specific checks
make test        # Run tests
make lint        # Run linter
make format      # Format code
```

### 4. Commit Your Changes
```bash
git add .
git commit -m "feat: add new feature description"
```

### 5. Push to Your Fork
```bash
git push origin feature/your-feature-name
```

### 6. Create a Pull Request
- Go to the original repository on GitHub
- Click "New Pull Request"
- Select your branch
- Fill out the PR template
- Submit the PR

## Testing

### Running Tests
```bash
# Run all tests
make test

# Run specific test modules
cd astra-core && cargo test module_name

# Run tests with output
cd astra-core && cargo test -- --nocapture
```

### Writing Tests
- Write unit tests for new functions
- Add integration tests for new features
- Test both success and error cases
- Use `tempfile` for test isolation

### Test Coverage
```bash
# Install cargo-tarpaulin
cargo install cargo-tarpaulin

# Generate coverage report
cd astra-core && cargo tarpaulin --out html
```

## Code Style

### Rust Code
- Follow Rust idioms and best practices
- Use `cargo fmt` for formatting
- Use `cargo clippy` for linting
- Write clear, concise comments
- Use `Result<T, E>` for error handling

### Lua Code
- Follow Lua best practices
- Use meaningful variable names
- Add comments for complex logic
- Use consistent indentation

### Commit Messages
Use [Conventional Commits](https://www.conventionalcommits.org/) format:
```
type(scope): description

# Optional body

# Optional footer
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Build process or auxiliary tool changes

Example:
```
feat(cli): add support for direct file path arguments in sync command

- Add trailing_var_arg parameter to sync command
- Update sync_files function to handle file paths
- Add tests for new functionality

Fixes #123
```

## Submitting Changes

### Pull Request Process
1. Ensure your code passes all checks
2. Update documentation if needed
3. Add tests for new functionality
4. Fill out the PR template completely
5. Link to any related issues

### Review Process
- All PRs must be reviewed by at least one maintainer
- Automated checks must pass
- Documentation must be updated
- Tests must be added/updated

### Merge Requirements
- All tests must pass
- Code must follow style guidelines
- Documentation must be complete
- PR must be approved by at least one maintainer

## Reporting Issues

### Bug Reports
Use the bug report template when creating issues. Include:
- Clear description of the bug
- Steps to reproduce
- Expected behavior
- Actual behavior
- Error messages
- Environment information
- Configuration details

### Feature Requests
Use the feature request template when suggesting new features. Include:
- Clear description of the feature
- Problem statement
- Proposed solution
- Use cases
- Priority level

## Feature Requests

### Process
1. Check existing issues to avoid duplicates
2. Use the feature request template
3. Provide detailed use cases
4. Explain the problem you're trying to solve
5. Consider if you can contribute to the implementation

### Implementation
- Large features should be discussed in issues first
- Breaking changes require a major version bump
- Backward compatibility should be maintained when possible

## Development Tools

### Useful Commands
```bash
# Format code
make format

# Check formatting
make format-check

# Run linter
make lint

# Run tests
make test

# Build releases
make release-all

# Clean build artifacts
make clean
```

### Docker Development
```bash
# Start development container
docker-compose run astra-dev

# Run tests in container
docker-compose run astra-test

# Build and run
docker-compose up astra-runtime
```

### IDE Configuration
- VS Code: Use the Rust Analyzer extension
- Neovim: Use rust-tools.nvim or similar
- IntelliJ: Use the Rust plugin

## Release Process

The release process is automated using the `scripts/release.sh` script. Do not create releases manually unless you're a maintainer.

### Automated Release Steps
1. Run tests and checks
2. Build for all platforms
3. Create release artifacts
4. Generate release notes
5. Create GitHub release
6. Upload release assets

### Version Management
- Use semantic versioning (SemVer)
- Update version in `astra-core/Cargo.toml`
- Update CHANGELOG.md
- Create git tags for releases

## Getting Help

If you need help with contributing:
- Check the documentation
- Search existing issues
- Ask in discussions
- Contact maintainers

## License

By contributing to Astra.nvim, you agree that your contributions will be licensed under the project's license.