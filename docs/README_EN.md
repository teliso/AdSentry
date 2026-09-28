# AdSentry

[中文](https://github.com/teliso/AdSentry/blob/main/README.md)

A DNS filtering module based on KernelSU and AdGuardHome. The module runs AdGuardHome on the device and uses iptables / ip6tables to redirect DNS requests (port 53) sent by the device to AdGuardHome, providing system-wide ad and tracker filtering.

## Features

* Uses KernelSU's module configuration system. Edit `config.sh` in the module directory and save it; the configuration is updated and AdSentry restarts automatically.
* Dynamically updates the module description with the runtime status: log switch, firewall rule switch, AdGuardHome version and PID, and the active firewall rules.
* Redirect and reject rules can be configured separately for UDP and TCP, for both IPv4 and IPv6.
* When startup fails or the configuration is invalid, the module description shows an error and the details are written to the log.
* Detects the system language automatically; output is available in Chinese and English.

## Requirements

* [KernelSU](https://kernelsu.org/) with support for module configuration (`ksud module config`)
* An arm64 or armv7 device
* `iptables` or `ip6tables` available on the system; redirect rules require nat table support

## Installation

1. Download the zip for your device's architecture (`AdSentry_arm64.zip` or `AdSentry_armv7.zip`) from [Releases](https://github.com/teliso/AdSentry/releases).
2. Install the module in the KernelSU manager.
3. When upgrading over an existing installation, the installer asks via the volume keys (no input for 10 seconds means "Yes"):
   * Whether to keep the old module's `config.sh`
   * Whether to keep the old AdGuardHome data (the `data` directory and `AdGuardHome.yaml`)
4. Reboot the device. The module initializes its configuration and starts automatically on boot.

## Usage

* **Start / stop**: Tap the module's action button in the KernelSU manager to toggle between starting and stopping.
* **AdGuardHome web interface**: `http://127.0.0.1:3000/`, default username `admin`, password `admin`. Change the password after your first login.
* **Change the configuration**: Edit `config.sh` in the module directory (`/data/adb/modules/AdSentry`); changes take effect when you save.

## Configuration

All options live in `config.sh`. Boolean values must be `'true'` or `'false'`.

| Option | Default | Description |
| --- | --- | --- |
| `enable_module_log` | `false` | Whether to write logs. Errors are always logged |
| `enable_firewall_rules` | `true` | Whether to apply firewall rules. When off, AdGuardHome runs but no traffic is redirected |
| `ipv4_target_port` / `ipv6_target_port` | `35533` | Port that DNS traffic is redirected to; must match the DNS port in `AdGuardHome.yaml` |
| `web_port` | `3000` | AdGuardHome web port; must match `AdGuardHome.yaml`, otherwise startup is reported as failed |
| `running_user` / `running_group` | `0` / `3004` | User and group that run AdGuardHome (0 is root, 3004 is net_raw). Their traffic is not redirected, to avoid loops |
| `ipv4_return_dst_list` / `ipv6_return_dst_list` | empty | Destination addresses that are not redirected, separated by spaces, e.g. `'192.168.1.1 10.0.0.0/8'` |
| `ipv4_redirect_udp_53` / `ipv4_redirect_tcp_53` | `true` / `true` | Redirect IPv4 UDP / TCP port 53 traffic to AdGuardHome |
| `ipv4_reject_udp_53` / `ipv4_reject_tcp_53` | `false` / `false` | Reject IPv4 UDP / TCP port 53 traffic |
| `ipv6_redirect_udp_53` / `ipv6_redirect_tcp_53` | `false` / `false` | Redirect IPv6 UDP / TCP port 53 traffic to AdGuardHome |
| `ipv6_reject_udp_53` / `ipv6_reject_tcp_53` | `true` / `true` | Reject IPv6 UDP / TCP port 53 traffic |

With the default configuration, IPv4 DNS requests are redirected to AdGuardHome and IPv6 DNS requests are rejected, so the system falls back to IPv4 DNS and no request bypasses the filter.

Redirect rules and the return lists use the nat table; reject rules use the filter table. If your iptables / ip6tables does not support the nat table, redirect rules are skipped and reject rules still apply.

## Module description

Once the module is running, its description looks like this:

```
Log 🚫 | Rules ✅ | AGH: v0.107.xx - PID: 12345
Net 4: UDP ↩️ TCP ↩️ | ↪️ 35533 | UDP ➡️ TCP ➡️
Net 6: UDP ➡️ TCP ➡️ | ↪️ 35533 | UDP 🚫 TCP 🚫
```

* First line: log switch, firewall rule switch, AdGuardHome version and PID
* `Net 4` / `Net 6`: redirect rules before the first bar, the redirect target port in the middle, reject rules after the second bar
* ✅ on, 🚫 off or rejected, ↩️ redirected to AdGuardHome, ➡️ passed through

If the description starts with ❌, an error occurred while reading the configuration, starting, or stopping. Check the log.

## Logs

The log file is `as.log` in the module directory. Errors are written to it even when logging is turned off.

## Building it yourself

1. Clone this repository.
2. Download AdGuardHome for your architecture (linux_arm64 or linux_armv7) from [AdGuardHome Releases](https://github.com/AdguardTeam/AdGuardHome/releases) and put the binary and `AdGuardHome.yaml` into the `agh_work` directory. **Do not rename the files.**
3. Make sure the DNS port and web port in `AdGuardHome.yaml` match `ipv4_target_port` / `ipv6_target_port` and `web_port` in `config.sh`.
4. Zip the files in the repository root (with `module.prop` at the root of the zip). The `version` directory does not need to be included.

## Acknowledgements

Idea inspired by: [twoone-3/AdGuardHomeForRoot](https://github.com/twoone-3/AdGuardHomeForRoot)

Powered by: [AdguardTeam/AdGuardHome](https://github.com/AdguardTeam/AdGuardHome)
