# FastPartz — Implementation Guide

**Companion document to [solution.md](solution.md)**
This file contains step-by-step technical instructions, configurations, scripts, and commands.

---

## Table of Contents

1. [OPNsense Installation & Base Setup](#1-opnsense-installation--base-setup)
2. [VLAN & Interface Configuration](#2-vlan--interface-configuration)
3. [Firewall Rules](#3-firewall-rules)
4. [Suricata IDS/IPS Setup](#4-suricata-idsips-setup)
5. [DNS Filtering (Unbound + DNSBL)](#5-dns-filtering-unbound--dnsbl)
6. [Certificate Authority & IPsec Setup](#6-certificate-authority--ipsec-setup)
7. [Dynamic DNS Configuration](#7-dynamic-dns-configuration)
8. [DHCP, NTP & Syslog](#8-dhcp-ntp--syslog)
9. [OPNsense Config Backup](#9-opnsense-config-backup)
10. [Windows Server Hardening — Commands & Scripts](#10-windows-server-hardening--commands--scripts)
11. [Veeam Backup Configuration](#11-veeam-backup-configuration)
12. [Cross-Branch Replication (rsync)](#12-cross-branch-replication-rsync)
13. [Offsite Backup — Cloud (Restic + Backblaze B2)](#13-offsite-backup--cloud-restic--backblaze-b2)
14. [Offsite Backup — Pakistan NAS (Borgbackup)](#14-offsite-backup--pakistan-nas-borgbackup)
15. [Roadwarrior VPN Configuration](#15-roadwarrior-vpn-configuration)
16. [Windows Log Forwarding (NXLog)](#16-windows-log-forwarding-nxlog)
17. [Monitoring (Uptime Kuma)](#17-monitoring-uptime-kuma)
18. [Telegram Bot Alerts](#18-telegram-bot-alerts)
19. [Managed Switch Configuration](#19-managed-switch-configuration)
20. [Verification & Testing Procedures](#20-verification--testing-procedures)

---

## 1. OPNsense Installation & Base Setup

### Download & Install

1. Download OPNsense ISO (amd64, vga) from https://opnsense.org/download/
2. Flash to USB with Rufus (Windows) or `dd` (macOS/Linux):
   ```bash
   dd if=OPNsense-*.img of=/dev/sdX bs=4M status=progress
   ```
3. Boot N100 mini-PC from USB
4. Follow installer: choose UFS filesystem, select target NVMe drive
5. Reboot, remove USB

### Initial Console Setup

After first boot, at the console:

```
Assign interfaces:
  WAN: igc0 (first NIC — connects to broadband router)
  LAN: igc1 (second NIC — connects to managed switch trunk)

Set LAN IP:
  10.x.30.1/24  (x = branch number: 1, 2, 3, or 4)
```

### First WebGUI Access

1. Connect a PC to the managed switch (or directly to LAN port temporarily)
2. Set PC IP to `10.x.30.10/24`, gateway `10.x.30.1`
3. Browse to `https://10.x.30.1`
4. Login: `root` / `opnsense`
5. **Immediately change the default password**

### Base Configuration (System > Settings > General)

```
Hostname:       branch1-fw  (or branch2-fw, branch3-fw, branch4-fw)
Domain:         fastpartz.local
Timezone:       Asia/Dubai
DNS Servers:    1.1.1.1, 9.9.9.9  (temporary — Unbound will handle DNS later)
```

### WAN Interface

```
Interface:      igc0
IPv4 Type:      DHCP (or Static if ISP provides)
Block private:  Enabled
Block bogon:    Enabled
```

### Enable SSH (Management VLAN only)

System > Settings > Administration:

```
SSH:            Enabled
Listen:         Management VLAN interface only (10.x.30.1)
Auth method:    Public key only (paste your SSH public key)
Root login:     Disabled (use a non-root user)
```

---

## 2. VLAN & Interface Configuration

### Create VLANs

Interfaces > Other Types > VLAN > Add:

| VLAN Tag | Parent Interface | Description |
|----------|-----------------|-------------|
| 10 | igc1 (LAN) | SERVERS |
| 20 | igc1 (LAN) | WORKSTATIONS |
| 30 | igc1 (LAN) | MANAGEMENT |
| 99 | igc1 (LAN) | GUEST |

### Assign VLAN Interfaces

Interfaces > Assignments > Add each VLAN:

| Interface Name | Network Port | IPv4 Address | Description |
|---------------|-------------|-------------|-------------|
| SERVERS | vlan01 (igc1, tag 10) | 10.x.10.1/24 | Server VLAN |
| WORKSTATIONS | vlan02 (igc1, tag 20) | 10.x.20.1/24 | Workstation VLAN |
| MANAGEMENT | vlan03 (igc1, tag 30) | 10.x.30.1/24 | Management VLAN |
| GUEST | vlan04 (igc1, tag 99) | 10.x.99.1/24 | Guest/IoT VLAN |

Replace `x` with the branch number (1, 2, 3, or 4).

**Enable each interface** after creating it (Interfaces > [Name] > Enable).

**Remove the default LAN assignment** — the parent igc1 interface should have no IP; VLANs handle all addressing.

---

## 3. Firewall Rules

### WAN Rules (Firewall > Rules > WAN)

```
#  Action   Proto   Source   Dest          Port      Description
1  ALLOW    UDP     *        WAN address   500       IKE (IPsec)
2  ALLOW    UDP     *        WAN address   4500      NAT-T (IPsec)
— (implicit deny all inbound)
```

**That's it. Zero other inbound ports.**

### SERVERS VLAN Rules (Firewall > Rules > SERVERS)

```
#  Action   Proto   Source         Dest                Port    Description
1  ALLOW    TCP     SERVERS net    10.0.0.0/8          1433    SQL sync to other branches (IPsec)
2  ALLOW    TCP     SERVERS net    Internet             80,443  Windows Update
3  ALLOW    TCP     SERVERS net    NAS IP (10.x.10.20) 445,873 Backup to NAS (SMB, rsync)
4  ALLOW    UDP     SERVERS net    SERVERS GW           53      DNS via OPNsense
5  ALLOW    UDP     SERVERS net    *                    123     NTP
6  DENY     *       SERVERS net    WORKSTATIONS net     *       Block server-to-workstation
7  DENY     *       SERVERS net    GUEST net            *       Block server-to-guest
8  DENY     *       SERVERS net    *                    *       Default deny (log)
```

### WORKSTATIONS VLAN Rules (Firewall > Rules > WORKSTATIONS)

```
#  Action   Proto   Source         Dest            Port       Description
1  ALLOW    TCP     WKSTNS net     SERVERS net     1433       SQL (accounting software)
2  ALLOW    TCP     WKSTNS net     SERVERS net     445        SMB (file shares)
3  ALLOW    TCP     WKSTNS net     Internet        80,443     Web browsing
4  ALLOW    TCP     WKSTNS net     GUEST net       9100,631   Printing
5  ALLOW    UDP     WKSTNS net     WKSTNS GW       53         DNS via OPNsense
6  DENY     *       WKSTNS net     MGMT net        *          Block access to management
7  DENY     *       WKSTNS net     *               *          Default deny (log)
```

### MANAGEMENT VLAN Rules (Firewall > Rules > MANAGEMENT)

```
#  Action   Proto   Source        Dest    Port   Description
1  ALLOW    *       MGMT net     *       *      Full access (management)
```

### GUEST VLAN Rules (Firewall > Rules > GUEST)

```
#  Action   Proto   Source       Dest            Port     Description
1  DENY     *       GUEST net   10.0.0.0/8      *        Block ALL private subnets
2  ALLOW    TCP     GUEST net   Internet        80,443   Web browsing only
3  ALLOW    UDP     GUEST net   GUEST GW        53       DNS via OPNsense
4  DENY     *       GUEST net   *               *        Default deny (log)
```

### IPsec Interface Rules (Firewall > Rules > IPsec)

```
#  Action   Proto   Source           Dest             Port   Description
1  ALLOW    TCP     10.0.0.0/8       10.0.0.0/8       1433   SQL sync between branches
2  ALLOW    *       10.x.30.0/24     10.0.0.0/8       *      Management full access
3  DENY     *       *                *                 *      Default deny (log)
```

---

## 4. Suricata IDS/IPS Setup

### Install Plugin

System > Firmware > Plugins > search `os-suricata` > Install

### Configuration (Services > Intrusion Detection > Administration)

**Settings tab:**

```
Enabled:                    Yes
IPS Mode:                   Enabled (inline blocking)
Promiscuous mode:           Enabled
Pattern matcher:            Hyperscan
Interfaces:                 WAN, SERVERS, WORKSTATIONS
Home networks:              10.1.0.0/16, 10.2.0.0/16, 10.3.0.0/16, 10.4.0.0/16
Default packet size:        1518
```

**Download tab — Enable these rulesets:**

```
☑ ET open/emerging-attack_response
☑ ET open/emerging-current_events
☑ ET open/emerging-exploit
☑ ET open/emerging-malware
☑ ET open/emerging-phishing
☑ ET open/emerging-scan
☑ ET open/emerging-trojan
☑ ET open/emerging-worm
☑ Abuse.ch/SSL Blacklist
☑ Abuse.ch/URLhaus
☑ Abuse.ch/Feodo Tracker
```

Click **Download & Update Rules**.

**Schedule tab:**

```
Enable:     Yes
Frequency:  Daily
Time:       03:00
```

### Performance Notes

- N100 with ET Open (~35,000 rules): ~800 Mbps throughput
- CPU usage: ~30-40% at full load
- Memory: ~1.5 GB for rule loading
- Monitor via Services > Intrusion Detection > Alerts

---

## 5. DNS Filtering (Unbound + DNSBL)

### Base Unbound Configuration (Services > Unbound DNS > General)

```
Enable:                 Yes
Listen port:            53
Network interfaces:     All (SERVERS, WORKSTATIONS, MANAGEMENT, GUEST)
DNSSEC:                 Enabled
DNS64:                  Disabled
DHCP registration:      Enabled
```

### DNS-over-TLS Forwarding (Services > Unbound DNS > DNS over TLS)

```
Enable forwarding:      Yes

Server 1:
  Address:  1.1.1.1
  Port:     853
  Hostname: cloudflare-dns.com

Server 2:
  Address:  9.9.9.9
  Port:     853
  Hostname: dns.quad9.net
```

### Blocklist Configuration (Services > Unbound DNS > Blocklist)

```
Enable:     Yes
Type:       DNSBL (URL-based blocklists)

Blocklists:
  ☑ Steven Black Unified Hosts (ads + malware + phishing)
  ☑ Abuse.ch URLhaus Domain Blocklist
  ☑ Malware Domain List
  ☑ Phishing Army Extended Blocklist

Whitelist:
  (Add any false-positive domains here as needed)

Destination address:    (leave default — returns NXDOMAIN for blocked domains)
```

Apply and restart Unbound.

---

## 6. Certificate Authority & IPsec Setup

### Step 1: Create Root CA (on Branch 1 OPNsense only)

System > Trust > Authorities > Add:

```
Method:             Create an internal Certificate Authority
Descriptive name:   FastPartz Root CA
Key Type:           RSA
Key length:         4096
Digest Algorithm:   SHA384
Lifetime:           3650 (10 years)
Country:            AE
State:              Dubai
City:               Dubai
Organization:       FastPartz
Common Name:        FastPartz Root CA
```

Save. This creates the Root CA with both public and private key on Branch 1.

### Step 2: Export Root CA Certificate

System > Trust > Authorities > FastPartz Root CA > Export (certificate only, NOT the key).

Save the `.crt` file — you'll import this on Branch 2, 3, 4.

### Step 3: Import Root CA on Other Branches

On Branch 2, 3, 4 OPNsense:

System > Trust > Authorities > Add:

```
Method:             Import an existing Certificate Authority
Descriptive name:   FastPartz Root CA
Certificate data:   (paste the .crt contents)
```

**Do NOT import the private key** — only Branch 1 holds the CA private key.

### Step 4: Create Server Certificates

On Branch 1 (where the CA private key lives), create server certs for ALL branches:

System > Trust > Certificates > Add:

```
Method:             Create an internal Certificate
Certificate authority: FastPartz Root CA
Type:               Server Certificate
Key Type:           ECDSA
Key length:         384
Digest Algorithm:   SHA384
Lifetime:           730 (2 years)
Common Name:        branch1.fastpartz.dynu.net
Alternative Names:  DNS: branch1.fastpartz.dynu.net
```

Repeat for branch2, branch3, branch4 (changing CN and SAN).

Export each certificate as PKCS#12 (.p12) and import on the respective branch's OPNsense (System > Trust > Certificates > Import).

### Step 5: Configure IPsec Tunnels

**VPN > IPsec > Tunnel Settings > Add Phase 1**

Example: Branch 1 ↔ Branch 2:

```
Connection method:      Default
Key Exchange version:   IKEv2
Internet Protocol:      IPv4
Interface:              WAN
Remote gateway:         branch2.fastpartz.dynu.net
Description:            Branch1-to-Branch2

Authentication method:  Mutual Certificate
My Certificate:         branch1.fastpartz.dynu.net
Peer Certificate Authority: FastPartz Root CA
My identifier:          Distinguished Name (from cert)
Peer identifier:        Distinguished Name (from cert)

Encryption algorithm:   AES-256-GCM (128-bit ICV)
Hash algorithm:         SHA384
DH Key Group:           20 (NIST P-384)
Lifetime:               28800

Dead Peer Detection:
  Enable:               Yes
  Delay:                10 seconds
  Max failures:         5
```

**VPN > IPsec > Tunnel Settings > Add Phase 2** (under the Phase 1 above):

```
Mode:                   Tunnel IPv4
Local Network:          10.1.10.0/24 (Branch 1 Server VLAN)
Remote Network:         10.2.10.0/24 (Branch 2 Server VLAN)
Description:            B1-B2-Servers

Protocol:               ESP
Encryption:             AES-256-GCM (128-bit ICV)
Hash:                   SHA384
PFS Key Group:          20 (NIST P-384)
Lifetime:               3600
```

Add a second Phase 2 for Management VLAN if needed:

```
Local Network:          10.1.30.0/24
Remote Network:         10.2.30.0/24
Description:            B1-B2-Management
```

### Full Mesh — Repeat for All Pairs

Each branch needs 3 Phase 1 entries (one per remote branch):

| On Branch 1 | Phase 1 to: | Server Phase 2 | Mgmt Phase 2 |
|-------------|------------|----------------|---------------|
| | Branch 2 | 10.1.10.0/24 ↔ 10.2.10.0/24 | 10.1.30.0/24 ↔ 10.2.30.0/24 |
| | Branch 3 | 10.1.10.0/24 ↔ 10.3.10.0/24 | 10.1.30.0/24 ↔ 10.3.30.0/24 |
| | Branch 4 | 10.1.10.0/24 ↔ 10.4.10.0/24 | 10.1.30.0/24 ↔ 10.4.30.0/24 |

Replicate this pattern on Branch 2 (peers: B1, B3, B4), Branch 3 (peers: B1, B2, B4), Branch 4 (peers: B1, B2, B3).

### Enable IPsec

VPN > IPsec > Tunnel Settings > Enable IPsec (checkbox at top) > Save > Apply.

---

## 7. Dynamic DNS Configuration

### OPNsense DDNS Setup

Services > Dynamic DNS > Add:

```
Service type:       Dynu  (or Cloudflare if using own domain)
Interface:          WAN
Username:           <Dynu account email or API ID>
Password:           <Dynu API key>
Hostname:           branch1.fastpartz.dynu.net
Check interval:     300 (seconds)
Force update:       Enabled
Description:        Branch 1 DDNS
```

Save and apply. Test by checking Services > Dynamic DNS — status should show "Updated".

### Broadband Router Configuration

**Option A (best): Bridge mode**
- ISP router passes public IP directly to OPNsense WAN
- OPNsense gets the public IP via DHCP

**Option B: DMZ mode**
- ISP router keeps the public IP
- Set OPNsense WAN IP (e.g., 192.168.1.2) as DMZ host
- All inbound traffic forwarded to OPNsense

**Option C (minimum): Port forwarding**
- Forward UDP 500 + UDP 4500 to OPNsense WAN IP
- Less ideal — double NAT may cause issues

---

## 8. DHCP, NTP & Syslog

### DHCP Server (Services > DHCPv4)

**WORKSTATIONS VLAN (VLAN 20):**

```
Enable:         Yes
Range:          10.x.20.100 — 10.x.20.200
Gateway:        10.x.20.1
DNS Server:     10.x.20.1 (OPNsense Unbound)
Domain:         fastpartz.local
Default lease:  86400 (24 hours)
```

**GUEST VLAN (VLAN 99):**

```
Enable:         Yes
Range:          10.x.99.100 — 10.x.99.200
Gateway:        10.x.99.1
DNS Server:     10.x.99.1 (OPNsense Unbound)
Default lease:  3600 (1 hour)
```

**SERVERS (VLAN 10) and MANAGEMENT (VLAN 30):** No DHCP — all static IPs.

### NTP (Services > NTP > General)

```
Enable:         Yes
Interface:      SERVERS, WORKSTATIONS, MANAGEMENT
NTP Servers:    0.pool.ntp.org, 1.pool.ntp.org, 2.pool.ntp.org
Orphan mode:    Enabled (serve time even if upstream is unreachable)
```

Point all Windows Servers and PCs to OPNsense as NTP source:
```powershell
w32tm /config /manualpeerlist:"10.x.10.1" /syncfromflags:manual /reliable:YES /update
Restart-Service w32time
```

### Syslog (System > Settings > Logging / Targets)

```
Enable remote logging:  Yes
Add target:
  Transport:            UDP
  Target:               10.1.10.30:514  (central syslog server or NAS)
  Facilities:           All
  Levels:               Warning, Error, Critical, Alert, Emergency

Log firewall default blocks: Yes
```

---

## 9. OPNsense Config Backup

### Method 1: Built-in Google Drive / Nextcloud Backup

System > Configuration > Backups:

```
Provider:       Google Drive  (or Nextcloud)
Frequency:      Daily
Encryption:     Set a password
```

### Method 2: Manual Export

System > Configuration > Backups > Download configuration:

- Save `config-branchX-YYYYMMDD.xml`
- Store on NAS and/or git repository
- Keep at least 30 days of backups

### Method 3: Cron Script to NAS

System > Settings > Cron > Add:

```
Minute:     0
Hour:       2
Day:        *
Command:    /conf/backup/backup_config.sh
Description: Daily config backup to NAS
```

Create `/conf/backup/backup_config.sh`:

```bash
#!/bin/sh
CONFIG="/conf/config.xml"
NAS="10.x.10.20"
DATE=$(date +%Y%m%d)
DEST="/volume1/opnsense-backup/"

scp "$CONFIG" "backup@${NAS}:${DEST}config-branch1-${DATE}.xml"
```

Make executable:
```bash
chmod +x /conf/backup/backup_config.sh
```

---

## 10. Windows Server Hardening — Commands & Scripts

### Enable Windows Defender + Tamper Protection

```powershell
# Verify Defender is active
Get-MpComputerStatus | Select-Object AntivirusEnabled, RealTimeProtectionEnabled, IoavProtectionEnabled

# Enable Tamper Protection (must be done via Windows Security GUI or Intune)
# Windows Security > Virus & threat protection > Settings > Tamper Protection = ON

# Enable cloud protection
Set-MpPreference -MAPSReporting Advanced
Set-MpPreference -SubmitSamplesConsent SendAllSamples
```

### Enable Attack Surface Reduction (ASR) Rules

```powershell
# Enable key ASR rules
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
    Add-MpPreference -AttackSurfaceReductionRules_Ids $rule `
        -AttackSurfaceReductionRules_Actions Enabled
}

# Verify ASR rules
Get-MpPreference | Select-Object -ExpandProperty AttackSurfaceReductionRules_Ids
```

### Configure Windows Firewall

```powershell
# Enable firewall on all profiles
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Default deny inbound
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block

# Allow SQL from internal subnets only
New-NetFirewallRule -DisplayName "SQL Server - Branch Traffic" `
    -Direction Inbound -Protocol TCP -LocalPort 1433 `
    -RemoteAddress 10.0.0.0/8 -Action Allow

# Allow RDP from management VLAN only
New-NetFirewallRule -DisplayName "RDP - Management VLAN" `
    -Direction Inbound -Protocol TCP -LocalPort 3389 `
    -RemoteAddress 10.0.0.0/8 -Action Allow

# Allow SMB from workstation VLAN
New-NetFirewallRule -DisplayName "SMB - Internal" `
    -Direction Inbound -Protocol TCP -LocalPort 445 `
    -RemoteAddress 10.0.0.0/8 -Action Allow

# Allow ICMP (ping) from internal
New-NetFirewallRule -DisplayName "ICMP - Internal" `
    -Direction Inbound -Protocol ICMPv4 `
    -RemoteAddress 10.0.0.0/8 -Action Allow
```

### Bind SQL Server to VLAN 10 IP Only

```
SQL Server Configuration Manager:
  SQL Server Network Configuration > Protocols for MSSQLSERVER > TCP/IP > IP Addresses:
    - IP All: Clear TCP Port and TCP Dynamic Ports
    - Find the entry for 10.x.10.10 (server's VLAN 10 IP)
    - Set TCP Port = 1433
    - Set Active = Yes, Enabled = Yes
    - All other IP entries: set Enabled = No

Restart SQL Server service after changes.
```

### Disable Unnecessary Protocols

```powershell
# Disable SMBv1
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart

# Disable NetBIOS over TCP/IP (all adapters)
Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true } |
    ForEach-Object { $_.SetTcpipNetbios(2) }  # 2 = Disable

# Disable PowerShell v2
Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root -NoRestart
Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2 -NoRestart

# Disable LLMNR (registry)
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" `
    -Name "EnableMulticast" -Value 0 -Type DWord

# Disable WPAD
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WinHttpAutoProxySvc" `
    -Name "Start" -Value 4 -Type DWord
```

### Configure RDP Security

```powershell
# Require NLA (Network Level Authentication)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
    -Name "UserAuthentication" -Value 1

# Set RDP encryption level to High
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
    -Name "MinEncryptionLevel" -Value 3
```

### Account Policies

```powershell
# Account lockout (via secpol.msc or net accounts)
net accounts /lockoutthreshold:5
net accounts /lockoutduration:30
net accounts /lockoutwindow:30

# Password policy
net accounts /minpwlen:14
net accounts /maxpwage:90
net accounts /minpwage:1
net accounts /uniquepw:12
```

### Rename Default Administrator

```powershell
Rename-LocalUser -Name "Administrator" -NewName "sysadm_fp"
```

### Enable Audit Logging

```powershell
auditpol /set /category:"Account Logon" /success:enable /failure:enable
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /category:"Object Access" /success:enable /failure:enable
auditpol /set /category:"Policy Change" /success:enable /failure:enable
auditpol /set /category:"Privilege Use" /failure:enable
auditpol /set /category:"System" /success:enable /failure:enable
```

### AppLocker Basic Configuration

```
secpol.msc > Application Control Policies > AppLocker:

Executable Rules (create default rules first):
  ALLOW: Everyone — %WINDIR%\*
  ALLOW: Everyone — %PROGRAMFILES%\*
  ALLOW: BUILTIN\Administrators — *
  DENY:  Everyone — %USERPROFILE%\*
  DENY:  Everyone — %TEMP%\*
  DENY:  Everyone — %APPDATA%\*

Start the Application Identity service:
  Set-Service AppIDSvc -StartupType Automatic
  Start-Service AppIDSvc
```

---

## 11. Veeam Backup Configuration

### Install Veeam Community Edition

1. Download from https://www.veeam.com/virtual-machine-backup-solution-free.html
2. Install on the master branch Windows Server
3. Community Edition is free for up to 10 workloads

### Create Backup Job

```
Job Name:           Branch1-DailyBackup
Source:              Branch 1 Windows Server (all volumes)
Destination:        \\10.x.10.20\veeam-backup\ (Synology NAS SMB share)

Schedule:
  Run job:          Daily at 22:00
  Retry:            3 times, wait 10 minutes

Backup mode:
  Incremental:      Daily
  Active full:      Every Sunday

Retention:          14 restore points

Advanced:
  Application-aware processing:  Enabled
  Guest OS credentials:          (domain admin or local admin)
  Transaction logs:
    SQL Server:     Process transaction logs
    Log backup interval: Every 15 minutes

  Storage:
    Enable backup file encryption: Yes
    Password:       (set a strong encryption password — document securely)
    Compression:    Optimal

  Notifications:
    Email:          admin@fastpartz.ae
    Send on:        Failure, Warning
```

### Synology NAS Preparation

```
1. Create shared folder: "veeam-backup"
2. Create user: "veeam-svc" with read/write access to the share
3. Enable SMB (Control Panel > File Services > SMB)
4. Enable Snapshot Replication:
   - Snapshot Schedule: Daily at 01:00 (after Veeam completes)
   - Retain: 7 snapshots
   - This provides immutable backup copies
```

---

## 12. Cross-Branch Replication (rsync)

### Setup on Synology NAS

Enable rsync: Control Panel > File Services > rsync > Enable rsync service.

Create rsync module in `/etc/rsyncd.conf`:
```
[cross-branch-backup]
path = /volume1/cross-branch-backup
comment = Cross-branch backup replication
uid = backup
gid = users
read only = false
auth users = backup
secrets file = /etc/rsyncd.secrets
```

### Replication Script (runs on source NAS, Task Scheduler)

```bash
#!/bin/bash
# Cross-branch backup replication
# Schedule: Daily at 01:00 (after Veeam completes)

SOURCE="/volume1/veeam-backup/"
DEST="rsync://backup@10.2.10.20/cross-branch-backup/branch1/"
LOG="/var/log/cross-branch-sync.log"

echo "$(date): Starting cross-branch sync" >> "$LOG"

rsync -avz --delete \
    --bwlimit=10000 \
    --log-file="$LOG" \
    "$SOURCE" "$DEST"

EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    # Alert on failure (see Telegram section)
    /usr/local/bin/send_telegram_alert.sh \
        "ALERT: Cross-branch backup sync FAILED (exit code: $EXIT_CODE)"
fi

echo "$(date): Sync completed with exit code $EXIT_CODE" >> "$LOG"
```

---

## 13. Offsite Backup — Cloud (Restic + Backblaze B2)

### Backblaze B2 Setup

1. Create B2 account at https://www.backblaze.com/b2/
2. Create bucket: `fastpartz-backup` with Object Lock enabled
3. Create application key with read/write access to the bucket
4. Set default retention: 30 days (Governance mode)

### Install Restic

```bash
# On Synology (if running Linux) or Windows Server
# Linux:
apt install restic

# Windows (download binary):
# https://github.com/restic/restic/releases
```

### Initialize Repository

```bash
export B2_ACCOUNT_ID="your-account-id"
export B2_ACCOUNT_KEY="your-account-key"
export RESTIC_PASSWORD="your-strong-repo-password"

restic -r b2:fastpartz-backup:/ init
```

### Backup Script (Weekly Full + Daily Incremental)

```bash
#!/bin/bash
# Offsite cloud backup via Restic + Backblaze B2
# Schedule: Daily at 03:00

export B2_ACCOUNT_ID="your-account-id"
export B2_ACCOUNT_KEY="your-account-key"
export RESTIC_PASSWORD="your-strong-repo-password"
REPO="b2:fastpartz-backup:/"

# Create backup
restic -r "$REPO" backup /volume1/veeam-backup/ \
    --exclude-caches \
    --tag "daily" \
    --verbose

# Apply retention policy
restic -r "$REPO" forget \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6 \
    --prune

# Weekly integrity check (Sundays)
if [ "$(date +%u)" -eq 7 ]; then
    restic -r "$REPO" check
fi

# Alert on failure
if [ $? -ne 0 ]; then
    /usr/local/bin/send_telegram_alert.sh \
        "ALERT: Offsite cloud backup FAILED"
fi
```

---

## 14. Offsite Backup — Pakistan NAS (Borgbackup)

### NAS Setup at Pakistan Location

1. Set up Synology DS223 (or TerraMaster F2-223) with 2x 4TB drives in RAID 1
2. Install Borgbackup (if Synology, use Docker or community package)
3. Create backup user and repository directory
4. Connect to UAE via VPN tunnel (WireGuard or IPsec)

### VPN Tunnel (WireGuard on NAS)

**UAE OPNsense side:**

Install WireGuard plugin (`os-wireguard`). Create a peer:

```
Endpoint:           (Pakistan NAS public IP or DDNS)
Public Key:         (Pakistan NAS WireGuard public key)
Allowed IPs:        10.100.0.2/32
Tunnel Address:     10.100.0.1/30
Listen Port:        51820
```

**Pakistan NAS side** (`/etc/wireguard/wg0.conf`):

```ini
[Interface]
PrivateKey = <pakistan-nas-private-key>
Address = 10.100.0.2/30

[Peer]
PublicKey = <opnsense-public-key>
Endpoint = branch1.fastpartz.dynu.net:51820
AllowedIPs = 10.1.0.0/16, 10.2.0.0/16, 10.3.0.0/16, 10.4.0.0/16
PersistentKeepalive = 25
```

### Initialize Borg Repository

```bash
# On Pakistan NAS
borg init --encryption=repokey-blake2 /volume1/borg-repos/fastpartz
```

### Borg Backup Script (runs from UAE NAS/server)

```bash
#!/bin/bash
# Offsite Borg backup to Pakistan NAS
# Schedule: Daily at 04:00

export BORG_REPO="ssh://backup@10.100.0.2/volume1/borg-repos/fastpartz"
export BORG_PASSPHRASE="your-strong-encryption-passphrase"

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

# Weekly integrity check
if [ "$(date +%u)" -eq 7 ]; then
    borg check "${BORG_REPO}"
fi

# Alert on failure
if [ $? -ne 0 ]; then
    /usr/local/bin/send_telegram_alert.sh \
        "ALERT: Pakistan offsite backup FAILED"
fi
```

### Append-Only Mode (Immutability)

On Pakistan NAS, restrict the SSH key in `/home/backup/.ssh/authorized_keys`:

```
command="borg serve --restrict-to-path /volume1/borg-repos --append-only",restrict ssh-rsa AAAA... backup@synology-uae
```

The `--append-only` flag means the UAE client can create but NOT delete archives. Only local access on the Pakistan NAS can prune old backups.

---

## 15. Roadwarrior VPN Configuration

### OPNsense Mobile Client Setup

**VPN > IPsec > Mobile Clients:**

```
Enable:                     Yes
User Authentication:        Local Database
Group Authentication:       None
Virtual Address Pool:       10.10.10.0/24
Virtual IPv4 Pool:          10.10.10.100 — 10.10.10.200
Network List:               Provide
  - 10.1.0.0/16
  - 10.2.0.0/16
  - 10.3.0.0/16
  - 10.4.0.0/16
DNS Servers:                10.10.10.1
Default Domain:             fastpartz.local
Split Tunneling:            Yes (only branch traffic through VPN)
```

**Phase 1 (VPN > IPsec > Tunnel Settings > Add Phase 1):**

```
Connection method:      Respond only
Key Exchange:           IKEv2
Interface:              WAN
Description:            Mobile-VPN

Authentication:         EAP-MSCHAPv2
My Certificate:         branch1.fastpartz.dynu.net

Encryption:             AES-256-GCM
Hash:                   SHA384
DH Group:               20 (NIST P-384)
Lifetime:               28800
```

**Phase 2 (Add under the Phase 1 above):**

```
Mode:                   Tunnel
Local Network:          0.0.0.0/0 (or specific subnets for split tunnel)
Protocol:               ESP
Encryption:             AES-256-GCM
PFS:                    Group 20
Lifetime:               3600
```

### Create VPN Users

System > Access > Users > Add:

```
Username:       john.admin
Password:       (strong password)
Certificate:    (generate a user certificate signed by Root CA)
OTP Seed:       (generate — user scans QR with authenticator app)
Group:          vpn-users
```

### TOTP MFA Setup

1. Install plugin: System > Firmware > Plugins > `os-totp`
2. System > Access > Servers > Add:
   ```
   Name:           TOTP
   Type:           Local + Timebased One Time Password
   Token length:   6
   Time window:    30 seconds
   ```
3. Assign the TOTP server as the authentication source for VPN

**Login flow:** User enters `<password><TOTP-code>` as the password in their VPN client. OPNsense separates and validates both.

### Windows Client Setup

```
Settings > Network & Internet > VPN > Add VPN:
  Provider:           Windows (built-in)
  Connection name:    FastPartz VPN
  Server:             branch1.fastpartz.dynu.net
  VPN type:           IKEv2
  Sign-in info:       Username and password
  Username:           john.admin
  Password:           <password><TOTP-code>
```

Import Root CA certificate: `certlm.msc > Trusted Root Certification Authorities > Import`.

### macOS Client Setup

```
System Settings > Network > + > VPN:
  Type:               IKEv2
  Server:             branch1.fastpartz.dynu.net
  Remote ID:          branch1.fastpartz.dynu.net
  Authentication:     Username
```

Install Root CA in Keychain Access, mark as "Always Trust".

---

## 16. Windows Log Forwarding (NXLog)

### Install NXLog Community Edition

Download from https://nxlog.co/downloads/nxlog-ce

### Configuration File (`C:\Program Files\nxlog\conf\nxlog.conf`)

```xml
## NXLog configuration for Windows Security log forwarding

define ROOT C:\Program Files\nxlog

Moduledir %ROOT%\modules
CacheDir  %ROOT%\data
Pidfile   %ROOT%\data\nxlog.pid
SpoolDir  %ROOT%\data
LogFile   %ROOT%\data\nxlog.log

<Extension _syslog>
    Module  xm_syslog
</Extension>

<Input in_eventlog>
    Module      im_msvistalog
    <QueryXML>
        <QueryList>
            <Query Id="0">
                <Select Path="Security">*[System[(Level=1 or Level=2 or Level=3 or Level=4) and (EventID=4625 or EventID=4624 or EventID=4720 or EventID=4732 or EventID=7045 or EventID=1102 or EventID=4648 or EventID=4672)]]</Select>
                <Select Path="System">*[System[(Level=1 or Level=2 or Level=3)]]</Select>
                <Select Path="Application">*[System[(Level=1 or Level=2 or Level=3)]]</Select>
            </Query>
        </QueryList>
    </QueryXML>
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

### Key Event IDs Forwarded

| Event ID | Description |
|----------|-------------|
| 4624 | Successful logon |
| 4625 | Failed logon |
| 4648 | Logon using explicit credentials |
| 4672 | Special privileges assigned |
| 4720 | User account created |
| 4732 | Member added to security group |
| 7045 | New service installed |
| 1102 | Audit log cleared |

### Start NXLog Service

```powershell
Set-Service nxlog -StartupType Automatic
Start-Service nxlog
```

---

## 17. Monitoring (Uptime Kuma)

### Deploy via Docker (on NAS or any Linux host)

```bash
docker run -d \
    --name uptime-kuma \
    -p 3001:3001 \
    -v uptime-kuma-data:/app/data \
    --restart unless-stopped \
    louislam/uptime-kuma:latest
```

Access at `http://<nas-ip>:3001`. Create admin account on first run.

### Monitoring Checks to Configure

| Monitor Name | Type | Target | Interval | Alert After |
|-------------|------|--------|----------|-------------|
| Branch 2 IPsec | TCP Ping | 10.2.10.1:443 | 60s | 2 min down |
| Branch 3 IPsec | TCP Ping | 10.3.10.1:443 | 60s | 2 min down |
| Branch 4 IPsec | TCP Ping | 10.4.10.1:443 | 60s | 2 min down |
| B1 SQL Server | TCP | 10.1.10.10:1433 | 30s | 1 min down |
| B1 OPNsense | HTTPS | https://10.1.30.1 | 60s | 2 min down |
| B1 NAS | TCP Ping | 10.1.10.20:5000 | 60s | 5 min down |
| Pakistan Offsite | TCP Ping | 10.100.0.2:22 | 300s | 15 min down |

### Alert Integration

In Uptime Kuma Settings > Notifications:

- Add **Telegram** notification:
  - Bot Token: `<your-bot-token>`
  - Chat ID: `<your-chat-id>`

- Add **Email (SMTP)** notification:
  - Host: smtp.gmail.com (or M365)
  - Port: 587 (TLS)
  - From: alerts@fastpartz.ae
  - To: admin@fastpartz.ae

---

## 18. Telegram Bot Alerts

### Create Telegram Bot

1. Open Telegram, search for `@BotFather`
2. Send `/newbot`, follow prompts
3. Save the bot token: `123456:ABC-DEF...`
4. Create a group or channel, add the bot
5. Get the chat ID: send a message to the bot, then visit `https://api.telegram.org/bot<TOKEN>/getUpdates`

### Alert Script

Save as `/usr/local/bin/send_telegram_alert.sh`:

```bash
#!/bin/bash
# Send alert to Telegram
# Usage: send_telegram_alert.sh "Your alert message"

TELEGRAM_BOT_TOKEN="your-bot-token-here"
TELEGRAM_CHAT_ID="your-chat-id-here"

MESSAGE="$1"

curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "text=${MESSAGE}" \
    -d "parse_mode=HTML" > /dev/null 2>&1
```

```bash
chmod +x /usr/local/bin/send_telegram_alert.sh
```

### OPNsense Email Alerts

System > Settings > Notifications:

```
SMTP Server:    smtp.gmail.com
Port:           587
TLS:            Enabled
From:           opnsense-alerts@fastpartz.ae
To:             admin@fastpartz.ae
Username:       (Gmail app password or M365 account)
Password:       (app-specific password)
```

Test with "Send test email" button.

---

## 19. Managed Switch Configuration

### TP-Link TL-SG2428P Initial Setup

1. Default IP: 192.168.0.1
2. Connect PC directly, set PC IP to 192.168.0.10/24
3. Browse to http://192.168.0.1, login admin/admin
4. Change admin password immediately

### VLAN Configuration

**Create VLANs:**

| VLAN ID | Name |
|---------|------|
| 10 | SERVERS |
| 20 | WORKSTATIONS |
| 30 | MANAGEMENT |
| 99 | GUEST |

**Port assignments (example — adjust per branch needs):**

| Port(s) | VLAN | Mode | Description |
|---------|------|------|-------------|
| 1 | Trunk (All VLANs tagged) | Trunk | Uplink to OPNsense LAN port |
| 2-4 | 10 | Access (untagged) | Windows Servers |
| 5-6 | 10 | Access (untagged) | NAS |
| 7-16 | 20 | Access (untagged) | Workstation PCs |
| 17-20 | 99 | Access (untagged) | WiFi APs, printers |
| 21-22 | 99 | Access (untagged) | IoT / cameras |
| 23-24 | 30 | Access (untagged) | Management (OPNsense console, switch stack) |

**Trunk port 1 configuration:**

```
Port 1:
  Type:     Trunk
  PVID:     1 (default)
  Tagged VLANs:   10, 20, 30, 99
  Untagged VLAN:  None
```

### Change Management IP

After VLAN setup:

```
Switch management IP:   10.x.30.10/24
Gateway:                10.x.30.1 (OPNsense)
Management VLAN:        30
```

**Warning:** After changing the management VLAN, you can only access the switch from VLAN 30. Make sure you have a device on VLAN 30 before making this change.

---

## 20. Verification & Testing Procedures

### Test 1: External Port Scan

From an external host (VPS, or use an online scanner):

```bash
nmap -sS -p- <branch-public-ip>
```

**Expected:** All ports filtered/closed. Zero open ports.

### Test 2: IPsec Tunnel Stability (72-hour Soak)

Monitor all 6 tunnels via Uptime Kuma for 72 continuous hours.

**Expected:** 100% uptime, zero unplanned drops.

### Test 3: DPD Failover

1. Reboot OPNsense at Branch 2
2. Monitor tunnel status on Branch 1, 3, 4

**Expected:** Tunnels re-establish within 60-90 seconds after Branch 2 comes back.

### Test 4: DynDNS Failover

1. Restart broadband router at Branch 3 (forces new IP)
2. Monitor DDNS update and tunnel recovery

**Expected:** DDNS updates within 5 minutes. Tunnels recover within 2-5 minutes.

### Test 5: SQL Sync Over IPsec

Run accounting software's sync/replication from Branch 1 to Branch 2.

**Expected:** Sync completes successfully. Data consistent.

### Test 6: Inter-VLAN Isolation

From a VLAN 20 workstation:

```cmd
ping 10.1.10.10   (local server — should work if ICMP is allowed)
ping 10.2.10.10   (remote branch server — should fail, workstations don't get IPsec)
ping 10.1.30.1    (management — should fail)
```

### Test 7: Guest VLAN Isolation

From a VLAN 99 device:

```cmd
ping 10.1.10.10   (server — should fail)
ping 10.1.30.1    (management — should fail)
ping 8.8.8.8      (internet — should work)
curl https://www.google.com  (web — should work)
```

### Test 8: IDS/IPS Detection

Download EICAR test file through OPNsense:

```cmd
curl -O https://www.eicar.org/download/eicar.com
```

**Expected:** Suricata blocks the download. Alert in Services > Intrusion Detection > Alerts.

### Test 9: DNS Filtering

```cmd
nslookup malware-test-domain.abuse.ch 10.1.20.1
```

**Expected:** NXDOMAIN (blocked by Unbound DNSBL).

### Test 10: Backup Restore (File-Level)

Veeam > Restore > File Level Restore > select a recent backup > restore a random file.

**Expected:** File restored, content matches original.

### Test 11: Windows Hardening Verification

From a VLAN 20 workstation, scan the server:

```cmd
nmap -sV 10.1.10.10
```

**Expected:** Only ports 445 (SMB) and 1433 (SQL) open. No RDP (3389). No NetBIOS (135/137-139).

### Test 12: Account Lockout

Attempt 6 failed RDP logins to the server.

**Expected:** Account locks after 5 attempts. Unlocks after 30 minutes.

### Test 13: VPN Access

Connect to IKEv2 VPN from a mobile hotspot (external network).

**Expected:** VPN connects. Can RDP to server via VPN. TOTP required.

### Test 14: VPN Access Restrictions

While on VPN:

```cmd
ping 10.1.20.100  (workstation VLAN — should fail)
ping 10.1.30.1    (management — should fail)
ping 10.1.10.10   (server — should work)
```

### Test 15: Backup Immutability (B2 Object Lock)

Attempt to delete a backup object from B2 within the 30-day retention:

```bash
restic -r b2:fastpartz-backup:/ forget --keep-last 0 --prune
```

**Expected:** Delete fails. Object Lock prevents deletion.

### Post-Test Sign-Off

```
Test conducted by:    _________________________
Date:                 _________________________
All tests passed:     [ ] Yes  [ ] No

Failed tests:
_________________________________________________________

Notes:
_________________________________________________________

Sign-off:             _________________________
```
