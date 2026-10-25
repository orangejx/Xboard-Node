# Changelog

All notable changes to this project are documented here, starting from commit [`a58bd524f50764c9eb6d7eecaf41494025605a89`](https://github.com/orangejx/Xboard-Node/commit/a58bd524f50764c9eb6d7eecaf41494025605a89).

## v1.13.1 (2026-10-24)

Released as tag `v1.13.1`, which points to commit [`ffa550a`](https://github.com/orangejx/Xboard-Node/commit/ffa550a5b11a0d0af9a831d42673ccebddf7d41f). This version contains every change since `v1.13`.

### Added

- Upgraded the embedded Xray core to upstream v26.10.21, replacing the previously patched fork.
- Added `kernel.routing_domain_strategy` for the Xray kernel. The setting is inherited by instances and controls the domain strategy used when generating routing rules.
- Added a Docker Compose deployment configuration with configurable `IMAGE` and `TAG` values.
- Added CI builds and release artifacts for macOS and Windows on `amd64` and `arm64`, in addition to Linux builds.
- Added multi-architecture Linux Docker images and manifests for `amd64` and `arm64`.
- Added manual dispatch support for the Docker release workflow.
- Added optional Docker Hub publishing alongside GHCR image publishing for version tags.
- Added project funding metadata.

### Changed

- Updated the Xray integration to use the upstream public APIs.
- Changed Xray routing generation to use the configured domain strategy instead of always using `AsIs`.
- Reordered Xray routing rules so panel-provided rules take precedence over raw custom rules.
- Consolidated CI artifact uploads and release asset publishing.

### Fixed

- Corrected the funding configuration formatting.
- Provided the Docker Hub environment configuration required by tag-triggered publishing jobs.

## Commit range

| Date | Commit | Summary |
| --- | --- | --- |
| 2026-10-24 | [`a58bd52`](https://github.com/orangejx/Xboard-Node/commit/a58bd524f50764c9eb6d7eecaf41494025605a89) | Upgrade Xray core to v26.10.21 |
| 2026-10-24 | [`c7ba149`](https://github.com/orangejx/Xboard-Node/commit/c7ba149681844fb48775d698ec00d48d275610b3) | Add Xray routing domain strategy |
| 2026-10-24 | [`e897df2`](https://github.com/orangejx/Xboard-Node/commit/e897df2c18f71bed0a739c54cf702ae4ae83acaf) | Support multi-registry Docker pushes |
| 2026-10-24 | [`9d7cbcc`](https://github.com/orangejx/Xboard-Node/commit/9d7cbccc7ca28eafe5b41533af21646e07168f54) | Enable manual Docker build triggers |
| 2026-10-24 | [`37db0b4`](https://github.com/orangejx/Xboard-Node/commit/37db0b4a1cd1a1afb2682721ec690981d4c671e1) | Build and release cross-platform binaries |
| 2026-10-24 | [`f39fe6a`](https://github.com/orangejx/Xboard-Node/commit/f39fe6a553020918c079c58782d81e8cbe8fe78b) | Update funding information |
| 2026-10-24 | [`94f1f9a`](https://github.com/orangejx/Xboard-Node/commit/94f1f9aa49ef237979c8903c81f0f99816de1847) | Fix funding configuration formatting |
| 2026-10-24 | [`96545ac`](https://github.com/orangejx/Xboard-Node/commit/96545ac4249928d5521593a7762d7b6b96c6f083) | Configure Docker Hub tag publishing |
| 2026-10-24 | [`ffa550a`](https://github.com/orangejx/Xboard-Node/commit/ffa550a5b11a0d0af9a831d42673ccebddf7d41f) | Configure Docker Hub tag publishing (follow-up) |

Merge commits are omitted from the table because their changes are represented by the commits they merge.
