# Network Cloak — Technical Architecture & Implementation Guide

Welcome to the technical blueprint of **Network Cloak**. This document details the architectural components, execution flows, native platform bridge mechanics, database schema, and custom security engines that power Network Cloak’s localized device shielding and network privacy utilities.

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
        Providers <-->|System TrafficStats Poll| KernelStats[24/7 Live Throughput Engine]
    end

    %% Native Enforcers (Kotlin)
    subgraph Kotlin Layer (Android Native)
        PlatformBridge <-->|MethodChannel| NativeChannel[Platform Channel Handler]
        NativeChannel -->|Sets Rules / Config| Rules[(In-Memory Rule Repository)]
        NativeChannel -->|Syncs Blocklists| DnsEngine[DNS Guard Engine]
        NativeChannel -->|Foreground Service Ops| VpnLifecycle[Android VpnService Lifecycle Manager]

        VpnService[NetworkCloakVpnService] <-->|Capture Packets| TUN[Virtual TUN Interface]
        VpnService -->|Evaluate Rules| Rules
        VpnService -->|Intercept DNS queries| DnsEngine
        VpnService -->|Multicast/Broadcast Filters| Cloak[Cloak Shield Engine]
        VpnService -->|Zero-Latency App State| UidMapper[ActivityManager Reflection Proxy]

        %% Buffered Connection Logs
        VpnService -->|Log ConnectionEvent| LogQueue[Native Event Buffer]
        LogQueue -->|Batch Flush every 500ms| BatchHandler
    end

    %% Outgoing Networking
    Rules -->|Allow/Forward| WAN[Internet Gateway]
    Rules -->|Drop / TCP RST / DNS NXDOMAIN| Drop[Connection Terminated]
    Cloak -->|Block Multicast/SMB| Drop
    DnsEngine -->|Block / Resolve Local| Client[DNS Response Payload]
    DnsEngine -->|Forward Valid Queries| DoH[Secure DoH Resolvers]
```

---

## 2. Kotlin Native VPN & Traffic Interceptor

The core protection of Network Cloak resides inside the custom Kotlin package `com.networkcloak.network_cloak` running inside the Android OS background process space.

### A. Virtual TUN Interface & Per-App Routing Strategy
The `NetworkCloakVpnService` class subclasses Android's standard `VpnService` API.
* **Interface Establishment**: Upon starting, the service establishes a virtual network TUN interface (`FileDescriptor`) configured with private IPv4 subnets (`10.0.0.1/32`) and optional IPv6 routes (`2001:db8:1::1/64`, wrapped safely in try-catch for kernel compatibility).
* **Per-App TUN Routing**:
  To ensure zero latency and prevent TCP loopback recursion without needing native third-party binaries:
  * **Blocked Apps**: Added to the TUN interface via `builder.addAllowedApplication(pkg)`. Their TCP packets receive immediate `TCP RST` packets; UDP/ICMP packets are dropped silently; DNS queries receive instant `NXDOMAIN` (RCODE 3 - Domain Not Found).
  * **Allowed Apps**: Bypass the TUN interface entirely and use the OS network stack natively over IPv4 & IPv6 with zero lag.
  * **Lockdown Mode**: Intercepts all device applications, routing everything into the TUN interface while excluding only essential telephony (`com.android.phone`) and allowlisted emergency apps.

### B. Cloak Shield Engine (SSDP, SMB, mDNS Blockers)
To make the device completely invisible on local area networks (LANs), the native `RuleRepository` drops local discovery and network exposure protocols before they escape the device:
* **Multicast/Broadcast Drops**: Blocks IP ranges matching the multicast mask `224.0.0.0/4` and the local subnet broadcast address `255.255.255.255`.
* **Port-Level Blocks**: Dropped outgoing connection attempts targeting:
  * **mDNS / Multicast DNS** (UDP Port `5353`)
  * **LLMNR / Link-Local Multicast Name Resolution** (UDP Port `5355`)
  * **NetBIOS Name Service / Session** (UDP Ports `137`, `138` and TCP Port `139`)
  * **SMB / Server Message Block** (TCP Port `445`)
  * **SSDP / Simple Service Discovery Protocol** (UDP Port `1900`)

### C. Live Speed & System Kernel TrafficStats (VPN ON & VPN OFF)
Watchtower monitors real-time network throughput 24 hours a day, 7 days a week:
* **Kernel TrafficStats Sampling**: `ThroughputNotifier` polls system kernel counters (`TrafficStats.getTotalRxBytes()` and `TrafficStats.getTotalTxBytes()`) every second via `PlatformChannelBridge.getSystemTrafficStats()`.
* **Dynamic Breakdown**: Calculates current Download speed (▼ Rx B/s, KB/s, MB/s) and Upload speed (▲ Tx B/s, KB/s, MB/s) regardless of whether the VPN is running or stopped.
* **Aggregator Buffer (`NativeEventBus`)**: When the VPN is active, connection metadata events flush in 500ms batches over the `EventChannel`, updating the live connections log with 0 dropped UI frames.

### D. DNS Guard Engine
Intercepts outgoing DNS requests (UDP port `53`) dynamically:
* **Category Filtering**: Compares the queried domain against lists parsed in memory (Ads, tracking, telemetry, adult content, etc.). If matched, the query returns `NXDOMAIN` (non-existent domain) locally without forwarding.
* **DoH Forwarding**: Valid requests are resolved via a secure DNS-over-HTTPS (DoH) resolver using IP-literals to prevent DNS bootstrapping loops.

---

## 3. Rule Evaluation Precedence

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

## 4. Android 14 (API 34) & Foreground Service Compliance

* **Foreground Service Startup**: `MainActivity.kt`, `PlatformChannelHandler.kt`, and `BootReceiver.kt` use `ContextCompat.startForegroundService(intent)` on Android 8.0+ (API 26+) to eliminate `ForegroundServiceStartNotAllowedException` crashes.
* **Android 14 Special Use Type**: `NetworkCloakVpnService` declares `android:foregroundServiceType="specialUse"` in `AndroidManifest.xml` and passes `ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE` to `startForeground()` on Android 14 (API 34+).

---

## 5. How to Build & Run Tests

### Generate Code Bindings (Drift ORM)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Run static code analytics
```bash
flutter analyze
```

### Execute Unit & Integration Tests
```bash
flutter test
```

### Build Release APK
```bash
flutter build apk
```
