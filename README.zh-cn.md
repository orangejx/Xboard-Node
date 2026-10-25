# xboard-node

[Xboard](https://github.com/cedar2025/Xboard) 的节点后端：单个二进制、内嵌双内核（`sing-box` 与 `xray-core`）、覆盖全部部署模式。

[![CI](https://github.com/orangejx/Xboard-Node/actions/workflows/ci.yml/badge.svg)](https://github.com/orangejx/Xboard-Node/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/tag/orangejx/Xboard-Node?label=release)](https://github.com/orangejx/Xboard-Node/releases)
[![Go](https://img.shields.io/badge/Go-1.27%2B-00ADD8?logo=go&logoColor=white)](https://go.dev/dl/)
[![License](https://img.shields.io/badge/License-MPL--2.0-blue)](#许可证)

[English](README.md) · [更新日志](CHANGELOG.md)

> **免责声明：** 本项目仅供学习和研究使用。

## 目录

- [功能特性](#功能特性)
- [安装](#安装)
- [配置](#配置)
- [证书](#证书)
- [路由与出站](#路由与出站)
- [xbctl](#xbctl)
- [运维](#运维)
- [扩展文档](#扩展文档)
- [许可证](#许可证)

## 功能特性

**协议。** VMess、VLESS、Trojan、Shadowsocks 双内核均支持；Hysteria2、TUIC、AnyTLS 需使用 `singbox` 内核。

**双内核。** `sing-box` 与 `xray-core` 以 Go 库形式内嵌，无需单独安装内核进程或二进制。通过 `kernel.type` 切换，支持按节点覆盖（如 `config_dir`）。

**面板同步。** WebSocket 推送（自带断线重连与退避），并以 REST 轮询兜底；流量、设备与 IP 上报间隔均可调。

**用户管控。** 按用户限速、设备数限制、在线 IP 跟踪；用户与节点变更即时生效，无需重启。

**部署模式。**

| 模式 | 运行内容 | 适用场景 |
| --- | --- | --- |
| 节点 | 一个进程绑定面板上的单个节点 | 经典的单节点部署 |
| 机器 | 一个进程托管某机器 ID 下的全部节点，节点通过 API 从面板自动发现 | 单机服务大量节点 |
| 独立 | 完全本地化的节点：协议、用户、限额与路由全部写在 `config.yml`，不与面板通信 | 测试、实验、隔离环境 |
| 多实例 | 单进程通过 `instances` 承载多个面板 / 节点，顶层配置作为可继承的默认值 | 单机混合多种模式与面板 |

**TLS。** 支持 ACME 自动签发（HTTP-01，或搭配 21 个 DNS 服务商的 DNS-01），以及自签、文件、内联 PEM 等模式。

**自定义。** 面板托管的 custom routes / custom outbounds、内核原生路由与出站覆盖，以及对自定义内核配置文件的深合并（兼容 V2bX `OriginalPath`）。

**运维能力。** `/healthz` 健康检查端点、配置热重载、按实例独立的数据目录、Go 运行时内存调优、分级日志、`xbctl` 命令行，以及失败自动回滚的 systemd 安装脚本。

**发布产物。** Linux、macOS、Windows（`amd64` / `arm64`）二进制文件；Linux 多架构镜像发布至 GHCR 与 Docker Hub。

## 安装

### Docker

```bash
docker run -d --restart=always --network=host \
  -e apiHost=https://panel.example.com -e apiKey=TOKEN -e nodeID=1 \
  orangejx/xboard-node:latest
```

支持以下环境变量，小写与大写别名均可：

| 用途 | 环境变量 |
| --- | --- |
| 面板地址 | `apiHost` / `API_HOST` |
| 面板令牌 | `apiKey` / `API_KEY` |
| 节点 ID | `nodeID` / `NODE_ID` |
| 节点类型 | `nodeType` / `NODE_TYPE` |
| 内核 | `kernel` / `KERNEL_TYPE` — 默认 `singbox`，可选 `xray` |
| 机器 ID / 令牌 | `MACHINE_ID`、`MACHINE_TOKEN` — 启用机器模式 |
| TLS 域名 | `domain` / `DOMAIN` — 同时启用 `auto_tls` |
| 证书路径 | `certFile` / `CERT_FILE`、`keyFile` / `KEY_FILE` |
| 日志级别 | `logLevel` / `LOG_LEVEL` |

### Docker Compose

```bash
git clone https://github.com/orangejx/Xboard-Node.git
cd Xboard-Node
cp config.yml.example config.yml
# 编辑 config.yml，设置 panel.url、panel.token 和 panel.node_id
docker compose up -d
```

仓库自带的 [`docker-compose.yml`](docker-compose.yml) 默认本地构建镜像并挂载 `./config.yml`。若要运行已发布的镜像，可将 `IMAGE` / `TAG` 指向仓库镜像：

```bash
IMAGE=ghcr.io/orangejx/xboard-node TAG=latest docker compose up -d
```

### systemd 安装脚本（Linux）

脚本会写入 `/etc/xboard-node/config.yml`、安装 systemd 服务单元，失败时自动回滚。

```bash
# 节点模式
curl -fsSL https://raw.githubusercontent.com/orangejx/Xboard-Node/dev/install.sh | \
  sudo bash -s -- --mode node --panel https://panel.example.com --token TOKEN --node-id 1

# 机器模式
curl -fsSL https://raw.githubusercontent.com/orangejx/Xboard-Node/dev/install.sh | \
  sudo bash -s -- --mode machine --panel https://panel.example.com --token TOKEN --machine-id 1
```

常用选项：`--kernel singbox|xray`、`--health-port 65530`、`--gomemlimit 256MiB`、`--gogc 50`、`--version vX.Y.Z`，以及指定本地二进制的 `--binary` / `--xbctl-binary`。脚本还支持 `install`（默认）、`upgrade`、`uninstall [--purge]`、`status` 等动作。

### 预编译二进制

从 [Releases](https://github.com/orangejx/Xboard-Node/releases) 下载 `xboard-node-<os>-<arch>` 与 `xbctl-<os>-<arch>`，覆盖 Linux、macOS、Windows 的 `amd64` 与 `arm64`。

### 从源码构建

需要 Go 1.27 或更高版本。

```bash
make build        # 构建当前平台的 xboard-node + xbctl
make build-all    # 构建全部发布目标：linux/darwin/windows × amd64/arm64
make test         # 运行单元测试
```

## 配置

所有配置集中在一个 YAML 文件（默认 `./config.yml`，可用 `-c` 覆盖）。原有的单面板配置继续兼容——添加 `instances` 即切换到多实例模式，顶层配置成为默认值，实例可逐项覆盖。

最小化的单节点配置：

```yaml
panel:
  url: "https://panel.example.com"
  token: "your-api-key"
  node_id: 1
kernel:
  type: singbox        # 或 xray
```

多实例示例——同一台主机上运行一个面板节点加一个机器实例：

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
      level: debug     # 仅覆盖本实例
```

主要配置段：

| 配置段 | 用途 |
| --- | --- |
| `panel` / `machine` / `nodes` | 绑定目标：单节点、机器下全部节点，或共享同一面板的节点 ID 列表 |
| `kernel` | 内核类型、`config_dir`、`geo_data_dir`、内核日志级别、自定义路由 / 出站、`custom_config`、`routing_domain_strategy` |
| `cert` | TLS 策略——见[证书](#证书) |
| `log` | 节点日志级别与输出 |
| `runtime` | Go 运行时调优：`gomemlimit`、`gogc` |
| `ws` | WebSocket 调优：`status_interval`、`handshake_timeout`、`backoff_initial`、`backoff_max`、`discovery_interval` |
| `node` | 上报间隔：`push_interval`、`pull_interval`、`track_interval`、`device_report_interval` |
| `standalone` | 无面板的完全本地节点 |
| `health_port` | `/healthz` HTTP 端点端口（0 表示禁用） |

运行时调优，小内存 VPS 常用：

```yaml
runtime:
  gomemlimit: "256MiB"   # 软性 RSS 上限，超过后 GC 更激进
  gogc: 50               # 降低 GC 目标 → 更省内存，略增 CPU
```

Xray 路由域名解析策略（未设置时使用 Xray 默认行为）：

```yaml
kernel:
  type: xray
  routing_domain_strategy: IPIfNonMatch
```

独立模式——用户直接写在配置里的本地节点，`tls: 0/1/2` 分别表示关闭 / TLS / REALITY：

```yaml
standalone:
  enabled: true
  node:
    protocol: vless
    server_port: 443
    tls: 2                # 0 = 关闭, 1 = TLS, 2 = REALITY
  users:
    - id: 1
      uuid: "b831381d-6324-4d53-ad4f-8cda48b30811"
      speed_limit: 100
      device_limit: 3
```

完整带注释模板见 [`config.yml.example`](config.yml.example)。

## 证书

`cert.cert_mode` 决定证书策略：

| 模式 | 行为 |
| --- | --- |
| *（未设置）* | 自动探测：设置了 `cert_file` → 文件；`auto_tls` → HTTP-01；否则无证书 |
| `http` | ACME HTTP-01 验证（需要 80 端口） |
| `dns` | 通过 DNS 服务商完成 ACME DNS-01 验证 |
| `self` | 自签名证书，有效期 10 年 |
| `file` | 使用 `cert_file` / `key_file` |
| `content` | 通过 `cert_content` / `key_content` 内联 PEM |
| `none` | 不启用 TLS |

DNS-01 支持 21 个服务商——Cloudflare、阿里云、腾讯云、AWS Route 53、Google Cloud DNS、Azure、GoDaddy、Porkbun、deSEC 等：

```yaml
cert:
  cert_mode: dns
  dns_provider: cloudflare
  dns_env:
    CLOUDFLARE_DNS_API_TOKEN: "xxx"
```

完整服务商列表见 [docs-dns-providers.md](docs-dns-providers.md)。

## 路由与出站

面板托管的**自定义路由**支持按域名、后缀、IP CIDR、端口、协议网络、来源网段/端口匹配，动作支持 `direct`（直连）、`block`（阻断）或路由到指定出站：

```json
{
  "custom_route_rules": [
    { "name": "direct-example", "match": { "domain_suffixes": ["example.com"] }, "action": { "type": "direct" } },
    { "name": "route-warp", "match": { "ip_cidrs": ["1.1.1.0/24"] }, "action": { "type": "route", "target": "warp-out" } }
  ]
}
```

**自定义出站**可添加 WARP（WireGuard）、链式代理（`proxy_tag`）等。双内核均支持：vmess、vless、trojan、shadowsocks、socks、http、wireguard；仅 sing-box 支持：tuic、hysteria2、anytls、naive、mieru。

如需完全控制，`kernel.custom_config` 可将一份内核原生 JSON/YAML 文件深合并进生成的配置。

- 自定义路由：[docs-custom-routes.md](docs-custom-routes.md)
- 自定义出站：[docs-custom-outbounds.md](docs-custom-outbounds.md)

## xbctl

`xbctl` 负责管理实例、systemd 服务与升级。常用命令如下（完整列表见 `xbctl help`）：

```bash
xbctl status                              # 版本、服务状态、健康与实例列表
xbctl list [--output json]                # 列出全部实例
xbctl instance get <id>                   # 查看单个实例详情
xbctl health                              # 探测健康端点
xbctl bind add-node --panel-url URL --token TOKEN --node-id 1 [--kernel singbox|xray]
xbctl bind add-machine --panel-url URL --token TOKEN --machine-id 1
xbctl bind remove <instance-id>           # 或：remove-node / remove-machine
xbctl config init --mode node --panel-url URL --token TOKEN
xbctl service start|stop|restart|enable|disable|logs
xbctl upgrade [--version vX.Y.Z]
xbctl uninstall [--purge] [--yes]
```

同时提供 `xbctl restart`、`xbctl logs`、`xbctl bind-node` / `xbctl unbind-node` 等快捷别名。

## 运维

- **健康检查** —— 设置 `health_port`（安装脚本默认 `65530`），探测 `GET /healthz` 返回 `{"status":"ok"}`；`xbctl health` 可一键检查。
- **热重载** —— 保存 `config.yml` 后所有实例自动加载新配置，进程无需重启。
- **日志** —— 节点用 `log.level`，内核用 `kernel.log_level`；systemd 下可用 `xbctl logs` 或 `journalctl -u xboard-node`。
- **数据布局** —— 证书、geo 数据库与缓存位于各实例的 `config_dir` 下（默认为配置文件所在目录；多实例时每个实例独占一个子目录）。

## 扩展文档

| 文档 | 内容 |
| --- | --- |
| [docs-custom-routes.md](docs-custom-routes.md) | 匹配条件、动作类型、优先级顺序、内核兼容性 |
| [docs-custom-outbounds.md](docs-custom-outbounds.md) | 各内核支持的协议、链式出站、面板字段与内核原生字段对比 |
| [docs-dns-providers.md](docs-dns-providers.md) | 全部 21 个 DNS 服务商及其环境变量 |
| [CHANGELOG.md](CHANGELOG.md) | 版本更新记录 |

## 许可证

MPL-2.0。
