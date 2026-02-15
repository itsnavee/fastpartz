# FastPartz Security & SD-WAN Solution

## Architecture & Implementation Guide

**Version:** 1.0
**Date:** February 2026
**Scope:** 4 branches (UAE) + 1 offsite (Pakistan)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Hardware Bill of Materials](#2-hardware-bill-of-materials)
3. [Network Architecture](#3-network-architecture)
4. [IP Addressing & VLAN Scheme](#4-ip-addressing--vlan-scheme)
5. [IPsec Full-Mesh Design](#5-ipsec-full-mesh-design)
6. [Dynamic DNS Strategy](#6-dynamic-dns-strategy)
7. [OPNsense Configuration Per Edge](#7-opnsense-configuration-per-edge)
8. [Windows Server Hardening Checklist](#8-windows-server-hardening-checklist)
9. [Backup Strategy (3-2-1)](#9-backup-strategy-3-2-1)
10. [Remote User Access](#10-remote-user-access)
11. [Ransomware Attack Surface Analysis & Mitigations](#11-ransomware-attack-surface-analysis--mitigations)
12. [Monitoring & Alerting](#12-monitoring--alerting)
13. [Container vs Bare-Metal Discussion](#13-container-vs-bare-metal-discussion)
14. [Implementation Phases](#14-implementation-phases)
15. [Verification & Testing](#15-verification--testing)

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

This is not a theoretical risk. This is a **ransomware attack waiting to happen**. Exposed RDP is the #1 initial access vector for ransomware gangs (Conti, LockBit, BlackCat, Akira). Exposed SQL ports enable direct data exfiltration and destruction. The absence of backups means any attack is a business-ending event.

### The Solution

We will deploy a **complete, layered security architecture** using primarily open-source software on commodity hardware:

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Perimeter | OPNsense on multi-NIC mini-PC | Firewall, IDS/IPS, DNS filtering, VPN |
| Transport | IKEv2 IPsec full-mesh | Encrypted inter-branch communication |
| Segmentation | VLANs + managed switches | Isolate servers, workstations, guests |
| Endpoint | Windows Defender + Enterprise AV | Malware detection and prevention |
| Hardening | Windows Server lockdown | Reduce attack surface to near-zero |
| Backup | Veeam + NAS + offsite | 3-2-1 backup with immutable copies |
| Access | IKEv2 roadwarrior VPN | Secure remote access with MFA |
| Monitoring | Suricata + syslog + alerting | Threat detection and visibility |

**Result:** Zero public-facing ports. Encrypted inter-branch traffic. Segmented networks. Hardened endpoints. Immutable backups. Full visibility. A posture that would withstand a targeted ransomware attack.

### Cost Estimate (Per Branch)

| Item | Approx. Cost (USD) |
|------|-------------------|
| SD-WAN edge (N100 mini-PC) | $150–200 |
| Managed switch (TP-Link SG2428P) | $200–300 |
| NAS (Synology DS223 + 2x 4TB) | $350–450 |
| Cabling / misc | $50 |
| **Per-branch total** | **$750–1,000** |
| **4-branch total** | **$3,000–4,000** |
| Pakistan offsite (RPi 5 + HDD) | $150–200 |
| **Grand total (hardware)** | **~$3,500–4,500** |

All software is open-source or free-tier. No recurring license costs for core infrastructure.

---

## 2. Hardware Bill of Materials

### Per Branch

#### SD-WAN Edge Device (Gateway/Firewall)

**Primary Recommendation: Topton/CWWK N100 4x 2.5GbE Mini-PC (~$150–200)**

- Intel N100 processor (4 cores, 3.4GHz burst)
- 4x Intel i226-V 2.5GbE NICs
- 8GB DDR5, 128GB NVMe SSD
- Fanless, <15W TDP
- AES-NI for hardware-accelerated IPsec

Why 4 NICs:
- **Port 1 (WAN):** Connected to broadband router
- **Port 2 (LAN/Trunk):** Connected to managed switch (VLAN trunk)
- **Port 3 (OPT1):** Dedicated management or secondary WAN (future)
- **Port 4 (OPT2):** Out-of-band management or DMZ (future)

**Alternative: Protectli Vault FW4C (~$350–400)**

- Intel Celeron J3710
- 4x Intel i211 GbE NICs
- Purpose-built for pfSense/OPNsense
- Higher cost but better vendor support, coreboot firmware

**Why NOT the Beelink SER8:**

The SER8 has only 1 NIC. A router/firewall requires at minimum 2 NICs (WAN + LAN). While you could use USB-to-Ethernet adapters or a single-NIC-with-VLANs (router-on-a-stick) setup, this is fragile, poorly supported, and defeats the purpose. The N100 4-NIC mini-PCs are purpose-built for this role at half the price.

#### Managed Switch

**Recommendation: TP-Link TL-SG2428P (24-port L2+ PoE+)**

- 24x GbE PoE+ ports (250W budget)
- 4x SFP slots
- Full VLAN (802.1Q) support
- LACP, IGMP snooping, QoS
- Web management GUI + CLI

For smaller branches: **TP-Link TL-SG2210P** (8-port PoE, L2+)

#### Local Backup NAS

**Recommendation: Synology DS223 (2-bay)**

- ARM Realtek RTD1619B
- 2GB RAM
- 2x 3.5" SATA bays (RAID 1 for redundancy)
- Supports: rsync, Hyper Backup, SMB, NFS, iSCSI
- Populate with: 2x WD Red Plus 4TB (~$100 each)

Alternative: **TerraMaster F2-223** (Intel N4505, 2-bay) — slightly more powerful, good for encryption workloads.

#### Pakistan Offsite Backup Receiver

**Recommendation: Raspberry Pi 5 (8GB) + External HDD**

- Raspberry Pi 5, 8GB RAM (~$80)
- Official Pi 5 active cooler (~$5)
- 128GB microSD for OS (~$15)
- WD Elements 8TB external USB HDD (~$150)
- Argon ONE Pi 5 case (~$25)

The Pi runs a minimal Debian/Ubuntu Server with:
- WireGuard or IPsec tunnel back to one UAE branch
- Borgbackup server receiving encrypted incremental backups
- Runs headless at a trusted location (family home, small office)

Alternative for larger scale: **Synology DS223** at Pakistan site (same as branches, more robust).

### Summary BOM — All Branches

| Item | Qty | Unit Cost | Total |
|------|-----|-----------|-------|
| Topton N100 4x2.5GbE mini-PC | 4 | $175 | $700 |
| TP-Link TL-SG2428P switch | 4 | $250 | $1,000 |
| Synology DS223 NAS | 4 | $200 | $800 |
| WD Red Plus 4TB | 8 | $100 | $800 |
| Raspberry Pi 5 kit (Pakistan) | 1 | $125 | $125 |
| WD Elements 8TB ext HDD | 1 | $150 | $150 |
| Cat6 patch cables, misc | 4 | $30 | $120 |
| **Grand Total** | | | **$3,695** |

---

## 3. Network Architecture

### Per-Branch Topology

```
                          INTERNET
                             |
                    [Broadband Router]
                     (Bridge Mode/DMZ)
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
                           │ 802.1Q Trunk
                           │ (All VLANs tagged)
                           │
                    ┌──────┴─────────┐
                    │ Managed Switch  │
                    │ (TL-SG2428P)   │
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
         VLAN 10    VLAN 20  VLAN 10  VLAN 99
```

### Traffic Flow Design (Hybrid Routing)

**All traffic flows through OPNsense.** This is the critical design decision. OPNsense is the **default gateway** for every device on every VLAN.

| Traffic Type | Path | Why |
|-------------|------|-----|
| Server ↔ Server (inter-branch) | OPNsense → IPsec tunnel → remote OPNsense | Encrypted, inspected |
| Server ↔ Server (same branch) | Switch (local VLAN) | Never leaves the VLAN |
| Workstation → Internet | OPNsense → WAN → ISP | IDS/IPS + DNS filtering applied |
| Workstation ↔ Server (same branch) | OPNsense (inter-VLAN routing) | Firewall rules enforced |
| Remote user → Server | IKEv2 VPN → OPNsense → Server VLAN | Encrypted + authenticated |

**Why route everything through OPNsense:**

- Suricata IDS/IPS inspects all traffic (browsing, downloads, C2 callbacks)
- DNS blocklists catch phishing/malware domains before connection
- Full traffic visibility and logging
- Single point of policy enforcement
- The N100 handles gigabit NAT + Suricata with ease (~800 Mbps throughput with IDS on)

### Bypass Procedure (Emergency Only)

If OPNsense ever becomes a performance bottleneck for user PC internet browsing (unlikely with N100):

1. On user PCs, change default gateway from OPNsense IP to broadband router IP
2. User PC internet traffic now goes directly through broadband router
3. Server traffic and inter-branch traffic still flows through OPNsense (servers' gateway is always OPNsense)
4. **Trade-off:** User PCs lose IDS/IPS and DNS filtering protection

**This bypass should rarely be needed.** The N100 with AES-NI handles:
- Gigabit NAT: ~940 Mbps
- NAT + Suricata (ET Open rules): ~800 Mbps
- IPsec AES-256-GCM: ~700 Mbps

### Full-Mesh Inter-Branch Topology

```
        Branch 1 (HQ)
       /    |     \
      /     |      \
Branch 2  Branch 3  Branch 4
      \     |      /
       \    |     /
        Branch 2--Branch 3
        Branch 2--Branch 4
        Branch 3--Branch 4
```

**6 IPsec tunnels** for full mesh (n*(n-1)/2 = 4*3/2 = 6):

| Tunnel | Endpoint A | Endpoint B |
|--------|-----------|-----------|
| 1 | Branch 1 | Branch 2 |
| 2 | Branch 1 | Branch 3 |
| 3 | Branch 1 | Branch 4 |
| 4 | Branch 2 | Branch 3 |
| 5 | Branch 2 | Branch 4 |
| 6 | Branch 3 | Branch 4 |

---

## 4. IP Addressing & VLAN Scheme

### Addressing Convention

Pattern: `10.<branch>.<vlan>.0/24`

| Branch | VLAN 10 (Servers) | VLAN 20 (Workstations) | VLAN 30 (Mgmt) | VLAN 99 (Guest/IoT) |
|--------|------------------|----------------------|----------------|---------------------|
| Branch 1 | 10.1.10.0/24 | 10.1.20.0/24 | 10.1.30.0/24 | 10.1.99.0/24 |
| Branch 2 | 10.2.10.0/24 | 10.2.20.0/24 | 10.2.30.0/24 | 10.2.99.0/24 |
| Branch 3 | 10.3.10.0/24 | 10.3.20.0/24 | 10.3.30.0/24 | 10.3.99.0/24 |
| Branch 4 | 10.4.10.0/24 | 10.4.20.0/24 | 10.4.30.0/24 | 10.4.99.0/24 |

### Gateway Assignments (OPNsense Interface IPs)

OPNsense at each branch is `.1` on every VLAN:

| Branch | VLAN 10 GW | VLAN 20 GW | VLAN 30 GW | VLAN 99 GW |
|--------|-----------|-----------|-----------|-----------|
| Branch 1 | 10.1.10.1 | 10.1.20.1 | 10.1.30.1 | 10.1.99.1 |
| Branch 2 | 10.2.10.1 | 10.2.20.1 | 10.2.30.1 | 10.2.99.1 |
| Branch 3 | 10.3.10.1 | 10.3.20.1 | 10.3.30.1 | 10.3.99.1 |
| Branch 4 | 10.4.10.1 | 10.4.20.1 | 10.4.30.1 | 10.4.99.1 |

### WAN Addressing

OPNsense WAN interfaces get IPs from the broadband router via DHCP (or static if ISP provides one). This varies per branch and ISP.

### VLAN Details

| VLAN ID | Name | Purpose | DHCP Range | Static Assignments |
|---------|------|---------|------------|-------------------|
| 10 | Servers | Windows Servers, NAS, SQL | None (all static) | .10-.50 |
| 20 | Workstations | User PCs, laptops | .100-.200 | None |
| 30 | Management | OPNsense WebGUI, switch mgmt, IPMI | .10-.50 | .1 = OPNsense |
| 99 | Guest/IoT | Guest WiFi, printers, IoT | .100-.200 | Printers: .10-.30 |

### Server Static IP Assignments (Example — Branch 1)

| Device | IP | VLAN |
|--------|-----|------|
| Windows Server 1 (Accounting) | 10.1.10.10 | 10 |
| Windows Server 2 (if applicable) | 10.1.10.11 | 10 |
| Synology NAS | 10.1.10.20 | 10 |
| Managed Switch | 10.1.30.10 | 30 |
| OPNsense (Mgmt) | 10.1.30.1 | 30 |

### Inter-VLAN Firewall Rules

**Default policy: DENY all inter-VLAN traffic.** Then add explicit allows:

| Source | Destination | Ports | Action | Purpose |
|--------|------------|-------|--------|---------|
| VLAN 20 (Workstations) | VLAN 10 (Servers) | TCP 1433 (SQL) | ALLOW | Accounting software |
| VLAN 20 (Workstations) | VLAN 10 (Servers) | TCP 445 (SMB) | ALLOW | File shares |
| VLAN 20 (Workstations) | VLAN 99 (Guest) | TCP 9100, 631 (Print) | ALLOW | Printing |
| VLAN 30 (Mgmt) | ALL VLANs | ALL | ALLOW | Management access |
| VLAN 99 (Guest) | ANY VLAN | ANY | **DENY** | Guest isolation |
| VLAN 99 (Guest) | Internet | TCP 80, 443 | ALLOW | Web only |
| ANY | VLAN 30 (Mgmt) | ANY | **DENY** | Protect management |

**Critical rule:** VLAN 99 (Guest/IoT) can NEVER reach VLAN 10 (Servers) or VLAN 30 (Management). This is enforced at OPNsense with explicit deny rules at the top of the Guest interface ruleset.

---

## 5. IPsec Full-Mesh Design

### Protocol Specifications

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| IKE Version | IKEv2 | Modern, supports FQDN peers, NAT-T, MOBIKE |
| Authentication | X.509 Certificates (Private CA) | Stronger than PSK, scalable |
| Phase 1 Encryption | AES-256-GCM | Authenticated encryption, hardware-accelerated |
| Phase 1 Integrity | SHA-384 | Implicit in GCM, explicit for non-GCM fallback |
| Phase 1 DH Group | Group 20 (384-bit ECDH / NIST P-384) | Strong, efficient on modern hardware |
| Phase 1 Lifetime | 28800 seconds (8 hours) | Standard, balances security with overhead |
| Phase 2 (ESP) Encryption | AES-256-GCM | Same as Phase 1 for consistency |
| Phase 2 PFS | Group 20 (384-bit ECDH) | Perfect Forward Secrecy on every rekey |
| Phase 2 Lifetime | 3600 seconds (1 hour) | Frequent rekey for PFS benefit |
| DPD | 10-second interval, 5 retries | Detect dead peer in ~60 seconds |
| NAT-T | Enabled (UDP 4500) | Handles ISP NAT transparently |

### Certificate Authority Setup

OPNsense includes a built-in CA manager (System > Trust > Authorities). Create a private CA hierarchy:

```
FastPartz Root CA (self-signed, 4096-bit RSA, 10-year validity)
├── Branch 1 Server Certificate (signed by Root CA, 2-year)
├── Branch 2 Server Certificate (signed by Root CA, 2-year)
├── Branch 3 Server Certificate (signed by Root CA, 2-year)
├── Branch 4 Server Certificate (signed by Root CA, 2-year)
└── VPN Roadwarrior Client CA (intermediate, signs user certs)
    ├── User: admin1 (1-year)
    ├── User: admin2 (1-year)
    └── ...
```

**Certificate setup on each OPNsense:**

1. **Create the Root CA** on Branch 1 OPNsense (System > Trust > Authorities > Add):
   - Method: Create an internal Certificate Authority
   - Key Type: RSA 4096
   - Digest: SHA384
   - Lifetime: 3650 days
   - CN: `FastPartz Root CA`

2. **Export the Root CA certificate** (public key only — NOT the private key)

3. **Import the Root CA** on Branch 2, 3, 4 OPNsense instances (System > Trust > Authorities > Add):
   - Method: Import an existing Certificate Authority
   - Paste the Root CA certificate (public key only)

4. **Create server certificates** on each branch's OPNsense (System > Trust > Certificates > Add):
   - Method: Create an internal Certificate (signed by FastPartz Root CA)
   - Key Type: ECDSA 384
   - CN: `branch1.fastpartz.dyn.example.com` (matching FQDN)
   - SAN: `DNS:branch1.fastpartz.dyn.example.com`
   - Lifetime: 730 days

   **Note:** Only Branch 1 (where the Root CA private key lives) can sign certificates. Generate CSRs on other branches, sign on Branch 1, and import back. Alternatively, generate all server certs on Branch 1 and distribute the PKCS#12 bundles.

### IPsec Tunnel Configuration (OPNsense)

**Per tunnel, configure under VPN > IPsec > Tunnel Settings:**

#### Phase 1 (IKE) — Example: Branch 1 ↔ Branch 2

```
Connection method:      Default (respond + initiate)
Key Exchange version:   IKEv2
Internet Protocol:      IPv4
Interface:              WAN
Remote gateway:         branch2.fastpartz.dynu.net  (FQDN!)
Description:            Branch1-to-Branch2

Authentication method:  Mutual Certificate
My Certificate:         branch1.fastpartz.dynu.net (server cert)
Remote Certificate:     branch2.fastpartz.dynu.net (imported peer cert)
My identifier:          Distinguished Name — from certificate
Peer identifier:        Distinguished Name — from certificate

Phase 1 proposal:
  Encryption:           AES-256-GCM (128-bit ICV)
  Hash:                 SHA384
  DH Group:             20 (NIST P-384)
  Lifetime:             28800

Dead Peer Detection:    Enabled
  Delay:                10 seconds
  Max failures:         5
```

#### Phase 2 (ESP) — Example: Branch 1 ↔ Branch 2

Create one Phase 2 entry **per subnet pair** that needs to communicate. For full branch-to-branch access:

```
Mode:                   Tunnel IPv4
Local Network:          10.1.0.0/16 (or individual /24 subnets)
Remote Network:         10.2.0.0/16
Description:            B1-Servers-to-B2-Servers

Protocol:               ESP
Encryption:             AES-256-GCM (128-bit ICV)
Hash:                   SHA384
PFS Key Group:          20 (NIST P-384)
Lifetime:               3600
```

**For granular control**, create separate Phase 2 entries per VLAN pair:

| Phase 2 Entry | Local Network | Remote Network | Purpose |
|---------------|--------------|----------------|---------|
| B1-B2-Servers | 10.1.10.0/24 | 10.2.10.0/24 | SQL sync between servers |
| B1-B2-Mgmt | 10.1.30.0/24 | 10.2.30.0/24 | Management access |

**Do NOT tunnel workstation-to-workstation** traffic between branches unless required. Keeping it to server-to-server and management reduces tunnel overhead.

### Full Mesh Configuration Matrix

Each OPNsense needs (n-1) = 3 Phase 1 tunnels configured:

| OPNsense | Phase 1 Peers | Phase 2 Entries |
|----------|--------------|-----------------|
| Branch 1 | B2, B3, B4 | 3 × (server + mgmt) = 6 |
| Branch 2 | B1, B3, B4 | 3 × (server + mgmt) = 6 |
| Branch 3 | B1, B2, B4 | 3 × (server + mgmt) = 6 |
| Branch 4 | B1, B2, B3 | 3 × (server + mgmt) = 6 |

### IPsec Firewall Rules

On each OPNsense, under Firewall > Rules > IPsec:

```
Action:  ALLOW
Source:  10.0.0.0/8 (all branch subnets)
Dest:    10.0.0.0/8 (all branch subnets)
Port:    TCP 1433 (SQL Server)
```

```
Action:  ALLOW
Source:  Management VLAN (any branch 10.x.30.0/24)
Dest:    Any branch subnet
Port:    ANY (management has full access)
```

```
Action:  DENY (default)
Source:  Any
Dest:    Any
Log:     Enabled
```

---

## 6. Dynamic DNS Strategy

### The Problem

UAE consumer/business broadband typically uses dynamic public IPs. IPsec tunnels need to find their peers. Without static IPs, we need Dynamic DNS (DDNS) so each branch has a stable FQDN that resolves to its current public IP.

### Solution: OPNsense Built-in DynDNS Client

OPNsense has native DynDNS support (Services > Dynamic DNS). It updates the DNS record whenever the WAN IP changes.

**Recommended DynDNS Providers (free tier):**

| Provider | Free Hostnames | Update Speed | Notes |
|----------|---------------|--------------|-------|
| **Dynu** (recommended) | 4 | Fast (<60s) | Reliable, well-supported in OPNsense |
| DuckDNS | 5 | Fast | Simple, community-run |
| Cloudflare | Unlimited (own domain) | Instant | Best if you own a domain |
| No-IP | 3 | Fast | Requires confirmation every 30 days (free) |

### DDNS Naming Convention

```
branch1.fastpartz.dynu.net
branch2.fastpartz.dynu.net
branch3.fastpartz.dynu.net
branch4.fastpartz.dynu.net
```

Or if using Cloudflare with a domain you own (e.g., `fastpartz.ae`):

```
edge1.fastpartz.ae
edge2.fastpartz.ae
edge3.fastpartz.ae
edge4.fastpartz.ae
```

### OPNsense DDNS Configuration

Under **Services > Dynamic DNS > Add**:

```
Service type:    Dynu (or Cloudflare)
Interface:       WAN
Username:        <Dynu API credentials>
Password:        <Dynu API key>
Hostname:        branch1.fastpartz.dynu.net
Check interval:  300 seconds (5 minutes)
Force update:    Enabled (every 24 hours regardless of change)
```

### How IPsec Works with Dynamic IPs

IKEv2 natively supports FQDN-based peer identification:

1. Branch 1 wants to initiate a tunnel to Branch 2
2. OPNsense resolves `branch2.fastpartz.dynu.net` → current public IP of Branch 2
3. IKEv2 handshake begins, peers authenticate via certificates (not IP)
4. Tunnel established

**When a public IP changes:**

1. Branch 2's ISP assigns a new IP
2. OPNsense on Branch 2 detects the change, updates Dynu DNS record
3. Existing tunnels to Branch 2 break (source IP changed)
4. DPD on peer branches detects dead peer (~60 seconds)
5. Peers re-resolve `branch2.fastpartz.dynu.net` → new IP
6. Tunnels re-establish automatically

**Expected downtime per IP change: 30–90 seconds.** This is acceptable for branch office data sync. SQL transactions will retry automatically.

### NAT Traversal (NAT-T)

Most UAE broadband routers perform NAT. IKEv2 handles this automatically:

- IKE negotiation starts on UDP 500
- If NAT is detected, both peers switch to **UDP 4500** (NAT-T)
- All ESP traffic is encapsulated in UDP 4500
- No special firewall rules needed on the broadband router (if in bridge mode) or OPNsense handles it

**Broadband router configuration:**
- **Ideal:** Set router to bridge mode (OPNsense gets the public IP directly)
- **Alternative:** Set OPNsense WAN IP as DMZ host on the router
- **Minimum:** Forward UDP 500 and UDP 4500 to OPNsense WAN IP

### Cloudflare as DNS Provider (Alternative)

If you own a domain, Cloudflare's free tier offers:

- Fastest DNS propagation (near-instant via Cloudflare edge)
- API-based updates from OPNsense
- Proxy mode OFF for IPsec records (DNS-only, no orange cloud)
- DNSSEC support

OPNsense supports Cloudflare DDNS natively. Use the Cloudflare API token with `Zone:DNS:Edit` permission.

---

## 7. OPNsense Configuration Per Edge

### Initial Installation

1. Download OPNsense ISO from https://opnsense.org/download/
2. Flash to USB with Rufus or `dd`
3. Boot mini-PC from USB, follow installer
4. Assign interfaces: `igc0` = WAN, `igc1` = LAN
5. Set LAN IP to `10.x.30.1/24` (management VLAN)
6. Access WebGUI at `https://10.x.30.1` from a PC on the management VLAN

### Interface Configuration

#### WAN Interface

```
Interface:      igc0
IPv4 Type:      DHCP (or Static if ISP provides)
Block private:  Enabled
Block bogon:    Enabled
```

#### LAN Interface (Trunk to Switch)

```
Interface:      igc1
IPv4 Type:      None (parent interface — VLANs handle addressing)
```

#### VLAN Sub-Interfaces

Create under **Interfaces > Other Types > VLAN**:

| VLAN Tag | Parent | Interface Name | IPv4 Address |
|----------|--------|---------------|-------------|
| 10 | igc1 | SERVERS | 10.x.10.1/24 |
| 20 | igc1 | WORKSTATIONS | 10.x.20.1/24 |
| 30 | igc1 | MANAGEMENT | 10.x.30.1/24 |
| 99 | igc1 | GUEST | 10.x.99.1/24 |

### Firewall Rules

#### WAN Rules

```
DEFAULT:    Block all inbound (implicit)
ALLOW:      UDP 500 (IKE) — source: any (for IPsec initiation)
ALLOW:      UDP 4500 (NAT-T) — source: any (for IPsec NAT traversal)
ALLOW:      UDP 1701 (L2TP) — only if L2TP used, otherwise skip
```

**That's it. ZERO other inbound ports.** No RDP. No SQL. No HTTP. Nothing.

#### SERVERS VLAN Rules (VLAN 10)

```
ALLOW:  Source: SERVERS net → Dest: IPsec peers (10.0.0.0/8) → Port: TCP 1433 (SQL sync)
ALLOW:  Source: SERVERS net → Dest: Internet → Port: TCP 80, 443 (Windows Update)
ALLOW:  Source: SERVERS net → Dest: NAS (10.x.10.20) → Port: TCP 445, 873 (SMB, rsync)
DENY:   Source: SERVERS net → Dest: WORKSTATIONS net
DENY:   Source: SERVERS net → Dest: GUEST net
ALLOW:  Source: SERVERS net → Dest: any → Port: UDP 53, TCP 53 (DNS to OPNsense)
ALLOW:  Source: SERVERS net → Dest: any → Port: UDP 123 (NTP)
```

#### WORKSTATIONS VLAN Rules (VLAN 20)

```
ALLOW:  Source: WKSTNS net → Dest: SERVERS net → Port: TCP 1433 (SQL - accounting)
ALLOW:  Source: WKSTNS net → Dest: SERVERS net → Port: TCP 445 (SMB - file shares)
ALLOW:  Source: WKSTNS net → Dest: Internet → Port: TCP 80, 443 (web browsing)
ALLOW:  Source: WKSTNS net → Dest: GUEST net → Port: TCP 9100, 631 (printing)
DENY:   Source: WKSTNS net → Dest: MGMT net
ALLOW:  Source: WKSTNS net → Dest: any → Port: UDP 53, TCP 53 (DNS)
```

#### MANAGEMENT VLAN Rules (VLAN 30)

```
ALLOW:  Source: MGMT net → Dest: any → Port: any (full access for management)
```

#### GUEST VLAN Rules (VLAN 99)

```
DENY:   Source: GUEST net → Dest: 10.0.0.0/8 (block ALL private subnets)
ALLOW:  Source: GUEST net → Dest: Internet → Port: TCP 80, 443, UDP 443 (web only)
ALLOW:  Source: GUEST net → Dest: OPNsense → Port: UDP 53 (DNS resolution)
DENY:   Source: GUEST net → Dest: any (default deny)
```

### Suricata IDS/IPS

**Installation:** System > Firmware > Plugins > `os-suricata`

**Configuration (Services > Intrusion Detection):**

```
Enabled:                Yes
IPS Mode:               Enabled (inline blocking, not just alerting)
Interfaces:             WAN, SERVERS, WORKSTATIONS
Pattern matcher:        Hyperscan (fastest on x86)
Default packet size:    1518

Rulesets:
  ☑ ET Open (Emerging Threats — free community rules)
  ☑ Abuse.ch SSL Blacklist
  ☑ Abuse.ch URLhaus
  ☑ Abuse.ch Feodo Tracker (banking trojans)

Rule update schedule:   Daily at 03:00

Home networks:          10.1.0.0/16, 10.2.0.0/16, 10.3.0.0/16, 10.4.0.0/16
```

**Performance on N100:**
- ET Open ruleset (~35,000 rules): ~800 Mbps throughput
- CPU usage: ~30-40% at full load
- Memory: ~1.5 GB for rule loading

### DNS Filtering (Unbound + DNSBL)

**Install plugin:** `os-unbound-plus-dnsbl` (or use the built-in Unbound blocklist feature)

**Configuration (Services > Unbound DNS > Blocklist):**

```
Enabled:            Yes
Blocklist type:     DNSBL (URL-based blocklists)

Blocklists:
  ☑ Steven Black Unified (ads + malware + phishing)
  ☑ Abuse.ch URLhaus Domain Blocklist
  ☑ Malware Domain List
  ☑ Phishing Army Extended

DNSSEC Validation:  Enabled
DNS over TLS:       Enabled (forwarding to Cloudflare 1.1.1.1 or Quad9 9.9.9.9)

Forward mode:       TLS
Forward servers:
  - 1.1.1.1 (cloudflare-dns.com)
  - 9.9.9.9 (dns.quad9.net)
```

### DHCP Server

Configure per VLAN (Services > DHCPv4):

| VLAN | Range Start | Range End | Gateway | DNS |
|------|------------|-----------|---------|-----|
| VLAN 20 (Workstations) | 10.x.20.100 | 10.x.20.200 | 10.x.20.1 | 10.x.20.1 (OPNsense) |
| VLAN 99 (Guest) | 10.x.99.100 | 10.x.99.200 | 10.x.99.1 | 10.x.99.1 (OPNsense) |

VLAN 10 (Servers) and VLAN 30 (Management) use **static IPs only** — no DHCP.

### NTP

OPNsense acts as NTP server for all branches (Services > NTP):

```
NTP Servers:    0.pool.ntp.org, 1.pool.ntp.org
Listen on:      SERVERS, WORKSTATIONS, MANAGEMENT
```

Windows Servers and PCs point to OPNsense as their NTP source.

### Syslog Forwarding

Configure under **System > Settings > Logging / Targets**:

```
Remote syslog:  Enabled
Target:         10.1.10.30:514 (central syslog server, or NAS with syslog)
Transport:      UDP (or TCP for reliability)
Facilities:     All
Levels:         Warning and above

Log firewall:   Enabled (log blocked connections)
Log IPsec:      Enabled
Log IDS/IPS:    Enabled (Suricata alerts)
```

### Configuration Backup

**Automated backup to NAS (recommended):**

Under **System > Configuration > Backups**:

```
Backup provider:    Google Drive / Nextcloud / Git
```

**Alternative: cron-based backup via script:**

Create a cron job (System > Settings > Cron) that runs daily:

```
Command:    /conf/backup/backup_config.sh
Schedule:   Daily at 02:00
```

Script content (`/conf/backup/backup_config.sh`):

```bash
#!/bin/sh
# Export OPNsense config and push to NAS
CONFIG="/conf/config.xml"
DEST="rsync://nas@10.x.10.20/opnsense-backup/"
DATE=$(date +%Y%m%d)
cp $CONFIG /tmp/config-${DATE}.xml
rsync -az /tmp/config-${DATE}.xml $DEST
rm /tmp/config-${DATE}.xml
```

Keep at least 30 days of config backups.

---

## 8. Windows Server Hardening Checklist

### OS & Patching

- [ ] **Windows Server 2022** (latest build) or 2019 with latest cumulative updates
- [ ] **Windows Update:** Configured for automatic security updates
  - GPO: `Computer Configuration > Administrative Templates > Windows Components > Windows Update`
  - Auto-download and schedule install: Daily at 03:00
  - Optional: Deploy **WSUS** at HQ branch for centralized patch management
- [ ] **Reboot schedule:** Automated monthly maintenance window (e.g., 3rd Sunday, 03:00)

### Antivirus & Endpoint Protection

#### Layer 1: Windows Defender (Built-in)

- [ ] **Windows Defender Antivirus:** Enabled and active
- [ ] **Tamper Protection:** ON (prevents malware from disabling Defender)
  - Windows Security > Virus & threat protection > Settings > Tamper Protection = ON
- [ ] **Cloud-delivered protection:** ON
- [ ] **Automatic sample submission:** ON
- [ ] **Real-time protection:** ON
- [ ] **Attack Surface Reduction (ASR) rules:** Enabled via PowerShell:

```powershell
# Enable key ASR rules (Audit mode first, then Block after testing)
$rules = @(
    "BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550", # Block executable content from email/webmail
    "D4F940AB-401B-4EFC-AADC-AD5F3C50688A", # Block Office apps from creating child processes
    "3B576869-A4EC-4529-8536-B80A7769E899", # Block Office apps from creating executable content
    "75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84", # Block Office apps from injecting into other processes
    "D3E037E1-3EB8-44C8-A917-57927947596D", # Block JavaScript/VBScript from launching downloads
    "5BEB7EFE-FD9A-4556-801D-275E5FFC04CC", # Block execution of potentially obfuscated scripts
    "92E97FA1-2EDF-4476-BDD6-9DD0B4DDDC7B", # Block Win32 API calls from Office macros
    "01443614-CD74-433A-B99E-2ECDC07BFC25", # Block executable files unless they meet criteria
    "C1DB55AB-C21A-4637-BB3F-A12568109D35", # Use advanced protection against ransomware
    "9E6C4E1F-7D60-472F-BA1A-A39EF669E4B2", # Block credential stealing from lsass.exe
    "D1E49AAC-8F56-4280-B9BA-993A6D77406C", # Block process creations from PSExec/WMI
    "B2B3F03D-6A65-4F7B-A9C7-1C7EF74A9BA4", # Block untrusted/unsigned processes from USB
    "26190899-1602-49E8-8B27-EB1D0A1CE869", # Block Office comms app from creating child processes
    "7674BA52-37EB-4A4F-A9A1-F0F9A1619A2C"  # Block Adobe Reader from creating child processes
)

foreach ($rule in $rules) {
    Add-MpPreference -AttackSurfaceReductionRules_Ids $rule -AttackSurfaceReductionRules_Actions Enabled
}
```

#### Layer 2: Enterprise AV (Recommended Addition)

Deploy one of these for defense-in-depth:

| Solution | License Cost | Features |
|----------|-------------|----------|
| **ESET PROTECT** | ~$40/server/year | Central management, ransomware shield, low resource usage |
| **Bitdefender GravityZone** | ~$35/server/year | Central cloud console, HyperDetect, sandbox |
| **Kaspersky Endpoint Security** | ~$35/server/year | Strong heuristics (check UAE sanctions compliance) |

Cost for 4 servers: ~$140-160/year. Worth every dirham.

### Network Hardening

- [ ] **RDP (Remote Desktop):**
  - Disabled from WAN (OPNsense firewall blocks TCP 3389 inbound)
  - Enabled only from Management VLAN (10.x.30.0/24)
  - NLA (Network Level Authentication) required:
    ```
    System Properties > Remote > "Allow connections only from computers running
    Remote Desktop with Network Level Authentication"
    ```
  - RDP Gateway with MFA for remote admin (or use VPN + RDP)

- [ ] **SQL Server binding:**
  ```
  SQL Server Configuration Manager > SQL Server Network Configuration >
  Protocols for MSSQLSERVER > TCP/IP > IP Addresses:
    - Remove 0.0.0.0 (listen on all)
    - Set to: 10.x.10.10 only (server's VLAN 10 IP)
  ```
  SQL Server should ONLY listen on the Server VLAN interface. Never on 0.0.0.0.

- [ ] **Windows Firewall:** ON with restrictive inbound rules

```powershell
# Enable Windows Firewall on all profiles
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Block all inbound by default
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block

# Allow SQL from Server VLAN and other branches only
New-NetFirewallRule -DisplayName "SQL Server - Branch Traffic" `
    -Direction Inbound -Protocol TCP -LocalPort 1433 `
    -RemoteAddress 10.0.0.0/8 -Action Allow

# Allow RDP from Management VLAN only
New-NetFirewallRule -DisplayName "RDP - Management VLAN" `
    -Direction Inbound -Protocol TCP -LocalPort 3389 `
    -RemoteAddress 10.0.0.0/8 -Action Allow

# Allow SMB from Workstation VLAN
New-NetFirewallRule -DisplayName "SMB - Workstations" `
    -Direction Inbound -Protocol TCP -LocalPort 445 `
    -RemoteAddress 10.0.0.0/8 -Action Allow

# Allow ICMP (ping) from internal
New-NetFirewallRule -DisplayName "ICMP - Internal" `
    -Direction Inbound -Protocol ICMPv4 `
    -RemoteAddress 10.0.0.0/8 -Action Allow
```

### Disable Unnecessary Protocols

```powershell
# Disable SMBv1 (WannaCry vector)
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart

# Disable NetBIOS over TCP/IP (all adapters)
Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true } |
    ForEach-Object { $_.SetTcpipNetbios(2) }  # 2 = Disable

# Disable LLMNR (via Group Policy)
# Computer Configuration > Administrative Templates > Network > DNS Client
# "Turn off multicast name resolution" = Enabled

# Disable WPAD (Web Proxy Auto-Discovery)
# Set registry: HKLM\SYSTEM\CurrentControlSet\Services\WinHttpAutoProxySvc Start = 4

# Disable PowerShell v2 (bypasses AMSI)
Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root -NoRestart
Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2 -NoRestart
```

### Account Security

- [ ] **Account lockout policy:**
  ```
  secpol.msc > Account Policies > Account Lockout Policy:
    Account lockout threshold:    5 invalid attempts
    Account lockout duration:     30 minutes
    Reset lockout counter after:  30 minutes
  ```

- [ ] **Password policy:**
  ```
  secpol.msc > Account Policies > Password Policy:
    Minimum password length:      14 characters
    Password complexity:          Enabled
    Maximum password age:         90 days
    Minimum password age:         1 day
    Enforce password history:     12 passwords
  ```

- [ ] **Separate admin accounts:**
  - Daily use: `user.firstname` (standard user, no admin rights)
  - Administration: `admin.firstname` (local admin or domain admin)
  - Never log in to servers with daily-use accounts
  - Never browse the internet from admin accounts

- [ ] **Rename built-in Administrator account** (obfuscation, not security — but reduces noise):
  ```powershell
  Rename-LocalUser -Name "Administrator" -NewName "sysadm_fp"
  ```

### Application Control

- [ ] **AppLocker** (Windows Server 2019/2022 Enterprise) or **WDAC** (all editions):

```powershell
# AppLocker: Allow only signed executables + Microsoft defaults
# Configure via secpol.msc > Application Control Policies > AppLocker

# Default rules (must create first):
# - Allow Everyone: %WINDIR%\*
# - Allow Everyone: %PROGRAMFILES%\*
# - Allow BUILTIN\Administrators: * (admins can run anything)

# Then add deny rules:
# - Deny Everyone: %USERPROFILE%\* (block executables from user profile)
# - Deny Everyone: %TEMP%\* (block executables from temp folders)
# - Deny Everyone: %APPDATA%\* (block executables from AppData)
```

### Audit Logging

- [ ] **Enable advanced audit policies:**

```powershell
# Enable key security audit categories
auditpol /set /category:"Account Logon" /success:enable /failure:enable
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /category:"Object Access" /success:enable /failure:enable
auditpol /set /category:"Policy Change" /success:enable /failure:enable
auditpol /set /category:"Privilege Use" /failure:enable
auditpol /set /category:"System" /success:enable /failure:enable
```

- [ ] **Forward security events to syslog:**
  - Install **NXLog Community Edition** (free) or **Winlogbeat**
  - Forward Windows Security log events to OPNsense syslog or central SIEM
  - Critical events to forward:
    - Event ID 4625: Failed logon
    - Event ID 4624: Successful logon
    - Event ID 4720: User account created
    - Event ID 4732: Member added to security group
    - Event ID 7045: New service installed
    - Event ID 1102: Audit log cleared

---

## 9. Backup Strategy (3-2-1)

### Overview

The 3-2-1 rule: **3 copies** of data, on **2 different media types**, with **1 copy offsite**.

```
                    ┌─────────────────────┐
                    │   Windows Server    │
                    │   (Production DB)   │
                    └─────────┬───────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
              ▼               ▼               ▼
     ┌────────────┐  ┌────────────────┐  ┌──────────────┐
     │  Copy 1    │  │   Copy 2       │  │   Copy 3     │
     │  Local NAS │  │   Cross-branch │  │   Offsite    │
     │  (Branch)  │  │   NAS via IPsec│  │   (Cloud or  │
     │            │  │                │  │    Pakistan)  │
     │  Veeam →   │  │  rsync/rclone  │  │  Borg/Restic │
     │  Synology  │  │  encrypted     │  │  encrypted   │
     └────────────┘  └────────────────┘  └──────────────┘
        Daily             Daily              Weekly
      incremental       incremental        full + daily
      + weekly full     sync               incremental
```

### Copy 1: Local Backup (Veeam → NAS)

**Software: Veeam Backup & Replication Community Edition (Free)**

- Free for up to 10 workloads (we have 4 servers — plenty of headroom)
- Full VM/physical server backup with application-aware processing
- MS SQL VSS integration (consistent database backups)
- Install Veeam B&R on one Windows Server per branch (or a dedicated management VM)

**Backup target: Synology NAS (VLAN 10)**

**Schedule:**

| Day | Backup Type | Retention |
|-----|------------|-----------|
| Monday–Saturday | Incremental | 14 days |
| Sunday | Active Full | 4 weeks |
| 1st of month | Synthetic Full (GFS) | 6 months |

**Veeam configuration:**

```
Backup job:
  Name:           Branch1-DailyBackup
  Source:          Branch 1 Windows Server (all volumes)
  Destination:    \\10.x.10.20\veeam-backup\ (Synology NAS SMB share)
  Schedule:       Daily at 22:00
  Backup mode:    Incremental (with periodic active full every Sunday)
  Retention:      14 restore points
  Application:    Enable application-aware processing (MS SQL)
  SQL log backup: Every 15 minutes (transaction log backup)
  Encryption:     AES-256 (set backup encryption password)
  Notifications:  Email on failure
```

**Synology NAS setup:**

- RAID 1 (mirror) with 2x 4TB drives = 4TB usable
- Create shared folder: `veeam-backup`
- SMB access: Veeam service account only
- Enable NAS snapshots (Snapshot Replication): daily, retain 7 days
  - This provides an **immutable** layer — ransomware cannot encrypt snapshots

### Copy 2: Cross-Branch Replication (UAE)

**Method: rsync over IPsec tunnel**

Each branch replicates its backups to a **partner branch NAS** over the encrypted IPsec mesh:

| Source Branch | Destination Branch | Why |
|--------------|-------------------|-----|
| Branch 1 | Branch 2 NAS | Geographic separation within UAE |
| Branch 2 | Branch 1 NAS | Reciprocal |
| Branch 3 | Branch 4 NAS | Geographic separation |
| Branch 4 | Branch 3 NAS | Reciprocal |

**rsync cron job (on Synology NAS, Task Scheduler):**

```bash
#!/bin/bash
# Cross-branch backup replication
# Runs daily at 01:00 (after Veeam completes at ~23:00)

SOURCE="/volume1/veeam-backup/"
DEST="rsync://backup@10.2.10.20/cross-branch-backup/branch1/"

# Use rsync over IPsec tunnel (already encrypted at network layer)
rsync -avz --delete \
    --bwlimit=10000 \  # 10 MB/s limit to avoid saturating tunnel
    --log-file=/var/log/cross-branch-sync.log \
    "$SOURCE" "$DEST"

# Check exit code and alert on failure
if [ $? -ne 0 ]; then
    # Send alert (webhook, email, etc.)
    curl -s "https://api.telegram.org/bot<TOKEN>/sendMessage" \
        -d "chat_id=<CHAT_ID>" \
        -d "text=ALERT: Cross-branch backup sync FAILED for Branch 1"
fi
```

**Alternative: rclone with encryption**

If you want an additional encryption layer on top of IPsec (defense in depth):

```bash
# rclone with crypt remote
rclone sync /volume1/veeam-backup/ encrypted-remote:cross-branch/branch1/ \
    --transfers 4 \
    --bwlimit 10M \
    --log-file /var/log/rclone-sync.log \
    --log-level INFO
```

### Copy 3: Offsite Backup (Outside UAE)

This is the disaster recovery copy. If UAE suffers a regional disaster (unlikely but not impossible) or all branches are hit by ransomware simultaneously, this copy survives.

#### Option A: Cloud Storage (Recommended for Simplicity)

| Provider | Cost | Egress | Immutability | Notes |
|----------|------|--------|-------------|-------|
| **Backblaze B2** | $5/TB/mo | $0.01/GB | Object Lock (S3-compatible) | Best balance of cost and features |
| **Cloudflare R2** | $15/TB/mo | **FREE** | No native object lock | Best if you need frequent restores |
| **AWS S3 Glacier Deep Archive** | $1/TB/mo | $0.09/GB | Object Lock + Vault Lock | Cheapest archival, slow restore (12-48h) |
| **Wasabi** | $7/TB/mo | FREE | Object Lock | No egress fees, 90-day minimum storage |

**Recommended: Backblaze B2 with Object Lock**

```bash
# Using restic with B2 backend
export B2_ACCOUNT_ID="your-account-id"
export B2_ACCOUNT_KEY="your-account-key"

# Initialize repository (one-time)
restic -r b2:fastpartz-backup-branch1:/ init

# Weekly full backup
restic -r b2:fastpartz-backup-branch1:/ backup /volume1/veeam-backup/ \
    --exclude-caches \
    --tag weekly-full

# Apply retention policy
restic -r b2:fastpartz-backup-branch1:/ forget \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6 \
    --prune

# Verify backup integrity
restic -r b2:fastpartz-backup-branch1:/ check
```

**B2 Object Lock configuration:**

```
Bucket:         fastpartz-backup-branch1
Lifecycle:      Object Lock enabled
Default retention: 30 days (Governance mode)
```

Object Lock prevents anyone (including admins) from deleting or modifying backups for the retention period. Even if ransomware compromises the backup server and steals API keys, it cannot delete locked objects.

**Estimated monthly cost:**

| Data Size | B2 Cost | S3 Glacier Cost |
|-----------|---------|-----------------|
| 500 GB | $2.50/mo | $0.50/mo |
| 1 TB | $5.00/mo | $1.00/mo |
| 5 TB | $25.00/mo | $5.00/mo |

#### Option B: Pakistan Physical Backup (Data Sovereignty)

For organizations wanting physical control over their offsite copy, or for regulatory reasons:

**Setup: Raspberry Pi 5 as backup receiver at trusted Pakistan location**

```
Location:       Family house / small office in Pakistan
Connectivity:   Consumer broadband (50+ Mbps)
Hardware:       Raspberry Pi 5 (8GB) + 8TB WD Elements USB HDD
OS:             Ubuntu Server 24.04 LTS (64-bit ARM)
Software:       Borgbackup server, WireGuard/IPsec client
```

**Raspberry Pi setup:**

```bash
# 1. Install Ubuntu Server on microSD
# 2. Mount external HDD
sudo mkfs.ext4 /dev/sda1
sudo mkdir /mnt/backup
echo '/dev/sda1 /mnt/backup ext4 defaults,noatime 0 2' | sudo tee -a /etc/fstab
sudo mount -a

# 3. Install Borgbackup
sudo apt update && sudo apt install -y borgbackup wireguard

# 4. Create backup user
sudo useradd -m -s /bin/bash backup
sudo mkdir -p /mnt/backup/borg-repos
sudo chown backup:backup /mnt/backup/borg-repos

# 5. Initialize Borg repository
sudo -u backup borg init --encryption=repokey-blake2 /mnt/backup/borg-repos/branch1

# 6. Set up WireGuard tunnel to UAE Branch 1
# (Alternative: IPsec if OPNsense-to-Pi IPsec is preferred)
```

**WireGuard configuration on Pi:**

```ini
# /etc/wireguard/wg0.conf
[Interface]
PrivateKey = <pi-private-key>
Address = 10.100.0.2/30
DNS = 1.1.1.1

[Peer]
PublicKey = <opnsense-public-key>
Endpoint = branch1.fastpartz.dynu.net:51820
AllowedIPs = 10.1.0.0/16, 10.2.0.0/16, 10.3.0.0/16, 10.4.0.0/16
PersistentKeepalive = 25
```

**Borg backup job (runs from UAE NAS, pushes to Pi):**

```bash
#!/bin/bash
# Daily incremental Borg backup to Pakistan offsite
# Runs on Synology NAS or Windows Server via WSL/scheduled task

export BORG_REPO="ssh://backup@10.100.0.2/mnt/backup/borg-repos/branch1"
export BORG_PASSPHRASE="<strong-encryption-passphrase>"

# Create daily backup
borg create \
    --compression zstd,6 \
    --stats \
    --show-rc \
    "${BORG_REPO}::daily-{now:%Y-%m-%d_%H:%M}" \
    /volume1/veeam-backup/

# Prune old backups
borg prune \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6 \
    --stats \
    "${BORG_REPO}"

# Verify integrity (weekly)
if [ "$(date +%u)" -eq 7 ]; then
    borg check "${BORG_REPO}"
fi
```

### Immutable Backup Protection

Ransomware increasingly targets backups. Protect against this:

| Method | Where | How |
|--------|-------|-----|
| NAS Snapshots | Synology NAS | Snapshot Replication: daily, 7-day retention. Snapshots are read-only. |
| B2 Object Lock | Backblaze B2 | 30-day governance mode. Cannot be deleted even with admin credentials. |
| Borg append-only | Pakistan Pi | Borg repo in append-only mode. Client can create but not delete archives. |
| Air gap | Pakistan Pi | Pi can be physically disconnected if attack is detected. |

**Borg append-only mode (on Pi):**

In `/home/backup/.ssh/authorized_keys`:

```
command="borg serve --restrict-to-path /mnt/backup/borg-repos --append-only",restrict ssh-rsa AAAA... backup@synology
```

The `--append-only` flag means the backup client can ADD new archives but cannot DELETE or PRUNE existing ones. Only local access on the Pi can prune old backups.

### Backup Testing Schedule

| Test | Frequency | Procedure |
|------|-----------|-----------|
| Backup completion verification | Daily (automated) | Check Veeam job status, alert on failure |
| File-level restore test | Monthly | Restore random files from each copy, verify integrity |
| Full server restore test | Quarterly | Restore entire server to test VM, verify boot + SQL |
| Cross-branch restore test | Quarterly | Restore from partner branch NAS |
| Offsite restore test | Semi-annually | Restore from B2 or Pakistan, verify complete recovery |
| DR simulation | Annually | Simulate total branch loss, restore from offsite only |

---

## 10. Remote User Access

### IKEv2 Roadwarrior VPN

OPNsense supports IKEv2 roadwarrior VPN natively. The key advantage: **no client software needed** — Windows, macOS, iOS, and Android all have built-in IKEv2 VPN clients.

### VPN VLAN

Remote VPN users land in a dedicated VPN subnet, separate from all branch VLANs:

```
VPN Pool:       10.10.10.0/24
Gateway:        10.10.10.1 (OPNsense)
DNS:            10.10.10.1 (OPNsense Unbound — filtered DNS)
```

### OPNsense Roadwarrior Configuration

**VPN > IPsec > Mobile Clients:**

```
Enable:                     Yes
IKE Extensions:             Enabled
User Authentication:        Local Database + Certificate
Group Authentication:       None
Virtual Address Pool:       10.10.10.0/24
Network List:               Provide (push internal routes to client)
  - 10.1.0.0/16 (Branch 1)
  - 10.2.0.0/16 (Branch 2)
  - 10.3.0.0/16 (Branch 3)
  - 10.4.0.0/16 (Branch 4)
DNS Servers:                10.10.10.1
Default domain:             fastpartz.local
Split tunneling:            Enabled (only branch traffic goes through VPN)
```

**Phase 1 (Mobile):**

```
Key Exchange:       IKEv2
Authentication:     EAP-MSCHAPv2 (for username/password on top of certificate)
My Certificate:     branch1.fastpartz.dynu.net
Encryption:         AES-256-GCM
Hash:               SHA384
DH Group:           20 (NIST P-384)
Lifetime:           28800
```

**Phase 2 (Mobile):**

```
Mode:               Tunnel
Local Network:      0.0.0.0/0 (or specific branch subnets for split tunnel)
Protocol:           ESP
Encryption:         AES-256-GCM
PFS:                Group 20
Lifetime:           3600
```

### Certificate + Password Authentication

Each remote user gets:

1. **Root CA certificate** installed on their device (trusted certificate)
2. **Username + password** in OPNsense local user database
3. IKEv2 authenticates the server by certificate, user by EAP-MSCHAPv2

### MFA via TOTP

**Install plugin:** `os-totp` (System > Firmware > Plugins)

**Configuration:**

1. Enable TOTP (System > Access > Servers > Add TOTP server)
2. Link VPN authentication to TOTP (local + TOTP as auth chain)
3. Users enroll TOTP via OPNsense user portal (scan QR code with Google Authenticator, Authy, etc.)
4. Login flow: Certificate + username + password + TOTP code

**Note:** IKEv2 with EAP-MSCHAPv2 doesn't natively support a separate TOTP field. Implementation options:

- **Option 1:** Append TOTP code to password (e.g., `MyPassword123456` where `123456` is the TOTP code). OPNsense TOTP plugin supports this.
- **Option 2:** Use OpenVPN instead of IKEv2 for roadwarrior (supports dedicated MFA prompt) but requires client software.

**Recommendation:** Option 1 (password+TOTP concatenation) for IKEv2. It's the cleanest approach with no extra client software.

### VPN Firewall Rules

Remote VPN users should have **restricted access** — only what they need:

```
# VPN interface rules (Firewall > Rules > IPsec)

ALLOW:  Source: 10.10.10.0/24 → Dest: 10.x.10.0/24 → Port: TCP 3389 (RDP to servers)
ALLOW:  Source: 10.10.10.0/24 → Dest: 10.x.10.0/24 → Port: TCP 1433 (SQL if needed)
ALLOW:  Source: 10.10.10.0/24 → Dest: 10.x.10.0/24 → Port: TCP 445 (file shares)
DENY:   Source: 10.10.10.0/24 → Dest: 10.x.20.0/24 (no access to workstations)
DENY:   Source: 10.10.10.0/24 → Dest: 10.x.30.0/24 (no access to management)
DENY:   Source: 10.10.10.0/24 → Dest: 10.x.99.0/24 (no access to guest)
```

### Client Configuration

#### Windows 10/11 (Built-in)

```
Settings > Network > VPN > Add VPN:
  Provider:           Windows (built-in)
  Connection name:    FastPartz VPN
  Server:             branch1.fastpartz.dynu.net
  VPN type:           IKEv2
  Sign-in info:       Username and password
  Username:           <user>
  Password:           <password><TOTP-code>
```

Import the Root CA certificate to: `certlm.msc > Trusted Root Certification Authorities`

#### macOS (Built-in)

```
System Preferences > Network > + > VPN > IKEv2:
  Server:             branch1.fastpartz.dynu.net
  Remote ID:          branch1.fastpartz.dynu.net
  Local ID:           (leave blank)
  Authentication:     Username
```

Install Root CA certificate in Keychain Access (mark as Always Trust).

#### iOS / Android

Both support IKEv2 natively:
- iOS: Settings > VPN > Add VPN Configuration > IKEv2
- Android: Settings > Network > VPN > Add > IKEv2/IPsec PSK/Certificate

### Vendor/Support Access

For software vendors or support technicians needing temporary access:

1. Create a **time-limited VPN account** in OPNsense (set expiry date)
2. Restrict to specific server IPs and ports only
3. Enable **session logging** (OPNsense logs all VPN connections)
4. **Revoke immediately** after support session ends
5. Consider recording sessions with a jump host (Apache Guacamole)

---

## 11. Ransomware Attack Surface Analysis & Mitigations

### Attack Vector Matrix

| # | Attack Vector | Current Risk | Mitigation | Post-Deployment Risk |
|---|-------------|-------------|-----------|---------------------|
| 1 | **RDP Brute Force** | CRITICAL (open to internet) | OPNsense blocks all inbound. RDP only via VPN + Management VLAN. | ELIMINATED |
| 2 | **SQL Server Exploitation** | CRITICAL (open to internet) | OPNsense blocks all inbound. SQL bound to VLAN 10 only. | ELIMINATED |
| 3 | **Phishing / Email** | HIGH | Microsoft 365/Google Workspace security. SPF/DKIM/DMARC. User awareness training. Email attachment sandboxing. | MEDIUM (human factor) |
| 4 | **Malicious Web Downloads** | HIGH | Suricata IDS/IPS on OPNsense. DNS blocklists (malware/phishing domains). Windows Defender + Enterprise AV. AppLocker blocks unsigned executables. | LOW |
| 5 | **USB / Removable Media** | MEDIUM | Group Policy: disable AutoRun. Optional: block USB mass storage entirely via GPO. ASR rule blocks untrusted processes from USB. | LOW |
| 6 | **Lateral Movement** | CRITICAL (flat network) | VLAN segmentation. Inter-VLAN firewall rules. Windows Firewall on each server. Separate admin accounts. | LOW |
| 7 | **Credential Theft / Brute Force** | HIGH | MFA on VPN. Account lockout (5 attempts/30 min). Separate admin accounts. LSASS credential guard (ASR rule). | LOW |
| 8 | **Supply Chain / Software** | MEDIUM | WSUS for patch management. AppLocker/WDAC whitelist. Software inventory. Vendor access time-limited. | LOW |
| 9 | **Insider Threat** | MEDIUM | Least privilege. Audit logging. No shared accounts. Separate admin accounts. | LOW |
| 10 | **WiFi** | MEDIUM | WPA3-Enterprise or WPA3-Personal. Guest SSID on VLAN 99 (isolated). No access to server/management VLANs. | LOW |
| 11 | **Printers / IoT** | LOW-MEDIUM | VLAN 99 (isolated). Only print ports (9100, 631) allowed from VLAN 20. No internet access for IoT. | LOW |
| 12 | **DNS-Based Attacks** | MEDIUM | DNSSEC validation on OPNsense Unbound. DNS-over-TLS to upstream (Cloudflare/Quad9). DNS blocklists. | LOW |
| 13 | **Backup Destruction** | CRITICAL (no backups exist) | 3-2-1 backup with immutable snapshots. Object Lock on cloud. Append-only Borg on offsite. Air-gapped Pi. | LOW |
| 14 | **Unpatched Vulnerabilities** | HIGH | Automated Windows Update. WSUS for centralized management. Monthly patch compliance review. | LOW |

### Phishing / Email Hardening

Since email is the #1 remaining attack vector after network hardening:

**DNS-based email authentication (configure on domain DNS):**

```
SPF:    v=spf1 include:_spf.google.com ~all
DKIM:   Configured via Google Workspace / M365 admin
DMARC:  v=DMARC1; p=quarantine; rua=mailto:dmarc@fastpartz.ae; pct=100
```

**Additional email controls:**
- Block `.exe`, `.bat`, `.cmd`, `.ps1`, `.vbs`, `.js` attachments at the mail gateway
- Enable Safe Links and Safe Attachments (M365) or similar
- User awareness training: quarterly phishing simulation

### USB / Removable Media

**Group Policy (Computer Configuration > Administrative Templates > System > Removable Storage Access):**

```
All Removable Storage classes: Deny all access = Enabled
  (or)
Removable Disks: Deny write access = Enabled  (allow read but prevent write-back)
```

**Less restrictive alternative:**
- Disable AutoRun only (prevents auto-execution of malware from USB)
- Combined with ASR rule "Block untrusted/unsigned processes from USB"

### WiFi Security

```
AP Configuration:
  Corporate SSID:   FastPartz-Corp
    Auth:           WPA3-Personal (or WPA3-Enterprise with RADIUS)
    VLAN:           20 (Workstations)
    Band:           5 GHz preferred

  Guest SSID:       FastPartz-Guest
    Auth:           WPA3-Personal (simple passphrase, rotate monthly)
    VLAN:           99 (Guest — fully isolated)
    Band:           2.4 + 5 GHz
    Client isolation: Enabled (clients can't see each other)
    Captive portal:  Optional (OPNsense captive portal on VLAN 99)
```

---

## 12. Monitoring & Alerting

### OPNsense Built-in Monitoring

OPNsense provides extensive built-in monitoring out of the box:

| Feature | Location | What It Shows |
|---------|----------|--------------|
| Dashboard widgets | Lobby > Dashboard | Traffic graphs, IPsec status, CPU/RAM, IDS alerts |
| IPsec status | VPN > IPsec > Status Overview | All tunnel states (established/connecting/down) |
| Suricata alerts | Services > Intrusion Detection > Alerts | IDS/IPS events, blocked threats |
| Firewall logs | Firewall > Log Files > Live View | Real-time blocked/allowed connections |
| DNS queries | Services > Unbound DNS > Query Log | All DNS queries (identify suspicious domains) |
| Traffic graphs | Reporting > Traffic | Per-interface bandwidth usage |

### Centralized Monitoring (Optional but Recommended)

Deploy a lightweight monitoring stack at Branch 1 (HQ):

**Option 1: Zabbix (Full SNMP/Agent Monitoring)**

- Run on a lightweight VM or container (2 vCPU, 2GB RAM)
- Monitor: OPNsense (SNMP), Windows Servers (Zabbix Agent), NAS (SNMP), switches (SNMP)
- Alerting: Email, Telegram, Slack

**Option 2: Uptime Kuma (Simple Availability Monitoring)**

- Docker container (256MB RAM)
- Ping/HTTP/TCP checks for all services
- Beautiful dashboard, push notifications
- Ideal for checking: IPsec tunnels up, SQL Server responding, NAS accessible, backups running

```bash
# Deploy Uptime Kuma (on any Linux VM/container or NAS Docker)
docker run -d \
    --name uptime-kuma \
    -p 3001:3001 \
    -v uptime-kuma:/app/data \
    --restart unless-stopped \
    louislam/uptime-kuma:latest
```

**Monitoring checks to configure:**

| Check | Type | Target | Interval | Alert On |
|-------|------|--------|----------|----------|
| Branch 2 IPsec | TCP ping | 10.2.10.1:443 | 60s | Down > 2 min |
| Branch 3 IPsec | TCP ping | 10.3.10.1:443 | 60s | Down > 2 min |
| Branch 4 IPsec | TCP ping | 10.4.10.1:443 | 60s | Down > 2 min |
| B1 SQL Server | TCP | 10.1.10.10:1433 | 30s | Down > 1 min |
| B1 NAS | TCP ping | 10.1.10.20:5000 | 60s | Down > 5 min |
| B1 OPNsense WebGUI | HTTPS | 10.1.30.1:443 | 60s | Down > 2 min |
| Pakistan offsite | TCP ping | 10.100.0.2:22 | 300s | Down > 15 min |
| Backblaze B2 | HTTP | api.backblazeb2.com | 300s | Down > 10 min |

### Syslog Aggregation

All OPNsense edges and Windows Servers forward logs to a central syslog collector:

**Lightweight option: rsyslog on NAS or VM**

```bash
# /etc/rsyslog.d/10-remote.conf
module(load="imudp")
input(type="imudp" port="514")

# Template for organized log storage
template(name="RemoteLogs" type="string" string="/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log")

*.* ?RemoteLogs
```

**Windows log forwarding (NXLog on each server):**

```xml
<!-- nxlog.conf -->
<Input in_eventlog>
    Module      im_msvistalog
    Query       <QueryList>\
                    <Query Id="0">\
                        <Select Path="Security">*[System[(Level=1 or Level=2 or Level=3)]]</Select>\
                        <Select Path="System">*[System[(Level=1 or Level=2 or Level=3)]]</Select>\
                        <Select Path="Application">*[System[(Level=1 or Level=2 or Level=3)]]</Select>\
                    </Query>\
                </QueryList>
</Input>

<Output out_syslog>
    Module      om_udp
    Host        10.1.10.30
    Port        514
    Exec        to_syslog_bsd();
</Output>

<Route route_syslog>
    Path        in_eventlog => out_syslog
</Route>
```

### Alerting Channels

#### Email Alerts

Configure on OPNsense (System > Settings > Notifications):

```
SMTP Server:    smtp.gmail.com (or M365 SMTP relay)
Port:           587 (TLS)
From:           opnsense-alerts@fastpartz.ae
To:             admin@fastpartz.ae
Authentication: Yes (app-specific password)
```

#### Telegram Bot Alerts (Recommended — Instant Mobile Notifications)

```bash
# Create Telegram bot via @BotFather
# Get bot token and chat ID

# Script for sending alerts (called from cron jobs, backup scripts, etc.)
#!/bin/bash
TELEGRAM_BOT_TOKEN="your-bot-token"
TELEGRAM_CHAT_ID="your-chat-id"

send_alert() {
    local message="$1"
    curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${message}" \
        -d "parse_mode=HTML" > /dev/null
}

# Usage: send_alert "🔴 ALERT: IPsec tunnel to Branch 2 is DOWN"
```

**Alert triggers:**

| Event | Source | Alert Method | Priority |
|-------|--------|-------------|----------|
| IPsec tunnel down | OPNsense / Uptime Kuma | Telegram + Email | CRITICAL |
| IDS/IPS alert (high severity) | Suricata | Email | HIGH |
| Failed login (5+ attempts) | Windows Server | Email | HIGH |
| Backup job failed | Veeam | Email + Telegram | CRITICAL |
| Cross-branch sync failed | rsync script | Telegram | HIGH |
| Offsite backup failed | Borg/Restic script | Telegram | CRITICAL |
| Disk space > 80% | Zabbix / NAS | Email | MEDIUM |
| Server offline | Uptime Kuma | Telegram + Email | CRITICAL |

---

## 13. Container vs Bare-Metal Discussion

### Recommendation: OPNsense Bare-Metal on Mini-PC

**This is the recommended approach for FastPartz.**

| Factor | Bare-Metal | Proxmox + OPNsense VM | Docker Custom SD-WAN |
|--------|-----------|----------------------|---------------------|
| Reliability | Best (fewer layers) | Good (mature hypervisor) | Risky (custom glue) |
| Performance | Best (direct NIC access) | Good (VT-d passthrough) | Varies |
| Complexity | Lowest | Medium | Highest |
| Attack surface | Smallest | Medium (hypervisor + VM) | Largest |
| Recovery | Flash USB, restore config | Reinstall Proxmox + VM | Rebuild containers + config |
| Community support | Excellent (OPNsense forums) | Good | Minimal (DIY) |
| Maintenance | OPNsense auto-update | Proxmox + OPNsense updates | Manual everything |

### Why Bare-Metal Wins

1. **A firewall is a network appliance.** It should be as simple and reliable as possible. Adding a hypervisor layer adds complexity and attack surface with minimal benefit for our use case.

2. **OPNsense on bare metal with 4 NICs** gives us everything we need: routing, firewall, IDS/IPS, VPN, DHCP, DNS — in a single, well-tested package.

3. **Recovery is trivial:** Flash a USB, install OPNsense, restore XML config backup. 30 minutes and the branch is back online.

4. **N100 performance is sufficient.** We don't need to run additional services on the edge device. Monitoring runs elsewhere (NAS Docker, separate VM, or cloud).

### When to Consider Proxmox

If in the future you need to run additional services at each branch edge (e.g., a local monitoring VM, a local DNS cache, a local reverse proxy), then a Proxmox setup makes sense:

```
Proxmox VE on N100 Mini-PC
├── VM: OPNsense (2 vCPU, 2GB RAM, NIC passthrough via VT-d)
├── LXC: Uptime Kuma (1 vCPU, 512MB RAM)
└── LXC: rsyslog collector (1 vCPU, 512MB RAM)
```

But this adds complexity and should only be considered after the core deployment is stable.

### Why NOT Docker-Based Custom SD-WAN

A custom solution using StrongSwan + FRRouting + iptables in Docker containers:

- Requires deep Linux networking expertise for ongoing maintenance
- No unified GUI for management
- Configuration drift between branches
- No integrated IDS/IPS (would need separate Suricata container)
- No community support for your specific stack
- Debugging network issues across container namespaces is painful
- **Every branch becomes a unique snowflake**

This approach is suitable for a tech company with a DevOps team. Not for a parts distribution business with an outsourced network engineer.

---

## 14. Implementation Phases

### Phase 1: Hardware Procurement & OPNsense Install (Week 1)

**Tasks:**

- [ ] Order all hardware (4x mini-PCs, 4x switches, 4x NAS, 1x Pi 5 kit)
- [ ] Download OPNsense ISO, create bootable USB
- [ ] Install OPNsense on all 4 mini-PCs (bench setup — configure at one location)
- [ ] Basic OPNsense configuration on each:
  - Set hostname (branch1-fw, branch2-fw, etc.)
  - Assign interfaces (WAN, LAN)
  - Set WAN to DHCP, LAN to management VLAN IP
  - Change default passwords
  - Enable SSH (key-based only, management VLAN only)
- [ ] Configure managed switches:
  - Create VLANs (10, 20, 30, 99)
  - Configure trunk port (to OPNsense)
  - Assign access ports to VLANs
  - Set management IP on VLAN 30
- [ ] Label all hardware and cables

**Deliverables:**
- 4 configured OPNsense appliances ready for deployment
- 4 configured managed switches
- Hardware inventory spreadsheet

### Phase 2: Branch 1 Pilot (Week 2)

**Tasks:**

- [ ] Deploy OPNsense + switch at Branch 1 (HQ)
- [ ] Configure broadband router: bridge mode or DMZ to OPNsense
- [ ] Create VLANs on OPNsense (VLAN 10, 20, 30, 99)
- [ ] Configure DHCP on VLAN 20, 99
- [ ] Move Windows Server to VLAN 10 (static IP)
- [ ] Move workstations to VLAN 20 (DHCP)
- [ ] Set OPNsense as default gateway for all devices
- [ ] Configure firewall rules (inter-VLAN)
- [ ] Install and configure Suricata IDS/IPS
- [ ] Configure Unbound DNS with blocklists
- [ ] Set up DynDNS (Dynu/Cloudflare)
- [ ] Create Root CA + Branch 1 server certificate
- [ ] Configure IPsec tunnel to Branch 2 (requires Branch 2 OPNsense deployed first — can test with lab setup)
- [ ] Verify: internet works, SQL works, no open ports from outside

**Deliverables:**
- Branch 1 fully operational with segmented network
- IDS/IPS running
- DNS filtering active
- At least one IPsec tunnel tested

### Phase 3: Full Mesh Deployment (Week 3)

**Tasks:**

- [ ] Deploy OPNsense + switch at Branch 2, 3, 4
- [ ] Replicate Branch 1 configuration (export/import XML config with adjustments)
- [ ] Configure broadband routers at each branch
- [ ] Create server certificates for Branch 2, 3, 4
- [ ] Configure all 6 IPsec tunnels (full mesh)
- [ ] Configure DynDNS at each branch
- [ ] Verify full mesh connectivity:
  - All 6 tunnels established
  - SQL sync working between all branches
  - Inter-VLAN isolation working
  - Internet access through OPNsense at all branches
- [ ] Move all Windows Servers to VLAN 10 at each branch
- [ ] Move all workstations to VLAN 20 at each branch

**Deliverables:**
- All 4 branches operational
- Full mesh IPsec (6 tunnels, all green)
- All servers on VLAN 10, all workstations on VLAN 20
- Zero public-facing ports on any branch

### Phase 4: Windows Hardening & Backup (Week 4)

**Tasks:**

- [ ] Windows Server hardening on all 4 servers:
  - Apply latest patches
  - Enable Windows Defender + ASR rules
  - Install enterprise AV (ESET or Bitdefender)
  - Configure Windows Firewall
  - Disable SMBv1, NetBIOS, LLMNR, PowerShell v2, WPAD
  - Configure account lockout + password policy
  - Create separate admin accounts
  - Bind SQL Server to VLAN 10 IP only
  - Enable audit logging + NXLog forwarding
- [ ] Set up Synology NAS at each branch (RAID 1, VLAN 10)
- [ ] Install Veeam Community Edition at each branch
- [ ] Configure Veeam backup jobs (daily incremental + weekly full)
- [ ] Configure cross-branch rsync replication
- [ ] Test backup and restore (file-level)

**Deliverables:**
- All Windows Servers hardened (checklist completed)
- Veeam backups running daily at all branches
- Cross-branch replication running daily
- First successful test restore completed

### Phase 5: Remote Access, Monitoring & Offsite (Week 5)

**Tasks:**

- [ ] Configure IKEv2 roadwarrior VPN on Branch 1 OPNsense
- [ ] Create VPN user accounts with TOTP MFA
- [ ] Test VPN from Windows, macOS, iOS, Android
- [ ] Configure VPN firewall rules (restricted access)
- [ ] Deploy monitoring (Uptime Kuma or Zabbix)
- [ ] Configure all monitoring checks
- [ ] Set up Telegram bot for alerts
- [ ] Configure syslog aggregation
- [ ] Set up Pakistan offsite backup:
  - Configure Raspberry Pi 5
  - Set up WireGuard tunnel
  - Configure Borgbackup
  - Test initial full backup
- [ ] Set up Backblaze B2 (or chosen cloud provider):
  - Create bucket with Object Lock
  - Configure Restic
  - Test initial backup + restore

**Deliverables:**
- Remote VPN working with MFA
- Monitoring dashboard operational
- Alerting verified (test alerts sent)
- Pakistan offsite receiving backups
- Cloud offsite receiving backups
- Full 3-2-1 backup strategy operational

### Phase 6: Testing, Documentation & Handover (Week 6)

**Tasks:**

- [ ] Run all verification tests (see Section 15)
- [ ] External port scan (verify zero open ports from internet)
- [ ] 72-hour IPsec soak test
- [ ] DynDNS failover test
- [ ] Full restore from each backup copy
- [ ] IDS/IPS test (EICAR test file)
- [ ] Inter-VLAN isolation verification
- [ ] Ransomware lateral movement simulation
- [ ] Create runbook documents:
  - "How to add a new VPN user"
  - "How to restore from backup"
  - "What to do when a tunnel goes down"
  - "How to add a new branch"
  - "Emergency bypass procedure"
- [ ] Knowledge transfer session with staff
- [ ] Update network diagrams with final IPs and configs
- [ ] Store all passwords in a password manager (Bitwarden)

**Deliverables:**
- All tests passed
- Runbooks documented
- Knowledge transfer completed
- Deployment sign-off

---

## 15. Verification & Testing

### Test Matrix

| # | Test | Procedure | Expected Result | Pass/Fail |
|---|------|-----------|----------------|-----------|
| 1 | **External Port Scan** | Run `nmap -sS -p- <public-IP>` from outside UAE (use online scanner or VPS) | All ports filtered/closed. Zero open ports. | |
| 2 | **IPsec Tunnel Stability** | Leave all 6 tunnels running for 72 hours. Monitor with Uptime Kuma. | Zero unplanned drops. All tunnels show 100% uptime. | |
| 3 | **DPD Failover** | Reboot OPNsense at Branch 2. Monitor tunnels to Branch 2 from other branches. | Tunnels re-establish within 60-90 seconds after Branch 2 OPNsense comes back. | |
| 4 | **DynDNS Failover** | Change WAN IP on Branch 3 (restart broadband router or change ISP settings). | DDNS updates within 5 minutes. Tunnels re-establish within 2-5 minutes. | |
| 5 | **SQL Sync Over IPsec** | Run accounting software's sync function between Branch 1 and Branch 2. | Sync completes successfully. No errors. Data consistent. | |
| 6 | **Inter-VLAN Isolation** | From a VLAN 20 workstation at Branch 1, attempt to ping 10.2.10.10 (Branch 2 server VLAN). | Ping fails (blocked by firewall rules — workstations don't have IPsec access to other branch server VLANs). | |
| 7 | **Guest VLAN Isolation** | From a VLAN 99 device, attempt to access 10.x.10.0/24 (servers) and 10.x.30.0/24 (management). | All access blocked. Only internet (80/443) works. | |
| 8 | **IDS/IPS Detection** | Download EICAR test file (https://www.eicar.org/download-anti-malware-testfile/) through OPNsense. | Suricata blocks the download. Alert appears in IDS dashboard. | |
| 9 | **DNS Filtering** | Attempt to resolve known malware domains (e.g., domains from abuse.ch test list). | OPNsense Unbound returns NXDOMAIN (blocked). | |
| 10 | **Backup - Local Restore** | Restore a single file from Veeam backup on local NAS. | File restored successfully, content matches original. | |
| 11 | **Backup - Cross-Branch Restore** | Restore from partner branch NAS backup. | Full server restore successful, SQL databases consistent. | |
| 12 | **Backup - Offsite Restore** | Restore from Backblaze B2 / Pakistan offsite. | Data decrypted and restored successfully. | |
| 13 | **VPN - Remote Access** | Connect to IKEv2 VPN from external network (mobile hotspot). | VPN connects. Can RDP to server. TOTP MFA works. | |
| 14 | **VPN - Access Restriction** | From VPN, attempt to access workstation VLAN (10.x.20.0/24). | Access blocked (VPN firewall rules). | |
| 15 | **Ransomware Simulation** | From a VLAN 20 workstation, attempt to reach other VLANs and branches beyond allowed ports. | Only TCP 1433 (SQL) and TCP 445 (SMB) to local server VLAN work. Everything else blocked. | |
| 16 | **Windows Hardening Verify** | Run `nmap -sV 10.x.10.10` from VLAN 20. | Only ports 445 (SMB) and 1433 (SQL) open. No RDP. No NetBIOS. | |
| 17 | **Account Lockout** | Attempt 6 failed RDP logins to a server. | Account locks out after 5 attempts. Unlocks after 30 minutes. | |
| 18 | **Backup Immutability** | Attempt to delete a backup from Backblaze B2 within Object Lock retention period. | Delete fails. Object Lock prevents deletion. | |
| 19 | **NAS Snapshot Recovery** | Simulate ransomware by encrypting files on NAS share. Recover from NAS snapshot. | Snapshot contains clean files. Recovery successful. | |
| 20 | **Full DR Test** | Simulate complete Branch 1 loss. Restore server from offsite backup to new hardware at a different branch. | Server restored. SQL databases consistent. Accounting software functional. | |

### Post-Test Sign-Off

```
Test conducted by:    _________________________
Date:                 _________________________
All tests passed:     [ ] Yes  [ ] No (list failures below)

Failures / Notes:
_________________________________________________________
_________________________________________________________

Sign-off:             _________________________
```

---

## Appendix A: Key Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Firewall Platform | OPNsense (bare-metal) | Battle-tested, full-featured, excellent GUI, free |
| Edge Hardware | Topton N100 4x2.5GbE | 4 NICs, AES-NI, fanless, cheap, purpose-built |
| VPN Protocol | IKEv2 with certificates | Modern, FQDN peers, NAT-T, native clients |
| IDS/IPS | Suricata (ET Open rules) | Free, performant on N100, integrated in OPNsense |
| Authentication | Certificate-based (private CA) | Stronger than PSK, scalable |
| Backup Software | Veeam Community Edition | Free, SQL-aware, industry standard |
| Offsite Backup | Backblaze B2 + Pakistan Pi | Cloud immutability + physical sovereignty |
| Monitoring | Uptime Kuma + syslog | Lightweight, effective, free |
| Internet Routing | All through OPNsense | IDS/IPS + DNS filtering on all traffic |
| AV Solution | Windows Defender + Enterprise AV | Defense-in-depth, ASR rules for ransomware |

## Appendix B: Emergency Contacts & Procedures

### Emergency: Suspected Ransomware

1. **ISOLATE:** Disconnect affected server from network (pull cable)
2. **DO NOT** reboot or shut down (preserves forensic evidence)
3. **VERIFY:** Check other branches — are they affected?
4. **CHECK:** Are backups intact? (NAS snapshots, B2 Object Lock, Pakistan offsite)
5. **ASSESS:** Determine scope (which servers, which data)
6. **RESTORE:** If contained, restore from most recent clean backup
7. **INVESTIGATE:** How did they get in? (check Suricata logs, Windows Security logs)
8. **REPORT:** File incident report. Notify stakeholders.
9. **HARDEN:** Address the entry vector. Update rules/policies.

### Emergency: OPNsense Failure

1. Branch internet and inter-branch connectivity goes down
2. **Bypass:** Configure workstations to use broadband router as gateway (internet-only)
3. **Restore:** Re-flash OPNsense, restore from XML config backup
4. **Recovery time:** ~30 minutes with prepared USB

### Emergency: IPsec Tunnel Down

1. Check OPNsense dashboard (VPN > IPsec > Status Overview)
2. If "Connecting" — wait 2 minutes (DPD recovery in progress)
3. If "Disconnected" — check remote branch status (broadband outage?)
4. Try: Disconnect + reconnect tunnel from OPNsense GUI
5. Check DynDNS — has the remote IP changed? Resolve FQDN and verify.
6. If persistent: check OPNsense logs (System > Log Files > IPsec)

---

*This document serves as the complete architecture reference and implementation guide for the FastPartz Security & SD-WAN deployment. It should be reviewed and updated after each implementation phase.*
