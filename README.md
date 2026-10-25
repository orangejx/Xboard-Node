# xboard-node

Node backend for [Xboard](https://github.com/cedar2025/Xboard): one binary, two embedded kernels (`sing-box` and `xray-core`), every deployment mode.

[![CI](https://github.com/orangejx/Xboard-Node/actions/workflows/ci.yml/badge.svg)](https://github.com/orangejx/Xboard-Node/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/tag/orangejx/Xboard-Node?label=release)](https://github.com/orangejx/Xboard-Node/releases)
[![Go](https://img.shields.io/badge/Go-1.27%2B-00ADD8?logo=go&logoColor=white)](https://go.dev/dl/)
[![License](https://img.shields.io/badge/License-MPL--2.0-blue)](#license)

[简体中文](README.zh-cn.md) · [Changelog](CHANGELOG.md)

> **Disclaimer:** This project is for educational and learning purposes only.

## Contents

- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Certificates](#certificates)
- [Routing and outbounds](#routing-and-outbounds)
- [xbctl](#xbctl)
- [Operations](#operations)
- [Documentation](#documentation)
- [License](#license)

## Features

**Protocols.** VMess, VLESS, Trojan, and Shadowsocks on both kernels; Hysteria2, TUIC, and AnyTLS via the `singbox` kernel.

**Dual kernels.** `sing-box` and `xray-core` are embedded as Go libraries — there is no separate kernel process or binary to install. Pick one with `kernel.type`; per-node overrides such as `config_dir` are supported.

**Panel sync.** WebSocket push with reconnect/backoff, plus REST polling as fallback. Traffic, device, and IP reporting intervals are all tunable.

**User control.** Per-user speed limits, device limits, and alive-IP tracking. User and node changes apply on the fly — no restart needed.

**Deployment modes.**

| Mode | What it runs | Best for |
| --- | --- | --- |
| Node | One process bound to a single panel node | The classic single-node deployment |
| Machine | One process for all nodes bound to a machine ID, discovered from the panel via API | Serving many nodes from one host |
| Standalone | A fully local node — protocol, users, limits, and routes are declared in `config.yml`; no panel contact | Testing, labs, air-gapped machines |
| Multi-instance | One process, several panels / nodes via `instances`; top-level settings act as inherited defaults | Mixing modes and panels on one host |

**TLS.** Automatic ACME via HTTP-01, or DNS-01 with 21 supported DNS providers; plus self-signed, file-based, and inline PEM modes.

**Customization.** Panel-managed custom routes and outbounds, kernel-native route/outbound overrides, and deep-merge of a custom kernel config file (V2bX `OriginalPath` compatible).

**Operations.** `/healthz` health endpoint, config hot reload, per-instance data directories, Go runtime memory tuning, leveled logging, an `xbctl` CLI, and a systemd installer that rolls back on failure.

**Releases.** Binaries for Linux, macOS, and Windows (`amd64` / `arm64`); multi-arch Linux images published to GHCR and Docker Hub.

## Installation

### Docker

```bash
docker run -d --restart=always --network=host \
  -e apiHost=https://panel.example.com -e apiKey=TOKEN -e nodeID=1 \
  orangejx/xboard-node:latest
```

Both lowercase and uppercase aliases are accepted:

| Purpose | Variables |
| --- | --- |
| Panel URL | `apiHost` / `API_HOST` |
| Panel token | `apiKey` / `API_KEY` |
| Node ID | `nodeID` / `NODE_ID` |
| Node type | `nodeType` / `NODE_TYPE` |
| Kernel | `kernel` / `KERNEL_TYPE` — `singbox` (default) or `xray` |
| Machine ID / token | `MACHINE_ID`, `MACHINE_TOKEN` — enables machine mode |
| TLS domain | `domain` / `DOMAIN` — also enables `auto_tls` |
| Certificate paths | `certFile` / `CERT_FILE`, `keyFile` / `KEY_FILE` |
| Log level | `logLevel` / `LOG_LEVEL` |

### Docker Compose

```bash
git clone https://github.com/orangejx/Xboard-Node.git
cd Xboard-Node
cp config.yml.example config.yml
# Edit config.yml to set panel.url, panel.token, and panel.node_id
docker compose up -d
```

The bundled [`docker-compose.yml`](docker-compose.yml) builds the image locally and mounts `./config.yml`. To run a published image instead, point `IMAGE` / `TAG` at a registry:

```bash
IMAGE=ghcr.io/orangejx/xboard-node TAG=latest docker compose up -d
```

### Systemd installer (Linux)

The installer writes `/etc/xboard-node/config.yml`, installs a systemd unit, and rolls the deployment back if anything fails.

```bash
# Node mode
curl -fsSL https://raw.githubusercontent.com/orangejx/Xboard-Node/dev/install.sh | \
  sudo bash -s -- --mode node --panel https://panel.example.com --token TOKEN --node-id 1

# Machine mode
curl -fsSL https://raw.githubusercontent.com/orangejx/Xboard-Node/dev/install.sh | \
  sudo bash -s -- --mode machine --panel https://panel.example.com --token TOKEN --machine-id 1
```

Common options: `--kernel singbox|xray`, `--health-port 65530`, `--gomemlimit 256MiB`, `--gogc 50`, `--version vX.Y.Z`, and `--binary` / `--xbctl-binary` for local binaries. The script also supports the actions `install` (default), `upgrade`, `uninstall [--purge]`, and `status`.

### Prebuilt binaries

Download `xboard-node-<os>-<arch>` and `xbctl-<os>-<arch>` from [Releases](https://github.com/orangejx/Xboard-Node/releases) — Linux, macOS, and Windows, `amd64` and `arm64`.

### Build from source

Go 1.27 or later.

```bash
make build        # xboard-node + xbctl for the current platform
make build-all    # all release targets: linux/darwin/windows × amd64/arm64
make test         # unit tests
```

## Configuration

Everything lives in one YAML file (default `./config.yml`; override with `-c`). Legacy single-panel configs keep working — adding `instances` switches to multi-instance mode, where top-level settings become defaults that each instance can override.

Minimal single node:

```yaml
panel:
  url: "https://panel.example.com"
  token: "your-api-key"
  node_id: 1
kernel:
  type: singbox        # or xray
```

Multi-instance — one panel node plus one machine on the same host:

```yaml
kernel:
  type: xray
log:
  level: info
instances:
  - panel:
      url: "https://panel.example.com"
      token: "api-key-1"
      node_id: 1
  - panel:
      url: "https://panel.example.com"
    machine:
      machine_id: 2
      token: "machine-token-2"
    log:
      level: debug     # override for this instance only
```

Main sections:

| Section | Purpose |
| --- | --- |
| `panel` / `machine` / `nodes` | What to bind to: one node, all nodes of a machine, or a list of node IDs sharing one panel |
| `kernel` | Kernel type, `config_dir`, `geo_data_dir`, kernel log level, custom routes / outbounds, `custom_config`, `routing_domain_strategy` |
| `cert` | TLS strategy — see [Certificates](#certificates) |
| `log` | Node log level and output |
| `runtime` | Go runtime tuning: `gomemlimit`, `gogc` |
| `ws` | WebSocket tuning: `status_interval`, `handshake_timeout`, `backoff_initial`, `backoff_max`, `discovery_interval` |
| `node` | Reporting intervals: `push_interval`, `pull_interval`, `track_interval`, `device_report_interval` |
| `standalone` | Fully local node without a panel |
| `health_port` | Port for the `/healthz` HTTP endpoint (0 = disabled) |

Runtime tuning, handy on small VPS:

```yaml
runtime:
  gomemlimit: "256MiB"   # soft RSS cap; GC becomes more aggressive above it
  gogc: 50               # lower GC target -> less memory, slightly more CPU
```

Xray routing domain strategy (unset uses Xray's default):

```yaml
kernel:
  type: xray
  routing_domain_strategy: IPIfNonMatch
```

Standalone mode — a local node whose users are declared in config; `tls: 0/1/2` selects off / TLS / REALITY:

```yaml
standalone:
  enabled: true
  node:
    protocol: vless
    server_port: 443
    tls: 2                # 0 = off, 1 = TLS, 2 = REALITY
  users:
    - id: 1
      uuid: "b831381d-6324-4d53-ad4f-8cda48b30811"
      speed_limit: 100
      device_limit: 3
```

See [`config.yml.example`](config.yml.example) for the full annotated template.

## Certificates

`cert.cert_mode` picks the strategy:

| Mode | Behavior |
| --- | --- |
| *(unset)* | Auto-detect: `cert_file` set → file; `auto_tls` → HTTP-01; otherwise none |
| `http` | ACME HTTP-01 challenge (requires port 80) |
| `dns` | ACME DNS-01 challenge via a DNS provider |
| `self` | Self-signed certificate, valid for 10 years |
| `file` | Use `cert_file` / `key_file` |
| `content` | Inline PEM via `cert_content` / `key_content` |
| `none` | No TLS |

DNS-01 supports 21 providers — Cloudflare, Aliyun, Tencent Cloud, AWS Route 53, Google Cloud DNS, Azure, GoDaddy, Porkbun, deSEC, and more:

```yaml
cert:
  cert_mode: dns
  dns_provider: cloudflare
  dns_env:
    CLOUDFLARE_DNS_API_TOKEN: "xxx"
```

Full provider list: [docs-dns-providers.md](docs-dns-providers.md).

## Routing and outbounds

Panel-managed **custom routes** match on domains, suffixes, IP CIDRs, ports, networks, and source ranges, and can `direct`, `block`, or route to a custom outbound:

```json
{
  "custom_route_rules": [
    { "name": "direct-example", "match": { "domain_suffixes": ["example.com"] }, "action": { "type": "direct" } },
    { "name": "route-warp", "match": { "ip_cidrs": ["1.1.1.0/24"] }, "action": { "type": "route", "target": "warp-out" } }
  ]
}
```

**Custom outbounds** add WARP (WireGuard), chained proxies (`proxy_tag`), and more. Supported on both kernels: vmess, vless, trojan, shadowsocks, socks, http, wireguard. Sing-box only: tuic, hysteria2, anytls, naive, mieru.

For full control, `kernel.custom_config` deep-merges a kernel-native JSON/YAML file into the generated config.

- Custom routes: [docs-custom-routes.md](docs-custom-routes.md)
- Custom outbounds: [docs-custom-outbounds.md](docs-custom-outbounds.md)

## xbctl

`xbctl` manages instances, the systemd service, and upgrades. Highlights (see `xbctl help` for everything):

```bash
xbctl status                              # version, service state, health, instance table
xbctl list [--output json]                # list all instances
xbctl instance get <id>                   # inspect one instance
xbctl health                              # probe health endpoints
xbctl bind add-node --panel-url URL --token TOKEN --node-id 1 [--kernel singbox|xray]
xbctl bind add-machine --panel-url URL --token TOKEN --machine-id 1
xbctl bind remove <instance-id>           # or: remove-node / remove-machine
xbctl config init --mode node --panel-url URL --token TOKEN
xbctl service start|stop|restart|enable|disable|logs
xbctl upgrade [--version vX.Y.Z]
xbctl uninstall [--purge] [--yes]
```

Shortcuts such as `xbctl restart`, `xbctl logs`, and `xbctl bind-node` / `xbctl unbind-node` also work.

## Operations

- **Health checks** — set `health_port` (the installer defaults it to `65530`) and probe `GET /healthz`, which returns `{"status":"ok"}`; `xbctl health` does it for you.
- **Hot reload** — saving `config.yml` reloads every instance without restarting the process.
- **Logs** — `log.level` for the node, `kernel.log_level` for the kernel; `xbctl logs` or `journalctl -u xboard-node` on systemd.
- **Data layout** — certificates, geo databases, and caches live under each instance's `config_dir`, which defaults to the config file's directory; multi-instance setups get one sub-directory per instance.

## Documentation

| Doc | Contents |
| --- | --- |
| [docs-custom-routes.md](docs-custom-routes.md) | Match conditions, actions, priority order, kernel compatibility |
| [docs-custom-outbounds.md](docs-custom-outbounds.md) | Supported protocols per kernel, chaining, panel vs kernel-native fields |
| [docs-dns-providers.md](docs-dns-providers.md) | All 21 DNS providers with their environment variables |
| [CHANGELOG.md](CHANGELOG.md) | Release history |

## License

MPL-2.0.
