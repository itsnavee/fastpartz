# FastPartz — Security Assessment

## 1. Current Setup

* **Branches:** 4 locations across the UAE, each with physical Windows Servers running vendor-supplied accounting software (MS SQL Server).
* **Connectivity:** Each branch has a broadband connection with a **public IP** assigned directly to the server.
* **Open Ports:** RDP (TCP 3389) and SQL Server (TCP 1433) are exposed to the internet on every branch.
* **Inter-Branch Sync:** Servers sync data directly across branches over the public internet — unencrypted.
* **Remote Access:** Users connect to servers directly via RDP over the internet.
* **Firewalls:** None — no hardware or software firewalls at any branch.
* **Antivirus / EDR:** None — Windows Defender is disabled or unconfigured. No third-party AV.
* **Network Segmentation:** None — flat network. Servers, workstations, printers, and guests share the same subnet.
* **Backups:** None — no local, cross-branch, or offsite backup strategy.
* **Authentication:** Password-only. No MFA. No account lockout policies.

---

## 2. Security Gaps

| # | Gap | Risk Level | Detail |
|---|-----|-----------|--------|
| 1 | **Open RDP to internet** | CRITICAL | Port 3389 is the #1 initial access vector for ransomware gangs. Brute-force bots scan and attack within minutes of discovery. |
| 2 | **Open SQL to internet** | CRITICAL | Port 1433 exposed allows direct database exploitation, data exfiltration, and xp_cmdshell abuse for remote code execution. |
| 3 | **No perimeter firewall** | CRITICAL | Zero inbound filtering. Every service on the server is reachable from the entire internet. |
| 4 | **No endpoint protection** | HIGH | No AV, no EDR, no ASR rules. Malware executes unopposed. |
| 5 | **Flat network (no segmentation)** | HIGH | A compromised workstation has unrestricted access to servers, printers, and every other device on the LAN. |
| 6 | **Unencrypted inter-branch sync** | HIGH | SQL data traverses the public internet in clear text. Subject to interception and man-in-the-middle attacks. |
| 7 | **No backups** | CRITICAL | Any ransomware event or hardware failure is a total data loss / business-ending event. |
| 8 | **No MFA** | HIGH | A single leaked or brute-forced password gives full administrative access to production servers. |
| 9 | **No account lockout** | MEDIUM | Unlimited login attempts make brute-force attacks trivial. |
| 10 | **No patch management** | MEDIUM | Unpatched Windows and SQL Server vulnerabilities remain exploitable indefinitely. |
| 11 | **No monitoring or logging** | MEDIUM | No visibility into attacks in progress. No audit trail for forensics. |
| 12 | **No remote access controls** | HIGH | Remote users connect directly to servers with no VPN, no restrictions, and no session logging. |
