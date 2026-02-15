// ─────────────────────────────────────────────────────────────
// FastPartz — Security & SD-WAN Proposal (v2 — FlexiWAN)
// Typst source — compile with: typst compile proposal-v2.typ
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
      #v(0.15cm)
      #text(size: 12pt, fill: luma(100))[Centrally Managed — FlexiWAN + Cloudflare Gateway]
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
      [*Version:*], [2.0],
      [*Scope:*], [4 branches (UAE) + offsite backup],
      [*Approach:*], [Cloud-managed SD-WAN with remote administration],
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

FastPartz operates four branches across the UAE, each running Windows Servers with vendor-supplied accounting software backed by MS SQL Server. Today, these servers sit directly on public IP addresses with RDP and SQL ports exposed to the internet — no firewalls, no antivirus, no backups, and no network segmentation. This configuration represents a critical security risk.

The proposed solution would address every layer of this exposure through a *centrally managed* architecture designed for a business without an on-site IT team. By placing a FlexiWAN SD-WAN appliance at each branch — managed from a single cloud dashboard — encrypting all inter-branch traffic through automated tunnels, filtering DNS traffic via Cloudflare Gateway, and implementing a 3-2-1 backup strategy, the result would be a resilient security posture that can be administered entirely from a remote location.

#v(0.4cm)
#stat-box[
  #set text(size: 10pt)
  *Key outcomes of the proposed approach:*
  #v(4pt)
  #grid(
    columns: (1fr, 1fr),
    gutter: 8pt,
    [- *Zero public-facing ports* — full perimeter closure],
    [- *Automated encrypted tunnels* between all branches],
    [- *Single cloud dashboard* to manage all 4 branches],
    [- *3-2-1 backups* with immutable offsite copies],
    [- *DNS threat filtering* via Cloudflare Gateway],
    [- *Full remote administration* — no on-site IT needed],
  )
]

#v(0.3cm)
#callout(accent-color: accent-m, bg-color: accent-l)[
  #set text(size: 10pt)
  *Design principle:* This solution prioritizes *manageability and simplicity* over maximum feature depth. A solution the client can operate is more valuable than a complex one that requires expert intervention for every change.
]

// ═══════════════════════════════════════════════════════════════
// 2. SOLUTION OVERVIEW
// ═══════════════════════════════════════════════════════════════
= 2. Solution Overview

The following table summarizes the proposed changes across each security layer. Every layer is designed to be cloud-managed or self-maintaining.

#v(0.3cm)
#prop-table(
  columns: (1fr, 1.8fr, 1.8fr),
  header: ([Layer], [Current State], [Proposed State]),
  ([*Perimeter*], [No firewall — public ports open to internet], [FlexiWAN firewall at each branch; zero inbound ports]),
  ([*Transport*], [Unencrypted SQL sync over public internet], [AES-256 IPsec tunnels via FlexiWAN SD-WAN (auto-configured)]),
  ([*Segmentation*], [Flat network — everything reachable], [VLANs: servers, workstations, mgmt, guests isolated]),
  ([*DNS Security*], [No filtering], [Cloudflare Gateway: malware, phishing, C2 domains blocked]),
  ([*Endpoint*], [No AV — Defender disabled], [Windows Defender + ESET PROTECT with ransomware rules]),
  ([*Backup*], [No backups at all], [3 copies, 2 media types, 1 offsite, immutable]),
  ([*Access*], [Direct RDP over internet], [WireGuard VPN with key-based authentication]),
  ([*Management*], [No central visibility], [Single cloud dashboard (flexiManage) for all branches]),
)

// ═══════════════════════════════════════════════════════════════
// 3. WHY FLEXIWAN
// ═══════════════════════════════════════════════════════════════
= 3. Why Cloud-Managed SD-WAN

Traditional firewall appliances (OPNsense, pfSense) are powerful, but each device is managed independently. For four branches with no IT staff on-site, this creates a maintenance burden that grows with every configuration change.

#v(0.2cm)
#prop-table(
  columns: (1.3fr, 2fr, 2fr),
  header: ([Concern], [Traditional Firewall], [FlexiWAN SD-WAN]),
  ([*Management*], [4 separate web GUIs — one per branch], [Single cloud dashboard for all branches]),
  ([*VPN tunnels*], [Manual IPsec on each end: 12 configurations], [Select devices, click "Create Tunnels", done]),
  ([*Updates*], [SSH into each device individually], [Push from cloud to all devices at once]),
  ([*Troubleshooting*], [Need SSH access + networking expertise], [Cloud dashboard shows device and tunnel status]),
  ([*IP changes*], [Manual DynDNS + tunnel re-keying], [Handled automatically by cloud controller]),
  ([*Remote admin*], [Need VPN just to reach each firewall GUI], [Web dashboard accessible from anywhere]),
)

#v(0.4cm)
FlexiWAN runs on the same Intel N100 mini-PC hardware as a traditional firewall. The difference is operational: all configuration, monitoring, and troubleshooting happens through a central cloud console rather than per-device.

#v(0.2cm)
#warn-box[
  #set text(size: 10pt)
  *Trade-off:* FlexiWAN's built-in firewall is simpler than OPNsense and does not include IDS/IPS (intrusion detection). This gap is addressed by Cloudflare Gateway for DNS-layer threat blocking and ESET PROTECT for endpoint defense. The combination covers the critical threat vectors for this environment.
]

// ═══════════════════════════════════════════════════════════════
// 4. SOFTWARE & COST
// ═══════════════════════════════════════════════════════════════
= 4. Recommended Software & Cost

All core infrastructure uses open-source software. The primary recurring costs are FlexiWAN cloud management and enterprise antivirus.

#v(0.3cm)
#prop-table(
  columns: (1.2fr, 1.3fr, 3fr),
  header: ([Software], [Purpose], [Key Features]),
  ([*FlexiWAN*], [SD-WAN + Firewall], [Cloud-managed, automated IPsec tunnels, app identification, VLAN support, DHCP, firewall rules]),
  ([*Cloudflare Gateway*], [DNS Security], [Blocks malware/phishing/C2 domains, DNSSEC, content categories (free for 50 users)]),
  ([*WireGuard*], [Remote Access VPN], [Fast, modern, native clients on all platforms, key-based authentication]),
  ([*Windows Defender*], [Endpoint AV], [Real-time protection, Tamper Protection, ASR rules, cloud-delivered protection]),
  ([*ESET PROTECT*], [Enterprise AV], [Central cloud console, ransomware shield, behavioral detection]),
  ([*Veeam Backup CE*], [Server Backup], [Full/incremental, MS SQL VSS, application-aware, AES-256 encryption (free ≤10 workloads)]),
  ([*Restic*], [Cloud Backup], [Backblaze B2 integration, encryption, deduplication, retention policies]),
  ([*Uptime Kuma*], [Monitoring], [Ping/TCP/HTTP checks, web dashboard, Telegram + email notifications]),
)

#v(0.4cm)
== Hardware per Branch

Each branch would require two devices:

- *FlexiWAN Edge (N100 Mini-PC)* — Intel N100, 4× 2.5GbE I226-V NICs, 8 GB DDR5, 128 GB NVMe, fanless. Runs Ubuntu 20.04 + FlexiWAN. (\$150–200)

- *Managed Switch* — TP-Link TL-SG2428P or similar with 802.1Q VLAN support. For smaller branches, an 8-port model is sufficient. (\$200–300)

Optional: Backup NAS at the master branch (\$400–500), offsite NAS (\$400–500).

#v(0.3cm)
== Cost Summary

#prop-table(
  columns: (2.5fr, 1.2fr, 1.2fr, 1.2fr),
  header: ([Scenario], [Hardware], [Year 1 Recurring], [Year 1 Total]),
  ([*Core* — 4× N100 + switches], [\$1,520–2,200], [\$2,080], [*\$3,600–4,280*]),
  ([*Core + self-hosted mgmt*], [\$1,520–2,200], [\$280], [*\$1,800–2,480*]),
  ([*Core + Backup NAS*], [\$1,920–2,700], [\$2,080], [*\$4,000–4,780*]),
  ([*Full (Core + NAS + offsite)*], [\$2,320–3,200], [\$2,080], [*\$4,400–5,280*]),
)

#v(0.2cm)
#callout(accent-color: accent-m, bg-color: accent-l)[
  #set text(size: 9.5pt)
  *Recurring breakdown:* FlexiWAN cloud: \$160/month (\$1,920/year) + ESET: \$160/year = \$2,080/year. \ *Self-hosted option:* Host flexiManage on a \$10/month VPS, reducing total recurring to \~\$280/year.
]

// ═══════════════════════════════════════════════════════════════
// 5. NETWORK ARCHITECTURE
// ═══════════════════════════════════════════════════════════════
= 5. Network Architecture

Each branch follows the same topology: broadband router hands off to a FlexiWAN appliance, which serves as the gateway for all traffic. A managed switch provides VLAN segmentation.

#v(0.3cm)
#figure(
  diagram(
    spacing: (12pt, 16pt),
    node-stroke: 1pt + luma(160),
    edge-stroke: 1pt + luma(120),

    // Internet
    node((0, 0), [*INTERNET*], shape: rect, fill: luma(240), stroke: 1pt + luma(160), inset: 10pt),

    // Router
    node((0, 1), [Broadband Router \ _(bridge mode)_], shape: rect, fill: luma(245), stroke: 1pt + luma(180), inset: 8pt),
    edge((0, 0), (0, 1), "->", label: []),

    // FlexiWAN
    node((0, 2), align(center)[
      #text(weight: "bold", size: 10pt)[FlexiWAN Edge] \
      #text(size: 8pt)[
        SD-WAN · Firewall \
        WireGuard VPN · DHCP \
        VLAN Routing
      ]
    ], shape: rect, fill: rgb("#E3F2FD"), stroke: 1.2pt + accent-m, inset: 10pt, corner-radius: 6pt),
    edge((0, 1), (0, 2), "->", label: text(size: 8pt)[WAN]),

    // Cloud mgmt (right side)
    node((2, 2), align(center)[
      #text(weight: "bold", size: 9pt)[flexiManage] \
      #text(size: 7.5pt)[Cloud Dashboard]
    ], shape: rect, fill: rgb("#FFF3E0"), stroke: 1.2pt + orange-d, inset: 8pt, corner-radius: 6pt),
    edge((0, 2), (2, 2), "<->", label: text(size: 7pt)[HTTPS], stroke: 1pt + orange-d),

    // Cloudflare (left side)
    node((-2, 2), align(center)[
      #text(weight: "bold", size: 9pt)[Cloudflare] \
      #text(size: 7.5pt)[DNS Gateway]
    ], shape: rect, fill: rgb("#E8F5E9"), stroke: 1.2pt + green-d, inset: 8pt, corner-radius: 6pt),
    edge((0, 2), (-2, 2), "->", label: text(size: 7pt)[DNS queries], stroke: 1pt + green-d),

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
  caption: [Proposed per-branch topology with cloud management and DNS security],
)

#v(0.3cm)
#prop-table(
  columns: (1.5fr, 2fr, 2fr),
  header: ([Traffic Type], [Path], [Protection]),
  ([Server → Server (inter-branch)], [FlexiWAN → IPsec SD-WAN tunnel → remote branch], [AES-256 encrypted (auto-configured)]),
  ([Workstation → Internet], [FlexiWAN → ISP], [DNS filtered by Cloudflare Gateway]),
  ([Workstation → Server], [FlexiWAN inter-VLAN routing], [Firewall rules + Windows Firewall]),
  ([Remote user → Server], [WireGuard VPN → FlexiWAN → Server], [Key-authenticated + encrypted]),
  ([Any device → DNS], [FlexiWAN → Cloudflare Gateway], [Malware/phishing/C2 blocked]),
)

// ═══════════════════════════════════════════════════════════════
// 6. NETWORK SEGMENTATION
// ═══════════════════════════════════════════════════════════════
= 6. Network Segmentation

== Why Segment the Network?

In a flat network, a single compromised device — whether a workstation hit by phishing or a printer with a default password — can reach every other device on the network. This is how ransomware spreads: once inside, it moves laterally to find servers, databases, and backups.

Network segmentation through VLANs creates isolated zones with strict rules between them. Even if an attacker compromises a workstation, they would be unable to reach servers in a different VLAN without passing through FlexiWAN, which enforces explicit access rules. This dramatically limits the blast radius of any incident.

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
#prop-table(
  columns: (0.5fr, 0.9fr, 1.5fr, 2fr),
  header: ([VLAN], [Name], [Devices], [Access Rules]),
  ([10], [*Servers*], [Windows Servers, NAS, SQL], [Reachable from workstations on SQL + file share ports only. Inter-branch via SD-WAN.]),
  ([20], [*Workstations*], [User PCs, laptops], [Can reach servers for SQL and file shares. Full inspected internet access.]),
  ([30], [*Management*], [FlexiWAN, switch mgmt], [IT administrators only. All other VLANs blocked.]),
  ([99], [*Guest / IoT*], [WiFi guests, printers, cameras], [Fully isolated. Internet-only (HTTP/HTTPS). Cannot reach internal VLANs.]),
)

// ═══════════════════════════════════════════════════════════════
// 7. SECURITY LAYERS
// ═══════════════════════════════════════════════════════════════
= 7. Security Layers

The proposed architecture combines network-level and endpoint-level defenses. Each layer compensates for the limitations of the others.

#v(0.3cm)
#prop-table(
  columns: (1.5fr, 3fr, 1fr),
  header: ([Defense Layer], [What It Does], [Priority]),
  ([*Firewall*], [FlexiWAN default-deny inbound. Closes all public ports — RDP, SQL, everything.], [Critical]),
  ([*DNS Filtering*], [Cloudflare Gateway blocks malware, phishing, C2, and DGA domains before they resolve.], [Critical]),
  ([*VLAN Segmentation*], [Isolates servers, workstations, management, and guests behind access rules.], [Critical]),
  ([*Encrypted Transport*], [FlexiWAN IPsec tunnels with AES-256. Auto-configured, auto-recovering.], [Critical]),
  ([*Endpoint AV*], [Windows Defender + ASR rules + ESET PROTECT enterprise antivirus.], [High]),
  ([*Server Hardening*], [Disable SMBv1, NetBIOS, LLMNR, PowerShell v2. Enable Windows Firewall, audit logging.], [High]),
  ([*Application Control*], [AppLocker blocks executables from user profile, temp, and AppData folders.], [Medium]),
  ([*Backup Immutability*], [3-2-1 backup with Object Lock. Ransomware cannot encrypt backup copies.], [Critical]),
  ([*Monitoring*], [Uptime Kuma dashboard + Telegram alerts for outages and failures.], [High]),
)

// ═══════════════════════════════════════════════════════════════
// 8. ENCRYPTED CONNECTIVITY
// ═══════════════════════════════════════════════════════════════
= 8. Encrypted Connectivity

The accounting software currently syncs SQL data over the open internet. The proposed solution would route all inter-branch traffic through encrypted SD-WAN tunnels that configure themselves automatically.

#v(0.2cm)
#prop-table(
  columns: (1.5fr, 3fr),
  header: ([Feature], [Specification]),
  ([Protocol], [IPsec over VXLAN (FlexiWAN native)]),
  ([Encryption], [AES-256 (keys auto-generated by flexiManage)]),
  ([Tunnel Setup], [Select devices in dashboard → "Create Tunnels" → full mesh auto-configures]),
  ([Route Advertisement], [LAN subnets automatically shared across tunnels]),
  ([NAT Traversal], [Automatic — works behind ISP routers]),
  ([Health Monitoring], [Real-time tunnel status in flexiManage dashboard]),
  ([Recovery], [Automatic reconnection on failure — no manual intervention]),
)

#v(0.4cm)
== Full-Mesh Topology

All four branches would be connected via six encrypted tunnels, providing direct branch-to-branch communication.

#v(0.2cm)
#figure(
  diagram(
    spacing: (40pt, 35pt),
    node-stroke: 1.2pt + accent-m,
    edge-stroke: 1.2pt + accent-m,

    node((0, -1), [*Branch 1* \ _(Master)_], shape: rect, fill: rgb("#E3F2FD"), inset: 10pt, corner-radius: 6pt),
    node((-1.5, 0), [*Branch 2*], shape: rect, fill: rgb("#E3F2FD"), inset: 10pt, corner-radius: 6pt),
    node((1.5, 0), [*Branch 3*], shape: rect, fill: rgb("#E3F2FD"), inset: 10pt, corner-radius: 6pt),
    node((0, 1), [*Branch 4*], shape: rect, fill: rgb("#E3F2FD"), inset: 10pt, corner-radius: 6pt),

    edge((0, -1), (-1.5, 0), "<->"),
    edge((0, -1), (1.5, 0), "<->"),
    edge((0, -1), (0, 1), "<->"),
    edge((-1.5, 0), (1.5, 0), "<->"),
    edge((-1.5, 0), (0, 1), "<->"),
    edge((1.5, 0), (0, 1), "<->"),
  ),
  caption: [Full-mesh SD-WAN — 6 encrypted tunnels, auto-configured from a single dashboard],
)

#v(0.3cm)
#stat-box[
  #set text(size: 10pt)
  *SD-WAN beyond basic VPN:* FlexiWAN provides application identification, link quality monitoring, and path selection — enabling SQL sync traffic to be prioritized over general browsing, and automatically re-routed if link quality degrades.
]

// ═══════════════════════════════════════════════════════════════
// 9. BACKUP STRATEGY
// ═══════════════════════════════════════════════════════════════
= 9. Backup Strategy (3-2-1)

Three copies of data, on two different media types, with one copy offsite. Backblaze B2 is recommended for the cloud tier.

#v(0.3cm)
#figure(
  diagram(
    spacing: (20pt, 18pt),
    node-stroke: 1pt + luma(160),
    edge-stroke: 1pt + luma(120),

    node((0, 0), align(center)[
      #text(weight: "bold")[Production Server] \
      #text(size: 8pt)[Windows Server + SQL DB]
    ], shape: rect, fill: rgb("#E3F2FD"), stroke: 1.5pt + accent-m, inset: 10pt, corner-radius: 6pt),

    node((-1.5, 1.5), align(center)[
      #text(weight: "bold", size: 9pt)[Copy 1: Local NAS] \
      #text(size: 8pt)[Veeam · Daily + Weekly] \
      #text(size: 7pt, fill: green-d)[Immutable snapshots]
    ], shape: rect, fill: rgb("#E8F5E9"), stroke: 1.2pt + green-d, inset: 10pt, corner-radius: 6pt),

    node((0, 1.5), align(center)[
      #text(weight: "bold", size: 9pt)[Copy 2: Cross-Branch] \
      #text(size: 8pt)[rsync via SD-WAN · Daily] \
      #text(size: 7pt, fill: green-d)[NAS snapshots]
    ], shape: rect, fill: rgb("#FFF3E0"), stroke: 1.2pt + orange-d, inset: 10pt, corner-radius: 6pt),

    node((1.5, 1.5), align(center)[
      #text(weight: "bold", size: 9pt)[Copy 3: Cloud Offsite] \
      #text(size: 8pt)[Restic → Backblaze B2] \
      #text(size: 7pt, fill: green-d)[Object Lock (30-day)]
    ], shape: rect, fill: rgb("#F3E5F5"), stroke: 1.2pt + rgb("#7B1FA2"), inset: 10pt, corner-radius: 6pt),

    edge((0, 0), (-1.5, 1.5), "->", label: text(size: 7pt)[Daily]),
    edge((0, 0), (0, 1.5), "->", label: text(size: 7pt)[Daily]),
    edge((0, 0), (1.5, 1.5), "->", label: text(size: 7pt)[Weekly]),
  ),
  caption: [3-2-1 backup architecture with immutability at every tier],
)

#v(0.4cm)
#prop-table(
  columns: (1fr, 1.2fr, 1.5fr, 1fr, 1.2fr),
  header: ([Copy], [Location], [Method], [Schedule], [Immutability]),
  ([*1 — Local*], [Synology NAS \ (master branch)], [Veeam CE \ (SQL-aware, free)], [Daily incremental + weekly full], [NAS snapshots \ (7-day retention)]),
  ([*2 — Cross-branch*], [Partner branch NAS via SD-WAN], [rsync with encryption], [Daily sync], [NAS snapshots]),
  ([*3 — Cloud*], [Backblaze B2], [Restic with AES-256], [Weekly full + daily incremental], [Object Lock \ (30-day)]),
)

// ═══════════════════════════════════════════════════════════════
// 10. REMOTE ACCESS & MANAGEMENT
// ═══════════════════════════════════════════════════════════════
= 10. Remote Access & Management

== Secure Remote Access (WireGuard VPN)

Remote users would connect via WireGuard VPN running on each FlexiWAN device. WireGuard is built into all modern operating systems and uses key-based authentication — there are no passwords to brute-force.

#v(0.2cm)
#prop-table(
  columns: (1.2fr, 3fr),
  header: ([Feature], [Detail]),
  ([Protocol], [WireGuard (modern, minimal, kernel-level)]),
  ([Authentication], [Public/private key pairs — no passwords]),
  ([Encryption], [ChaCha20-Poly1305 (or AES-256-GCM with HW acceleration)]),
  ([Split Tunneling], [Only branch traffic through VPN; internet browsing stays local]),
  ([VPN Subnet], [`10.10.10.0/24` (dedicated, isolated from all branch VLANs)]),
  ([Client Software], [Built into Windows, macOS, iOS, Android, Linux]),
)

#v(0.3cm)
== Remote Administration

The administrator can manage the entire infrastructure remotely through five web dashboards:

#v(0.2cm)
#prop-table(
  columns: (1.5fr, 2fr, 1.5fr),
  header: ([Dashboard], [What It Manages], [Access]),
  ([*flexiManage*], [All SD-WAN devices, tunnels, firewall rules], [Web browser, anywhere]),
  ([*Cloudflare Gateway*], [DNS policies, block/allow rules, query logs], [Web browser, anywhere]),
  ([*ESET PROTECT*], [Antivirus status across all servers], [Web browser, anywhere]),
  ([*Uptime Kuma*], [Monitoring dashboard, alert configuration], [Web browser via VPN]),
  ([*WireGuard VPN*], [Direct access to any branch for RDP, troubleshooting], [VPN client]),
)

#v(0.2cm)
#stat-box[
  #set text(size: 10pt)
  *No on-site presence needed* for day-to-day management. All five interfaces are accessible from any location with an internet connection.
]

// ═══════════════════════════════════════════════════════════════
// 11. RANSOMWARE RISK MATRIX
// ═══════════════════════════════════════════════════════════════
= 11. Ransomware Risk Assessment

This matrix maps every significant attack vector against the current exposure and proposed mitigations.

#v(0.3cm)
#prop-table(
  columns: (0.3fr, 1.2fr, 0.8fr, 2fr, 0.8fr),
  header: ([\#], [Attack Vector], [Current], [Proposed Mitigation], [After]),
  ([1], [*RDP Brute Force*], [CRITICAL], [FlexiWAN blocks all inbound. RDP via VPN only.], [*ELIMINATED*]),
  ([2], [*SQL Exploitation*], [CRITICAL], [FlexiWAN blocks inbound. SQL bound to VLAN 10.], [*ELIMINATED*]),
  ([3], [*Phishing / Email*], [HIGH], [Cloudflare Gateway + SPF/DKIM/DMARC + training.], [MEDIUM]),
  ([4], [*Malicious Downloads*], [HIGH], [Cloudflare DNS + Defender + ESET + AppLocker.], [LOW]),
  ([5], [*Lateral Movement*], [CRITICAL], [VLAN segmentation + Windows Firewall + separate accounts.], [LOW]),
  ([6], [*Credential Theft*], [HIGH], [VPN uses keys (no passwords). Account lockout. Separate admins.], [LOW]),
  ([7], [*Backup Destruction*], [CRITICAL], [3-2-1 backup + NAS snapshots + B2 Object Lock.], [LOW]),
  ([8], [*DNS Attacks*], [MEDIUM], [Cloudflare: DNSSEC + malware blocklist + DGA detection.], [LOW]),
  ([9], [*Unpatched Vulns*], [HIGH], [Automated Windows Update. Monthly review.], [LOW]),
)

// ═══════════════════════════════════════════════════════════════
// 12. IMPLEMENTATION & EMERGENCY
// ═══════════════════════════════════════════════════════════════
= 12. Implementation & Emergency Reference

== Proposed Timeline

#v(0.2cm)
#prop-table(
  columns: (0.5fr, 2.5fr, 2.5fr),
  header: ([Week], [Scope], [Deliverable]),
  ([*1*], [Hardware procurement + Ubuntu + FlexiWAN installation], [4 flexiEdge devices registered in flexiManage]),
  ([*2*], [Branch 1 pilot — VLANs, firewall, Cloudflare DNS, WireGuard], [Master branch fully segmented and protected]),
  ([*3*], [Deploy branches 2–4 + auto-create full-mesh tunnels], [All branches connected. SQL sync encrypted.]),
  ([*4*], [Server hardening + AV + backup setup], [All servers hardened. Daily backups running.]),
  ([*5*], [Monitoring + offsite backup (Backblaze B2)], [Uptime Kuma live. 3-2-1 backup complete.]),
  ([*6*], [Testing, verification, documentation, training], [All tests passed. Runbooks delivered.]),
)

#v(0.3cm)
#callout(accent-color: accent-m, bg-color: accent-l)[
  #set text(size: 10pt)
  *Estimated deployment: 6 weeks.* Each phase is independently valuable — the network becomes progressively more secure from week one.
]

#v(0.5cm)
== Emergency Quick-Reference

#warn-box[
  #set text(size: 10pt)
  *Suspected ransomware:* #h(4pt) ① Isolate — pull Ethernet immediately #h(4pt) ② Do not reboot (preserves forensic evidence) #h(4pt) ③ Check other branches via flexiManage dashboard #h(4pt) ④ Restore from most recent clean backup #h(4pt) ⑤ Investigate via Windows logs #h(4pt) ⑥ Harden the exploited vulnerability
]

#v(0.3cm)
#warn-box[
  #set text(size: 10pt)
  *FlexiWAN device failure:* #h(4pt) Branch loses connectivity. Boot standby N100 — already registered in flexiManage, auto-configures on startup (\~5 min recovery).
]

#v(0.3cm)
#warn-box[
  #set text(size: 10pt)
  *SD-WAN tunnel down:* #h(4pt) Check flexiManage dashboard (accessible from anywhere). Wait 2 minutes for auto-recovery. If still down, check remote branch broadband. Restart tunnel from dashboard — no SSH needed.
]
