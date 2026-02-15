// ─────────────────────────────────────────────────────────────
// FastPartz — Security & SD-WAN Proposal
// Typst source — compile with: typst compile proposal.typ
// ─────────────────────────────────────────────────────────────

#import "@preview/fletcher:0.5.8": diagram, node, edge

// ── Colours ──────────────────────────────────────────────────
#let accent    = rgb("#1B3A5C")   // dark navy
#let accent-l  = rgb("#E8EEF4")   // light navy tint
#let accent-m  = rgb("#3A6EA5")   // medium blue
#let green-d   = rgb("#1B7A3D")   // dark green (security)
#let green-l   = rgb("#E6F4EC")   // light green tint
#let orange-d  = rgb("#C65D07")   // dark orange (warning)
#let orange-l  = rgb("#FFF3E6")   // light orange tint
#let red-d     = rgb("#B22222")   // dark red (critical)
#let red-l     = rgb("#FDECEC")   // light red tint

// ── Page setup ───────────────────────────────────────────────
#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2cm, left: 2.5cm, right: 2.5cm),
  header: context {
    if counter(page).get().first() > 1 {
      set text(size: 8pt, fill: luma(120))
      [FastPartz — Security & SD-WAN Proposal]
      h(1fr)
      [February 2026]
      v(-3pt)
      line(length: 100%, stroke: 0.4pt + luma(200))
    }
  },
  footer: context {
    if counter(page).get().first() > 1 {
      line(length: 100%, stroke: 0.4pt + luma(200))
      v(2pt)
      set text(size: 8pt, fill: luma(120))
      h(1fr)
      [Page #counter(page).display()]
      h(1fr)
    }
  },
)

// ── Typography ───────────────────────────────────────────────
#set text(font: "Helvetica Neue", size: 10.5pt, fill: luma(30))
#set par(justify: true, leading: 0.7em)

#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  v(0.6cm)
  block(
    width: 100%,
    below: 0.7cm,
    {
      set text(size: 20pt, weight: "bold", fill: accent)
      it.body
      v(3pt)
      line(length: 100%, stroke: 1.5pt + accent)
    },
  )
}

#show heading.where(level: 2): it => {
  v(0.5cm)
  block(below: 0.4cm, {
    set text(size: 14pt, weight: "bold", fill: accent)
    it.body
  })
}

#show heading.where(level: 3): it => {
  v(0.3cm)
  block(below: 0.25cm, {
    set text(size: 12pt, weight: "bold", fill: accent-m)
    it.body
  })
}

// ── Callout box helper ───────────────────────────────────────
#let callout(body, accent-color: accent-m, bg-color: accent-l) = {
  block(
    width: 100%,
    inset: (left: 14pt, right: 12pt, top: 10pt, bottom: 10pt),
    radius: 4pt,
    fill: bg-color,
    stroke: (left: 3.5pt + accent-color),
    body,
  )
}

#let stat-box(body) = {
  callout(accent-color: green-d, bg-color: green-l, body)
}

#let warn-box(body) = {
  callout(accent-color: orange-d, bg-color: orange-l, body)
}

// ── Table helper ─────────────────────────────────────────────
#let prop-table(columns: (), header: (), ..rows) = {
  let row-data = rows.pos()
  table(
    columns: columns,
    inset: 8pt,
    stroke: 0.5pt + luma(200),
    fill: (_, y) => {
      if y == 0 { accent }
      else if calc.odd(y) { accent-l }
      else { white }
    },
    align: (x, _) => left,
    ..header.map(h => table.cell({
      set text(fill: white, weight: "bold", size: 9pt)
      h
    })),
    ..row-data.flatten().map(c => {
      set text(size: 9pt)
      c
    }),
  )
}

// ═══════════════════════════════════════════════════════════════
// COVER PAGE
// ═══════════════════════════════════════════════════════════════
#page(header: none, footer: none)[
  #v(3.5cm)
  #align(center)[
    #block(width: 80%)[
      #line(length: 100%, stroke: 2.5pt + accent)
      #v(1cm)
      #text(size: 36pt, weight: "bold", fill: accent)[FastPartz]
      #v(0.3cm)
      #text(size: 18pt, fill: accent-m)[Security & SD-WAN Proposal]
      #v(1cm)
      #line(length: 100%, stroke: 2.5pt + accent)
    ]
  ]
  #v(2cm)
  #align(center)[
    #set text(size: 11pt, fill: luma(80))
    #table(
      columns: (auto, auto),
      stroke: none,
      inset: 8pt,
      align: (right, left),
      [*Date:*], [February 2026],
      [*Scope:*], [4 branches (UAE) + offsite backup],
      [*Type:*], [Technical proposal & recommendation],
    )
  ]
  #v(1fr)
  #align(center)[
    #set text(size: 9pt, fill: luma(140))
    _Confidential — Prepared for FastPartz Management_
  ]
]

// ═══════════════════════════════════════════════════════════════
// TABLE OF CONTENTS
// ═══════════════════════════════════════════════════════════════
#page(header: none)[
  #v(1cm)
  #text(size: 22pt, weight: "bold", fill: accent)[Table of Contents]
  #v(0.3cm)
  #line(length: 100%, stroke: 1pt + accent)
  #v(0.5cm)
  #outline(title: none, indent: 1.5em, depth: 2)
]

// ═══════════════════════════════════════════════════════════════
// 1. EXECUTIVE SUMMARY
// ═══════════════════════════════════════════════════════════════
= 1. Executive Summary

FastPartz operates four branches across the UAE, each running Windows Servers with vendor-supplied accounting software backed by MS SQL Server. Today, these servers sit directly on public IP addresses with RDP and SQL ports exposed to the internet, no firewalls, no antivirus, no backups, and no network segmentation. This configuration represents a critical security risk — exposed RDP is the \#1 entry point for ransomware groups, and the absence of backups means any incident could result in total data loss.

The proposed solution would address every layer of this exposure through a unified, open-source security architecture. By placing an OPNsense firewall appliance at each branch, encrypting all inter-branch traffic through IPsec tunnels, segmenting networks with VLANs, hardening every server endpoint, and implementing a 3-2-1 backup strategy with immutable copies, the result would be a resilient posture built on commodity hardware with no recurring license costs for infrastructure.

#v(0.4cm)
#stat-box[
  #set text(size: 10pt)
  *Key outcomes of the proposed approach:*
  #v(4pt)
  #grid(
    columns: (1fr, 1fr),
    gutter: 8pt,
    [- *Zero public-facing ports* — full perimeter closure],
    [- *AES-256 encryption* on all inter-branch links],
    [- *4-VLAN segmentation* at every branch],
    [- *3-2-1 backups* with immutable offsite copies],
    [- *VPN with MFA* replaces exposed RDP],
    [- *Real-time monitoring* with instant alerts],
  )
]

// ═══════════════════════════════════════════════════════════════
// 2. SOLUTION OVERVIEW
// ═══════════════════════════════════════════════════════════════
= 2. Solution Overview

The following table summarizes the proposed changes across seven security layers. Each layer addresses a specific gap in the current environment.

#v(0.3cm)
#prop-table(
  columns: (1fr, 1.8fr, 1.8fr),
  header: ([Layer], [Current State], [Proposed State]),
  ([*Perimeter*], [No firewall — public ports open to internet], [OPNsense firewall at each branch; zero inbound ports]),
  ([*Transport*], [Unencrypted SQL sync over public internet], [AES-256 IPsec tunnels, certificate-authenticated]),
  ([*Segmentation*], [Flat network — everything reachable], [VLANs: servers, workstations, mgmt, guests isolated]),
  ([*Endpoint*], [No AV — Defender disabled], [Windows Defender + enterprise AV with ransomware rules]),
  ([*Backup*], [No backups at all], [3 copies, 2 media types, 1 offsite, immutable]),
  ([*Access*], [Direct RDP over internet], [IKEv2 VPN with certificate + password + TOTP]),
  ([*Monitoring*], [No visibility into threats], [IDS/IPS, DNS filtering, email + Telegram alerts]),
)

// ═══════════════════════════════════════════════════════════════
// 3. SOFTWARE STACK
// ═══════════════════════════════════════════════════════════════
= 3. Recommended Software

All core software is open-source or free-tier — no recurring license costs for infrastructure. We recommend *ESET PROTECT* (\~\$40/server/year) as the enterprise antivirus layer for central management and ransomware-specific shielding, bringing the total AV cost to approximately \$160/year for all four servers.

#v(0.3cm)
#prop-table(
  columns: (1.2fr, 1.3fr, 3fr),
  header: ([Software], [Purpose], [Key Features]),
  ([*OPNsense*], [Firewall / VPN / IDS], [Stateful firewall, IPsec/IKEv2, Suricata IDS/IPS, Unbound DNS with blocklists, DHCP, DynDNS, web GUI]),
  ([*Suricata*], [Intrusion Detection], [ET Open + Abuse.ch rulesets (\~35k rules), inline blocking, protocol anomaly detection]),
  ([*Unbound DNS*], [DNS Security], [DNSBL blocklists (malware/phishing), DNSSEC validation, DNS-over-TLS upstream]),
  ([*Windows Defender*], [Endpoint AV], [Real-time protection, Tamper Protection, ASR rules, cloud-delivered protection]),
  ([*ESET PROTECT*], [Enterprise AV], [Central cloud console, ransomware shield, behavioral detection]),
  ([*Veeam Backup CE*], [Server Backup], [Full/incremental, MS SQL VSS, application-aware, AES-256 encryption (free for ≤10 workloads)]),
  ([*Restic*], [Cloud Backup], [Backblaze B2 / Cloudflare R2 / S3 integration, encryption, deduplication, retention]),
  ([*NXLog CE*], [Log Forwarding], [Forwards Windows Security events to central syslog for audit trail]),
  ([*Uptime Kuma*], [Monitoring], [Ping/TCP/HTTP checks, web dashboard, push notifications, Docker-based]),
)

// ═══════════════════════════════════════════════════════════════
// 4. HARDWARE & COST
// ═══════════════════════════════════════════════════════════════
= 4. Hardware & Cost

Each branch would require two primary devices:

- *SD-WAN Edge (N100 Mini-PC)* — Intel N100, 2× 2.5GbE NICs, 8 GB DDR5, 128 GB NVMe, fanless, AES-NI hardware acceleration. Runs OPNsense as a dedicated firewall/VPN appliance. All branch traffic flows through this device. (\$150–200)

- *Managed Switch* — TP-Link TL-SG2428P or similar with 24× GbE, PoE+, 802.1Q VLAN support, web GUI. Provides network segmentation. For smaller branches, an 8-port model (TL-SG2210P) would be sufficient. (\$200–300)

Optional additions include a backup NAS at the master branch (Synology DS223, \$400–500) and an offsite NAS for geographic disaster recovery (\$400–500).

#v(0.3cm)
== Cost Summary

#prop-table(
  columns: (2.5fr, 1.2fr, 1.2fr),
  header: ([Scenario], [4 Branches], [Grand Total]),
  ([*Core* — N100 + managed switch per branch], [\$1,520–2,200], [*\$1,520–2,200*]),
  ([*Core + HA* — add standby N100 per branch], [\$2,120–3,000], [*\$2,120–3,000*]),
  ([*Core + Backup NAS* — master branch only], [\$1,520–2,200 + \$400–500], [*\$1,920–2,700*]),
  ([*Full* — Core + HA + NAS + offsite NAS], [\$2,120–3,000 + \$800–1,000], [*\$2,920–4,000*]),
)

#v(0.3cm)
#callout(accent-color: accent-m, bg-color: accent-l)[
  #set text(size: 10pt)
  *Total investment range:* \$1,520 (minimum viable) to \$4,000 (full redundancy + offsite). All built on open-source software with no recurring infrastructure licensing.
]

// ═══════════════════════════════════════════════════════════════
// 5. NETWORK ARCHITECTURE
// ═══════════════════════════════════════════════════════════════
= 5. Network Architecture

Each branch would follow the same topology: the existing broadband router hands off to a dedicated OPNsense appliance, which serves as the single gateway for all traffic. A managed switch downstream provides VLAN-based network segmentation.

#v(0.3cm)
#figure(
  diagram(
    spacing: (12pt, 16pt),
    node-stroke: 1pt + luma(160),
    edge-stroke: 1pt + luma(120),

    // Internet cloud
    node((0, 0), [*INTERNET*], shape: rect, fill: luma(240), stroke: 1pt + luma(160), inset: 10pt),

    // Router
    node((0, 1), [Broadband Router \ _(bridge mode)_], shape: rect, fill: luma(245), stroke: 1pt + luma(180), inset: 8pt),
    edge((0, 0), (0, 1), "->", label: []),

    // OPNsense
    node((0, 2), align(center)[
      #text(weight: "bold", size: 10pt)[OPNsense] \
      #text(size: 8pt)[
        Firewall · IDS/IPS \
        IPsec VPN · DHCP \
        DNS Filtering
      ]
    ], shape: rect, fill: rgb("#E3F2FD"), stroke: 1.2pt + accent-m, inset: 10pt, corner-radius: 6pt),
    edge((0, 1), (0, 2), "->", label: text(size: 8pt)[WAN]),

    // Switch
    node((0, 3), align(center)[
      #text(weight: "bold", size: 10pt)[Managed Switch] \
      #text(size: 8pt)[802.1Q VLAN Trunk]
    ], shape: rect, fill: rgb("#F3E5F5"), stroke: 1.2pt + rgb("#7B1FA2"), inset: 10pt, corner-radius: 6pt),
    edge((0, 2), (0, 3), "->", label: text(size: 8pt)[LAN trunk]),

    // VLANs
    node((-1.5, 4.2), align(center)[#text(weight: "bold", size: 8pt)[VLAN 10] \ Servers], shape: rect, fill: rgb("#E8F5E9"), stroke: 1pt + green-d, inset: 8pt, corner-radius: 4pt),
    node((-0.5, 4.2), align(center)[#text(weight: "bold", size: 8pt)[VLAN 20] \ Workstations], shape: rect, fill: rgb("#FFF3E0"), stroke: 1pt + orange-d, inset: 8pt, corner-radius: 4pt),
    node((0.5, 4.2), align(center)[#text(weight: "bold", size: 8pt)[VLAN 30] \ Management], shape: rect, fill: rgb("#E3F2FD"), stroke: 1pt + accent-m, inset: 8pt, corner-radius: 4pt),
    node((1.5, 4.2), align(center)[#text(weight: "bold", size: 8pt)[VLAN 99] \ Guest / IoT], shape: rect, fill: rgb("#FFEBEE"), stroke: 1pt + red-d, inset: 8pt, corner-radius: 4pt),

    edge((0, 3), (-1.5, 4.2), "->"),
    edge((0, 3), (-0.5, 4.2), "->"),
    edge((0, 3), (0.5, 4.2), "->"),
    edge((0, 3), (1.5, 4.2), "->"),
  ),
  caption: [Proposed per-branch network topology],
)

// ═══════════════════════════════════════════════════════════════
// 6. TRAFFIC FLOWS
// ═══════════════════════════════════════════════════════════════
= 6. Traffic Flow Architecture

OPNsense would serve as the default gateway for every device. All traffic — internet-bound, inter-branch, and inter-VLAN — would pass through OPNsense for inspection and policy enforcement.

#v(0.3cm)
#figure(
  diagram(
    spacing: (28pt, 14pt),
    node-stroke: 1pt + luma(160),
    edge-stroke: 1pt + luma(120),

    // OPNsense center
    node((0, 0), align(center)[
      #text(weight: "bold", size: 10pt)[OPNsense Gateway] \
      #text(size: 8pt)[Inspect · Filter · Encrypt]
    ], shape: rect, fill: rgb("#E3F2FD"), stroke: 1.5pt + accent-m, inset: 12pt, corner-radius: 6pt),

    // Sources (left)
    node((-2, -1), [Workstation], shape: rect, fill: rgb("#FFF3E0"), stroke: 1pt + orange-d, inset: 8pt, corner-radius: 4pt),
    node((-2, 0), [Server], shape: rect, fill: rgb("#E8F5E9"), stroke: 1pt + green-d, inset: 8pt, corner-radius: 4pt),
    node((-2, 1), [VPN User], shape: rect, fill: rgb("#F3E5F5"), stroke: 1pt + rgb("#7B1FA2"), inset: 8pt, corner-radius: 4pt),

    // Destinations (right)
    node((2, -1), [Internet], shape: rect, fill: luma(240), stroke: 1pt + luma(160), inset: 8pt, corner-radius: 4pt),
    node((2, 0), [Remote Branch], shape: rect, fill: rgb("#E3F2FD"), stroke: 1pt + accent-m, inset: 8pt, corner-radius: 4pt),
    node((2, 1), [Local Server], shape: rect, fill: rgb("#E8F5E9"), stroke: 1pt + green-d, inset: 8pt, corner-radius: 4pt),

    // Edges with labels
    edge((-2, -1), (0, 0), "->", label: text(size: 7pt)[IDS + DNS filter], label-side: left),
    edge((-2, 0), (0, 0), "->", label: text(size: 7pt)[Firewall rules], label-side: left),
    edge((-2, 1), (0, 0), "->", label: text(size: 7pt)[MFA + encrypted], label-side: left),

    edge((0, 0), (2, -1), "->", label: text(size: 7pt)[IDS/IPS + blocklists], label-side: left),
    edge((0, 0), (2, 0), "->", label: text(size: 7pt)[AES-256 IPsec], label-side: left),
    edge((0, 0), (2, 1), "->", label: text(size: 7pt)[Inter-VLAN rules], label-side: left),
  ),
  caption: [All traffic flows through OPNsense for inspection and policy enforcement],
)

#v(0.4cm)
#prop-table(
  columns: (1.5fr, 2fr, 2fr),
  header: ([Traffic Type], [Path], [Protection]),
  ([Server → Server (inter-branch)], [OPNsense → IPsec tunnel → remote OPNsense], [AES-256 encryption + IDS/IPS]),
  ([Workstation → Internet], [OPNsense → ISP], [IDS/IPS + DNS blocklists]),
  ([Workstation → Server (same branch)], [OPNsense inter-VLAN routing], [Firewall rules per port]),
  ([Remote user → Server], [IKEv2 VPN → OPNsense → Server], [Encrypted + MFA authenticated]),
)

// ═══════════════════════════════════════════════════════════════
// 7. NETWORK SEGMENTATION
// ═══════════════════════════════════════════════════════════════
= 7. Network Segmentation

== Why Segment the Network?

In a flat network, a single compromised device — whether a workstation hit by phishing or an IoT device with a default password — can reach every other device on the network. This is how ransomware spreads: once inside, it moves laterally to find servers, databases, and backups. Network segmentation through VLANs creates isolated zones with strict firewall rules between them. Even if an attacker compromises a workstation, they would be unable to reach servers in a different VLAN without passing through the OPNsense firewall, which enforces explicit per-port access rules. This approach dramatically limits the blast radius of any incident.

== IP Addressing Scheme

Pattern: `10.<branch>.<vlan>.0/24`

#prop-table(
  columns: (1fr, 1.2fr, 1.5fr, 1fr, 1.2fr),
  header: ([Branch], [VLAN 10 (Servers)], [VLAN 20 (Workstations)], [VLAN 30 (Mgmt)], [VLAN 99 (Guest)]),
  ([Branch 1], [`10.1.10.0/24`], [`10.1.20.0/24`], [`10.1.30.0/24`], [`10.1.99.0/24`]),
  ([Branch 2], [`10.2.10.0/24`], [`10.2.20.0/24`], [`10.2.30.0/24`], [`10.2.99.0/24`]),
  ([Branch 3], [`10.3.10.0/24`], [`10.3.20.0/24`], [`10.3.30.0/24`], [`10.3.99.0/24`]),
  ([Branch 4], [`10.4.10.0/24`], [`10.4.20.0/24`], [`10.4.30.0/24`], [`10.4.99.0/24`]),
)

#v(0.2cm)
== VLAN Roles

#prop-table(
  columns: (0.5fr, 0.9fr, 1.5fr, 2fr),
  header: ([VLAN], [Name], [Devices], [Access Rules]),
  ([10], [*Servers*], [Windows Servers, NAS, SQL], [Reachable from workstations on SQL + file share ports only. Inter-branch via IPsec.]),
  ([20], [*Workstations*], [User PCs, laptops], [Can reach servers for SQL and file shares. Full inspected internet access.]),
  ([30], [*Management*], [OPNsense GUI, switch mgmt], [IT administrators only. All other VLANs blocked.]),
  ([99], [*Guest / IoT*], [WiFi guests, printers, cameras], [Fully isolated. Internet-only (HTTP/HTTPS). Cannot reach internal VLANs.]),
)

// ═══════════════════════════════════════════════════════════════
// 8. SECURITY LAYERS
// ═══════════════════════════════════════════════════════════════
= 8. Security Layers

The proposed architecture combines network-level and endpoint-level defenses into a unified security model. Each layer would be deployed at every branch.

#v(0.3cm)
#prop-table(
  columns: (1.5fr, 3fr, 1fr),
  header: ([Defense Layer], [What It Does], [Priority]),
  ([*Stateful Firewall*], [Default-deny inbound on OPNsense. Closes all public ports — RDP, SQL, everything.], [Critical]),
  ([*IDS/IPS (Suricata)*], [\~35,000 signatures detect and block exploits, malware downloads, C2 callbacks.], [Critical]),
  ([*DNS Filtering*], [Blocks connections to known malicious/phishing domains before they resolve.], [High]),
  ([*VLAN Segmentation*], [Isolates servers, workstations, management, and guests behind firewall rules.], [Critical]),
  ([*Encrypted Transport*], [IKEv2 IPsec with AES-256-GCM and certificate auth. Perfect Forward Secrecy.], [Critical]),
  ([*Endpoint AV*], [Windows Defender + ASR rules + ESET PROTECT enterprise antivirus.], [High]),
  ([*Server Hardening*], [Disable SMBv1, NetBIOS, LLMNR, PowerShell v2. Enable Windows Firewall, audit logging, account lockout.], [High]),
  ([*Application Control*], [AppLocker/WDAC blocks executables from user profile, temp, and AppData folders.], [Medium]),
  ([*Backup Immutability*], [3-2-1 backup with immutable snapshots. Ransomware cannot encrypt backup copies.], [Critical]),
  ([*Monitoring & Alerts*], [IDS alerts, backup status, availability checks via email + Telegram notifications.], [High]),
)

// ═══════════════════════════════════════════════════════════════
// 9. ENCRYPTED CONNECTIVITY
// ═══════════════════════════════════════════════════════════════
= 9. Encrypted Connectivity

The accounting software currently syncs SQL data between branches over the open internet. The proposed solution would route all inter-branch traffic through encrypted IPsec tunnels. Dynamic DNS (via Dynu, free) handles UAE's dynamic broadband IPs — if an IP changes, tunnels would auto-recover within 30–90 seconds.

#v(0.2cm)
#prop-table(
  columns: (1.5fr, 3fr),
  header: ([Feature], [Specification]),
  ([Protocol], [IKEv2 — supports dynamic IPs, NAT traversal, mobile clients]),
  ([Authentication], [X.509 certificates from a private CA (no shared passwords)]),
  ([Encryption], [AES-256-GCM (hardware-accelerated on N100 via AES-NI)]),
  ([Key Exchange], [ECDH Group 20 (384-bit NIST P-384)]),
  ([Forward Secrecy], [New keys every hour — past sessions cannot be decrypted]),
  ([Failover], [Dead Peer Detection recovers failed tunnels in \~60 seconds]),
  ([NAT Traversal], [Automatic via UDP 4500 — works behind any ISP router]),
)

#v(0.4cm)
== Full-Mesh Topology

All four branches would be connected to each other via six encrypted IPsec tunnels, providing direct branch-to-branch communication. If any single tunnel fails, all other branches remain connected.

#v(0.2cm)
#figure(
  diagram(
    spacing: (40pt, 35pt),
    node-stroke: 1.2pt + accent-m,
    edge-stroke: 1.2pt + accent-m,

    // Branch nodes in a diamond
    node((0, -1), [*Branch 1* \ _(Master)_], shape: rect, fill: rgb("#E3F2FD"), inset: 10pt, corner-radius: 6pt),
    node((-1.5, 0), [*Branch 2*], shape: rect, fill: rgb("#E3F2FD"), inset: 10pt, corner-radius: 6pt),
    node((1.5, 0), [*Branch 3*], shape: rect, fill: rgb("#E3F2FD"), inset: 10pt, corner-radius: 6pt),
    node((0, 1), [*Branch 4*], shape: rect, fill: rgb("#E3F2FD"), inset: 10pt, corner-radius: 6pt),

    // All 6 mesh connections
    edge((0, -1), (-1.5, 0), "<->"),
    edge((0, -1), (1.5, 0), "<->"),
    edge((0, -1), (0, 1), "<->"),
    edge((-1.5, 0), (1.5, 0), "<->"),
    edge((-1.5, 0), (0, 1), "<->"),
    edge((1.5, 0), (0, 1), "<->"),
  ),
  caption: [Full-mesh IPsec topology — 6 encrypted tunnels between all branch pairs],
)

// ═══════════════════════════════════════════════════════════════
// 10. BACKUP STRATEGY
// ═══════════════════════════════════════════════════════════════
= 10. Backup Strategy (3-2-1)

The proposed approach follows the industry-standard 3-2-1 rule: three copies of data, on two different media types, with one copy offsite. We recommend Backblaze B2 for the cloud offsite tier — it offers the best balance of cost (\$5/TB/month), immutability (Object Lock), and ease of use.

#v(0.3cm)
#figure(
  diagram(
    spacing: (20pt, 18pt),
    node-stroke: 1pt + luma(160),
    edge-stroke: 1pt + luma(120),

    // Production
    node((0, 0), align(center)[
      #text(weight: "bold")[Production Server] \
      #text(size: 8pt)[Windows Server + SQL DB]
    ], shape: rect, fill: rgb("#E3F2FD"), stroke: 1.5pt + accent-m, inset: 10pt, corner-radius: 6pt),

    // Three backup tiers
    node((-1.5, 1.5), align(center)[
      #text(weight: "bold", size: 9pt)[Copy 1: Local NAS] \
      #text(size: 8pt)[Veeam · Daily + Weekly] \
      #text(size: 7pt, fill: green-d)[Immutable snapshots]
    ], shape: rect, fill: rgb("#E8F5E9"), stroke: 1.2pt + green-d, inset: 10pt, corner-radius: 6pt),

    node((0, 1.5), align(center)[
      #text(weight: "bold", size: 9pt)[Copy 2: Cross-Branch] \
      #text(size: 8pt)[rsync via IPsec · Daily] \
      #text(size: 7pt, fill: green-d)[NAS snapshots]
    ], shape: rect, fill: rgb("#FFF3E0"), stroke: 1.2pt + orange-d, inset: 10pt, corner-radius: 6pt),

    node((1.5, 1.5), align(center)[
      #text(weight: "bold", size: 9pt)[Copy 3: Cloud Offsite] \
      #text(size: 8pt)[Restic → Backblaze B2] \
      #text(size: 7pt, fill: green-d)[Object Lock (30-day)]
    ], shape: rect, fill: rgb("#F3E5F5"), stroke: 1.2pt + rgb("#7B1FA2"), inset: 10pt, corner-radius: 6pt),

    // Edges
    edge((0, 0), (-1.5, 1.5), "->", label: text(size: 7pt)[Daily]),
    edge((0, 0), (0, 1.5), "->", label: text(size: 7pt)[Daily]),
    edge((0, 0), (1.5, 1.5), "->", label: text(size: 7pt)[Weekly]),
  ),
  caption: [Proposed 3-2-1 backup architecture with immutability at every tier],
)

#v(0.4cm)
#prop-table(
  columns: (1fr, 1.2fr, 1.5fr, 1fr, 1.2fr),
  header: ([Copy], [Location], [Method], [Schedule], [Immutability]),
  ([*1 — Local*], [Synology NAS \ (master branch)], [Veeam CE \ (SQL-aware, free)], [Daily incremental + weekly full], [NAS snapshots \ (7-day retention)]),
  ([*2 — Cross-branch*], [Partner branch NAS via IPsec], [rsync/rclone with encryption], [Daily sync], [NAS snapshots]),
  ([*3 — Cloud*], [Backblaze B2], [Restic with AES-256], [Weekly full + daily incremental], [Object Lock \ (30-day, cannot be deleted)]),
)

// ═══════════════════════════════════════════════════════════════
// 11. SECURE REMOTE ACCESS
// ═══════════════════════════════════════════════════════════════
= 11. Secure Remote Access

Remote users would connect to the branch OPNsense via IKEv2 VPN. No client software would be needed — Windows, macOS, iOS, and Android all include built-in IKEv2 support. This approach would completely replace direct RDP access from the internet.

#v(0.2cm)
#prop-table(
  columns: (1.2fr, 3fr),
  header: ([Feature], [Detail]),
  ([Protocol], [IKEv2 (native on all modern operating systems)]),
  ([Authentication], [Certificate + Username/Password + TOTP (multi-factor)]),
  ([Encryption], [AES-256-GCM]),
  ([Split Tunneling], [Only branch traffic goes through VPN; internet browsing stays local]),
  ([VPN Subnet], [`10.10.10.0/24` (dedicated, isolated from all branch VLANs)]),
  ([DNS], [OPNsense Unbound — malware/phishing domains blocked for VPN users too]),
)

#v(0.3cm)
#grid(
  columns: (1fr, 1fr),
  gutter: 12pt,
  [
    === VPN Users Can Access
    - Servers: RDP, SQL, file shares
    - Only on authorized ports
    - Filtered through OPNsense rules
  ],
  [
    === VPN Users Cannot Access
    - Workstation VLAN
    - Management VLAN
    - Guest / IoT VLAN
    - Other VPN users
  ],
)

#v(0.2cm)
Vendor and support access would be handled through time-limited VPN accounts restricted to specific server IPs and ports, with full session logging and immediate revocation after each support session.

// ═══════════════════════════════════════════════════════════════
// 12. RANSOMWARE RISK MATRIX
// ═══════════════════════════════════════════════════════════════
= 12. Ransomware Risk Assessment

This matrix maps every significant attack vector against the current exposure and the proposed mitigation. Four of the fourteen vectors are currently at *critical* risk level.

#v(0.3cm)
#prop-table(
  columns: (0.3fr, 1.2fr, 0.8fr, 2fr, 0.8fr),
  header: ([\#], [Attack Vector], [Current], [Proposed Mitigation], [After]),
  ([1], [*RDP Brute Force*], [CRITICAL], [OPNsense blocks all inbound. RDP only via VPN.], [*ELIMINATED*]),
  ([2], [*SQL Exploitation*], [CRITICAL], [OPNsense blocks inbound. SQL bound to VLAN 10.], [*ELIMINATED*]),
  ([3], [*Phishing / Email*], [HIGH], [SPF/DKIM/DMARC + user training + attachment blocking.], [MEDIUM]),
  ([4], [*Malicious Downloads*], [HIGH], [IDS/IPS + DNS blocklists + Defender + ESET + AppLocker.], [LOW]),
  ([5], [*USB / Removable*], [MEDIUM], [Disable AutoRun. ASR blocks untrusted USB processes.], [LOW]),
  ([6], [*Lateral Movement*], [CRITICAL], [VLAN segmentation + firewalls + separate admin accounts.], [LOW]),
  ([7], [*Credential Theft*], [HIGH], [MFA on VPN. Account lockout. LSASS protection.], [LOW]),
  ([8], [*Supply Chain*], [MEDIUM], [Auto-patching. AppLocker whitelist. Vendor access time-limited.], [LOW]),
  ([9], [*Insider Threat*], [MEDIUM], [Least privilege. Audit logging. No shared accounts.], [LOW]),
  ([10], [*WiFi*], [MEDIUM], [WPA3. Guest SSID on isolated VLAN 99.], [LOW]),
  ([11], [*Printers / IoT*], [LOW], [VLAN 99 isolated. Only print ports from workstations.], [LOW]),
  ([12], [*DNS Attacks*], [MEDIUM], [DNSSEC + DNS-over-TLS + blocklists on OPNsense.], [LOW]),
  ([13], [*Backup Destruction*], [CRITICAL], [3-2-1 backup + immutable snapshots + Object Lock.], [LOW]),
  ([14], [*Unpatched Vulns*], [HIGH], [Automated Windows Update. Monthly patch review.], [LOW]),
)

// ═══════════════════════════════════════════════════════════════
// 13. IMPLEMENTATION TIMELINE + EMERGENCY REFERENCE
// ═══════════════════════════════════════════════════════════════
= 13. Implementation & Emergency Reference

== Proposed Timeline

The deployment would be structured in six weekly phases, with the master branch serving as the pilot before rolling out to remaining locations.

#v(0.2cm)
#prop-table(
  columns: (0.5fr, 2.5fr, 2.5fr),
  header: ([Week], [Scope], [Deliverable]),
  ([*1*], [Hardware procurement + OPNsense installation], [4 configured OPNsense appliances]),
  ([*2*], [Branch 1 pilot — VLANs, firewall, IDS/IPS, DNS], [Master branch fully segmented and protected]),
  ([*3*], [Deploy branches 2–4 + 6 IPsec tunnels], [All branches connected. SQL sync encrypted.]),
  ([*4*], [Server hardening + AV + backup setup], [All servers hardened. Daily backups running.]),
  ([*5*], [VPN with MFA + monitoring + offsite backup], [Remote access live. 3-2-1 backup complete.]),
  ([*6*], [Testing, verification, documentation, training], [All tests passed. Runbooks delivered.]),
)

#v(0.3cm)
#callout(accent-color: accent-m, bg-color: accent-l)[
  #set text(size: 10pt)
  *Estimated total deployment: 6 weeks.* Each phase is designed to be independently valuable — the network would become progressively more secure from week one.
]

#v(0.5cm)
== Emergency Quick-Reference

#warn-box[
  #set text(size: 10pt)
  *Suspected ransomware:* #h(4pt) ① Isolate — pull Ethernet immediately #h(4pt) ② Do not reboot (preserves forensic evidence) #h(4pt) ③ Check other branches and backup integrity #h(4pt) ④ Restore from most recent clean backup #h(4pt) ⑤ Investigate entry point via Suricata + Windows logs #h(4pt) ⑥ Harden the exploited vulnerability
]

#v(0.3cm)
#warn-box[
  #set text(size: 10pt)
  *OPNsense failure:* #h(4pt) Branch loses connectivity. Bypass by pointing workstations to broadband router (internet-only, no security). Boot standby N100 (\~5 min) or reinstall from XML config backup (\~30 min).
]

#v(0.3cm)
#warn-box[
  #set text(size: 10pt)
  *IPsec tunnel down:* #h(4pt) Wait 2 minutes for DPD auto-recovery. If still down, check remote branch broadband. Try disconnect/reconnect from OPNsense GUI. Verify DynDNS has updated if IP changed.
]
