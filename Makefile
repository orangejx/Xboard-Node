VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
BUILD_TIME ?= $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
LDFLAGS := -s -w -X main.version=$(VERSION) -X main.buildTime=$(BUILD_TIME) -X main.commit=$(shell git rev-parse --short HEAD 2>/dev/null || echo unknown)

.PHONY: build build-target clean test docker install \
	build-linux build-linux-arm64 build-darwin-amd64 build-darwin-arm64 \
	build-windows-amd64 build-windows-arm64 build-all

TARGET_GOOS ?= $(shell go env GOOS)
TARGET_GOARCH ?= $(shell go env GOARCH)
TARGET_SUFFIX = $(if $(filter windows,$(TARGET_GOOS)),.exe,)
TARGET_TAGS = with_quic with_utls with_wireguard with_acme with_clash_api

# Build for current platform
build:
	go build -ldflags "$(LDFLAGS)" -tags "with_quic with_utls with_wireguard with_clash_api" -o xboard-node$(TARGET_SUFFIX) ./cmd/xboard-node
	go build -ldflags "$(LDFLAGS)" -o xbctl$(TARGET_SUFFIX) ./cmd/xbctl

# Build an explicitly selected target, e.g. make build-target TARGET_GOOS=windows TARGET_GOARCH=arm64.
build-target:
	CGO_ENABLED=0 GOOS=$(TARGET_GOOS) GOARCH=$(TARGET_GOARCH) go build -ldflags "$(LDFLAGS)" -tags "$(TARGET_TAGS)" -o xboard-node-$(TARGET_GOOS)-$(TARGET_GOARCH)$(TARGET_SUFFIX) ./cmd/xboard-node
	CGO_ENABLED=0 GOOS=$(TARGET_GOOS) GOARCH=$(TARGET_GOARCH) go build -ldflags "$(LDFLAGS)" -o xbctl-$(TARGET_GOOS)-$(TARGET_GOARCH)$(TARGET_SUFFIX) ./cmd/xbctl

build-linux:
	$(MAKE) build-target TARGET_GOOS=linux TARGET_GOARCH=amd64

build-linux-arm64:
	$(MAKE) build-target TARGET_GOOS=linux TARGET_GOARCH=arm64

build-darwin-amd64:
	$(MAKE) build-target TARGET_GOOS=darwin TARGET_GOARCH=amd64

build-darwin-arm64:
	$(MAKE) build-target TARGET_GOOS=darwin TARGET_GOARCH=arm64

build-windows-amd64:
	$(MAKE) build-target TARGET_GOOS=windows TARGET_GOARCH=amd64

build-windows-arm64:
	$(MAKE) build-target TARGET_GOOS=windows TARGET_GOARCH=arm64

# Build all release binary targets.
build-all: build-linux build-linux-arm64 build-darwin-amd64 build-darwin-arm64 build-windows-amd64 build-windows-arm64

# Run tests
test:
	go test -v -race -count=1 ./internal/...

# Clean build artifacts
clean:
	rm -f xboard-node xbctl xboard-node-*-* xbctl-*-* xboard-node-*-*.exe xbctl-*-*.exe

# Build Docker image
docker:
	docker build -t xboard-node:$(VERSION) -t xboard-node:latest .

# Install to system (single node, legacy compat)
install: build
	sudo cp xboard-node /usr/local/bin/
	sudo cp xbctl /usr/local/bin/
	sudo mkdir -p /etc/xboard-node
	@if [ ! -f /etc/xboard-node/config.yml ]; then \
		sudo cp config.yml.example /etc/xboard-node/config.yml; \
		echo "Config copied to /etc/xboard-node/config.yml - please edit it"; \
	fi
