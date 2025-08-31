# Multi-stage build for Astra.nvim core
FROM rust:1.75-slim AS builder

# Install dependencies for cross-compilation
RUN apt-get update && apt-get install -y \
    musl-tools \
    musl-dev \
    pkg-config \
    libssl-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Add musl target
RUN rustup target add x86_64-unknown-linux-musl

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Build the application
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/target \
    cd astra-core && \
    cargo build --target x86_64-unknown-linux-musl --release

# Final stage
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    openssh-client \
    curl

# Create non-root user
RUN addgroup -g 1000 -S astra && \
    adduser -u 1000 -S astra -G astra

# Copy binary from builder stage
COPY --from=builder /app/astra-core/target/x86_64-unknown-linux-musl/release/astra-core /usr/local/bin/

# Copy example configuration
COPY --from=builder /app/lua/astra-example.lua /etc/astra/

# Set permissions
RUN chmod +x /usr/local/bin/astra-core

# Create app directory
RUN mkdir -p /app && chown astra:astra /app

# Switch to non-root user
USER astra

# Set working directory
WORKDIR /app

# Expose port (if needed for future web interface)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD astra-core --version || exit 1

# Default command
CMD ["astra-core", "--help"]