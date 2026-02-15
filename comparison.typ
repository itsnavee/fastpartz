// ─────────────────────────────────────────────────────────────
// FastPartz — Solution Comparison (4 Options)
// Typst source — compile with: typst compile comparison.typ
// ─────────────────────────────────────────────────────────────

#import "@preview/fletcher:0.5.8": diagram, node, edge

// ── Colours ──────────────────────────────────────────────────
#let accent    = rgb("#1B3A5C")
#let accent-l  = rgb("#E8EEF4")
#let accent-m  = rgb("#3A6EA5")
#let green-d   = rgb("#1B7A3D")
#let green-l   = rgb("#E6F4EC")
#let orange-d  = rgb("#C65D07")
#let orange-l  = rgb("#FFF3E6")
#let red-d     = rgb("#B22222")
#let red-l     = rgb("#FDECEC")
#let purple-d  = rgb("#6A1B9A")
#let purple-l  = rgb("#F3E5F5")

// Solution colors
#let color-a = rgb("#1565C0")  // blue  — OPNsense
#let color-b = rgb("#E65100")  // orange — FlexiWAN
#let color-c = rgb("#2E7D32")  // green — Cloud Hub
#let color-d = rgb("#6A1B9A")  // purple — Cloudflare

// ── Page setup ───────────────────────────────────────────────
#set page(
  paper: "a4",
  margin: (top: 2.2cm, bottom: 1.8cm, left: 2.2cm, right: 2.2cm),
  header: context {
    if counter(page).get().first() > 1 {
      set text(size: 8pt, fill: luma(120))
      [FastPartz — Solution Comparison]
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
  v(0.4cm)
  block(width: 100%, below: 0.5cm, {
    set text(size: 20pt, weight: "bold", fill: accent)
    it.body
    v(3pt)
    line(length: 100%, stroke: 1.5pt + accent)
  })
}

#show heading.where(level: 2): it => {
  v(0.4cm)
  block(below: 0.3cm, {
    set text(size: 14pt, weight: "bold", fill: accent)
    it.body
  })
}

// ── Helpers ──────────────────────────────────────────────────
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

#let prop-table(columns: (), header: (), ..rows) = {
  let row-data = rows.pos()
  table(
    columns: columns,
    inset: 7pt,
    stroke: 0.5pt + luma(200),
    fill: (_, y) => {
      if y == 0 { accent }
      else if calc.odd(y) { accent-l }
      else { white }
    },
    align: (x, _) => left,
    ..header.map(h => table.cell({
      set text(fill: white, weight: "bold", size: 8.5pt)
      h
    })),
    ..row-data.flatten().map(c => {
      set text(size: 8.5pt)
      c
    }),
  )
}

#let solution-badge(label, color) = {
  box(
    inset: (x: 8pt, y: 4pt),
    radius: 4pt,
    fill: color.lighten(85%),
    stroke: 1pt + color,
    text(size: 9pt, weight: "bold", fill: color)[#label],
  )
}

// ═══════════════════════════════════════════════════════════════
// PAGE 1: COVER
// ═══════════════════════════════════════════════════════════════
#page(header: none, footer: none)[
  #v(3cm)
  #align(center)[
    #block(width: 80%)[
      #line(length: 100%, stroke: 2.5pt + accent)
      #v(1cm)
      #text(size: 36pt, weight: "bold", fill: accent)[FastPartz]
      #v(0.3cm)
      #text(size: 18pt, fill: accent-m)[Solution Comparison]
      #v(0.5cm)
      #text(size: 12pt, fill: luma(80))[4 Approaches to Securing Your Network]
      #v(1cm)
      #line(length: 100%, stroke: 2.5pt + accent)
    ]
  ]
  #v(1.5cm)
  #align(center)[
    #grid(
      columns: (1fr, 1fr),
      gutter: 12pt,
      solution-badge("A: OPNsense", color-a),
      solution-badge("B: FlexiWAN", color-b),
      solution-badge("C: Cloud Hub", color-c),
      solution-badge("D: Cloudflare Zero Trust", color-d),
    )
  ]
  #v(1.5cm)
  #align(center)[
    #set text(size: 11pt, fill: luma(80))
    #table(
      columns: (auto, auto),
      stroke: none,
      inset: 8pt,
      align: (right, left),
      [*Date:*], [February 2026],
      [*Scope:*], [4 branches (UAE)],
      [*Purpose:*], [Compare cost, complexity, security, and maintenance],
    )
  ]
  #v(1fr)
  #align(center)[
    #set text(size: 9pt, fill: luma(140))
    _Confidential — Prepared for FastPartz Management_
  ]
]

// ═══════════════════════════════════════════════════════════════
// PAGE 2: SOLUTION A — EXPLAIN
// ═══════════════════════════════════════════════════════════════
= Solution A: OPNsense Traditional Firewall

#solution-badge("OPNsense + Manual IPsec + Suricata IDS", color-a)

#v(0.4cm)

A dedicated OPNsense firewall appliance (N100 mini-PC) at each branch, with manually configured IPsec tunnels creating a full-mesh VPN between all branches. Each device runs Suricata IDS/IPS for intrusion detection and Unbound DNS for malware/phishing filtering.

#v(0.3cm)
== Key Characteristics

#prop-table(
  columns: (1.3fr, 3fr),
  header: ([Aspect], [Detail]),
  ([*Edge Device*], [OPNsense on Intel N100 mini-PC (dedicated per branch)]),
  ([*Inter-Branch*], [6 manual IPsec tunnels (IKEv2, AES-256-GCM, certificate auth)]),
  ([*Firewall*], [Full stateful firewall with per-port, per-VLAN rules]),
  ([*IDS/IPS*], [Suricata with \~35,000 ET Open + Abuse.ch rules, inline blocking]),
  ([*DNS Filtering*], [Unbound with DNSBL blocklists, DNSSEC, DNS-over-TLS]),
  ([*Remote Access*], [IKEv2 VPN with certificate + password + TOTP (MFA)]),
  ([*Management*], [Per-device web GUI (4 separate logins) — no central dashboard]),
  ([*Dynamic DNS*], [Dynu DDNS on each branch for tunnel peer discovery]),
)

#v(0.3cm)
== Strengths & Weaknesses

#grid(
  columns: (1fr, 1fr),
  gutter: 12pt,
  callout(accent-color: green-d, bg-color: green-l)[
    #set text(size: 9.5pt)
    *Strengths* \
    - Deepest security (IDS/IPS + stateful FW) \
    - Full open-source, zero recurring cost \
    - Mature, battle-tested platform \
    - Massive community + documentation \
    - Complete feature set (VPN, DNS, DHCP, CA)
  ],
  callout(accent-color: red-d, bg-color: red-l)[
    #set text(size: 9.5pt)
    *Weaknesses* \
    - 4 separate GUIs — no central management \
    - 12 manual IPsec configurations \
    - Requires networking expertise \
    - DynDNS adds fragility \
    - Cannot be managed remotely without VPN first
  ],
)

// ═══════════════════════════════════════════════════════════════
// PAGE 3: SOLUTION A — DIAGRAM
// ═══════════════════════════════════════════════════════════════
= Solution A: Architecture Diagram

#v(0.3cm)
#figure(
  diagram(
    spacing: (12pt, 14pt),
    node-stroke: 1pt + luma(160),
    edge-stroke: 1pt + luma(120),

    node((0, 0), [*INTERNET*], shape: rect, fill: luma(240), inset: 8pt),
    node((0, 1), [Broadband Router], shape: rect, fill: luma(245), inset: 6pt),
    edge((0, 0), (0, 1), "->"),

    node((0, 2), align(center)[
      #text(weight: "bold", size: 9pt)[OPNsense] \
      #text(size: 7pt)[Firewall · Suricata IDS \
      IPsec VPN · DNS Filter \
      DHCP · DynDNS]
    ], shape: rect, fill: color-a.lighten(88%), stroke: 1.2pt + color-a, inset: 8pt, corner-radius: 5pt),
    edge((0, 1), (0, 2), "->", label: text(size: 7pt)[WAN]),

    node((0, 3), align(center)[
      #text(weight: "bold", size: 9pt)[Managed Switch] \
      #text(size: 7pt)[802.1Q VLANs]
    ], shape: rect, fill: purple-l, stroke: 1pt + purple-d, inset: 8pt, corner-radius: 5pt),
    edge((0, 2), (0, 3), "->", label: text(size: 7pt)[Trunk]),

    node((-1.2, 4), align(center)[#text(size: 7pt, weight: "bold")[VLAN 10] \ #text(size: 7pt)[Servers]], shape: rect, fill: green-l, stroke: 1pt + green-d, inset: 6pt, corner-radius: 3pt),
    node((-0.4, 4), align(center)[#text(size: 7pt, weight: "bold")[VLAN 20] \ #text(size: 7pt)[Wkstns]], shape: rect, fill: orange-l, stroke: 1pt + orange-d, inset: 6pt, corner-radius: 3pt),
    node((0.4, 4), align(center)[#text(size: 7pt, weight: "bold")[VLAN 30] \ #text(size: 7pt)[Mgmt]], shape: rect, fill: accent-l, stroke: 1pt + accent-m, inset: 6pt, corner-radius: 3pt),
    node((1.2, 4), align(center)[#text(size: 7pt, weight: "bold")[VLAN 99] \ #text(size: 7pt)[Guest]], shape: rect, fill: red-l, stroke: 1pt + red-d, inset: 6pt, corner-radius: 3pt),

    edge((0, 3), (-1.2, 4), "->"),
    edge((0, 3), (-0.4, 4), "->"),
    edge((0, 3), (0.4, 4), "->"),
    edge((0, 3), (1.2, 4), "->"),
  ),
  caption: [Solution A: Per-branch topology (× 4 branches)],
)

#v(0.5cm)
#figure(
  diagram(
    spacing: (40pt, 35pt),
    node-stroke: 1.2pt + color-a,
    edge-stroke: 1.5pt + color-a,

    node((0, -1), [*Branch 1* \ _(Master)_], shape: rect, fill: color-a.lighten(88%), inset: 10pt, corner-radius: 6pt),
    node((-1.5, 0), [*Branch 2*], shape: rect, fill: color-a.lighten(88%), inset: 10pt, corner-radius: 6pt),
    node((1.5, 0), [*Branch 3*], shape: rect, fill: color-a.lighten(88%), inset: 10pt, corner-radius: 6pt),
    node((0, 1), [*Branch 4*], shape: rect, fill: color-a.lighten(88%), inset: 10pt, corner-radius: 6pt),

    edge((0, -1), (-1.5, 0), "<->", label: text(size: 7pt)[IPsec], label-side: left),
    edge((0, -1), (1.5, 0), "<->", label: text(size: 7pt)[IPsec], label-side: left),
    edge((0, -1), (0, 1), "<->", label: text(size: 7pt)[IPsec]),
    edge((-1.5, 0), (1.5, 0), "<->", label: text(size: 7pt)[IPsec]),
    edge((-1.5, 0), (0, 1), "<->", label: text(size: 7pt)[IPsec], label-side: left),
    edge((1.5, 0), (0, 1), "<->", label: text(size: 7pt)[IPsec], label-side: left),
  ),
  caption: [6 manual IPsec tunnels — full mesh, manually configured on each end],
)

// ═══════════════════════════════════════════════════════════════
// PAGE 4: SOLUTION B — EXPLAIN
// ═══════════════════════════════════════════════════════════════
= Solution B: FlexiWAN Cloud-Managed SD-WAN

#solution-badge("FlexiWAN + Cloudflare Gateway DNS", color-b)

#v(0.4cm)

FlexiWAN SD-WAN appliance at each branch, managed from a single cloud dashboard (flexiManage). Tunnels are created with one click from the dashboard — no manual IPsec configuration. DNS security provided by Cloudflare Gateway (free tier, 50 users).

#v(0.3cm)
== Key Characteristics

#prop-table(
  columns: (1.3fr, 3fr),
  header: ([Aspect], [Detail]),
  ([*Edge Device*], [FlexiWAN (Ubuntu 20.04) on Intel N100 mini-PC]),
  ([*Inter-Branch*], [6 auto-configured IPsec/VXLAN tunnels via flexiManage dashboard]),
  ([*Firewall*], [Basic iptables + application identification]),
  ([*IDS/IPS*], [Not available — gap filled by Cloudflare Gateway DNS + endpoint AV]),
  ([*DNS Filtering*], [Cloudflare Gateway (cloud-based, free for 50 users)]),
  ([*Remote Access*], [WireGuard VPN on the FlexiWAN device]),
  ([*Management*], [Single cloud dashboard (flexiManage) for all 4 branches]),
  ([*Dynamic DNS*], [Not needed — flexiManage handles tunnel peer discovery]),
)

#v(0.3cm)
== Strengths & Weaknesses

#grid(
  columns: (1fr, 1fr),
  gutter: 12pt,
  callout(accent-color: green-d, bg-color: green-l)[
    #set text(size: 9.5pt)
    *Strengths* \
    - Single dashboard for all branches \
    - One-click tunnel creation (full mesh) \
    - True SD-WAN (app identification, QoS) \
    - Push updates to all devices at once \
    - Remote management from anywhere
  ],
  callout(accent-color: red-d, bg-color: red-l)[
    #set text(size: 9.5pt)
    *Weaknesses* \
    - No IDS/IPS (Suricata equivalent) \
    - Basic firewall (not stateful NGFW) \
    - \$160/month cloud management fee \
    - Requires DPDK-compatible NICs (I226) \
    - Smaller community than OPNsense
  ],
)

// ═══════════════════════════════════════════════════════════════
// PAGE 5: SOLUTION B — DIAGRAM
// ═══════════════════════════════════════════════════════════════
= Solution B: Architecture Diagram

#v(0.3cm)
#figure(
  diagram(
    spacing: (12pt, 14pt),
    node-stroke: 1pt + luma(160),
    edge-stroke: 1pt + luma(120),

    node((0, 0), [*INTERNET*], shape: rect, fill: luma(240), inset: 8pt),
    node((0, 1), [Broadband Router], shape: rect, fill: luma(245), inset: 6pt),
    edge((0, 0), (0, 1), "->"),

    node((0, 2), align(center)[
      #text(weight: "bold", size: 9pt)[FlexiWAN Edge] \
      #text(size: 7pt)[SD-WAN · Firewall \
      WireGuard VPN · DHCP \
      VLAN Routing]
    ], shape: rect, fill: color-b.lighten(88%), stroke: 1.2pt + color-b, inset: 8pt, corner-radius: 5pt),
    edge((0, 1), (0, 2), "->", label: text(size: 7pt)[WAN]),

    // Cloud management (right)
    node((2, 2), align(center)[
      #text(weight: "bold", size: 8pt)[flexiManage] \
      #text(size: 7pt)[Cloud Dashboard]
    ], shape: rect, fill: orange-l, stroke: 1pt + color-b, inset: 7pt, corner-radius: 5pt),
    edge((0, 2), (2, 2), "<->", label: text(size: 6pt)[HTTPS], stroke: 1pt + color-b),

    // Cloudflare (left)
    node((-2, 2), align(center)[
      #text(weight: "bold", size: 8pt)[Cloudflare] \
      #text(size: 7pt)[DNS Gateway]
    ], shape: rect, fill: green-l, stroke: 1pt + green-d, inset: 7pt, corner-radius: 5pt),
    edge((0, 2), (-2, 2), "->", label: text(size: 6pt)[DNS], stroke: 1pt + green-d),

    node((0, 3), align(center)[
      #text(weight: "bold", size: 9pt)[Managed Switch] \
      #text(size: 7pt)[802.1Q VLANs]
    ], shape: rect, fill: purple-l, stroke: 1pt + purple-d, inset: 8pt, corner-radius: 5pt),
    edge((0, 2), (0, 3), "->", label: text(size: 7pt)[Trunk]),

    node((-1.2, 4), align(center)[#text(size: 7pt, weight: "bold")[VLAN 10] \ #text(size: 7pt)[Servers]], shape: rect, fill: green-l, stroke: 1pt + green-d, inset: 6pt, corner-radius: 3pt),
    node((-0.4, 4), align(center)[#text(size: 7pt, weight: "bold")[VLAN 20] \ #text(size: 7pt)[Wkstns]], shape: rect, fill: orange-l, stroke: 1pt + orange-d, inset: 6pt, corner-radius: 3pt),
    node((0.4, 4), align(center)[#text(size: 7pt, weight: "bold")[VLAN 30] \ #text(size: 7pt)[Mgmt]], shape: rect, fill: accent-l, stroke: 1pt + accent-m, inset: 6pt, corner-radius: 3pt),
    node((1.2, 4), align(center)[#text(size: 7pt, weight: "bold")[VLAN 99] \ #text(size: 7pt)[Guest]], shape: rect, fill: red-l, stroke: 1pt + red-d, inset: 6pt, corner-radius: 3pt),

    edge((0, 3), (-1.2, 4), "->"),
    edge((0, 3), (-0.4, 4), "->"),
    edge((0, 3), (0.4, 4), "->"),
    edge((0, 3), (1.2, 4), "->"),
  ),
  caption: [Solution B: Per-branch topology with cloud management + DNS security],
)

#v(0.5cm)
#figure(
  diagram(
    spacing: (30pt, 25pt),
    node-stroke: 1.2pt + color-b,
    edge-stroke: 1.5pt + color-b,

    // flexiManage cloud
    node((0, -1.5), align(center)[
      #text(weight: "bold", size: 9pt)[flexiManage] \
      #text(size: 7pt)[Cloud Dashboard]
    ], shape: rect, fill: color-b.lighten(88%), inset: 10pt, corner-radius: 6pt),

    node((-1.5, 0), [*Branch 1*], shape: rect, fill: color-b.lighten(88%), inset: 9pt, corner-radius: 6pt),
    node((1.5, 0), [*Branch 2*], shape: rect, fill: color-b.lighten(88%), inset: 9pt, corner-radius: 6pt),
    node((-1.5, 1.2), [*Branch 3*], shape: rect, fill: color-b.lighten(88%), inset: 9pt, corner-radius: 6pt),
    node((1.5, 1.2), [*Branch 4*], shape: rect, fill: color-b.lighten(88%), inset: 9pt, corner-radius: 6pt),

    // Management connections
    edge((0, -1.5), (-1.5, 0), "->", stroke: 0.8pt + luma(160)),
    edge((0, -1.5), (1.5, 0), "->", stroke: 0.8pt + luma(160)),
    edge((0, -1.5), (-1.5, 1.2), "->", stroke: 0.8pt + luma(160)),
    edge((0, -1.5), (1.5, 1.2), "->", stroke: 0.8pt + luma(160)),

    // SD-WAN mesh
    edge((-1.5, 0), (1.5, 0), "<->"),
    edge((-1.5, 0), (-1.5, 1.2), "<->"),
    edge((-1.5, 0), (1.5, 1.2), "<->"),
    edge((1.5, 0), (-1.5, 1.2), "<->"),
    edge((1.5, 0), (1.5, 1.2), "<->"),
    edge((-1.5, 1.2), (1.5, 1.2), "<->"),
  ),
  caption: [Auto-configured full mesh + cloud management],
)

// ═══════════════════════════════════════════════════════════════
// PAGE 6: SOLUTION C — EXPLAIN
// ═══════════════════════════════════════════════════════════════
= Solution C: Cloud Hub (OCI UAE)

#solution-badge("Central Cloud Server + Outbound Sync Only", color-c)

#v(0.4cm)

A central Windows/Linux server in Oracle Cloud (UAE region) acts as the sync hub. Each branch pushes data outbound to the cloud — no branch talks to any other branch. Remote users RDP to the cloud server. Zero inter-branch tunnels.

#v(0.3cm)
== Key Characteristics

#prop-table(
  columns: (1.3fr, 3fr),
  header: ([Aspect], [Detail]),
  ([*Cloud Server*], [OCI VM (Dubai/Abu Dhabi) — Windows Server + SQL or Linux + SQL Express]),
  ([*Inter-Branch*], [None — all sync goes through the cloud hub]),
  ([*Branch Firewall*], [OPNsense (simplified — block all inbound, allow outbound to cloud)]),
  ([*DNS Filtering*], [OPNsense Unbound with DNSBL blocklists]),
  ([*Remote Access*], [RDP to cloud server (via RD Gateway / HTTPS)]),
  ([*Management*], [OCI Console + RDP to cloud server — all remote]),
  ([*Sync Model*], [Branches initiate outbound SQL sync to cloud. Cloud redistributes.]),
)

#v(0.3cm)
== Strengths & Weaknesses

#grid(
  columns: (1fr, 1fr),
  gutter: 12pt,
  callout(accent-color: green-d, bg-color: green-l)[
    #set text(size: 9.5pt)
    *Strengths* \
    - Zero inter-branch tunnels \
    - Simplest branch firewall config \
    - Cloud = built-in disaster recovery \
    - No branch-to-branch lateral movement \
    - OCI UAE keeps data in-country
  ],
  callout(accent-color: red-d, bg-color: red-l)[
    #set text(size: 9.5pt)
    *Weaknesses* \
    - Monthly cloud cost (\$55–100/mo) \
    - Accounting software must support hub sync \
    - Internet dependency for all sync \
    - Added latency for SQL queries \
    - Cloud server = new attack surface to protect
  ],
)

// ═══════════════════════════════════════════════════════════════
// PAGE 7: SOLUTION C — DIAGRAM
// ═══════════════════════════════════════════════════════════════
= Solution C: Architecture Diagram

#v(0.3cm)
#figure(
  diagram(
    spacing: (20pt, 18pt),
    node-stroke: 1pt + luma(160),
    edge-stroke: 1pt + luma(120),

    // Cloud server
    node((0, 0), align(center)[
      #text(weight: "bold", size: 10pt)[OCI Cloud Server] \
      #text(size: 8pt)[Dubai / Abu Dhabi] \
      #text(size: 7pt)[Windows + SQL · RDP Gateway \
      Backups · Monitoring]
    ], shape: rect, fill: color-c.lighten(85%), stroke: 1.5pt + color-c, inset: 12pt, corner-radius: 6pt),

    // Remote user
    node((2.2, 0), align(center)[
      #text(weight: "bold", size: 8pt)[Remote Users] \
      #text(size: 7pt)[RDP → Cloud]
    ], shape: rect, fill: purple-l, stroke: 1pt + purple-d, inset: 8pt, corner-radius: 5pt),
    edge((2.2, 0), (0, 0), "->", label: text(size: 7pt)[RDP/HTTPS], stroke: 1pt + purple-d),

    // Branches
    node((-1.5, 1.8), align(center)[
      #text(weight: "bold", size: 8pt)[Branch 1] \
      #text(size: 7pt)[OPNsense + Server]
    ], shape: rect, fill: color-c.lighten(88%), stroke: 1.2pt + color-c, inset: 8pt, corner-radius: 5pt),

    node((-0.5, 1.8), align(center)[
      #text(weight: "bold", size: 8pt)[Branch 2] \
      #text(size: 7pt)[OPNsense + Server]
    ], shape: rect, fill: color-c.lighten(88%), stroke: 1.2pt + color-c, inset: 8pt, corner-radius: 5pt),

    node((0.5, 1.8), align(center)[
      #text(weight: "bold", size: 8pt)[Branch 3] \
      #text(size: 7pt)[OPNsense + Server]
    ], shape: rect, fill: color-c.lighten(88%), stroke: 1.2pt + color-c, inset: 8pt, corner-radius: 5pt),

    node((1.5, 1.8), align(center)[
      #text(weight: "bold", size: 8pt)[Branch 4] \
      #text(size: 7pt)[OPNsense + Server]
    ], shape: rect, fill: color-c.lighten(88%), stroke: 1.2pt + color-c, inset: 8pt, corner-radius: 5pt),

    // Outbound sync arrows
    edge((-1.5, 1.8), (0, 0), "->", label: text(size: 6pt)[SQL sync ↑], stroke: 1pt + color-c),
    edge((-0.5, 1.8), (0, 0), "->", label: text(size: 6pt)[sync ↑], stroke: 1pt + color-c),
    edge((0.5, 1.8), (0, 0), "->", label: text(size: 6pt)[sync ↑], stroke: 1pt + color-c),
    edge((1.5, 1.8), (0, 0), "->", label: text(size: 6pt)[SQL sync ↑], stroke: 1pt + color-c),
  ),
  caption: [All branches sync outbound to cloud. No branch-to-branch traffic. Remote users RDP to cloud.],
)

#v(0.5cm)
#callout(accent-color: color-c, bg-color: color-c.lighten(90%))[
  #set text(size: 9.5pt)
  *Key architecture decision:* No branch communicates with any other branch. If Branch 2 is compromised, there is *no network path* to Branch 3. The cloud server is the only shared resource, protected by OCI Security Lists (IP whitelisting) and RD Gateway.
]

#v(0.3cm)
#figure(
  diagram(
    spacing: (12pt, 14pt),
    node-stroke: 1pt + luma(160),
    edge-stroke: 1pt + luma(120),

    node((0, 0), [*INTERNET*], shape: rect, fill: luma(240), inset: 8pt),
    node((0, 1), [Broadband Router], shape: rect, fill: luma(245), inset: 6pt),
    edge((0, 0), (0, 1), "->"),
    node((0, 2), align(center)[
      #text(weight: "bold", size: 9pt)[OPNsense] \
      #text(size: 7pt)[Block ALL inbound \
      Allow outbound to cloud only \
      DNS filtering · VLANs]
    ], shape: rect, fill: color-c.lighten(88%), stroke: 1.2pt + color-c, inset: 8pt, corner-radius: 5pt),
    edge((0, 1), (0, 2), "->"),
    node((0, 3), [Managed Switch + VLANs], shape: rect, fill: purple-l, stroke: 1pt + purple-d, inset: 8pt, corner-radius: 5pt),
    edge((0, 2), (0, 3), "->"),
  ),
  caption: [Simplified branch topology — no tunnels, no VPN, just firewall + VLANs],
)

// ═══════════════════════════════════════════════════════════════
// PAGE 8: SOLUTION D — EXPLAIN
// ═══════════════════════════════════════════════════════════════
= Solution D: Cloudflare Zero Trust Mesh

#solution-badge("cloudflared Tunnels + Browser RDP + Free", color-d)

#v(0.4cm)

A lightweight agent (`cloudflared`) installed on each Windows Server creates outbound tunnels to Cloudflare's global network using HTTP/2 or QUIC — indistinguishable from regular HTTPS browsing. Cloudflare routes traffic between branches, provides browser-based RDP for remote users, and enforces zero-trust access policies. No VPN protocols. No cloud server. Free for up to 50 users.

#v(0.3cm)
== Key Characteristics

#prop-table(
  columns: (1.3fr, 3fr),
  header: ([Aspect], [Detail]),
  ([*Tunnel Agent*], [cloudflared on each Windows Server (30MB, runs as service)]),
  ([*Protocol*], [HTTP/2 or QUIC — looks like HTTPS to ISPs. No VPN signatures.]),
  ([*Inter-Branch*], [Cloudflare routes SQL traffic between branch tunnels]),
  ([*Remote Access*], [Browser-based RDP — no client software, MFA via M365/Google]),
  ([*DNS Filtering*], [Cloudflare Gateway (same dashboard, free)]),
  ([*Access Policies*], [Zero-trust: "Branch A → Branch B on port 1433 only"]),
  ([*Management*], [Cloudflare Zero Trust dashboard (single pane of glass)]),
  ([*Cost*], [\$0 — free tier supports up to 50 users]),
)

#v(0.3cm)
== Strengths & Weaknesses

#grid(
  columns: (1fr, 1fr),
  gutter: 12pt,
  callout(accent-color: green-d, bg-color: green-l)[
    #set text(size: 9.5pt)
    *Strengths* \
    - Completely free (Cloudflare Zero Trust) \
    - Zero hardware beyond basic firewall \
    - No VPN — uses HTTPS (ISP-invisible) \
    - Browser-based RDP with MFA \
    - Granular zero-trust policies \
    - Single management dashboard
  ],
  callout(accent-color: red-d, bg-color: red-l)[
    #set text(size: 9.5pt)
    *Weaknesses* \
    - Depends on Cloudflare (third-party) \
    - cloudflared adds 5–20ms latency \
    - SQL sync through Cloudflare needs testing \
    - Browser RDP may be slower than native \
    - Free tier: 24-hour log retention only \
    - Newer technology — less battle-tested
  ],
)

// ═══════════════════════════════════════════════════════════════
// PAGE 9: SOLUTION D — DIAGRAM
// ═══════════════════════════════════════════════════════════════
= Solution D: Architecture Diagram

#v(0.3cm)
#figure(
  diagram(
    spacing: (18pt, 16pt),
    node-stroke: 1pt + luma(160),
    edge-stroke: 1pt + luma(120),

    // Cloudflare cloud
    node((0, 0), align(center)[
      #text(weight: "bold", size: 10pt)[Cloudflare Global Network] \
      #text(size: 7.5pt)[Zero Trust Gateway · Access Policies \
      DNS Filtering · Browser-Based RDP \
      MFA · Session Logging]
    ], shape: rect, fill: color-d.lighten(85%), stroke: 1.5pt + color-d, inset: 12pt, corner-radius: 6pt),

    // Remote user
    node((2.5, 0), align(center)[
      #text(weight: "bold", size: 8pt)[Remote User] \
      #text(size: 7pt)[Browser + MFA]
    ], shape: rect, fill: orange-l, stroke: 1pt + orange-d, inset: 8pt, corner-radius: 5pt),
    edge((2.5, 0), (0, 0), "->", label: text(size: 6pt)[HTTPS], stroke: 1pt + orange-d),

    // Branches with cloudflared
    node((-1.5, 1.8), align(center)[
      #text(weight: "bold", size: 8pt)[Branch 1] \
      #text(size: 7pt)[Server + cloudflared]
    ], shape: rect, fill: color-d.lighten(88%), stroke: 1.2pt + color-d, inset: 8pt, corner-radius: 5pt),

    node((-0.5, 1.8), align(center)[
      #text(weight: "bold", size: 8pt)[Branch 2] \
      #text(size: 7pt)[Server + cloudflared]
    ], shape: rect, fill: color-d.lighten(88%), stroke: 1.2pt + color-d, inset: 8pt, corner-radius: 5pt),

    node((0.5, 1.8), align(center)[
      #text(weight: "bold", size: 8pt)[Branch 3] \
      #text(size: 7pt)[Server + cloudflared]
    ], shape: rect, fill: color-d.lighten(88%), stroke: 1.2pt + color-d, inset: 8pt, corner-radius: 5pt),

    node((1.5, 1.8), align(center)[
      #text(weight: "bold", size: 8pt)[Branch 4] \
      #text(size: 7pt)[Server + cloudflared]
    ], shape: rect, fill: color-d.lighten(88%), stroke: 1.2pt + color-d, inset: 8pt, corner-radius: 5pt),

    // Outbound tunnels (HTTPS)
    edge((-1.5, 1.8), (0, 0), "->", label: text(size: 6pt)[HTTP/2 ↑], stroke: 1pt + color-d),
    edge((-0.5, 1.8), (0, 0), "->", label: text(size: 6pt)[QUIC ↑], stroke: 1pt + color-d),
    edge((0.5, 1.8), (0, 0), "->", label: text(size: 6pt)[HTTP/2 ↑], stroke: 1pt + color-d),
    edge((1.5, 1.8), (0, 0), "->", label: text(size: 6pt)[QUIC ↑], stroke: 1pt + color-d),
  ),
  caption: [All tunnels outbound (looks like HTTPS). Cloudflare routes traffic + enforces zero-trust policies.],
)

#v(0.5cm)
#callout(accent-color: color-d, bg-color: color-d.lighten(90%))[
  #set text(size: 9.5pt)
  *How SQL sync flows:* Branch 1 Server → cloudflared (HTTP/2 outbound) → Cloudflare Edge → cloudflared (Branch 2) → Branch 2 SQL Server. To the ISP, this is indistinguishable from regular HTTPS browsing. No VPN signatures.
]

#v(0.3cm)
#figure(
  diagram(
    spacing: (12pt, 14pt),
    node-stroke: 1pt + luma(160),
    edge-stroke: 1pt + luma(120),

    node((0, 0), [*INTERNET*], shape: rect, fill: luma(240), inset: 8pt),
    node((0, 1), [Broadband Router], shape: rect, fill: luma(245), inset: 6pt),
    edge((0, 0), (0, 1), "->"),
    node((0, 2), align(center)[
      #text(weight: "bold", size: 9pt)[OPNsense] \
      #text(size: 7pt)[Block ALL inbound \
      Allow HTTPS out only \
      VLANs · DHCP]
    ], shape: rect, fill: color-d.lighten(88%), stroke: 1.2pt + color-d, inset: 8pt, corner-radius: 5pt),
    edge((0, 1), (0, 2), "->"),
    node((0, 3), align(center)[
      Managed Switch + VLANs \
      #text(size: 7pt)[VLAN 10: Servers _(cloudflared here)_]
    ], shape: rect, fill: purple-l, stroke: 1pt + purple-d, inset: 8pt, corner-radius: 5pt),
    edge((0, 2), (0, 3), "->"),
  ),
  caption: [Simplest branch setup — firewall blocks everything, cloudflared handles connectivity],
)

// ═══════════════════════════════════════════════════════════════
// PAGE 10: COMPARISON TABLE
// ═══════════════════════════════════════════════════════════════
= Side-by-Side Comparison

#v(0.2cm)

#table(
  columns: (1.5fr, 1.6fr, 1.6fr, 1.6fr, 1.6fr),
  inset: 7pt,
  stroke: 0.5pt + luma(200),
  fill: (x, y) => {
    if y == 0 { accent }
    else if x == 0 { accent-l }
    else if calc.odd(y) { luma(248) }
    else { white }
  },
  align: (x, _) => if x == 0 { left } else { left },

  // Header
  table.cell({set text(fill: white, weight: "bold", size: 8pt); []}),
  table.cell({set text(fill: white, weight: "bold", size: 8pt); [A: OPNsense]}),
  table.cell({set text(fill: white, weight: "bold", size: 8pt); [B: FlexiWAN]}),
  table.cell({set text(fill: white, weight: "bold", size: 8pt); [C: Cloud Hub]}),
  table.cell({set text(fill: white, weight: "bold", size: 8pt); [D: Cloudflare ZT]}),

  // Rows
  {set text(size: 8pt, weight: "bold"); [Hardware Cost]},
  {set text(size: 8pt); [\$1,520–2,200]},
  {set text(size: 8pt); [\$1,520–2,200]},
  {set text(size: 8pt); [\$1,520–2,200]},
  {set text(size: 8pt); [\$1,520–2,200]},

  {set text(size: 8pt, weight: "bold"); [Year 1 Recurring]},
  {set text(size: 8pt); [\$160 \ (ESET only)]},
  {set text(size: 8pt); [\$2,080 \ (FlexiWAN + ESET)]},
  {set text(size: 8pt); [\$920–1,460 \ (OCI + ESET + B2)]},
  {set text(size: 8pt); [*\$220* \ (ESET + B2 only)]},

  {set text(size: 8pt, weight: "bold"); [Year 1 Total]},
  {set text(size: 8pt); [\$1,680–2,360]},
  {set text(size: 8pt); [\$3,600–4,280]},
  {set text(size: 8pt); [\$2,440–3,660]},
  {set text(size: 8pt); [*\$1,740–2,420*]},

  {set text(size: 8pt, weight: "bold"); [Year 2+ Annual]},
  {set text(size: 8pt); [*\$160*]},
  {set text(size: 8pt); [\$2,080]},
  {set text(size: 8pt); [\$920–1,460]},
  {set text(size: 8pt); [\$220]},

  {set text(size: 8pt, weight: "bold"); [Complexity]},
  {set text(size: 8pt, fill: red-d); [*HIGH* \ 4 GUIs, 12 IPsec configs, DynDNS]},
  {set text(size: 8pt, fill: orange-d); [MEDIUM \ 1 dashboard, auto tunnels]},
  {set text(size: 8pt, fill: green-d); [LOW \ No tunnels, simple FW]},
  {set text(size: 8pt, fill: green-d); [*LOWEST* \ Software only, 1 dashboard]},

  {set text(size: 8pt, weight: "bold"); [Security Depth]},
  {set text(size: 8pt, fill: green-d); [*HIGHEST* \ IDS/IPS + stateful FW + DNS]},
  {set text(size: 8pt, fill: orange-d); [MEDIUM \ Basic FW + DNS (cloud)]},
  {set text(size: 8pt); [MEDIUM \ FW + cloud isolation]},
  {set text(size: 8pt, fill: green-d); [HIGH \ Zero-trust + DNS + MFA]},

  {set text(size: 8pt, weight: "bold"); [Maintenance]},
  {set text(size: 8pt, fill: red-d); [*HIGH* \ Per-device, manual tunnels]},
  {set text(size: 8pt, fill: green-d); [LOW \ Cloud-managed, auto-healing]},
  {set text(size: 8pt, fill: green-d); [LOW \ Manage cloud server only]},
  {set text(size: 8pt, fill: green-d); [*LOWEST* \ Cloudflare manages infra]},

  {set text(size: 8pt, weight: "bold"); [Remote Admin]},
  {set text(size: 8pt); [Need VPN to reach each FW GUI]},
  {set text(size: 8pt); [flexiManage dashboard (anywhere)]},
  {set text(size: 8pt); [OCI Console + RDP (anywhere)]},
  {set text(size: 8pt); [CF dashboard + browser RDP]},

  {set text(size: 8pt, weight: "bold"); [Inter-Branch]},
  {set text(size: 8pt); [6 manual IPsec tunnels]},
  {set text(size: 8pt); [6 auto SD-WAN tunnels]},
  {set text(size: 8pt); [None — cloud hub sync]},
  {set text(size: 8pt); [Cloudflare mesh (HTTPS)]},

  {set text(size: 8pt, weight: "bold"); [VPN Protocol]},
  {set text(size: 8pt); [IKEv2 IPsec]},
  {set text(size: 8pt); [IPsec/VXLAN + WireGuard]},
  {set text(size: 8pt); [None (RDP to cloud)]},
  {set text(size: 8pt); [None (HTTP/2 / QUIC)]},

  {set text(size: 8pt, weight: "bold"); [IDS/IPS]},
  {set text(size: 8pt, fill: green-d); [Suricata (\~35K rules)]},
  {set text(size: 8pt, fill: red-d); [None]},
  {set text(size: 8pt, fill: orange-d); [OCI Cloud Guard]},
  {set text(size: 8pt, fill: orange-d); [CF Gateway (DNS layer)]},

  {set text(size: 8pt, weight: "bold"); [Lateral Movement Risk]},
  {set text(size: 8pt); [Low (VLANs + tunnels exist)]},
  {set text(size: 8pt); [Low (VLANs + tunnels exist)]},
  {set text(size: 8pt, fill: green-d); [*None* (no branch links)]},
  {set text(size: 8pt, fill: green-d); [*None* (zero-trust policies)]},

  {set text(size: 8pt, weight: "bold"); [Third-Party Dependency]},
  {set text(size: 8pt, fill: green-d); [None (self-hosted)]},
  {set text(size: 8pt); [FlexiWAN company]},
  {set text(size: 8pt); [Oracle Cloud]},
  {set text(size: 8pt); [Cloudflare]},

  {set text(size: 8pt, weight: "bold"); [SW Compatibility Risk]},
  {set text(size: 8pt, fill: green-d); [*None* — same sync model]},
  {set text(size: 8pt, fill: green-d); [*None* — same sync model]},
  {set text(size: 8pt, fill: red-d); [Must verify hub sync works]},
  {set text(size: 8pt, fill: orange-d); [Must test SQL via CF tunnel]},

  {set text(size: 8pt, weight: "bold"); [Best For]},
  {set text(size: 8pt); [Max security, IT team available]},
  {set text(size: 8pt); [Central mgmt, willing to pay]},
  {set text(size: 8pt); [Simplicity, if hub sync works]},
  {set text(size: 8pt); [Lowest cost + zero VPN needed]},
)

#v(0.5cm)
#callout(accent-color: accent-m, bg-color: accent-l)[
  #set text(size: 10pt)
  *Recommendation:* For FastPartz (no IT team, remote admin from outside UAE), *Solution D (Cloudflare Zero Trust)* offers the best balance of cost, simplicity, and security — provided SQL sync through Cloudflare tunnels is validated during a pilot phase. *Solution C (Cloud Hub)* is the safest fallback if the accounting software requires a traditional hub-and-spoke sync model.
]
