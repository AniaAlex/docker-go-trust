# Go-Trust Containerized Deployment Makefile

.PHONY: help build run stop logs clean test

# Default target
help: ## Show this help message
	@echo "Go-Trust Service - Pure Binary with Controlled Dependencies"
	@echo "This builds the actual go-trust binary using dependency versions"
	@echo "controlled by  docker-go-trust (no cmd/ directory needed)."
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Build the Docker image
	@echo "Building go-trust-service containerized image with custom LOTL..."
	docker build -f Dockerfile -t go-trust-service:latest ..


run: build ## Build and run go-trust-service with docker-compose
	@echo "Starting containerized go-trust-service with custom LOTL..."
	docker-compose up -d


stop: ## Stop the running service
	@echo "Stopping containerized go-trust..."
	docker-compose down

logs: ## View service logs
	docker-compose logs -f go-trust-service

restart: stop run ## Restart the service

status: ## Check service status
	@echo "Service Status:"
	docker-compose ps
	@echo ""
	@echo "Health Check:"
	@curl -s http://localhost:6001/health | jq . || echo "Service not responding"

test-api: ## Test the AuthZEN API endpoint
	@echo "Testing AuthZEN API..."
	@curl -X POST http://localhost:6001/api/v1/authzen/access/v1/evaluation \
		-H "Content-Type: application/json" \
		-d '{"subject":{"identity":{"x5c":["test"]}},"action":{"name":"verify"},"resource":{"type":"certificate"}}' \
		| jq . || echo "API test failed"

clean: ## Clean up containers and images
	@echo "Cleaning up..."
	docker-compose down -v
	docker rmi go-trust-service:custom-lotl || true
	docker system prune -f

dev: ## Start development environment with debug logging
	LOG_LEVEL=debug docker-compose up --build

shell: ## Get shell access to running container
	docker-compose exec go-trust-service /bin/sh

config: ## Validate configuration
	@echo "Validating configuration..."
	@if [ -f config/config.example.json ]; then \
		echo "✓ Config file exists"; \
		cat config/config.example.json | jq . > /dev/null && echo "✓ Config is valid JSON" || echo "✗ Invalid JSON"; \
	else \
		echo "✗ Config file missing"; \
	fi
	@if [ -f pipeline.yaml ]; then \
		echo "✓ Pipeline file exists"; \
	else \
		echo "✗ Pipeline file missing"; \
	fi

# Quick start for new developers
quick-start: ## Quick start guide for new developers
	@echo "=== Go-Trust Containerized Quick Start ==="
	@echo ""
	@echo "Choose your build approach:"
	@echo ""
	@echo "1. Standard build:"
	@echo "   make run"
	@echo ""
	@echo "2. Optimized build (recommended for production):"
	@echo "   make run-optimized"
	@echo ""
	@echo "3. Simple build (minimal features):"
	@echo "   make run-simple"
	@echo ""
	@echo "Check status and test:"
	@echo "4. Check status: make status"
	@echo "5. View logs: make logs"
	@echo "6. Test API: make test-api"
	@echo "7. Stop service: make stop"
	@echo ""
	@echo "Build Types Explained:"
	@echo "- Standard: Full dependency installation during build"
	@echo "- Optimized: Multi-stage build with separated dependency installation"
	@echo "- Simple: Minimal build with basic dependencies"

build-info: ## Show information about different build types
	@echo "=== Go-Trust Service Deployment Types ==="
	@echo ""
	@echo "This is a containerized deployment of the go-trust service."
	@echo "No custom cmd/ or SMD dependencies - pure go-trust binary."
	@echo ""
	@echo "1. STANDARD BUILD (Dockerfile)"
	@echo "   - Builds go-trust from source with all dependencies"
	@echo "   - TSL processing and certificate validation service"
	@echo "   - Good for: Development, testing"
	@echo "   - Command: make build"
	@echo ""
	@echo "2. OPTIMIZED BUILD (Dockerfile.optimized) - RECOMMENDED"
	@echo "   - Builds go-trust binary with  docker-go-trust controlled dependencies"
	@echo "   - Clones go-trust source but uses YOUR dependency versions"
	@echo "   - You control SUNET-specific forks and dependency versions"
	@echo "   - Results in actual go-trust binary (not wrapper)"
	@echo "   - Best of both worlds: upstream code + your dependency control"
	@echo "   - Good for: Production, when you need dependency control"
	@echo "   - Command: make build-optimized"
	@echo ""
	@echo "3. SIMPLE BUILD (Dockerfile.simple)"
	@echo "   - Minimal dependencies, direct build"
	@echo "   - Good for: Quick testing, minimal footprint"
	@echo "   - Command: make build-simple"
	@echo ""
	@echo "What this deployment provides:"
	@echo "   - Direct go-trust binary execution"
	@echo "   - TSL (Trust Service List) processing"
	@echo "   - Certificate validation against European trust anchors"
	@echo "   - AuthZEN API for certificate verification"
	@echo "   - Prometheus metrics and health checks"
	@echo "   - Background updates of trust lists"
	@echo ""
	@echo "Architecture:"
	@echo "   - Pure go-trust binary (no cmd/ wrapper)"
	@echo "   - Dependency versions controlled by  docker-go-trust/go.mod"
	@echo "   - SUNET-specific forks via replace directives"  
	@echo "   - No SMD dependencies"
	@echo ""
	@echo "Local builds:"
	@echo "   ./build.sh --help    # Show all local build options"
