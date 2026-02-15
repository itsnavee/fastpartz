# FastPartz — Cloudflare Zero Trust Mesh Solution (v4)

**Version:** 4.0
**Date:** February 2026
**Scope:** 4 branches (UAE) + remote users
**Approach:** Cloudflare Zero Trust — cloudflared tunnels, browser-based RDP, zero hardware, zero cost

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [How It Works](#2-how-it-works)
3. [Architecture Overview](#3-architecture-overview)
4. [Solution Components](#4-solution-components)
5. [Branch-to-Branch SQL Sync](#5-branch-to-branch-sql-sync)
6. [Remote User Access (Browser-Based RDP)](#6-remote-user-access-browser-based-rdp)
7. [Identity & Access Control](#7-identity--access-control)
8. [Branch Network Setup](#8-branch-network-setup)
9. [Security Features](#9-security-features)
10. [Network Segmentation (VLANs)](#10-network-segmentation-vlans)
11. [Backup Strategy (3-2-1)](#11-backup-strategy-3-2-1)
12. [Windows Server Hardening](#12-windows-server-hardening)
13. [Ransomware Risk Assessment](#13-ransomware-risk-assessment)
14. [Cost Summary](#14-cost-summary)
15. [Implementation Phases](#15-implementation-phases)
16. [Open Questions](#16-open-questions)

---

## 1. Executive Summary

### The Problem

FastPartz operates 4 branches across the UAE with Windows Servers running accounting software (MS SQL Server). Servers are exposed to the internet with RDP and SQL open, no firewalls, no backups, no segmentation.

### What This Solution Delivers

Instead of building VPN tunnels or renting cloud servers, this solution uses **Cloudflare Zero Trust** — a free service that creates encrypted connections between all branches through Cloudflare's global network. A tiny software agent (`cloudflared`) installed on each Windows Server creates outbound tunnels. No inbound ports are opened. No VPN protocols are used.

- **Zero inbound ports** on every branch
- **Zero hardware** beyond basic firewall — runs on existing Windows Servers
- **Zero cost** — Cloudflare Zero Trust is free for up to 50 users
- **No VPN protocols** — uses HTTP/2 and QUIC (looks like normal HTTPS to ISPs)
- **Browser-based RDP** — remote users access servers through a web browser with MFA
- **Granular access policies** — "Branch A can only talk to Branch B on SQL port 1433"
- **Managed from a single cloud dashboard** — Cloudflare Zero Trust dashboard

### The Key Insight

Cloudflare Tunnel (`cloudflared`) does **not** use WireGuard. It uses HTTP/2 or QUIC — the same protocols used for web browsing. To the ISP, this traffic is indistinguishable from regular HTTPS browsing. No VPN signatures, no blocked protocols, fully compliant with UAE regulations.

---

## 2. How It Works

### Technical Flow

```
Step 1: Install cloudflared on each Windows Server
Step 2: Each server creates an outbound tunnel to Cloudflare's edge
Step 3: Cloudflare routes traffic between tunnels (encrypted end-to-end)
Step 4: Branch A's SQL Server can reach Branch B's SQL Server through Cloudflare
Step 5: Remote users open a browser, authenticate with MFA, get RDP access
```

### Protocol Stack

| Layer | Protocol | Visible to ISP? |
|-------|----------|-----------------|
| Application | SQL (TCP 1433), RDP (TCP 3389) | No — encapsulated |
| Tunnel | cloudflared (HTTP/2 or QUIC) | Looks like HTTPS traffic |
| Transport | TLS 1.3 | Standard encrypted web |
| Network | TCP/UDP to Cloudflare edge | Normal web browsing pattern |

**No VPN signatures. No IPsec. No WireGuard. Just HTTPS.**

---

## 3. Architecture Overview

```
              ┌──────────────────────────────┐
              │    Cloudflare Global Network  │
              │    (Zero Trust Gateway)       │
              │                              │
              │  - Routes traffic between     │
              │    branch tunnels             │
              │  - Enforces access policies   │
              │  - Provides browser-based RDP │
              │  - DNS filtering              │
              │  - MFA authentication         │
              └──────────┬───────────────────┘
                         │
            All tunnels OUTBOUND (HTTP/2 / QUIC)
            (Looks like normal HTTPS browsing)
                         │
        ┌────────┬───────┼───────┬─────────┐
        │        │       │       │         │
     Branch 1  Branch 2 Branch 3 Branch 4  Remote
     cloudflared cloudflared cloudflared cloudflared  Users
     (tunnel↑)  (tunnel↑)  (tunnel↑)  (tunnel↑)   (browser)
```

### What Cloudflare Replaces

| Traditional Component | Cloudflare Equivalent | Cost |
|---|---|---|
| IPsec tunnels (6) | Cloudflare Tunnel mesh (automatic) | Free |
| VPN server (IKEv2/WireGuard) | Browser-based RDP via Cloudflare Access | Free |
| IDS/IPS (Suricata) | Cloudflare Gateway DNS filtering | Free |
| DNS filtering (Unbound DNSBL) | Cloudflare Gateway DNS policies | Free |
| Dynamic DNS (Dynu) | Not needed — tunnels are outbound | Free |
| Certificate Authority | Not needed — Cloudflare manages certs | Free |
| Central management dashboard | Cloudflare Zero Trust dashboard | Free |

---

## 4. Solution Components

### Software Components

| Component | Protocol | Function | Installed On |
|---|---|---|---|
| **cloudflared** | HTTP/2 / QUIC | Creates encrypted tunnel from each server to Cloudflare edge. Enables branch-to-branch SQL sync and private networking. | Each Windows Server (lightweight service, ~30MB) |
| **Cloudflare Access** | HTTPS | Provides browser-based RDP. Users authenticate via MFA in their browser, then get a rendered RDP session. No client software. | Cloudflare edge (cloud service) |
| **Cloudflare Gateway** | DNS | Filters DNS queries to block malware, phishing, C2 domains. Replaces on-device DNS filtering. | Cloud — point branch DNS to Cloudflare |
| **Identity Provider** | OIDC/SAML | Microsoft 365 or Google Workspace for user authentication + MFA. | Cloud (existing email provider) |

### Hardware Components

| Item | Purpose | Cost |
|---|---|---|
| N100 Mini-PC + OPNsense (per branch) | Firewall, VLAN routing, DHCP — blocks all inbound, segments network | $150-200 |
| Managed Switch (per branch) | VLAN segmentation | $200-300 |
| **Optional:** GL.iNet Brume 2 (per branch) | Run cloudflared on a separate device instead of the Windows Server | $80 |

**Note on GL.iNet Brume 2:** This is optional. cloudflared runs perfectly fine as a Windows service on the existing servers. The Brume 2 option is for those who prefer keeping tunnel software off the production server.

---

## 5. Branch-to-Branch SQL Sync

### How SQL Traffic Flows Through Cloudflare

```
Branch 1 SQL Server                    Branch 2 SQL Server
      │                                       │
      ▼                                       ▼
 cloudflared                              cloudflared
 (local agent)                           (local agent)
      │                                       │
      ▼ (outbound HTTP/2)                     ▼ (outbound HTTP/2)
      │                                       │
      └────────► Cloudflare Edge ◄────────────┘
                 (routes traffic)
```

### Configuration

Each `cloudflared` instance is configured with a **private network route**. This tells Cloudflare which IP ranges are reachable through each tunnel:

| Tunnel | Server | Private Network | Advertised Routes |
|--------|--------|----------------|-------------------|
| tunnel-branch1 | Branch 1 Windows Server | 10.1.10.0/24 | Server VLAN |
| tunnel-branch2 | Branch 2 Windows Server | 10.2.10.0/24 | Server VLAN |
| tunnel-branch3 | Branch 3 Windows Server | 10.3.10.0/24 | Server VLAN |
| tunnel-branch4 | Branch 4 Windows Server | 10.4.10.0/24 | Server VLAN |

With these routes, Branch 1's SQL Server can reach `10.2.10.10:1433` (Branch 2's SQL) through Cloudflare — without any inbound ports, without any VPN, without any public IP exposure.

### Access Policies (Granular Control)

In the Cloudflare Zero Trust dashboard, define what traffic is allowed:

| Policy | Source | Destination | Port | Action |
|--------|--------|-------------|------|--------|
| SQL Sync | Branch 1 Server | Branch 2, 3, 4 Servers | TCP 1433 | Allow |
| SQL Sync | Branch 2 Server | Branch 1, 3, 4 Servers | TCP 1433 | Allow |
| SQL Sync | Branch 3 Server | Branch 1, 2, 4 Servers | TCP 1433 | Allow |
| SQL Sync | Branch 4 Server | Branch 1, 2, 3 Servers | TCP 1433 | Allow |
| **Everything else** | Any | Any | Any | **Deny** |

**This is zero-trust networking:** only explicitly allowed traffic flows. A compromised server cannot port-scan or laterally move to other branches because Cloudflare enforces the policy at the network level.

---

## 6. Remote User Access (Browser-Based RDP)

### How It Works

Remote users access branch servers through their **web browser**. No VPN client, no RDP client — just a browser.

```
Remote User's Browser
        │
        ▼ (HTTPS)
   ┌─────────────────┐
   │ Cloudflare Access│
   │                  │
   │ 1. User goes to  │
   │    rdp.fastpartz │
   │    .com          │
   │                  │
   │ 2. Authenticates │
   │    via M365/Google│
   │    + MFA          │
   │                  │
   │ 3. Selects server │
   │                  │
   │ 4. Browser renders│
   │    RDP session    │
   └────────┬─────────┘
            │ (through cloudflared tunnel)
            ▼
     Branch Windows Server
```

### User Experience

1. Open browser, navigate to `https://rdp.fastpartz.com`
2. Log in with company email (Microsoft 365 or Google Workspace)
3. Enter MFA code (authenticator app or SMS)
4. Select which server to connect to
5. Browser renders an RDP session — full Windows desktop in the browser
6. Close the tab when done

**No software to install. No VPN to configure. Works from any device with a browser.**

### Access Policies

| User Group | Can Access | Authentication |
|---|---|---|
| Branch managers | Their own branch server | Email + MFA |
| Accountants | Accounting server (specific branch) | Email + MFA |
| IT admin (you) | All servers | Email + MFA + device posture check |
| Vendor/support | Specific server, time-limited | Email + MFA, expires after X hours |

---

## 7. Identity & Access Control

### Authentication Flow

```
User → Cloudflare Access → Identity Provider (M365/Google) → MFA → Access Granted
```

### Supported Identity Providers (Free)

| Provider | MFA Method | Setup Effort |
|---|---|---|
| **Microsoft 365** | Authenticator app, SMS, phone call | Configure OIDC in Cloudflare dashboard |
| **Google Workspace** | Google Authenticator, phone prompt | Configure OIDC in Cloudflare dashboard |
| **One-time PIN (email)** | Email OTP — no IdP needed | Built into Cloudflare Access (default) |

If FastPartz doesn't have M365 or Google Workspace, Cloudflare Access can send a one-time PIN to any email address. This is the simplest option — zero setup beyond adding email addresses.

### Device Posture (Optional Enhancement)

Cloudflare can check the user's device before granting access:

- Is antivirus running?
- Is the OS up to date?
- Is disk encryption enabled?
- Is the device managed by the company?

This is optional but adds another security layer.

---

## 8. Branch Network Setup

Each branch still gets a firewall and VLANs for internal segmentation. The only change from the OPNsense solution is: **no IPsec tunnels and no VPN server**.

### Per-Branch Topology

```
                          INTERNET
                             |
                    [Broadband Router]
                             |
                    ┌────────────────┐
                    │   OPNsense     │
                    │  (N100 Mini-PC)│
                    │                │
                    │  - Firewall    │
                    │  - DHCP        │
                    │  - VLAN routing│
                    │                │
                    │  NO tunnels    │
                    │  NO VPN server │
                    │  NO DNS filter │
                    │  (Cloudflare   │
                    │   handles DNS) │
                    └──────┬─────────┘
                       LAN port (Trunk)
                           │
                    ┌──────┴─────────┐
                    │ Managed Switch  │
                    │                │
                    │ VLAN 10: Servers│  ← cloudflared runs here
                    │ VLAN 20: Wkstns│
                    │ VLAN 30: Mgmt  │
                    │ VLAN 99: Guest │
                    └────────────────┘
```

### Firewall Rules (Simplest of All Solutions)

**WAN Inbound:**
```
DENY ALL (zero exceptions)
```

**Server VLAN Outbound:**
```
ALLOW  TCP/UDP  Servers → Cloudflare IPs   443,7844  (cloudflared tunnel)
ALLOW  TCP      Servers → Internet         80,443    (Windows Update, AV)
DENY   ALL      (everything else)
```

**Workstation VLAN:**
```
ALLOW  TCP  Workstations → Servers  1433,445  (SQL, file shares)
ALLOW  TCP  Workstations → Internet 80,443    (web browsing, DNS via Cloudflare)
DENY   ALL  (everything else)
```

**DNS for all VLANs:** Point to Cloudflare Gateway resolvers (managed in Cloudflare dashboard).

---

## 9. Security Features

| Feature | How It's Delivered | Benefit |
|---|---|---|
| **Zero inbound ports** | OPNsense blocks all inbound. cloudflared only makes outbound connections. | No attack surface on any branch |
| **Zero-trust access** | Cloudflare evaluates every connection against policies. Only explicitly allowed traffic flows. | No implicit trust between branches |
| **DNS filtering** | Cloudflare Gateway blocks malware, phishing, C2, DGA domains | Threat blocking before DNS resolution |
| **MFA on all remote access** | Cloudflare Access requires identity provider + MFA | Stolen passwords are useless without MFA |
| **Browser-based RDP** | No RDP port exposed anywhere. RDP rendered in browser through Cloudflare. | RDP brute-force is impossible |
| **Encrypted transport** | All traffic TLS 1.3 via Cloudflare edge | End-to-end encryption |
| **Granular policies** | "Branch A can talk to Branch B on port 1433 only" | Limits lateral movement to exactly zero unauthorized paths |
| **Session logging** | Every access attempt logged in Cloudflare dashboard | Full audit trail |
| **VLAN segmentation** | Managed switches at each branch | Internal network isolation |
| **Endpoint AV** | Windows Defender + ESET PROTECT | Multi-layer malware defense |
| **Server hardening** | Same as all solutions: disable SMBv1, enable ASR, AppLocker | Reduced attack surface |
| **Backup with immutability** | Local NAS + Backblaze B2 with Object Lock | Recovery capability |

### Unique Security Advantages

| Advantage | Why It Matters |
|---|---|
| **No VPN protocols** | VPN traffic (IPsec, WireGuard) can be detected and blocked by ISPs. Cloudflare tunnels use HTTPS — unblockable. |
| **No tunnel endpoints** | IPsec VPN endpoints are attackable (CVEs exist for IKE implementations). cloudflared has no listening port. |
| **Per-request authentication** | Every access request is authenticated. Traditional VPN: authenticate once, then full network access. |
| **Invisible to network scanners** | Port scans show zero open ports. The servers are completely invisible from the internet. |

---

## 10. Network Segmentation (VLANs)

Same as all solutions:

| VLAN | Name | Devices | Rules |
|------|------|---------|-------|
| 10 | Servers | Windows Servers (+ cloudflared) | Inter-branch via Cloudflare tunnel. Workstations: SQL + SMB only. |
| 20 | Workstations | User PCs | Reach servers on SQL/SMB. Internet via Cloudflare DNS. |
| 30 | Management | OPNsense, switch | IT only |
| 99 | Guest/IoT | WiFi, printers, cameras | Internet only, fully isolated |

---

## 11. Backup Strategy (3-2-1)

| Copy | Location | Method | Schedule | Immutability |
|------|----------|--------|----------|-------------|
| **1 — Local NAS** | Synology NAS (master branch) | Veeam CE | Daily + weekly | NAS snapshots |
| **2 — Cross-branch** | Partner branch via Cloudflare tunnel | rsync (through cloudflared) | Daily | NAS snapshots |
| **3 — Cloud** | Backblaze B2 | Restic with AES-256 | Weekly + daily | Object Lock (30-day) |

**Note:** Cross-branch backup replication (Copy 2) flows through Cloudflare tunnels — same path as SQL sync. No separate backup network needed.

---

## 12. Windows Server Hardening

Identical to all solutions. Applied to every branch server:

- Windows Defender + Tamper Protection + ASR rules
- ESET PROTECT enterprise AV (~$40/server/year)
- Windows Firewall (default-deny inbound)
- Disable SMBv1, NetBIOS, LLMNR, PowerShell v2
- Account lockout, strong passwords, separate admin accounts
- AppLocker, automatic patching, audit logging
- SQL Server bound to VLAN 10 IP only

---

## 13. Ransomware Risk Assessment

| # | Attack Vector | Current Risk | Mitigation | After |
|---|---|---|---|---|
| 1 | **RDP Brute Force** | CRITICAL | No RDP exposed anywhere. Browser-based RDP via Cloudflare with MFA. | **ELIMINATED** |
| 2 | **SQL Exploitation** | CRITICAL | No SQL port exposed. Branch-to-branch SQL through Cloudflare with access policies. | **ELIMINATED** |
| 3 | **Phishing / Email** | HIGH | Cloudflare Gateway DNS + SPF/DKIM/DMARC + training | MEDIUM |
| 4 | **Lateral Movement** | CRITICAL | Zero-trust policies: only SQL (1433) between specific servers. Everything else denied. | **ELIMINATED** |
| 5 | **Credential Theft** | HIGH | MFA required for all remote access. Per-request authentication. | LOW |
| 6 | **Backup Destruction** | CRITICAL | 3-2-1 backup + B2 Object Lock | LOW |
| 7 | **VPN Exploitation** | MEDIUM | No VPN protocols used. No tunnel endpoints to attack. | **ELIMINATED** |
| 8 | **Unpatched Vulnerabilities** | HIGH | Automatic Windows Update | LOW |

---

## 14. Cost Summary

### Hardware (One-Time)

| Item | Per Branch | 4 Branches |
|------|-----------|-----------|
| N100 Mini-PC (OPNsense) | $150-200 | $600-800 |
| Managed Switch | $200-300 | $800-1,200 |
| Cabling | $30-50 | $120-200 |
| **Subtotal** | **$380-550** | **$1,520-2,200** |
| Optional: GL.iNet Brume 2 (run cloudflared off-server) | $80 | $320 |
| Optional: Backup NAS (master branch) | — | $400-500 |

### Software & Services (Recurring)

| Item | Monthly | Annual |
|------|---------|--------|
| Cloudflare Zero Trust (50 users) | **$0** | **$0** |
| Cloudflare Gateway DNS filtering | **$0** | **$0** |
| cloudflared agent | **$0** | **$0** |
| ESET PROTECT (4 servers) | $13 | $160 |
| Backblaze B2 (1TB estimated) | $5 | $60 |
| **Total recurring** | **$18** | **$220** |

### Grand Total — Year 1

| Scenario | Hardware | Recurring | Year 1 Total |
|----------|---------|-----------|-------------|
| **Minimum (no NAS, no Brume)** | $1,520-2,200 | $220 | **$1,740-2,420** |
| **With Brume 2 gateways** | $1,840-2,520 | $220 | **$2,060-2,740** |
| **Full (+ NAS + B2)** | $1,920-2,700 | $220 | **$2,140-2,920** |

**This is the cheapest solution by a significant margin** — essentially just hardware + antivirus.

---

## 15. Implementation Phases

| Phase | Scope | Duration | Deliverable |
|-------|-------|----------|-------------|
| **1** | Set up Cloudflare Zero Trust account. Configure identity provider (M365/Google/email OTP). Create tunnel tokens for each branch. | 3 days | Cloudflare Zero Trust ready |
| **2** | Branch 1 (master) pilot — install cloudflared, configure tunnel, verify SQL accessibility through Cloudflare | 1 week | Branch 1 tunnel live |
| **3** | Deploy N100 + OPNsense + managed switch at Branch 1. VLANs, firewall (block all inbound), DNS via Cloudflare Gateway. | 1 week | Branch 1 fully segmented and protected |
| **4** | Deploy cloudflared + OPNsense + switch at branches 2-4. Configure access policies for SQL sync. | 1 week | All branches connected via Cloudflare mesh |
| **5** | Set up browser-based RDP for remote users. Configure access policies per user group. Test MFA flow. | 3 days | Remote access working |
| **6** | Windows hardening + AV + backup setup (all servers) | 1 week | All servers hardened. Backups running. |
| **7** | Testing, monitoring (Uptime Kuma), documentation, training | 1 week | All tests passed. Runbooks delivered. |

**Total: ~5.5 weeks** (slightly faster than other solutions due to no tunnel/VPN configuration)

---

## 16. Open Questions

| # | Question | Impact |
|---|----------|--------|
| 1 | Does the accounting software support SQL sync over the network routes that Cloudflare provides? (Should work — it's standard TCP, but needs testing) | Core feasibility |
| 2 | Does FastPartz use Microsoft 365 or Google Workspace? | Determines identity provider for MFA |
| 3 | If neither: is email-based OTP sufficient for remote access? | Fallback authentication method |
| 4 | How latency-sensitive is the SQL sync? (Cloudflare adds ~5-20ms) | Determines if real-time queries are viable |
| 5 | Are branch users comfortable with browser-based RDP for remote access? | User acceptance |
| 6 | Total database size across branches? | Validates Cloudflare tunnel bandwidth is sufficient |
| 7 | What email provider? | SPF/DKIM/DMARC setup |
| 8 | Which branch is the master? | Determines sync topology |
| 9 | Broadband speed at each branch? | Validates sync feasibility |
| 10 | Printers, cameras, IoT devices? | VLAN 99 scope |

---

## Appendix: Quick Start — Installing cloudflared on Branch 1

### Step 1: Download and Install

```powershell
# On the Windows Server, open PowerShell as Administrator
# Download cloudflared
Invoke-WebRequest -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.msi" -OutFile "$env:TEMP\cloudflared.msi"

# Install
Start-Process msiexec.exe -ArgumentList "/i $env:TEMP\cloudflared.msi /quiet" -Wait
```

### Step 2: Authenticate

```powershell
cloudflared tunnel login
# Opens browser — log in with your Cloudflare account
```

### Step 3: Create Tunnel

```powershell
cloudflared tunnel create branch1
# Outputs a tunnel ID and credentials file
```

### Step 4: Configure

Create `C:\Users\<user>\.cloudflared\config.yml`:

```yaml
tunnel: <tunnel-id>
credentials-file: C:\Users\<user>\.cloudflared\<tunnel-id>.json

ingress:
  - hostname: branch1-sql.fastpartz.com
    service: tcp://localhost:1433
  - hostname: branch1-rdp.fastpartz.com
    service: rdp://localhost:3389
  - service: http_status:404
```

### Step 5: Install as Windows Service

```powershell
cloudflared service install
# Starts automatically on boot
```

### Step 6: Configure Private Network

```powershell
cloudflared tunnel route ip add 10.1.10.0/24 branch1
```

That's it. Branch 1 is now accessible through Cloudflare's network. Repeat for branches 2-4 with their respective tunnel names and IP ranges.

---

## Appendix: Emergency Procedures

### cloudflared Service Down on a Branch
1. Branch loses inter-branch connectivity and remote access
2. **Local operations continue** — users on-site can still access their local server
3. Fix: restart the service: `Restart-Service cloudflared`
4. If persistent: check Windows Event Log for cloudflared errors

### Cloudflare Service Outage
1. All inter-branch connectivity drops simultaneously
2. **Local operations continue** — each branch has its own local database
3. Wait for Cloudflare to recover (99.99% SLA)
4. SQL sync resumes automatically when connectivity returns

### Suspected Ransomware
1. **ISOLATE** — pull Ethernet cable from affected server
2. **Revoke access** — disable the branch tunnel in Cloudflare dashboard (instant, from anywhere)
3. Other branches are safe — Cloudflare policies prevent lateral spread
4. Restore from backup
5. Investigate and harden
