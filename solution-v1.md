# FastPartz — Security & SD-WAN Solution

**Version:** 1.0
**Date:** February 2026
**Scope:** 4 branches (UAE) + offsite backup (optional)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Solution Overview](#2-solution-overview)
3. [Software Stack](#3-software-stack)
4. [Hardware Bill of Materials](#4-hardware-bill-of-materials)
5. [Network Architecture](#5-network-architecture)
6. [Security Features](#6-security-features)
7. [Network Segmentation (VLANs)](#7-network-segmentation-vlans)
8. [Encrypted Inter-Branch Connectivity (IPsec SD-WAN)](#8-encrypted-inter-branch-connectivity-ipsec-sd-wan)
9. [Dynamic DNS for Branch Discovery](#9-dynamic-dns-for-branch-discovery)
10. [Windows Server Hardening](#10-windows-server-hardening)
11. [Backup Strategy (3-2-1)](#11-backup-strategy-3-2-1)
12. [Secure Remote Access](#12-secure-remote-access)
13. [Ransomware Attack Surface Analysis & Mitigations](#13-ransomware-attack-surface-analysis--mitigations)
14. [Monitoring & Alerting](#14-monitoring--alerting)
15. [Implementation Phases](#15-implementation-phases)
16. [Open Questions](#16-open-questions)

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

Exposed RDP is the #1 initial access vector for ransomware gangs (Conti, LockBit, BlackCat, Akira). Exposed SQL ports enable direct data exfiltration and destruction. The absence of backups means any attack is a business-ending event.

### What We Will Deliver

A **complete, layered security architecture** that:

- **Closes all public-facing ports** — zero attack surface from the internet
- **Encrypts all inter-branch traffic** — IPsec tunnels between all branches
- **Segments the network** — servers, workstations, and guests are isolated from each other
- **Hardens every endpoint** — antivirus, firewall, attack surface reduction on all servers
- **Implements 3-2-1 backups** — local, cross-branch, and offsite copies with immutability
- **Provides secure remote access** — VPN with multi-factor authentication
- **Monitors and alerts** — intrusion detection, DNS filtering, real-time alerts

**Result:** A posture that would withstand a targeted ransomware attack, built entirely on open-source software and commodity hardware.

---

## 2. Solution Overview

| Layer | What Changes | Before | After |
|-------|-------------|--------|-------|
| **Perimeter** | OPNsense firewall at each branch | No firewall, public ports open | Zero inbound ports, all traffic inspected |
| **Transport** | IPsec encrypted tunnels | Unencrypted sync over internet | AES-256 encrypted, certificate-authenticated |
| **Segmentation** | VLANs on managed switches | Flat network, everything reachable | Servers, workstations, guests isolated |
| **Endpoint** | Windows Defender + Enterprise AV | No AV, Defender disabled | Real-time protection, ransomware-specific rules |
| **Backup** | Local NAS + cross-branch + offsite | No backups at all | 3 copies, 2 media types, 1 offsite, immutable |
| **Access** | IKEv2 VPN with MFA | Direct RDP over internet | Encrypted VPN, certificate + password + TOTP |
| **Monitoring** | IDS/IPS + DNS filtering + alerts | No visibility | Real-time threat detection, email/Telegram alerts |

---

## 3. Software Stack

All core software is open-source or free-tier. No recurring license costs for infrastructure.

| Software | Purpose | Key Features | Installed On |
|----------|---------|-------------|-------------|
| **OPNsense** | Firewall, router, VPN gateway, IDS/IPS, DNS filtering | Stateful firewall, IPsec/IKEv2, Suricata IDS/IPS, Unbound DNS with blocklists, DHCP, DynDNS client, web management GUI | N100 mini-PC (dedicated appliance per branch) |
| **Suricata** (OPNsense plugin) | Intrusion Detection & Prevention System (IDS/IPS) | ET Open + Abuse.ch rulesets (~35,000 rules), inline blocking, protocol anomaly detection | Runs within OPNsense on N100 |
| **Unbound DNS** (OPNsense built-in) | DNS filtering & security | DNSBL blocklists (malware/phishing), DNSSEC validation, DNS-over-TLS upstream | Runs within OPNsense on N100 |
| **Windows Defender** | Endpoint antivirus (built-in) | Real-time protection, Tamper Protection, Attack Surface Reduction (ASR) rules, cloud-delivered protection | Each Windows Server |
| **ESET PROTECT** or **Bitdefender GravityZone** | Enterprise antivirus (layered defense) | Central management console, ransomware shield, behavioral detection | Each Windows Server (~$40/server/year) |
| **Veeam Backup Community Edition** | Server backup (free for up to 10 workloads) | Full/incremental backup, MS SQL VSS integration, application-aware, AES-256 encryption, email notifications | Master branch Windows Server |
| **Borgbackup** | Encrypted offsite backup | Deduplication, AES-256 encryption, compression, append-only mode (immutable), incremental | Offsite NAS (optional) |
| **Restic** | Cloud backup client | Backblaze B2 / Cloudflare R2 / AWS S3 integration, encryption, deduplication, retention policies | Master branch NAS or server |
| **NXLog Community Edition** | Windows log forwarding to syslog | Forwards Windows Security events (failed logins, account changes, service installs) to central syslog | Each Windows Server |
| **Uptime Kuma** | Availability monitoring dashboard | Ping/TCP/HTTP checks, beautiful web UI, push notifications, Docker-based | Master branch NAS (Docker) or any server |

### Enterprise AV Options (Recommended — Pick One)

| Solution | Cost | Central Mgmt | Key Feature |
|----------|------|-------------|-------------|
| **ESET PROTECT** | ~$40/server/year | Cloud console | Low resource usage, ransomware shield |
| **Bitdefender GravityZone** | ~$35/server/year | Cloud console | HyperDetect behavioral analysis |

**Total AV cost for 4 servers: ~$140–160/year.**

---

## 4. Hardware Bill of Materials

### Per Branch — Required Items

| Item | Spec | Purpose | Unit Cost (USD) |
|------|------|---------|----------------|
| **SD-WAN Edge** (N100 Mini-PC) | Intel N100, 2x 2.5GbE NICs, 8GB DDR5, 128GB NVMe, fanless, AES-NI | Runs OPNsense — firewall, IDS/IPS, VPN, DNS filtering, DHCP. All branch traffic flows through this device. | $150–200 |
| **Managed Switch** | TP-Link TL-SG2428P or similar — 24x GbE RJ45, PoE+, VLAN (802.1Q), web management GUI | Network segmentation via VLANs. Trunk port to OPNsense. Access ports per VLAN. | $200–300 |
| Cat6 patch cables, misc | — | Wiring | $30–50 |

**N100 port usage:** Port 1 = WAN (to broadband router), Port 2 = LAN (trunk to managed switch carrying all VLANs).

**Managed switch requirements:** RJ45 ports only (no SFP needed), VLAN support (802.1Q), PoE+ (for APs/cameras), web GUI for management. For smaller branches, TP-Link TL-SG2210P (8-port) is sufficient.

#### Optional: Active/Standby N100 for High Availability

For branches requiring zero downtime, deploy a second N100 as a cold standby:

| Item | Purpose | Unit Cost |
|------|---------|-----------|
| **Standby N100 Mini-PC** | Pre-configured with identical OPNsense config. If primary fails, swap and boot. Recovery in <5 minutes. | $150–200 |

With OPNsense config backup (XML export), restoring to the standby takes minutes. The standby sits powered off until needed.

### Optional Items

| Item | Spec | Purpose | Unit Cost (USD) |
|------|------|---------|----------------|
| **Backup NAS** (master branch only) | Synology DS223 (2-bay, RAID 1) + 2x WD Red Plus 4TB | Local backup target for Veeam. Also serves as cross-branch replication target. Only needed at the master branch since all branches sync there. | $400–500 |
| **Offsite NAS** (Pakistan or other location) | Synology DS223 or TerraMaster F2-223 (2-bay) + 2x 4TB drives | Receives encrypted backups from UAE over VPN tunnel. Provides geographic disaster recovery outside UAE. | $400–500 |

### Cost Summary

| Scenario | Per Branch | 4 Branches | Optional | Grand Total |
|----------|-----------|-----------|----------|-------------|
| **Core (N100 + Switch)** | $380–550 | $1,520–2,200 | — | **$1,520–2,200** |
| **Core + HA standby** | $530–750 | $2,120–3,000 | — | **$2,120–3,000** |
| **Core + Backup NAS (master only)** | — | $1,520–2,200 | $400–500 | **$1,920–2,700** |
| **Full (Core + HA + NAS + Offsite)** | — | $2,120–3,000 | $800–1,000 | **$2,920–4,000** |

---

## 5. Network Architecture

### Per-Branch Topology

```
                          INTERNET
                             |
                    [Broadband Router]
                     (Bridge Mode / DMZ)
                             |
                         WAN port
                    ┌────────────────┐
                    │   OPNsense     │
                    │  (N100 Mini-PC)│
                    │                │
                    │  - Firewall    │
                    │  - IDS/IPS     │
                    │  - IPsec VPN   │
                    │  - DHCP        │
                    │  - DNS Filter  │
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

**OPNsense is the default gateway for every device.** All traffic — internet, inter-branch, and inter-VLAN — passes through OPNsense for inspection and policy enforcement.

| Traffic Type | Path | Protection Applied |
|-------------|------|-------------------|
| Server-to-Server (inter-branch) | OPNsense → IPsec tunnel → remote OPNsense | AES-256 encryption + IDS/IPS |
| Server-to-Server (same branch) | Direct via switch (same VLAN) | Windows Firewall rules |
| Workstation to Internet | OPNsense → ISP | IDS/IPS + DNS blocklists |
| Workstation to Server (same branch) | OPNsense inter-VLAN routing | Firewall rules per port |
| Remote User to Server | IKEv2 VPN → OPNsense → Server | Encrypted + MFA authenticated |

**N100 performance:** Gigabit NAT ~940 Mbps, with Suricata IDS ~800 Mbps, IPsec AES-256-GCM ~700 Mbps. More than sufficient for branch office workloads.

### Full-Mesh Inter-Branch Connectivity

All 4 branches are connected to each other via encrypted IPsec tunnels — **6 tunnels** total for full mesh:

```
        Branch 1 (Master)
       /       |        \
      /        |         \
Branch 2 --- Branch 3 --- Branch 4
      \        |         /
       \       |        /
        Branch 2 ---- Branch 4
```

Every branch can reach every other branch directly. If one tunnel fails, other branches remain connected. Dead Peer Detection (DPD) automatically recovers tunnels within 60 seconds.

---

## 6. Security Features

### What Gets Deployed at Each Branch

| Feature | Description | Benefit |
|---------|------------|---------|
| **Stateful Firewall** | OPNsense default-deny inbound. Only explicitly allowed traffic passes. | Closes all public ports (RDP, SQL, everything). Zero attack surface. |
| **Intrusion Detection & Prevention (IDS/IPS)** | Suricata with ET Open + Abuse.ch rules (~35,000 signatures). Inline blocking mode. | Detects and blocks exploit attempts, malware downloads, C2 callbacks, port scans. |
| **DNS Filtering** | Unbound DNS with blocklists (malware, phishing, ads). DNSSEC validation. DNS-over-TLS upstream. | Blocks connections to known malicious domains before they happen. |
| **Network Segmentation** | VLANs isolate servers, workstations, management, and guests. Inter-VLAN firewall rules. | Limits blast radius. Compromised workstation cannot reach servers in other VLANs/branches. |
| **Encrypted Transport** | IKEv2 IPsec with AES-256-GCM, certificate authentication, Perfect Forward Secrecy. | All inter-branch data is encrypted. No eavesdropping or tampering possible. |
| **Endpoint Protection** | Windows Defender + ASR rules + enterprise AV (ESET/Bitdefender). | Multi-layer malware defense on every server. |
| **Server Hardening** | Disabled: SMBv1, NetBIOS, LLMNR, PowerShell v2. Enabled: Windows Firewall, audit logging, account lockout. | Reduces exploitable services to absolute minimum. |
| **Secure Remote Access** | IKEv2 VPN with certificate + password + TOTP (MFA). No client software needed. | Eliminates exposed RDP. Remote users must authenticate through VPN. |
| **Backup with Immutability** | 3-2-1 backup: local + cross-branch + offsite. Immutable snapshots prevent ransomware encryption of backups. | Full recovery capability even in worst-case scenario. |
| **Monitoring & Alerting** | Availability checks, IDS alerts, backup status. Email + Telegram notifications. | Immediate awareness of security events or outages. |

---

## 7. Network Segmentation (VLANs)

### IP Addressing Scheme

Pattern: `10.<branch>.<vlan>.0/24`

| Branch | VLAN 10 (Servers) | VLAN 20 (Workstations) | VLAN 30 (Mgmt) | VLAN 99 (Guest/IoT) |
|--------|------------------|----------------------|----------------|---------------------|
| Branch 1 | 10.1.10.0/24 | 10.1.20.0/24 | 10.1.30.0/24 | 10.1.99.0/24 |
| Branch 2 | 10.2.10.0/24 | 10.2.20.0/24 | 10.2.30.0/24 | 10.2.99.0/24 |
| Branch 3 | 10.3.10.0/24 | 10.3.20.0/24 | 10.3.30.0/24 | 10.3.99.0/24 |
| Branch 4 | 10.4.10.0/24 | 10.4.20.0/24 | 10.4.30.0/24 | 10.4.99.0/24 |

### VLAN Descriptions

| VLAN | Name | What Connects Here | Access Rules |
|------|------|-------------------|-------------|
| 10 | **Servers** | Windows Servers, NAS, SQL Server | Accessible from Workstations (SQL + file share only). Accessible from other branches via IPsec. |
| 20 | **Workstations** | User PCs, laptops | Can reach servers for SQL and file shares. Full internet access via OPNsense (inspected). |
| 30 | **Management** | OPNsense WebGUI, switch management | Only accessible by IT administrators. All other VLANs blocked from reaching this. |
| 99 | **Guest / IoT** | Guest WiFi, printers, cameras, IoT | Fully isolated. Internet access only (web). Cannot reach any internal VLAN. |

### Inter-VLAN Access Control

**Default: DENY everything between VLANs.** Only these specific flows are allowed:

| From | To | Allowed Ports | Purpose |
|------|----|--------------|---------|
| Workstations | Servers | TCP 1433 (SQL), TCP 445 (file shares) | Accounting software, file access |
| Workstations | Guest/IoT | TCP 9100, 631 (printing) | Printing |
| Management | All | All | IT administration |
| Guest/IoT | Internet only | TCP 80, 443 | Web browsing for guests |

**Blocked:** Guest/IoT can never reach Servers or Management. Workstations can never reach Management. No VLAN can access another except through explicit rules above.

---

## 8. Encrypted Inter-Branch Connectivity (IPsec SD-WAN)

### How It Works

Each branch runs OPNsense which establishes encrypted IPsec tunnels to every other branch. The accounting software's SQL sync now travels through these encrypted tunnels instead of over the open internet.

| Feature | Specification |
|---------|--------------|
| Protocol | IKEv2 (modern, supports dynamic IPs, NAT traversal, mobile clients) |
| Authentication | X.509 Certificates from a private CA (no shared passwords) |
| Encryption | AES-256-GCM (hardware-accelerated on N100) |
| Key Exchange | ECDH Group 20 (384-bit, NIST P-384) |
| Perfect Forward Secrecy | Yes — new keys every hour, past sessions cannot be decrypted |
| Failover | Dead Peer Detection: detects failed tunnel in ~60 seconds, auto-recovers |
| NAT Traversal | Automatic (UDP 4500) — works behind any ISP NAT/router |

### Tunnel Matrix

| # | Branch A | Branch B | Traffic |
|---|----------|----------|---------|
| 1 | Branch 1 | Branch 2 | SQL sync, management |
| 2 | Branch 1 | Branch 3 | SQL sync, management |
| 3 | Branch 1 | Branch 4 | SQL sync, management |
| 4 | Branch 2 | Branch 3 | SQL sync, management |
| 5 | Branch 2 | Branch 4 | SQL sync, management |
| 6 | Branch 3 | Branch 4 | SQL sync, management |

### Certificate-Based Trust

A private Certificate Authority (CA) is created on the master branch OPNsense. Each branch receives a signed certificate. Only devices with certificates signed by this CA can establish tunnels. This is significantly stronger than pre-shared keys and cannot be brute-forced.

---

## 9. Dynamic DNS for Branch Discovery

Since UAE broadband uses dynamic public IPs, each branch OPNsense registers its current IP with a Dynamic DNS (DDNS) provider. IPsec peers find each other by hostname (FQDN) rather than IP address.

| Feature | Detail |
|---------|--------|
| DDNS Provider | Dynu (recommended, free, 4 hostnames) or Cloudflare (if client owns a domain) |
| Branch FQDNs | `branch1.fastpartz.dynu.net`, `branch2.fastpartz.dynu.net`, etc. |
| Update Speed | DNS record updates within 60 seconds of IP change |
| Tunnel Recovery | If IP changes, tunnels recover automatically in 30–90 seconds via DPD |
| OPNsense Integration | Built-in DDNS client — no external scripts needed |

**Impact of ISP IP change:** Brief tunnel interruption (~30–90 seconds). SQL sync retries automatically. No manual intervention needed.

---

## 10. Windows Server Hardening

### What Changes on Each Server

| Category | Action | Why |
|----------|--------|-----|
| **Antivirus** | Enable Windows Defender with Tamper Protection + ASR rules. Install enterprise AV (ESET/Bitdefender). | Multi-layer defense against malware and ransomware. |
| **RDP** | Disabled from internet. Accessible only via VPN + Management VLAN. NLA (Network Level Auth) required. | Eliminates the #1 ransomware entry point. |
| **SQL Server** | Bind to Server VLAN IP only (not 0.0.0.0). | SQL only reachable from internal network, not from any external source. |
| **Windows Firewall** | Enabled. Default-deny inbound. Allow only SQL (1433), SMB (445), RDP (from mgmt only). | Defense-in-depth even if network firewall is bypassed. |
| **Disabled Protocols** | SMBv1 (WannaCry vector), NetBIOS, LLMNR, WPAD, PowerShell v2 (bypasses AMSI). | Removes unnecessary attack surface. |
| **Account Security** | Lockout after 5 failed attempts (30 min). 14-char minimum password. Separate admin accounts. | Prevents brute-force and limits damage from credential theft. |
| **Application Control** | AppLocker or WDAC: block executables from user profile, temp, and AppData folders. | Prevents ransomware from executing even if downloaded. |
| **Patching** | Automatic Windows Update for security patches. Monthly reboot schedule. | Closes known vulnerabilities promptly. |
| **Audit Logging** | Security events forwarded to central syslog via NXLog. Track logins, account changes, service installs. | Forensic trail and real-time alerting on suspicious activity. |

---

## 11. Backup Strategy (3-2-1)

Three copies of data, on two different media types, with one copy offsite.

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
   │  Local NAS │  │ Cross-   │  │  Offsite     │
   │  (master   │  │ branch   │  │  (Cloud or   │
   │   branch)  │  │ via IPsec│  │   Pakistan)  │
   └────────────┘  └──────────┘  └──────────────┘
      Daily           Daily         Weekly
```

| Copy | Location | Method | Schedule | Immutability |
|------|----------|--------|----------|-------------|
| **1 — Local** | Synology NAS at master branch | Veeam Community Edition (SQL-aware, free) | Daily incremental + weekly full | NAS snapshots (read-only, 7-day retention) |
| **2 — Cross-branch** | Partner branch NAS via IPsec tunnel | rsync/rclone with encryption | Daily sync | NAS snapshots |
| **3a — Cloud** (recommended) | Backblaze B2 / Cloudflare R2 / AWS S3 Glacier | Restic with AES-256 encryption | Weekly full + daily incremental | Object Lock (30-day, cannot be deleted) |
| **3b — Physical offsite** (optional) | NAS at Pakistan location | Borgbackup with AES-256 encryption over VPN | Weekly full + daily incremental | Append-only mode (client cannot delete backups) |

### Cloud Offsite Options

| Provider | Storage Cost | Egress Cost | Immutability | Best For |
|----------|-------------|-------------|-------------|----------|
| **Backblaze B2** | $5/TB/month | $0.01/GB | Object Lock | Best balance of cost and features |
| **Cloudflare R2** | $15/TB/month | **Free** | No native lock | Frequent restores needed |
| **AWS S3 Glacier Deep Archive** | $1/TB/month | $0.09/GB | Vault Lock | Cheapest long-term archival |

### Backup Testing

| Test | Frequency |
|------|-----------|
| Backup completion verification | Daily (automated alert on failure) |
| File-level restore | Monthly |
| Full server restore to test environment | Quarterly |
| Offsite restore | Semi-annually |

---

## 12. Secure Remote Access

### IKEv2 Roadwarrior VPN

Remote users connect to the branch OPNsense via IKEv2 VPN. **No client software needed** — Windows, macOS, iOS, and Android all have built-in IKEv2 VPN clients.

| Feature | Detail |
|---------|--------|
| Protocol | IKEv2 (native on all modern OS) |
| Authentication | Certificate + Username/Password + TOTP (MFA) |
| Encryption | AES-256-GCM |
| Split Tunneling | Only branch traffic goes through VPN (internet browsing stays local) |
| VPN Subnet | 10.10.10.0/24 (dedicated, isolated from all branch VLANs) |
| DNS | OPNsense Unbound (filtered — malware/phishing domains blocked) |

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
| Time-limited accounts | VPN account with expiry date |
| Restricted access | Only specific server IPs and ports |
| Session logging | All VPN connections logged |
| Immediate revocation | Account disabled after support session |

---

## 13. Ransomware Attack Surface Analysis & Mitigations

| # | Attack Vector | Current Risk | Mitigation | Risk After Deployment |
|---|-------------|-------------|-----------|----------------------|
| 1 | **RDP Brute Force** | CRITICAL | OPNsense blocks all inbound. RDP only via VPN + Management VLAN. | **ELIMINATED** |
| 2 | **SQL Server Exploitation** | CRITICAL | OPNsense blocks all inbound. SQL bound to VLAN 10 only. | **ELIMINATED** |
| 3 | **Phishing / Email** | HIGH | Email provider security + SPF/DKIM/DMARC + user awareness training. | MEDIUM |
| 4 | **Malicious Downloads** | HIGH | Suricata IDS/IPS + DNS blocklists + Windows Defender + Enterprise AV + AppLocker. | LOW |
| 5 | **USB / Removable Media** | MEDIUM | Group Policy: disable AutoRun. ASR rule blocks untrusted processes from USB. | LOW |
| 6 | **Lateral Movement** | CRITICAL | VLAN segmentation + inter-VLAN firewall + Windows Firewall + separate admin accounts. | LOW |
| 7 | **Credential Theft** | HIGH | MFA on VPN. Account lockout (5 attempts/30 min). Separate admin accounts. LSASS protection. | LOW |
| 8 | **Supply Chain / Software** | MEDIUM | Auto-patching. AppLocker/WDAC whitelist. Vendor access time-limited. | LOW |
| 9 | **Insider Threat** | MEDIUM | Least privilege. Audit logging. No shared accounts. | LOW |
| 10 | **WiFi** | MEDIUM | WPA3. Guest SSID on VLAN 99 (isolated from servers). | LOW |
| 11 | **Printers / IoT** | LOW-MEDIUM | VLAN 99 (isolated). Only print ports allowed from workstation VLAN. | LOW |
| 12 | **DNS-Based Attacks** | MEDIUM | DNSSEC validation. DNS-over-TLS. DNS blocklists on OPNsense. | LOW |
| 13 | **Backup Destruction** | CRITICAL | 3-2-1 backup with immutable snapshots. Object Lock on cloud. Append-only offsite. | LOW |
| 14 | **Unpatched Vulnerabilities** | HIGH | Automated Windows Update. Monthly patch review. | LOW |

### Email / Phishing Protection

DNS-based email authentication will be configured on the company domain:

| Record | Purpose |
|--------|---------|
| **SPF** | Specifies which mail servers can send email for your domain |
| **DKIM** | Cryptographically signs outgoing emails to prevent spoofing |
| **DMARC** | Tells receiving servers to reject emails that fail SPF/DKIM |

Additional controls: block dangerous attachment types (.exe, .bat, .ps1, .vbs, .js) at the mail gateway. Quarterly phishing awareness training for staff.

---

## 14. Monitoring & Alerting

### What Gets Monitored

| Check | What It Detects | Alert Method |
|-------|----------------|-------------|
| IPsec tunnel status | Tunnel down between any two branches | Email + Telegram |
| IDS/IPS alerts | Exploit attempts, malware downloads, C2 callbacks | Email |
| Server availability | Windows Server offline or SQL unreachable | Email + Telegram |
| Backup job status | Backup failed or incomplete | Email + Telegram |
| Cross-branch sync | Replication failure | Telegram |
| Offsite backup | Cloud or Pakistan backup failure | Telegram |
| Disk space | NAS or server storage >80% full | Email |
| Failed logins | 5+ failed login attempts on any server | Email |

### Alert Channels

| Channel | Use Case | Why |
|---------|---------|-----|
| **Email** | All alerts | Formal record, reaches everyone |
| **Telegram Bot** | Critical alerts (tunnel down, backup failed, server offline) | Instant mobile notification, free, works globally |

### Monitoring Dashboard

**Uptime Kuma** (free, open-source) provides a web dashboard showing the status of all branches, tunnels, servers, and backup jobs at a glance. Runs as a lightweight container on the master branch NAS or server.

---

## 15. Implementation Phases

| Phase | Scope | Duration | Deliverable |
|-------|-------|----------|-------------|
| **1** | Hardware procurement + OPNsense installation on all N100 devices | 1 week | 4 configured OPNsense appliances ready for deployment |
| **2** | Branch 1 (master) pilot — full VLAN deployment, firewall rules, IDS/IPS, DNS filtering | 1 week | Branch 1 fully operational with segmented, protected network |
| **3** | Deploy remaining 3 branches + establish all 6 IPsec tunnels (full mesh) | 1 week | All branches connected with encrypted tunnels. SQL sync working. |
| **4** | Windows Server hardening + AV deployment + backup setup on all servers | 1 week | All servers hardened. Veeam backups running daily. |
| **5** | Remote user VPN + monitoring + offsite backup (cloud/Pakistan) | 1 week | VPN with MFA working. Monitoring dashboard live. 3-2-1 backup complete. |
| **6** | Testing, verification, documentation, knowledge transfer | 1 week | All tests passed. Runbooks delivered. Staff trained. |

**Total estimated deployment: 6 weeks**

---

## 16. Open Questions

*To be discussed and filled in during client meeting:*

| # | Question | Answer | Impact |
|---|----------|--------|--------|
| 1 | What email provider do the branches use? (Gmail, local UAE provider, Microsoft 365, other?) | | Determines email security controls (SPF/DKIM/DMARC setup, attachment filtering options) |
| 2 | Which branch is the "master" that others sync to? Or is it peer-to-peer sync? | | Determines where NAS and Veeam are deployed, backup flow direction |
| 3 | How much data (GB/TB) is on each server? | | Sizes NAS drives and cloud backup costs |
| 4 | How often do servers sync, and how much data changes daily? | | Sizes IPsec tunnel bandwidth needs and backup window |
| 5 | What is the broadband speed at each branch (download/upload)? | | Validates N100 is sufficient, sizes cross-branch replication window |
| 6 | Are broadband routers ISP-managed or client-owned? Can we set bridge mode? | | Determines WAN configuration (bridge vs DMZ vs port forward) |
| 7 | Does the client own a domain name (e.g., fastpartz.ae)? | | Determines DDNS strategy (Cloudflare with own domain vs Dynu free) |
| 8 | How many remote users need VPN access? | | Sizes VPN configuration and user certificate management |
| 9 | Are there any printers, IP cameras, or IoT devices on the network? | | Determines VLAN 99 scope and firewall rules |
| 10 | Is there WiFi at any branch? If so, what APs? | | Determines VLAN tagging on APs and WiFi security config |
| 11 | Does the client have a Microsoft 365 or Google Workspace subscription? | | Determines available email security features |
| 12 | What Windows Server version is currently running at each branch? | | Determines patching strategy and feature availability (AppLocker, ASR) |
| 13 | Is the accounting software vendor supportive of network changes? Will they need access? | | Determines vendor VPN access requirements |
| 14 | Is there a preference for cloud offsite (Backblaze/AWS) vs physical offsite (Pakistan NAS)? | | Determines offsite backup architecture |
| 15 | What is the acceptable downtime window for maintenance/reboots? | | Sets maintenance window for patching and updates |

---

## Appendix: Emergency Procedures

### Suspected Ransomware Attack

1. **ISOLATE** — Disconnect affected server from network immediately (pull Ethernet cable)
2. **DO NOT reboot** — preserves forensic evidence in memory
3. **CHECK** — Are other branches affected? Are backups intact?
4. **RESTORE** — Recover from most recent clean backup (local NAS → cross-branch → offsite)
5. **INVESTIGATE** — Review Suricata logs and Windows Security logs for entry point
6. **HARDEN** — Address the vulnerability that was exploited

### OPNsense Failure

1. Branch loses internet and inter-branch connectivity
2. **Bypass:** Set workstation gateway to broadband router directly (internet-only, no security)
3. **Restore:** Boot standby N100 (if available) or re-flash OPNsense + restore XML config backup
4. **Recovery time:** ~5 minutes with standby unit, ~30 minutes with fresh install

### IPsec Tunnel Down

1. Check OPNsense dashboard → VPN → IPsec → Status Overview
2. Wait 2 minutes (DPD auto-recovery in progress)
3. If still down: check if remote branch has broadband outage
4. Try disconnect + reconnect from OPNsense GUI
5. Check if DynDNS has updated (remote IP may have changed)
