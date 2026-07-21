# Network Cloak — Technical Architecture & Implementation Guide

Welcome to the technical blueprint of **Network Cloak**. This document details the architectural components, execution flows, native platform bridge mechanics, database schema, and custom engines that power Network Cloak’s localized device shielding and network privacy utilities.

---

## 1. System Architecture

Network Cloak utilizes a split-layer architecture: a cross-platform **Flutter & Dart** application layer for UI presentation and database persistence, and an asynchronous, native **Android Kotlin VPN Service** layer for packet-level enforcement, protocol interception, and DNS filtering.

### Data Flow Overview

The diagram below illustrates how packet capture, rule enforcement, background logging, and configuration synchronization interact across platform boundaries:

```mermaid
graph TD
    %% UI & Storage Layers (Dart)
    subgraph Dart Layer (Flutter UI & State)
        UI[Flutter UI Components] <-->|Riverpod State Management| Providers[State Providers]
        Providers <-->|Drift ORM| DB[(SQLite Database)]
        Providers -->|MethodChannel API Calls| PlatformBridge[Platform Channel Bridge]
        PlatformBridge <-->|EventChannel Listeners| BatchHandler[Event Batch Handler]
    end

    %% Native Enforcers (Kotlin)
    subgraph Kotlin Layer (Android Native)
        PlatformBridge <-->|MethodChannel| NativeChannel[Platform Channel Handler]
        NativeChannel -->|Sets Rules / Config| Rules[(In-Memory Rule Repository)]
        NativeChannel -->|Syncs Blocklists| DnsEngine[DNS Guard Engine]

        VpnService[NetworkCloakVpnService] <-->|Capture Packets| TUN[Virtual TUN Interface]
        VpnService -->|Evaluate Rules| Rules
        VpnService -->|Intercept DNS queries| DnsEngine
        VpnService -->|Multicast/Broadcast Filters| Cloak[Cloak Shield Engine]

        %% Buffered Connection Logs
        VpnService -->|Log ConnectionEvent| LogQueue[Native Event Buffer]
        LogQueue -->|Batch Flush every 500ms| BatchHandler
    end

    %% Outgoing Networking
    Rules -->|Allow/Forward| WAN[Internet Gateway]
    Rules -->|Drop| Drop[Connection Terminated]
    Cloak -->|Block Multicast/SMB| Drop
    DnsEngine -->|Block / Resolve Local| Client[DNS Response Payload]
    DnsEngine -->|Forward Valid Queries| DoH[Secure DoH Resolvers]
```

---

## 2. Kotlin Native VPN & Traffic Interceptor

The core protection of Network Cloak resides inside the custom Kotlin package `com.networkcloak.network_cloak` running inside the Android OS background process space.

### A. Virtual TUN Interface & Packet Processing
The `NetworkCloakVpnService` class subclasses Android's standard `VpnService` API.
* **Interface Establishment**: Upon starting, the service establishes a virtual network TUN interface (`FileDescriptor`) configured with private IPv4 subnets (e.g. `10.0.0.2/32`) and a default gateway route (`0.0.0.0/0`) intercepting all outbound packets.
* **Loop Thread**: A dedicated worker thread runs a packet loop that reads raw bytes from the TUN interface descriptor into a buffer:
  * **Header Parsing**: Parses the raw byte buffer to isolate the IPv4 header (extracting source IP, destination IP, payload protocol identifier).
  * **Protocol Multiplexing**: If the payload is UDP or TCP, it further parses the transport header to extract source and destination ports.
  * **Local App Attribution**: Uses the native socket identifier mappings or Linux `/proc/net` files (via socket owner UIDs) to match the packet to the Android application package identifier (e.g., `com.whatsapp`, `com.android.chrome`).

### B. Cloak Shield Engine (SSDP, SMB, mDNS Blockers)
To make the device completely invisible on local area networks (LANs), the native `RuleRepository` drops local discovery and network exposure protocols before they escape the device:
* **Multicast/Broadcast Drops**: Blocks IP ranges matching the multicast mask `224.0.0.0/4` and the local subnet broadcast address `255.255.255.255`.
* **Port-Level Blocks**: Dropped outgoing connection attempts targeting:
  * **mDNS / Multicast DNS** (UDP Port `5353`)
  * **LLMNR / Link-Local Multicast Name Resolution** (UDP Port `5355`)
  * **NetBIOS Name Service / Session** (UDP Ports `137`, `138` and TCP Port `139`)
  * **SMB / Server Message Block** (TCP Port `445`)
  * **SSDP / Simple Service Discovery Protocol** (UDP Port `1900`)

### C. Live Speed & Connection Event Batching (`NativeEventBus`)
Reporting each intercepted packet to Flutter creates severe performance issues. At high throughput (e.g., a 10 MB/s download), this can trigger over 7,000 serialized messages per second over the platform channel, causing the Flutter UI thread to drop frames and freeze.
* **Aggregator Buffer**: The `NativeEventBus` utilizes a thread-safe synchronized list to accumulate connection metadata events.
* **Timer Flush**: A background timer flushes accumulated events every **500 milliseconds**, serializing the lists into a single payload block.
* **Batch Yield**: Flutter parses this batch as a single transaction, reducing platform channel CPU load by **99%** and allowing smooth graph rendering on the canvas.

### D. DNS Guard Engine
Intercepts outgoing DNS requests (UDP port `53`) dynamically:
* **Category Filtering**: Compares the queried domain against lists parsed in memory (Ads, tracking, telemetry, adult content, etc.). If matched, the query returns `NXDOMAIN` (non-existent domain) locally without forwarding.
* **DoH Forwarding**: Valid requests are resolved via a secure DNS-over-HTTPS (DoH) resolver. To prevent a bootstrapping loop where the system default DNS fails while the VPN is coming up, DoH URLs must contain IP-literals (e.g., `https://1.1.1.1/dns-query`) coupled with a hostname for TLS certificate verification.

---

## 3. SQLite Database Schema & Drift ORM

Network Cloak stores all operational parameters, connection statistics, geolocated connections, and rules locally on-device. The database schema is configured via **Drift ORM** in Dart:

| Table Name | Primary Key | Purpose | Key Columns / Schema Details |
| :--- | :--- | :--- | :--- |
| `Settings` | `(category, key)` | Key-value settings store | `key`, `value`, `value_type`, `updated_at` |
| `Profiles` | `id` | Network profiles (e.g., Home, Work) | `name`, `type`, `is_system`, `config_json` |
| `FirewallRules` | `id` | Per-app rule enforcements | `app_id`, `action` (Allow/Block/Ask), `profile_id` |
| `TemporaryRules` | `id` | Time-limited firewall overrides | `app_id`, `action`, `start_at`, `end_at` |
| `SessionRules` | `id` | One-off VPN session permissions | `app_id`, `action`, `session_id` |
| `TrustedNetworks` | `id` | Wi-Fi fingerprints to evaluate Evil Twin | `ssid`, `bssid`, `trust_level` |
| `DnsProfiles` | `id` | Active configuration for DNS resolving | `name`, `provider`, `endpoint`, `blocklists` (JSON) |
| `DnsBlocklists` | `id` | Synced lists of categories | `name`, `category`, `enabled`, `url`, `domain_count` |
| `DnsLogs` | `id` (Auto) | Persistent history of DNS queries | `domain`, `action`, `app_id`, `timestamp` |
| `Applications` | `id` | Cached list of installed system/user apps | `package_name` (Unique), `display_name`, `icon_bytes` |
| `ApplicationStats` | `id` | Aggregate bandwidth data per app | `app_id`, `connections`, `bytes_sent`, `bytes_recv` |
| `ConnectionHistory` | `id` (Auto) | Log of all inbound/outbound packets | `app_id`, `dest_host`, `dest_ip`, `latitude`, `longitude` |
| `Alerts` | `id` | Threat notifications (e.g., Evil Twin flag) | `type`, `severity`, `title`, `body`, `status` |
| `LiveConnections` | `id` | Real-time active socket connections | `app_id`, `dest`, `bytes`, `started_at` |
| `SchemaVersions` | `version` | Migration verification log | `version`, `applied_at`, `description` |

---

## 4. Rule Evaluation Precedence

The native firewall engine evaluates connection permissions using a strictly ordered cascading hierarchy:

```
[Incoming Packet Capture]
          │
          ▼
1. Lockdown Mode Active? ────► [Yes] ──► App is Allowlisted? ──► [No] ──► [BLOCK]
          │                                  │
         [No]                               [Yes] ──► [ALLOW]
          │
          ▼
2. Has Active Temporary Rule? ──► [Yes] ──► Apply Action (Allow/Block/Ask)
          │
         [No]
          │
          ▼
3. Has Custom App-Level Rule? ──► [Yes] ──► Apply Action (Allow/Block/Ask)
          │
         [No]
          │
          ▼
4. Fallback to Active Profile Default ──► Apply Mode Default (Allow/Block)
```

---

## 5. UI Layout & UX Design System

Network Cloak incorporates a customized design system using **Stealth Dark (Dark Mode)** and **High-Clarity Light Mode**:

* **Theme Definitions (`NcColors`)**:
  * `bg`: Deep obsidian black (`0xFF0A0E17`) in Dark mode; pure soft white (`0xFFF8F9FD`) in Light mode.
  * `surface`: Charcoal slate (`0xFF121824`) / Warm light-grey (`0xFFFFFFFF`).
  * `primary`: High-visibility electric blue (`0xFF2563EB`) / Cyan-blue (`0xFF1D4ED8`).
  * `border`: Dark steel grey (`0xFF1F2937`) / Pale grey (`0xFFE5E7EB`).
  * Action Colors: `chipAllow` (green `0xFF10B981`), `chipBlock` (red `0xFFEF4444`), `chipAsk` (orange `0xFFF59E0B`).

* **De-congested Rule Tiles**: 
  App rule list tiles are split into two sections:
  1. *Header*: Displays the package icon, high-weight text showing the display name, package suffix, and current rule badge (`Allowed`, `Blocked`, `Ask`).
  2. *Footer*: A dedicated bottom actions section housing the active network profile dropdown, live network chips (`Wi-Fi`, `Cellular`, `LAN`, `Background`), and three large quick-action selector buttons (`Allow`, `Block`, `Ask`). When active, buttons toggle to a solid colored fill state.

---

## 6. How to Build & Run Tests

### Generate Code Bindings (Drift ORM)
Generate compiled code database mapping configurations:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Run static code analytics
```bash
flutter analyze
```

### Execute Unit & Integration Tests
Run unit tests for network classification and rule resolution:
```bash
flutter test
```
