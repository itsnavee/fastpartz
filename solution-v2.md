# FastPartz — Security & SD-WAN Solution (v2)

**Version:** 2.0
**Date:** February 2026
**Scope:** 4 branches (UAE) + offsite backup (optional)
**Approach:** FlexiWAN SD-WAN + Cloudflare Gateway — centrally managed, remote-friendly

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Why This Approach](#2-why-this-approach)
3. [Solution Overview](#3-solution-overview)
4. [Software Stack](#4-software-stack)
5. [Hardware Bill of Materials](#5-hardware-bill-of-materials)
6. [Network Architecture](#6-network-architecture)
7. [Security Features](#7-security-features)
8. [Network Segmentation (VLANs)](#8-network-segmentation-vlans)
9. [Encrypted Inter-Branch Connectivity (FlexiWAN SD-WAN)](#9-encrypted-inter-branch-connectivity-flexiwan-sd-wan)
10. [DNS & Web Security (Cloudflare Gateway)](#10-dns--web-security-cloudflare-gateway)
11. [Windows Server Hardening](#11-windows-server-hardening)
12. [Backup Strategy (3-2-1)](#12-backup-strategy-3-2-1)
13. [Secure Remote Access](#13-secure-remote-access)
14. [Ransomware Attack Surface Analysis & Mitigations](#14-ransomware-attack-surface-analysis--mitigations)
15. [Monitoring & Alerting](#15-monitoring--alerting)
16. [Implementation Phases](#16-implementation-phases)
17. [Ongoing Management — What the Client Sees](#17-ongoing-management--what-the-client-sees)
18. [Open Questions](#18-open-questions)

---

## 1. Executive Summary

### The Problem

FastPartz operates 4 branches across the UAE, each running physical Windows Servers with vendor-supplied accounting software backed by MS SQL Server. The current network posture is **critically vulnerable**:

- **Public IP addresses** assigned directly to servers
- **RDP (TCP 3389)** open to the entire internet
- **SQL Server (TCP 1433)** open to the entire internet
- **No firewalls** — zero perimeter defense
- **No antivirus** — zero endpoint protection
- **No network segmentation** — flat network topology
- **No backup strategy** — no recovery capability
- **Direct server-to-server sync** over the public internet — unencrypted

### What This Solution Delivers

A **centrally managed security architecture** that:

- **Closes all public-facing ports** — zero attack surface from the internet
- **Encrypts all inter-branch traffic** — automated SD-WAN tunnels between all branches
- **Segments the network** — servers, workstations, and guests are isolated
- **Hardens every endpoint** — antivirus, firewall, attack surface reduction on all servers
- **Implements 3-2-1 backups** — local, cross-branch, and offsite copies with immutability
- **Provides secure remote access** — WireGuard VPN with strong authentication
- **Filters DNS and web traffic** — cloud-based threat blocking via Cloudflare
- **Is manageable remotely** — single cloud dashboard controls all 4 branches

### Why This Approach (vs. Traditional Firewalls)

The client has **no IT team on-site**. The person providing support is **not based in UAE**. A traditional setup (e.g., OPNsense with manual IPsec tunnels) would require:

- Logging into 4 separate firewall GUIs to make any change
- Manually configuring 12 IPsec tunnel endpoints (6 tunnels × 2 ends)
- Per-device Suricata IDS tuning and rule management
- Physical access or SSH for troubleshooting

**FlexiWAN + Cloudflare Gateway** replaces this with:

- **One cloud dashboard** (flexiManage) to manage all 4 branch devices
- **Automated tunnel creation** — select devices, click "Create Tunnels", done
- **Cloud-based DNS security** — Cloudflare Gateway filters malware/phishing from the cloud, no on-device config
- **Remote management from anywhere** — manage UAE branches from Pakistan, Europe, anywhere
- **Push updates** to all devices at once from the central console

---

## 2. Why This Approach

### FlexiWAN vs. OPNsense — Honest Comparison

| Concern | OPNsense | FlexiWAN |
|---------|----------|----------|
| **Management** | 4 separate web GUIs, no central view | Single cloud dashboard for all branches |
| **Tunnel setup** | Manual IPsec config: 6 tunnels × 2 ends = 12 configurations | Click "Create Tunnels" → full mesh auto-configures |
| **Tunnel recovery** | DPD + DynDNS (manual DDNS setup per branch) | Automatic via cloud controller |
| **Updates** | SSH/GUI into each device individually | Push from cloud to all devices at once |
| **Firewall depth** | Excellent (stateful, Suricata IDS/IPS, DNS blocklists) | Basic (iptables + app identification). Gaps filled by Cloudflare Gateway |
| **IDS/IPS** | Suricata (~35,000 rules, needs tuning) | Not built-in. Partially compensated by Cloudflare DNS/HTTP filtering |
| **DNS filtering** | Unbound + DNSBL (on-device) | Not built-in. Handled by Cloudflare Gateway (cloud) |
| **Remote access VPN** | IKEv2 (native clients, MFA via TOTP plugin) | OpenVPN app (needs client software) or WireGuard (manual setup) |
| **VLAN support** | Full (802.1Q, inter-VLAN routing, firewall rules) | Supported (802.1Q sub-interfaces) |
| **Cost** | Free (open-source) | $40/device/month cloud managed, or free self-hosted |
| **Learning curve** | Steep (networking expertise needed) | Moderate (cloud UI is simpler) |
| **Troubleshooting remotely** | Need SSH access + networking knowledge | Cloud dashboard shows device status, logs, tunnel health |

### What We Gain

1. **Manageability from anywhere** — the single biggest win
2. **Automated tunnels** — no manual IPsec configuration, no DynDNS
3. **Faster deployment** — less per-device configuration
4. **Simpler troubleshooting** — cloud dashboard shows tunnel health, device status

### What We Trade Away

1. **No on-device IDS/IPS** — compensated by Cloudflare Gateway DNS filtering + endpoint AV
2. **Less granular firewall** — compensated by Windows Firewall on servers + VLAN isolation
3. **Recurring cost** — $160/month for cloud management (or free if self-hosted)

### Security Gap Analysis

| Gap | Impact | Mitigation |
|-----|--------|------------|
| No Suricata IDS/IPS | Cannot detect exploit signatures in network traffic | Cloudflare Gateway blocks malicious domains (DNS layer). Endpoint AV catches malware. Windows Firewall blocks unauthorized ports. |
| Simpler firewall rules | Less fine-grained port/protocol control | VLANs provide isolation. Windows Firewall on each server enforces port-level rules. Only SQL (1433) and SMB (445) allowed inbound on servers. |
| No on-device DNS filtering | DNS queries not inspected locally | Cloudflare Gateway handles all DNS filtering from the cloud. All branch DNS points to Cloudflare. |

**Bottom line:** For a client going from *zero security* to this architecture, the protection level is dramatically better. The IDS/IPS gap is real but secondary — the #1 threats (exposed RDP, exposed SQL, no backups) are fully addressed.

---

## 3. Solution Overview

| Layer | Before | After |
|-------|--------|-------|
| **Perimeter** | No firewall, public ports open | FlexiWAN firewall at each branch; zero inbound ports |
| **Transport** | Unencrypted SQL sync over internet | AES-256 IPsec tunnels via FlexiWAN SD-WAN (auto-configured) |
| **Segmentation** | Flat network, everything reachable | VLANs: servers, workstations, guests isolated |
| **DNS Security** | None | Cloudflare Gateway: malware, phishing, C2 domains blocked |
| **Endpoint** | No AV, Defender disabled | Windows Defender + ESET PROTECT enterprise AV |
| **Backup** | No backups at all | 3 copies, 2 media types, 1 offsite, immutable |
| **Access** | Direct RDP over internet | WireGuard VPN with certificate authentication |
| **Monitoring** | No visibility | Uptime Kuma dashboard, email + Telegram alerts |
| **Management** | N/A | Single cloud dashboard (flexiManage) for all branches |

---

## 4. Software Stack

### Core Infrastructure

| Software | Purpose | Key Features | Where It Runs |
|----------|---------|-------------|---------------|
| **FlexiWAN (flexiEdge)** | SD-WAN router, firewall, VPN gateway, VLAN routing | Cloud-managed, automated IPsec tunnels, application identification, firewall rules, DHCP, VLAN support | N100 mini-PC (Ubuntu 20.04) per branch |
| **FlexiWAN (flexiManage)** | Central management console | Single dashboard for all branches, tunnel management, policy push, device monitoring, remote troubleshooting | Cloud hosted ($40/device/month) or self-hosted (free) |
| **Cloudflare Gateway** | DNS filtering, web security, malware blocking | Block malware/phishing/C2 domains, DNSSEC, content categories, free for up to 50 users | Cloud service (DNS queries routed to Cloudflare) |
| **WireGuard** | Remote access VPN | Fast, modern, minimal attack surface, native clients on all platforms, certificate-based auth | Runs on FlexiWAN N100 (Ubuntu) |

### Endpoint & Backup

| Software | Purpose | Key Features | Where It Runs |
|----------|---------|-------------|---------------|
| **Windows Defender** | Endpoint antivirus (built-in) | Real-time protection, Tamper Protection, ASR rules, cloud-delivered protection | Each Windows Server |
| **ESET PROTECT** | Enterprise antivirus (layered defense) | Central cloud console, ransomware shield, behavioral detection (~$40/server/year) | Each Windows Server |
| **Veeam Backup Community Edition** | Server backup (free for ≤10 workloads) | Full/incremental, MS SQL VSS, application-aware, AES-256 encryption | Master branch Windows Server |
| **Restic** | Cloud backup client | Backblaze B2 integration, encryption, deduplication, retention policies | Master branch NAS or server |
| **Uptime Kuma** | Availability monitoring dashboard | Ping/TCP/HTTP checks, web UI, Telegram/email notifications | Master branch (Docker) |

### Pricing Summary — Software

| Item | Cost | Billing |
|------|------|---------|
| FlexiWAN cloud management (4 devices) | $160/month | Monthly or annual ($133/month annual) |
| Cloudflare Gateway | Free | Up to 50 users |
| ESET PROTECT (4 servers) | ~$160/year | Annual |
| Veeam Community Edition | Free | ≤10 workloads |
| WireGuard | Free | Open-source |
| Uptime Kuma | Free | Open-source |
| **Total recurring** | **~$175/month** ($160 FlexiWAN + ~$13 ESET) | |

**Self-hosted flexiManage option:** FlexiWAN's management server can be self-hosted on a $5–10/month VPS (e.g., Hetzner, DigitalOcean), reducing the recurring cost to ~$20/month total. The open-source flexiManage code is available under AGPLv3. This requires initial setup effort but eliminates the $160/month cloud fee.

---

## 5. Hardware Bill of Materials

### Per Branch — Required Items

| Item | Spec | Purpose | Unit Cost (USD) |
|------|------|---------|----------------|
| **FlexiWAN Edge** (N100 Mini-PC) | Intel N100, 4x 2.5GbE I226-V NICs, 8GB DDR5, 128GB NVMe, fanless | Runs FlexiWAN (Ubuntu 20.04) — SD-WAN router, firewall, VPN, DHCP, VLAN routing. **Must have I225/I226 NICs** (DPDK-compatible, supported since FlexiWAN v6.4.1). | $150–200 |
| **Managed Switch** | TP-Link TL-SG2428P or similar — 24x GbE, PoE+, 802.1Q VLAN, web GUI | Network segmentation via VLANs. Trunk port to FlexiWAN. Access ports per VLAN. | $200–300 |
| Cat6 patch cables, misc | — | Wiring | $30–50 |

**Important NIC requirement:** FlexiWAN uses DPDK for packet processing, which requires PCIe-based Intel NICs. The common N100 mini-PCs with 4x I226-V 2.5GbE ports are compatible (confirmed since FlexiWAN v6.4.1). Avoid models with Realtek NICs.

**N100 port usage:** Port 1 = WAN (to broadband router), Port 2 = LAN (trunk to managed switch carrying all VLANs). Ports 3–4 available for future use (HA, dedicated management, etc.).

### Optional Items

| Item | Spec | Purpose | Unit Cost (USD) |
|------|------|---------|----------------|
| **Backup NAS** (master branch only) | Synology DS223 (2-bay, RAID 1) + 2x WD Red Plus 4TB | Local backup target for Veeam. Also serves cross-branch replication target. | $400–500 |
| **Offsite NAS** (Pakistan or other location) | Synology DS223 or TerraMaster F2-223 (2-bay) + 2x 4TB | Receives encrypted backups from UAE over VPN. Geographic disaster recovery. | $400–500 |
| **Standby N100** (per branch, optional) | Same spec as primary | Cold standby — swap and boot if primary fails. Recovery in <5 minutes. | $150–200 |

### Cost Summary

| Scenario | 4 Branches Hardware | Monthly Recurring | Year 1 Total |
|----------|-------------------|-------------------|--------------|
| **Core** (N100 + switch per branch) | $1,520–2,200 | $175/mo | **$3,620–4,300** |
| **Core + self-hosted flexiManage** | $1,520–2,200 | $23/mo | **$1,796–2,476** |
| **Core + Backup NAS** (master only) | $1,920–2,700 | $175/mo | **$4,020–4,800** |
| **Full** (Core + NAS + offsite NAS) | $2,320–3,200 | $175/mo | **$4,420–5,300** |

---

## 6. Network Architecture

### Per-Branch Topology

```
                          INTERNET
                             |
                    [Broadband Router]
                     (Bridge Mode / DMZ)
                             |
                         WAN port
                    ┌────────────────┐
                    │   FlexiWAN     │
                    │  (N100 Mini-PC)│
                    │  Ubuntu 20.04  │
                    │                │
                    │  - Firewall    │
                    │  - SD-WAN      │
                    │  - WireGuard   │
                    │  - DHCP        │
                    │  - VLAN routing│
                    └──────┬─────────┘
                       LAN port (Trunk)
                           │
                           │ 802.1Q VLAN Trunk
                           │
                    ┌──────┴─────────┐
                    │ Managed Switch  │
                    │                │
                    │ VLAN 10: Servers│
                    │ VLAN 20: Wkstns│
                    │ VLAN 30: Mgmt  │
                    │ VLAN 99: Guest │
                    └─┬──┬──┬──┬─────┘
                      │  │  │  │
              ┌───────┘  │  │  └───────┐
              │          │  │          │
         [Windows    [User  [NAS]   [APs /
          Servers]    PCs]          Printers]
         VLAN 10    VLAN 20        VLAN 99
```

### How Traffic Flows

FlexiWAN is the default gateway for every device. All traffic passes through FlexiWAN for routing and policy enforcement. DNS queries are forwarded to Cloudflare Gateway for threat filtering.

| Traffic Type | Path | Protection |
|-------------|------|------------|
| Server → Server (inter-branch) | FlexiWAN → IPsec SD-WAN tunnel → remote FlexiWAN | AES-256 encryption (auto-configured) |
| Workstation → Internet | FlexiWAN → ISP | DNS filtered by Cloudflare Gateway |
| Workstation → Server (same branch) | FlexiWAN inter-VLAN routing | Firewall rules + Windows Firewall |
| Remote user → Server | WireGuard VPN → FlexiWAN → Server | Encrypted + key-authenticated |
| Any device → DNS | FlexiWAN → Cloudflare Gateway (DoT/DoH) | Malware/phishing/C2 domains blocked |

### Cloud Management Architecture

```
                    ┌──────────────────────┐
                    │    flexiManage        │
                    │  (Cloud Dashboard)    │
                    │                      │
                    │  Manage all branches  │
                    │  from anywhere        │
                    └──────────┬───────────┘
                               │ HTTPS
              ┌────────────────┼────────────────┐
              │                │                │
        ┌─────┴─────┐   ┌─────┴─────┐   ┌─────┴─────┐
        │ Branch 1   │   │ Branch 2   │   │ Branch 3   │   Branch 4
        │ flexiEdge  │   │ flexiEdge  │   │ flexiEdge  │   flexiEdge
        └─────┬─────┘   └─────┬─────┘   └─────┬─────┘
              │                │                │
              └────── IPsec SD-WAN Tunnels ─────┘
                    (auto-configured full mesh)
```

### Full-Mesh Inter-Branch Connectivity

All 4 branches connected via encrypted IPsec tunnels — **6 tunnels** total, auto-configured from the flexiManage dashboard:

```
        Branch 1 (Master)
       /       |        \
      /        |         \
Branch 2 --- Branch 3 --- Branch 4
```

To create the full mesh: select all 4 devices in flexiManage → Actions → Create Tunnels → Full Mesh. Done. Routes advertise automatically.

---

## 7. Security Features

### Defense Layers at Each Branch

| Feature | How It's Delivered | Benefit |
|---------|-------------------|---------|
| **Firewall** | FlexiWAN iptables-based firewall with app identification | Closes all public ports. Zero inbound attack surface. |
| **Encrypted Transport** | FlexiWAN IPsec over VXLAN (AES-256, auto-configured) | All inter-branch traffic encrypted. No eavesdropping possible. |
| **DNS Security** | Cloudflare Gateway (cloud) | Blocks malware, phishing, C2, DGA domains before they resolve. Free for 50 users. |
| **Network Segmentation** | VLANs on managed switch + FlexiWAN inter-VLAN routing | Servers, workstations, guests isolated. Limits blast radius. |
| **Endpoint Protection** | Windows Defender + ASR rules + ESET PROTECT | Multi-layer malware defense on every server. |
| **Server Hardening** | Disabled: SMBv1, NetBIOS, LLMNR, PowerShell v2. Enabled: Windows Firewall, audit logging, account lockout. | Reduces exploitable services to minimum. |
| **Secure Remote Access** | WireGuard VPN on FlexiWAN device | Encrypted tunnel, no exposed ports. Replaces direct RDP. |
| **Backup with Immutability** | 3-2-1: local NAS + cross-branch + cloud (Backblaze B2 with Object Lock) | Full recovery even in worst-case ransomware scenario. |
| **Monitoring** | Uptime Kuma + Telegram + email alerts | Immediate awareness of outages or failures. |
| **Central Management** | flexiManage cloud dashboard | Manage, monitor, and troubleshoot all branches remotely. |

### What's NOT Included (and Why It's OK)

| Missing Feature | Why | Risk Mitigation |
|----------------|-----|-----------------|
| **Network IDS/IPS** (Suricata) | FlexiWAN doesn't include IDS. Adding it would require a separate appliance or OPNsense — adding complexity. | Cloudflare Gateway blocks the majority of real-world threats at the DNS layer (malware downloads, phishing, C2 callbacks all require DNS resolution). Endpoint AV (ESET + Defender) catches what gets through. |
| **Deep packet inspection** | FlexiWAN's firewall is basic compared to OPNsense | Windows Firewall on each server enforces strict port rules. VLANs prevent lateral movement. The combination of network isolation + endpoint protection + DNS filtering covers the critical threat vectors. |

---

## 8. Network Segmentation (VLANs)

### Why Segment the Network?

In a flat network, a single compromised device — a workstation hit by phishing, a printer with a default password — can reach every other device. This is how ransomware spreads: once inside, it moves laterally to find servers, databases, and backups.

VLANs create isolated zones. Even if an attacker compromises a workstation, they cannot reach servers in a different VLAN without passing through FlexiWAN, which enforces access rules. This dramatically limits the blast radius of any incident.

### IP Addressing Scheme

Pattern: `10.<branch>.<vlan>.0/24`

| Branch | VLAN 10 (Servers) | VLAN 20 (Workstations) | VLAN 30 (Mgmt) | VLAN 99 (Guest/IoT) |
|--------|------------------|----------------------|----------------|---------------------|
| Branch 1 | 10.1.10.0/24 | 10.1.20.0/24 | 10.1.30.0/24 | 10.1.99.0/24 |
| Branch 2 | 10.2.10.0/24 | 10.2.20.0/24 | 10.2.30.0/24 | 10.2.99.0/24 |
| Branch 3 | 10.3.10.0/24 | 10.3.20.0/24 | 10.3.30.0/24 | 10.3.99.0/24 |
| Branch 4 | 10.4.10.0/24 | 10.4.20.0/24 | 10.4.30.0/24 | 10.4.99.0/24 |

### VLAN Descriptions

| VLAN | Name | Devices | Access Rules |
|------|------|---------|-------------|
| 10 | **Servers** | Windows Servers, NAS, SQL Server | Reachable from workstations (SQL + file shares only). Reachable from other branches via SD-WAN. |
| 20 | **Workstations** | User PCs, laptops | Can reach servers for SQL and file shares. Internet via FlexiWAN (DNS filtered by Cloudflare). |
| 30 | **Management** | FlexiWAN management, switch management | IT administrators only. All other VLANs blocked. |
| 99 | **Guest / IoT** | Guest WiFi, printers, cameras | Fully isolated. Internet only (HTTP/HTTPS). Cannot reach any internal VLAN. |

### Access Control

**Default: DENY everything between VLANs.** Only these flows are allowed:

| From | To | Allowed Ports | Purpose |
|------|----|--------------|---------|
| Workstations | Servers | TCP 1433 (SQL), TCP 445 (file shares) | Accounting software, file access |
| Workstations | Guest/IoT | TCP 9100, 631 (printing) | Printing |
| Management | All | All | IT administration |
| Guest/IoT | Internet only | TCP 80, 443 | Web browsing for guests |

---

## 9. Encrypted Inter-Branch Connectivity (FlexiWAN SD-WAN)

### How It Works

Each branch runs FlexiWAN (flexiEdge) which registers with the central flexiManage cloud controller. From the dashboard, you select all 4 devices and create a full-mesh tunnel topology with one click. FlexiWAN automatically:

1. Generates IPsec encryption keys
2. Configures tunnel endpoints on each device
3. Advertises LAN routes across tunnels
4. Handles NAT traversal
5. Monitors tunnel health and auto-recovers

**No manual IPsec configuration. No DynDNS setup. No certificate management.**

### Tunnel Specifications

| Feature | Specification |
|---------|--------------|
| Protocol | IPsec over VXLAN |
| Encryption | AES-256 (auto-configured) |
| Key Management | Automatic via flexiManage (no pre-shared keys to manage) |
| NAT Traversal | Automatic (handles most ISP NAT scenarios) |
| Topology | Full mesh (all branches interconnect directly) |
| Route Advertisement | Automatic — LAN subnets advertised across tunnels |
| Health Monitoring | flexiManage dashboard shows real-time tunnel status |
| Recovery | Automatic reconnection on failure |

### Tunnel Matrix

| # | Branch A | Branch B | Traffic |
|---|----------|----------|---------|
| 1 | Branch 1 | Branch 2 | SQL sync, management |
| 2 | Branch 1 | Branch 3 | SQL sync, management |
| 3 | Branch 1 | Branch 4 | SQL sync, management |
| 4 | Branch 2 | Branch 3 | SQL sync, management |
| 5 | Branch 2 | Branch 4 | SQL sync, management |
| 6 | Branch 3 | Branch 4 | SQL sync, management |

### SD-WAN Features Beyond Simple VPN

FlexiWAN provides true SD-WAN capabilities that a basic IPsec setup cannot:

| Feature | Benefit |
|---------|---------|
| **Application identification** | Identify and prioritize SQL sync traffic over general browsing |
| **Link quality monitoring** | Detect packet loss, latency, jitter on each WAN link |
| **Path selection** | Route critical traffic (SQL) over the best-quality link |
| **Centralized policy** | Push traffic policies to all branches from one dashboard |

---

## 10. DNS & Web Security (Cloudflare Gateway)

### Why Cloudflare Gateway?

Since FlexiWAN doesn't include IDS/IPS or DNS filtering, we fill this gap with Cloudflare Gateway (part of Cloudflare Zero Trust). The free tier supports up to 50 users and provides:

- **DNS filtering** — blocks malware, phishing, C2/botnet, DGA domains
- **Content categories** — block gambling, adult content, etc.
- **DNSSEC validation** — prevents DNS spoofing
- **24-hour activity logging** — see what domains are being queried

### How It Works

1. All branch DNS queries are pointed to Cloudflare Gateway's DNS resolvers
2. FlexiWAN DHCP assigns Cloudflare's DNS IPs (or a local DNS forwarder pointing to Cloudflare)
3. Cloudflare evaluates every DNS query against threat intelligence
4. Malicious domains return a block page; clean domains resolve normally

```
User Device → FlexiWAN (DHCP: DNS = Cloudflare) → Cloudflare Gateway
                                                        │
                                                   ┌────┴────┐
                                                   │ Threat   │
                                                   │ Intel    │
                                                   │ Database │
                                                   └────┬────┘
                                                        │
                                              ┌─────────┴──────────┐
                                              │                    │
                                         CLEAN → resolve        MALICIOUS → block
```

### What Gets Blocked

| Category | Examples | Action |
|----------|----------|--------|
| Malware | Known malware distribution domains | Block |
| Phishing | Credential harvesting sites | Block |
| Command & Control | Botnet C2 servers, ransomware callbacks | Block |
| DGA Domains | Algorithmically-generated domains (malware communication) | Block |
| Cryptomining | Browser-based crypto miners | Block |
| DNS Tunneling | Data exfiltration via DNS queries | Block |
| New/uncategorized domains | Recently registered domains (often malicious) | Optional block |

### Setup per Branch

On each FlexiWAN device, configure DHCP to assign Cloudflare Gateway DNS:

```
DNS Server 1: <Cloudflare Gateway IPv4 — from Zero Trust dashboard>
DNS Server 2: <Cloudflare Gateway IPv4 secondary>
```

Alternatively, configure FlexiWAN as a DNS forwarder pointing to Cloudflare Gateway for all VLANs.

### Cloudflare Gateway Dashboard

Managed at `https://one.dash.cloudflare.com` — separate from FlexiWAN but also cloud-managed. Provides:

- DNS query logs (24-hour retention on free tier)
- Block/allow policy management
- Per-location policies (can have different rules per branch)
- Up to 3 physical network locations on free tier (sufficient — register by source IP)

---

## 11. Windows Server Hardening

Same hardening applies regardless of the edge device (FlexiWAN or OPNsense). These changes protect each server independently.

| Category | Action | Why |
|----------|--------|-----|
| **Antivirus** | Enable Windows Defender + Tamper Protection + ASR rules. Install ESET PROTECT. | Multi-layer malware and ransomware defense. |
| **RDP** | Disabled from internet. Accessible only via VPN or Management VLAN. NLA required. | Eliminates the #1 ransomware entry point. |
| **SQL Server** | Bind to Server VLAN IP only (not 0.0.0.0). | SQL only reachable from internal network. |
| **Windows Firewall** | Enabled. Default-deny inbound. Allow only SQL (1433), SMB (445), RDP (from mgmt only). | Defense-in-depth even if network firewall is bypassed. |
| **Disabled Protocols** | SMBv1 (WannaCry vector), NetBIOS, LLMNR, WPAD, PowerShell v2. | Removes unnecessary attack surface. |
| **Account Security** | Lockout after 5 failed attempts (30 min). 14-char minimum password. Separate admin accounts. | Prevents brute-force. Limits credential theft damage. |
| **Application Control** | AppLocker: block executables from user profile, temp, AppData folders. | Prevents ransomware from executing even if downloaded. |
| **Patching** | Automatic Windows Update. Monthly reboot schedule. | Closes known vulnerabilities. |
| **Audit Logging** | Windows Security events tracked (logins, account changes, service installs). | Forensic trail for incident investigation. |

---

## 12. Backup Strategy (3-2-1)

Three copies of data, on two different media types, with one copy offsite. Identical to v1 — backup strategy is independent of the edge device.

```
             ┌──────────────────┐
             │  Windows Server  │
             │  (Production DB) │
             └────────┬─────────┘
                      │
          ┌───────────┼───────────┐
          │           │           │
          ▼           ▼           ▼
   ┌────────────┐  ┌──────────┐  ┌──────────────┐
   │  Copy 1    │  │ Copy 2   │  │  Copy 3      │
   │  Local NAS │  │ Cross-   │  │  Cloud       │
   │  (master   │  │ branch   │  │  Backblaze   │
   │   branch)  │  │ via SD-  │  │  B2 + Object │
   │            │  │ WAN      │  │  Lock        │
   └────────────┘  └──────────┘  └──────────────┘
      Daily           Daily         Weekly
```

| Copy | Location | Method | Schedule | Immutability |
|------|----------|--------|----------|-------------|
| **1 — Local** | Synology NAS at master branch | Veeam CE (SQL-aware, free) | Daily incremental + weekly full | NAS snapshots (7-day retention) |
| **2 — Cross-branch** | Partner branch via SD-WAN tunnel | rsync with encryption | Daily sync | NAS snapshots |
| **3 — Cloud** | Backblaze B2 | Restic with AES-256 | Weekly full + daily incremental | Object Lock (30-day, cannot be deleted) |

### Cloud Offsite Cost

| Provider | Storage Cost | Egress | Immutability | Recommendation |
|----------|-------------|--------|-------------|----------------|
| **Backblaze B2** | $5/TB/month | $0.01/GB | Object Lock | **Best balance** |
| Cloudflare R2 | $15/TB/month | Free | No native lock | If frequent restores needed |
| AWS S3 Glacier | $1/TB/month | $0.09/GB | Vault Lock | Cheapest archival |

### Backup Testing

| Test | Frequency |
|------|-----------|
| Backup completion verification | Daily (automated alert on failure) |
| File-level restore | Monthly |
| Full server restore | Quarterly |

---

## 13. Secure Remote Access

### WireGuard VPN

WireGuard runs on the FlexiWAN device (it's Ubuntu underneath) and provides secure remote access. WireGuard is:

- **Fast** — kernel-level, minimal overhead
- **Simple** — ~4,000 lines of code (vs. 600,000+ for OpenVPN)
- **Native clients** — Windows, macOS, iOS, Android, Linux
- **Cryptographically modern** — Curve25519, ChaCha20, Poly1305

| Feature | Detail |
|---------|--------|
| Protocol | WireGuard (UDP) |
| Authentication | Public/private key pairs (no passwords to brute-force) |
| Encryption | ChaCha20-Poly1305 (or AES-256-GCM with hardware acceleration) |
| VPN Subnet | 10.10.10.0/24 (dedicated, isolated) |
| Split Tunneling | Only branch traffic through VPN; internet stays local |
| Port | Single UDP port (e.g., 51820) |

### Remote User Access Control

| VPN users CAN access | VPN users CANNOT access |
|---------------------|------------------------|
| Servers (RDP, SQL, file shares) | Workstation VLAN |
| Only on authorized ports | Management VLAN |
| | Guest/IoT VLAN |
| | Other VPN users |

### Vendor/Support Access

| Control | Detail |
|---------|--------|
| Dedicated keys | Each vendor gets a unique WireGuard key pair |
| Restricted access | iptables rules limit vendor to specific server IPs and ports |
| Easy revocation | Remove the vendor's public key from WireGuard config |
| Session logging | Connection logs on the FlexiWAN device |

---

## 14. Ransomware Attack Surface Analysis & Mitigations

| # | Attack Vector | Current Risk | Mitigation | After |
|---|-------------|-------------|-----------|-------|
| 1 | **RDP Brute Force** | CRITICAL | FlexiWAN blocks all inbound. RDP only via VPN + Management VLAN. | **ELIMINATED** |
| 2 | **SQL Server Exploitation** | CRITICAL | FlexiWAN blocks all inbound. SQL bound to VLAN 10 only. | **ELIMINATED** |
| 3 | **Phishing / Email** | HIGH | Cloudflare Gateway blocks phishing domains. SPF/DKIM/DMARC. User training. | MEDIUM |
| 4 | **Malicious Downloads** | HIGH | Cloudflare DNS blocklists + Windows Defender + ESET + AppLocker. | LOW |
| 5 | **USB / Removable Media** | MEDIUM | Disable AutoRun. ASR rule blocks untrusted processes from USB. | LOW |
| 6 | **Lateral Movement** | CRITICAL | VLAN segmentation + Windows Firewall + separate admin accounts. | LOW |
| 7 | **Credential Theft** | HIGH | VPN uses keys (not passwords). Account lockout. Separate admin accounts. | LOW |
| 8 | **Supply Chain / Software** | MEDIUM | Auto-patching. AppLocker whitelist. Vendor VPN access time-limited. | LOW |
| 9 | **Insider Threat** | MEDIUM | Least privilege. Audit logging. No shared accounts. | LOW |
| 10 | **WiFi** | MEDIUM | WPA3. Guest SSID on VLAN 99 (isolated from servers). | LOW |
| 11 | **Printers / IoT** | LOW | VLAN 99 (isolated). Only print ports from workstation VLAN. | LOW |
| 12 | **DNS-Based Attacks** | MEDIUM | Cloudflare Gateway: DNSSEC + malware blocklists + DGA detection. | LOW |
| 13 | **Backup Destruction** | CRITICAL | 3-2-1 backup + NAS snapshots + B2 Object Lock (immutable 30 days). | LOW |
| 14 | **Unpatched Vulnerabilities** | HIGH | Automated Windows Update. Monthly patch review. | LOW |

---

## 15. Monitoring & Alerting

### What Gets Monitored

| Check | What It Detects | Alert Method |
|-------|----------------|-------------|
| SD-WAN tunnel status | Tunnel down between branches (visible in flexiManage) | flexiManage dashboard + Telegram |
| Server availability | Windows Server offline or SQL unreachable | Email + Telegram |
| Backup job status | Veeam backup failed or incomplete | Email + Telegram |
| Cross-branch sync | rsync replication failure | Telegram |
| Cloud backup | Backblaze B2 backup failure | Telegram |
| Disk space | NAS or server storage >80% full | Email |
| DNS filtering | Cloudflare Gateway blocks (visible in CF dashboard) | Cloudflare dashboard |
| Failed logins | 5+ failed login attempts on any server | Email |

### Alert Channels

| Channel | Use Case |
|---------|---------|
| **flexiManage Dashboard** | Real-time device status, tunnel health, for the IT admin |
| **Cloudflare Dashboard** | DNS query logs, blocked domains, security events |
| **Email** | All automated alerts (backup, server, sync failures) |
| **Telegram Bot** | Critical alerts (tunnel down, backup failed, server offline) — instant mobile notification |

### Monitoring Dashboard

**Uptime Kuma** (free, open-source) provides a web dashboard showing status of all servers, backups, and services. Runs as a Docker container on the master branch NAS.

---

## 16. Implementation Phases

| Phase | Scope | Duration | Deliverable |
|-------|-------|----------|-------------|
| **1** | Hardware procurement + Ubuntu 20.04 + FlexiWAN installation on all N100s | 1 week | 4 flexiEdge devices registered in flexiManage |
| **2** | Branch 1 (master) pilot — VLANs, firewall rules, Cloudflare Gateway DNS, WireGuard VPN | 1 week | Branch 1 fully operational with segmented, protected network |
| **3** | Deploy remaining 3 branches + create full-mesh SD-WAN tunnels (one click in flexiManage) | 1 week | All branches connected. SQL sync working over encrypted tunnels. |
| **4** | Windows Server hardening + AV deployment + backup setup on all servers | 1 week | All servers hardened. Veeam backups running daily. |
| **5** | Monitoring setup (Uptime Kuma + Telegram) + offsite backup (Backblaze B2) | 1 week | Monitoring live. 3-2-1 backup complete. |
| **6** | Testing, verification, documentation, knowledge transfer | 1 week | All tests passed. Simple runbooks delivered. Staff trained. |

**Total estimated deployment: 6 weeks**

---

## 17. Ongoing Management — What the Client Sees

### Day-to-Day (Client Staff)

The client doesn't need to manage any of this daily. Everything runs automatically:

- SD-WAN tunnels auto-reconnect if ISP drops
- Backups run on schedule and alert on failure
- DNS filtering is cloud-managed (no on-device updates)
- Windows updates install automatically

### When Something Goes Wrong

| Issue | Who Handles It | How |
|-------|---------------|-----|
| Internet outage at a branch | ISP / auto-recovers | FlexiWAN reconnects tunnels automatically when internet returns |
| Backup failure alert | Remote admin (you) | Check Veeam logs remotely via RDP over VPN |
| Tunnel down alert | Remote admin (you) | Check flexiManage dashboard from anywhere |
| FlexiWAN device failure | On-site staff | Swap with standby N100, boot it (pre-configured in flexiManage) |
| Windows Server issue | Remote admin (you) | RDP via WireGuard VPN |
| DNS false positive (site blocked) | Remote admin (you) | Add exception in Cloudflare Gateway dashboard |

### Remote Admin Access

You (the administrator) can manage everything remotely:

1. **flexiManage** — all SD-WAN devices, tunnels, firewall rules (web browser)
2. **Cloudflare Gateway** — DNS policies, block/allow rules (web browser)
3. **ESET PROTECT** — antivirus status across all servers (web browser)
4. **WireGuard VPN** — connect to any branch for RDP, troubleshooting
5. **Uptime Kuma** — monitoring dashboard (web browser, accessible via VPN)

**All five management interfaces are accessible from any web browser, anywhere in the world.**

---

## 18. Open Questions

| # | Question | Impact |
|---|----------|--------|
| 1 | What email provider do the branches use? | Determines SPF/DKIM/DMARC setup |
| 2 | Which branch is the "master" that others sync to? | Determines NAS and Veeam placement |
| 3 | How much data (GB/TB) is on each server? | Sizes NAS drives and cloud backup costs |
| 4 | How often do servers sync, and how much data changes daily? | Sizes tunnel bandwidth and backup window |
| 5 | What is the broadband speed at each branch? | Validates SD-WAN throughput requirements |
| 6 | Are broadband routers ISP-managed or client-owned? Can we set bridge mode? | Determines WAN configuration |
| 7 | Does the client own a domain name? | Determines Cloudflare Gateway setup approach |
| 8 | How many remote users need VPN access? | Sizes WireGuard configuration |
| 9 | Are there printers, IP cameras, or IoT devices? | Determines VLAN 99 scope |
| 10 | Is there WiFi at any branch? | Determines VLAN tagging on APs |
| 11 | What Windows Server version at each branch? | Determines feature availability (AppLocker, ASR) |
| 12 | Is the accounting software vendor supportive of network changes? | Determines vendor VPN access needs |
| 13 | Preference for FlexiWAN cloud managed ($160/mo) vs self-hosted (free, more setup)? | Determines flexiManage deployment |

---

## Appendix: Emergency Procedures

### Suspected Ransomware Attack

1. **ISOLATE** — Disconnect affected server from network (pull Ethernet cable)
2. **DO NOT reboot** — preserves forensic evidence in memory
3. **CHECK** — Are other branches affected? (Check flexiManage dashboard.) Are backups intact?
4. **RESTORE** — Recover from most recent clean backup (local NAS → cross-branch → Backblaze B2)
5. **INVESTIGATE** — Review Windows Security logs for entry point
6. **HARDEN** — Address the vulnerability that was exploited

### FlexiWAN Device Failure

1. Branch loses internet and inter-branch connectivity
2. **Bypass:** Set workstation gateway to broadband router directly (internet-only, no security)
3. **Restore:** Boot standby N100 — it's already registered in flexiManage and will auto-configure
4. **Recovery time:** ~5 minutes with standby unit

### SD-WAN Tunnel Down

1. Check flexiManage dashboard — shows tunnel status for all branches
2. Wait 2 minutes (auto-recovery in progress)
3. If still down: check if remote branch has broadband outage
4. Try restarting the tunnel from flexiManage dashboard (no SSH needed)
