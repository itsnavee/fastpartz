# FastPartz — Cloud Hub Sync Solution (v3)

**Version:** 3.0
**Date:** February 2026
**Scope:** 4 branches (UAE) + cloud sync hub
**Approach:** Central cloud server in OCI UAE — branches sync outbound only, zero inbound ports

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Architecture Overview](#2-architecture-overview)
3. [Why a Cloud Hub](#3-why-a-cloud-hub)
4. [Cloud Provider — Oracle Cloud (OCI) UAE](#4-cloud-provider--oracle-cloud-oci-uae)
5. [Branch Network Setup](#5-branch-network-setup)
6. [SQL Sync Architecture](#6-sql-sync-architecture)
7. [Remote User Access](#7-remote-user-access)
8. [Security Features](#8-security-features)
9. [Network Segmentation (VLANs)](#9-network-segmentation-vlans)
10. [Backup Strategy (3-2-1)](#10-backup-strategy-3-2-1)
11. [Windows Server Hardening](#11-windows-server-hardening)
12. [Monitoring & Alerting](#12-monitoring--alerting)
13. [Ransomware Risk Assessment](#13-ransomware-risk-assessment)
14. [Cost Summary](#14-cost-summary)
15. [Implementation Phases](#15-implementation-phases)
16. [Open Questions](#16-open-questions)

---

## 1. Executive Summary

### The Problem

FastPartz operates 4 branches across the UAE with Windows Servers running accounting software (MS SQL Server). The current setup is critically vulnerable: public IPs, open RDP/SQL ports, no firewalls, no backups, no segmentation.

### What This Solution Delivers

Instead of building encrypted tunnels between branches, this solution places a **central cloud server** in Oracle Cloud Infrastructure (OCI) UAE region. Each branch syncs its SQL data **outbound** to the cloud server. No branch talks to any other branch directly.

- **Zero inbound ports** on every branch — branches only make outbound connections
- **No inter-branch tunnels** — eliminates the most complex part of the network
- **Central database** in the cloud — single source of truth for all branches
- **Remote users connect to the cloud** — no VPN to individual branches needed
- **OCI UAE region** — data stays in UAE (Dubai or Abu Dhabi)
- **Managed remotely** — cloud server accessible from anywhere

### Why This Approach

| Complexity Source | Traditional (OPNsense/FlexiWAN) | Cloud Hub |
|---|---|---|
| Inter-branch tunnels | 6 IPsec tunnels to configure and maintain | **None** |
| Dynamic DNS | 4 DDNS registrations for changing IPs | **Not needed** |
| Tunnel monitoring | Monitor 6 tunnels for failures | **Not needed** |
| Remote user VPN | Configure VPN server + user certificates | **RDP to cloud** |
| Branch firewalls | Complex stateful firewall rules | **Simple: block all inbound** |

---

## 2. Architecture Overview

```
                    ┌──────────────────────────┐
                    │   OCI Cloud Server (UAE)  │
                    │                          │
                    │  - Windows Server 2022    │
                    │  - SQL Server (central)   │
                    │  - RDP Gateway            │
                    │  - Automated Backups      │
                    │  - Monitoring Dashboard   │
                    └──────────┬───────────────┘
                               │
              All connections OUTBOUND from branches
              (initiated by branch servers → cloud)
                               │
          ┌────────┬───────────┼───────────┬────────┐
          │        │           │           │        │
       Branch 1  Branch 2   Branch 3   Branch 4   Remote
       Server    Server     Server     Server     Users
       (sync↑)   (sync↑)    (sync↑)    (sync↑)   (RDP→cloud)
```

### Traffic Flow

| Flow | Direction | Protocol | Description |
|------|-----------|----------|-------------|
| Branch → Cloud | **Outbound** (branch initiates) | TLS/SQL | SQL sync: branch pushes changes to cloud |
| Cloud → Branch | **Response only** (within established connection) | TLS/SQL | SQL sync: cloud sends changes back to branch |
| Remote User → Cloud | **Inbound to cloud** | RDP (TLS) | Users RDP to cloud server for remote work |
| Branch → Internet | **Outbound** | HTTPS | Windows Update, AV updates |
| Branch ← Internet | **Blocked** | — | **Zero inbound ports on branches** |

**Key insight:** Branches never accept inbound connections. They only reach out to the cloud server. This eliminates the entire tunnel infrastructure and makes branch firewall rules trivially simple.

---

## 3. Why a Cloud Hub

### What This Eliminates

| Removed Component | What It Was For | Why It's Not Needed |
|---|---|---|
| IPsec tunnels (6) | Branch-to-branch encrypted links | Branches sync to cloud instead of to each other |
| Dynamic DNS (4) | Finding branches when IPs change | Cloud server has a fixed IP |
| Tunnel monitoring | Detecting failed tunnels | No tunnels to monitor |
| VPN for remote users | Encrypted access to branch servers | Users RDP to cloud server directly |
| Certificate Authority | Authenticating IPsec peers | No IPsec = no certs needed |
| SD-WAN appliance complexity | Managing tunnel routing | Branches just need outbound internet access |

### What Remains

| Component | Still Needed | Why |
|---|---|---|
| Branch firewall (N100 + OPNsense) | Yes | VLAN segmentation, block inbound, DNS filtering, endpoint protection |
| Managed switch | Yes | VLAN isolation for servers, workstations, guests |
| Windows hardening | Yes | Endpoint defense regardless of network architecture |
| Endpoint AV | Yes | ESET + Defender on all servers |
| Backups | Yes — but simplified | Cloud server is naturally an additional copy |

---

## 4. Cloud Provider — Oracle Cloud (OCI) UAE

### Why OCI

| Factor | OCI | Azure | AWS |
|---|---|---|---|
| **UAE region** | Dubai + Abu Dhabi | Dubai + Abu Dhabi | Bahrain (not UAE) |
| **Data sovereignty** | UAE data stays in UAE | UAE data stays in UAE | Data in Bahrain |
| **Egress pricing** | 10TB/month free, then $0.0085/GB | $0.08/GB from first byte | $0.09/GB from first byte |
| **Compute pricing** | ~$55/month (2 OCPU, 16GB) | ~$120/month (B4ms, 4 vCPU, 16GB) | ~$100/month (m6i.large, 2 vCPU, 8GB) |
| **Free tier** | 4 ARM OCPUs, 24GB RAM, 200GB — always free | 12-month limited trial | 12-month limited trial |
| **Windows Server** | Supported (paid shapes) | Included in VM price | Included in VM price |

**OCI is the cheapest option with UAE presence.** The always-free ARM tier could run monitoring/backup tools at zero cost.

### Recommended Cloud Server Spec

**Option A: Windows Server (if accounting software requires Windows)**

| Component | Spec | Monthly Cost (USD) |
|---|---|---|
| Compute | VM.Standard.E4.Flex — 2 OCPU (AMD EPYC) | $37 |
| Memory | 16 GB RAM | $18 |
| Windows Server License | Standard (via OCI) | ~$20-30 |
| Boot Volume | 256 GB Block Storage (SSD) | $6.50 |
| Backup | 500 GB Object Storage | $13 |
| Data Transfer | 10 TB/month outbound (free) | $0 |
| **Total** | | **~$95-105/month** |

**Option B: Linux + SQL Server (cheapest)**

| Component | Spec | Monthly Cost (USD) |
|---|---|---|
| Compute | VM.Standard.A1.Flex — 4 OCPU (ARM Ampere) | **$0 (Always Free)** |
| Memory | 24 GB RAM | **$0 (Always Free)** |
| OS | Ubuntu 22.04 LTS | $0 |
| SQL Server | SQL Server 2022 Express on Linux (free, up to 10GB/DB) | $0 |
| Boot Volume | 200 GB Block Storage | **$0 (Always Free)** |
| Data Transfer | 10 TB/month outbound | **$0 (Always Free)** |
| **Total** | | **$0/month** |

**Note on Option B:** SQL Server Express runs on x86 Linux, NOT on ARM. The OCI Always Free ARM instances cannot run SQL Server. If using Option B, we'd need a paid x86 VM (~$55/month for compute only, no Windows license needed) with SQL Server Express on Ubuntu Linux.

**Realistic Option B pricing:** ~$55/month (paid x86 Linux VM + SQL Server Express free).

### Recommended Configuration

| Scenario | Monthly Cost | Annual Cost |
|---|---|---|
| **Windows Server + SQL** (full compatibility) | ~$100/month | ~$1,200/year |
| **Linux + SQL Express** (cheapest viable) | ~$55/month | ~$660/year |

---

## 5. Branch Network Setup

Each branch gets a simplified network — the firewall only needs to block inbound and segment VLANs. No tunnel configuration.

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
                    │  - DHCP        │
                    │  - DNS Filter  │
                    │  - VLAN routing│
                    │                │
                    │  NO tunnels    │
                    │  NO VPN server │
                    └──────┬─────────┘
                       LAN port (Trunk)
                           │
                    ┌──────┴─────────┐
                    │ Managed Switch  │
                    │                │
                    │ VLAN 10: Servers│
                    │ VLAN 20: Wkstns│
                    │ VLAN 30: Mgmt  │
                    │ VLAN 99: Guest │
                    └────────────────┘
```

### Simplified Firewall Rules

The OPNsense config becomes dramatically simpler:

**WAN Inbound:**
```
DENY ALL (zero exceptions — no IPsec, no VPN, nothing)
```

**Server VLAN Outbound:**
```
ALLOW  TCP  Servers → Cloud_Server_IP  1433    (SQL sync)
ALLOW  TCP  Servers → Cloud_Server_IP  3389    (RDP to cloud for management)
ALLOW  TCP  Servers → Internet         80,443  (Windows Update, AV updates)
DENY   ALL  (everything else)
```

That's it. Compare this to the 30+ rules per VLAN in the tunnel-based solutions.

---

## 6. SQL Sync Architecture

### How Sync Works

The accounting software currently syncs between branch SQL Servers. With the cloud hub, the sync target changes from "other branches" to "cloud server":

```
Before (direct sync):              After (hub sync):

Branch 1 ←→ Branch 2              Branch 1 → Cloud ← Branch 1
Branch 1 ←→ Branch 3              Branch 2 → Cloud ← Branch 2
Branch 1 ←→ Branch 4              Branch 3 → Cloud ← Branch 3
Branch 2 ←→ Branch 3              Branch 4 → Cloud ← Branch 4
Branch 2 ←→ Branch 4
Branch 3 ←→ Branch 4              (Cloud redistributes to all)
(6 connections)                    (4 connections — all outbound)
```

### SQL Replication Options

| Method | How It Works | Best For |
|---|---|---|
| **SQL Merge Replication** | Each branch has local DB + syncs changes bidirectionally with cloud. Conflict resolution handles simultaneous edits. | Branches that need to work offline and sync later |
| **SQL Transactional Replication** | Cloud is the publisher. Branches subscribe and receive changes. Branch changes pushed via linked server. | Central control, predictable data flow |
| **Vendor Sync Mechanism** | If the accounting software has its own sync, point it at the cloud server instead of branch servers. | Least disruption to current workflow |

**Most likely approach:** Change the accounting software's sync target from branch IPs to the cloud server's fixed IP. The software continues to sync as before — it just syncs with the cloud instead of with other branches.

### Connection Security

| Layer | Protection |
|---|---|
| **Transport** | SQL connections over TLS 1.2+ (encrypted in transit) |
| **Authentication** | SQL Server authentication with strong passwords |
| **Network** | OCI Security List: allow inbound SQL only from branch public IPs |
| **Encryption at rest** | OCI block volume encryption (AES-256, managed keys) |

---

## 7. Remote User Access

Remote users RDP directly to the cloud server. No VPN needed.

### How It Works

1. User opens Remote Desktop Connection
2. Connects to `cloud.fastpartz.ae` (fixed IP / DNS name)
3. Authenticates with Windows credentials
4. Works on the central database directly

### Security Controls

| Control | Implementation |
|---|---|
| **NLA required** | Network Level Authentication before session starts |
| **IP whitelist** | OCI Security List: allow RDP only from known IPs (or use RD Gateway) |
| **Account lockout** | 5 failed attempts → 30 min lockout |
| **Session timeout** | Idle sessions disconnect after 30 min |
| **MFA (optional)** | Azure MFA or Duo for RDP (recommended) |

### RD Gateway (Recommended Enhancement)

For better security, deploy Remote Desktop Gateway on the cloud server:

- Users connect via HTTPS (port 443) instead of raw RDP (port 3389)
- Gateway authenticates users before establishing RDP session
- Works through any firewall (HTTPS is universally allowed)
- Built into Windows Server — no extra licensing

---

## 8. Security Features

| Feature | How It's Delivered | Benefit |
|---|---|---|
| **Zero inbound ports (branches)** | OPNsense blocks ALL inbound traffic | No attack surface on any branch |
| **Firewall (cloud)** | OCI Security Lists + Network Security Groups | Only SQL and RDP from known IPs allowed |
| **Encryption in transit** | SQL over TLS, RDP over TLS | All data encrypted between branches and cloud |
| **Encryption at rest** | OCI block volume encryption (AES-256) | Data encrypted on cloud storage |
| **DNS filtering** | OPNsense Unbound with DNSBL blocklists | Malware/phishing domains blocked at each branch |
| **Endpoint AV** | Windows Defender + ESET PROTECT | Multi-layer defense on all servers (branch + cloud) |
| **Network segmentation** | VLANs on managed switches at each branch | Servers, workstations, guests isolated |
| **Server hardening** | SMBv1 disabled, Windows Firewall, ASR rules, AppLocker | Reduced attack surface on all servers |
| **Backup with immutability** | OCI snapshots + Backblaze B2 + local NAS | Multiple copies, immutable offsite |
| **Monitoring** | Uptime Kuma + OCI monitoring + Telegram alerts | Immediate notification of issues |

### What's Different from Tunnel-Based Solutions

| Feature | Tunnel-Based (v1/v2) | Cloud Hub (v3) |
|---|---|---|
| IDS/IPS (Suricata) | Available on OPNsense | Not needed for inter-branch (no tunnels). Cloud server protected by OCI security. |
| Inter-branch encryption | IPsec tunnels (AES-256) | SQL over TLS (AES-256) — same encryption level |
| Attack surface | Tunnels = potential entry points | Zero tunnel endpoints to attack |
| Branch compromise impact | Attacker could pivot through tunnels | Attacker stuck on one branch — no tunnel to other branches |

---

## 9. Network Segmentation (VLANs)

Same VLAN structure as other solutions — this protects each branch internally.

Pattern: `10.<branch>.<vlan>.0/24`

| Branch | VLAN 10 (Servers) | VLAN 20 (Workstations) | VLAN 30 (Mgmt) | VLAN 99 (Guest) |
|--------|------------------|----------------------|----------------|-----------------|
| Branch 1 | 10.1.10.0/24 | 10.1.20.0/24 | 10.1.30.0/24 | 10.1.99.0/24 |
| Branch 2 | 10.2.10.0/24 | 10.2.20.0/24 | 10.2.30.0/24 | 10.2.99.0/24 |
| Branch 3 | 10.3.10.0/24 | 10.3.20.0/24 | 10.3.30.0/24 | 10.3.99.0/24 |
| Branch 4 | 10.4.10.0/24 | 10.4.20.0/24 | 10.4.30.0/24 | 10.4.99.0/24 |

Inter-VLAN rules remain the same: workstations can reach servers on SQL (1433) and SMB (445) only. Guest VLAN isolated. Management VLAN restricted to IT.

---

## 10. Backup Strategy (3-2-1)

The cloud hub naturally provides an additional backup layer:

```
             ┌──────────────────┐
             │  Branch Server   │
             │  (Local SQL DB)  │
             └────────┬─────────┘
                      │
          ┌───────────┼───────────┐
          │           │           │
          ▼           ▼           ▼
   ┌────────────┐  ┌──────────┐  ┌──────────────┐
   │  Copy 1    │  │ Copy 2   │  │  Copy 3      │
   │  Cloud     │  │ Local    │  │  Backblaze   │
   │  Server    │  │ NAS      │  │  B2 (Object  │
   │  (OCI)     │  │ (master) │  │  Lock)       │
   └────────────┘  └──────────┘  └──────────────┘
     Continuous      Daily          Weekly
     (SQL sync)    (Veeam)       (Restic)
```

| Copy | Location | Method | Schedule | Immutability |
|------|----------|--------|----------|-------------|
| **1 — Cloud** | OCI UAE | SQL sync (continuous) + OCI boot volume snapshots | Continuous + daily snapshots | OCI snapshot retention policy |
| **2 — Local NAS** | Synology NAS (master branch) | Veeam CE | Daily incremental + weekly full | NAS snapshots (7-day) |
| **3 — Offsite cloud** | Backblaze B2 | Restic with AES-256 | Weekly full + daily incremental | Object Lock (30-day) |

**Bonus:** The cloud server itself is an always-up-to-date copy of all branch data. If a branch server dies, the data is already in the cloud.

---

## 11. Windows Server Hardening

Identical to all other solutions — applied to every branch server AND the cloud server:

- Windows Defender + Tamper Protection + ASR rules
- ESET PROTECT enterprise AV
- Windows Firewall (default-deny inbound)
- Disable SMBv1, NetBIOS, LLMNR, PowerShell v2
- Account lockout (5 attempts / 30 min)
- 14-character minimum passwords
- AppLocker (block executables from user profile/temp/AppData)
- Automatic Windows Update
- Audit logging (logons, account changes, service installs)

**Cloud server additional hardening:**
- OCI Security Lists: whitelist branch IPs for SQL (1433)
- RDP via RD Gateway (HTTPS 443) instead of direct 3389
- OCI Cloud Guard: automated security monitoring
- Enable OCI Vulnerability Scanning

---

## 12. Monitoring & Alerting

| Check | What It Detects | Alert Method |
|-------|----------------|-------------|
| Cloud server availability | OCI VM down | OCI Monitoring + Telegram |
| SQL sync status | Branch failed to sync | Telegram |
| Branch server availability | Windows Server offline | Uptime Kuma + Telegram |
| Backup job status | Veeam/Restic failure | Email + Telegram |
| Disk space | Cloud or branch storage >80% | Email |
| Failed logins (cloud) | Brute-force attempt on cloud RDP | Email + Telegram |
| OCI Security alerts | Cloud Guard threat detection | OCI Notifications + Email |

**Uptime Kuma** runs on the OCI cloud server (Docker), monitoring all branch servers via outbound health checks.

---

## 13. Ransomware Risk Assessment

| # | Attack Vector | Current Risk | Mitigation | After |
|---|---|---|---|---|
| 1 | **RDP Brute Force (branches)** | CRITICAL | OPNsense blocks ALL inbound. Zero exposed ports. | **ELIMINATED** |
| 2 | **RDP Brute Force (cloud)** | — | RD Gateway (HTTPS) + IP whitelist + account lockout + MFA | LOW |
| 3 | **SQL Exploitation** | CRITICAL | No SQL port exposed on branches. Cloud SQL only from whitelisted IPs. | **ELIMINATED** |
| 4 | **Phishing / Email** | HIGH | DNS blocklists + SPF/DKIM/DMARC + user training | MEDIUM |
| 5 | **Lateral Movement** | CRITICAL | No inter-branch tunnels = no lateral path between branches. VLANs within each branch. | **ELIMINATED** |
| 6 | **Backup Destruction** | CRITICAL | 3 copies: cloud + local NAS + B2 Object Lock | LOW |
| 7 | **Credential Theft** | HIGH | MFA on cloud RDP. Account lockout. Separate admin accounts. | LOW |
| 8 | **Unpatched Vulnerabilities** | HIGH | Automatic Windows Update on all servers | LOW |

**Lateral movement is uniquely mitigated:** In tunnel-based solutions, a compromised branch could potentially reach other branches through the tunnels. In the cloud hub model, branches have no path to each other — a compromised Branch 2 cannot reach Branch 3 at all.

---

## 14. Cost Summary

### Hardware (One-Time)

| Item | Per Branch | 4 Branches |
|------|-----------|-----------|
| N100 Mini-PC (OPNsense) | $150-200 | $600-800 |
| Managed Switch (TP-Link) | $200-300 | $800-1,200 |
| Cabling | $30-50 | $120-200 |
| **Subtotal** | **$380-550** | **$1,520-2,200** |
| Backup NAS (master branch, optional) | — | $400-500 |

### Recurring (Monthly/Annual)

| Item | Monthly | Annual |
|------|---------|--------|
| OCI Cloud Server (Windows + SQL) | $100 | $1,200 |
| OCI Cloud Server (Linux + SQL Express) | $55 | $660 |
| ESET PROTECT (5 servers: 4 branch + 1 cloud) | $17 | $200 |
| Backblaze B2 (1TB estimated) | $5 | $60 |
| **Total (Windows cloud)** | **$122** | **$1,460** |
| **Total (Linux cloud)** | **$77** | **$920** |

### Grand Total — Year 1

| Scenario | Hardware | Recurring | Year 1 Total |
|----------|---------|-----------|-------------|
| **Core (Linux cloud)** | $1,520-2,200 | $920 | **$2,440-3,120** |
| **Core (Windows cloud)** | $1,520-2,200 | $1,460 | **$2,980-3,660** |
| **Full (+ NAS + B2)** | $1,920-2,700 | $1,460 | **$3,380-4,160** |

---

## 15. Implementation Phases

| Phase | Scope | Duration | Deliverable |
|-------|-------|----------|-------------|
| **1** | Provision OCI cloud server. Install Windows/Linux + SQL Server. Configure security lists. | 1 week | Cloud server running with secured access |
| **2** | Set up SQL sync between Branch 1 (master) and cloud server. Verify data integrity. | 1 week | Branch 1 syncing to cloud successfully |
| **3** | Deploy N100 + OPNsense + managed switch at Branch 1. VLANs, firewall, DNS filtering. | 1 week | Branch 1 fully segmented, zero inbound ports |
| **4** | Deploy remaining branches (2-4) + connect sync to cloud | 1 week | All branches syncing to cloud |
| **5** | Windows hardening + AV deployment + backup setup (all servers including cloud) | 1 week | All servers hardened. Backups running. |
| **6** | Testing, monitoring (Uptime Kuma), documentation, training | 1 week | All tests passed. Runbooks delivered. |

**Total: 6 weeks**

---

## 16. Open Questions

| # | Question | Impact |
|---|----------|--------|
| 1 | **How does the accounting software sync?** (SQL replication? Vendor mechanism? Real-time queries?) | Determines if cloud hub model is viable |
| 2 | Do branch users need to query other branches' data in real-time? | If yes, cloud server becomes the central query point |
| 3 | What is the total database size across all branches? | Sizes the cloud server and determines if SQL Express (10GB limit) is sufficient |
| 4 | Does the accounting software require Windows? | Determines Windows vs Linux cloud server |
| 5 | What email provider? | SPF/DKIM/DMARC setup |
| 6 | Which branch is the master? | Determines initial sync direction |
| 7 | Broadband speed at each branch? | Validates sync over internet is feasible |
| 8 | How many remote users need access? | Sizes cloud server resources |
| 9 | Are broadband routers ISP-managed or client-owned? | Determines WAN config (bridge vs DMZ) |
| 10 | Are there printers, cameras, IoT devices? | Determines VLAN 99 scope |

---

## Appendix: Emergency Procedures

### Cloud Server Down
1. Check OCI Console — is the VM running?
2. If stopped: restart from OCI Console
3. If unresponsive: reboot from OCI Console (hard reset)
4. Branch servers continue operating locally — sync resumes when cloud returns
5. **No branch is affected operationally** — they have their own local database

### Branch Server Down
1. Data is safe in the cloud (last sync)
2. Restore from Veeam backup (local NAS) or rebuild and re-sync from cloud
3. Other branches are unaffected (they sync to cloud, not to this branch)

### Suspected Ransomware (Branch)
1. **ISOLATE** — pull Ethernet cable
2. **DO NOT reboot** — preserves evidence
3. Other branches and cloud server are safe (no inter-branch connectivity)
4. Restore from Veeam backup or re-sync from cloud
5. Investigate and harden
