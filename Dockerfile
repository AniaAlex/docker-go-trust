# Multi-stage Docker build: go-trust binary with controlled dependencies
FROM golang:1.25-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    git \
    build-base \
    libxml2-dev \
    libxslt-dev \
    pkgconfig

WORKDIR /build

# Clone go-trust source code
RUN git clone https://github.com/SUNET/go-trust.git .

# Copy controlled dependencies from docker-go-trust
COPY ./go.mod ./go.sum /tmp/controlled-deps/

# Create hybrid go.mod: go-trust module name + controlled dependencies
RUN echo 'module github.com/SUNET/go-trust' > go.mod.new && \
    echo '' >> go.mod.new && \
    echo 'go 1.25' >> go.mod.new && \
    echo '' >> go.mod.new && \
    # Copy require blocks from controlled dependencies
    sed -n '/^require (/,/^)/{p}' /tmp/controlled-deps/go.mod >> go.mod.new || true && \
    echo '' >> go.mod.new && \
    # Copy replace directives
    grep '^replace ' /tmp/controlled-deps/go.mod >> go.mod.new || true && \
    # Apply the new go.mod
    mv go.mod.new go.mod

# Use controlled go.sum
COPY ./go.sum ./

# Download and build with controlled dependencies
RUN go mod tidy && \
    go mod download && \
    go mod verify && \
    CGO_ENABLED=1 GOOS=linux go build -a -trimpath \
    -ldflags="-X main.Version=${VERSION:-dev} -w -s -extldflags '-static'" \
    -o gt ./cmd

# Final runtime stage
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache \
    libc6-compat \
    ca-certificates \
    bash \
    openssl \
    libxml2 \
    libxslt \
    curl \
    && update-ca-certificates

# Create non-root user
RUN addgroup -g 1000 appgroup && \
    adduser -D -s /bin/sh -u 1000 -G appgroup gotrust

# Create directories
RUN mkdir -p /app /etc/go-trust && \
    chown -R gotrust:appgroup /app /etc/go-trust

WORKDIR /app

# Copy binary and configuration
COPY --from=builder /build/gt .
COPY ./config/config.yaml /etc/go-trust/config.yaml
COPY ./test-tl-setup/pipeline.yaml ./pipeline.yaml
COPY ./start.sh ./start.sh

# Make files executable
RUN chmod +x gt start.sh

# Switch to non-root user
USER gotrust

# Expose port
EXPOSE 6001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://127.0.0.1:6001/healthz || exit 1

# Run the service
CMD ["./start.sh"]
