# Network Cloak 🛡️

A premium, high-performance Flutter & Android VPN utility designed to protect mobile devices from local network threats, scan exposure, and untrusted network eavesdropping. 

Network Cloak combines packet-level local shielding, dynamic per-app firewall controls, 24/7 real-time network speed monitoring, and DNS query filtering to keep your device secure and invisible on local area networks (LANs).

---

## 🚀 Key Features

*   **Cloak Engine (Local Shielding)**: Active prevention of LAN exposure. Automatically drops multicast/broadcast discovery packets:
    *   **mDNS** (port `5353`) & **LLMNR** (port `5355`)
    *   **NetBIOS** (ports `137-139`) & **SMB** (port `445`)
    *   **SSDP / UPnP** (port `1900`)
    *   Multicast IP ranges (`224.0.0.0/4`) and Broadcast (`255.255.255.255`)
*   **Watchtower (Real-Time Traffic Monitor & Speedometer)**:
    *   **24/7 Real-Time Network Speedometer**: Live Download (▼ Rx) and Upload (▲ Tx) speed monitoring powered by system kernel `TrafficStats` and smooth cubic Bezier sparkline charts (works whether VPN is **ON** or **OFF**).
    *   **Geolocated Connection History**: Active logging of connection attempts with dynamic country-flag resolution and reactive Drift SQLite streams.
    *   **IP Network Lookup**: Integrated on-demand ARIN RDAP network registry lookup to identify target servers.
*   **Dynamic Per-App Firewall**: Hardened per-app network blocking (Allow, Ask, Block) handled by a native Android VPN interceptor with instant IPv4 TCP RST, UDP drop, and DNS NXDOMAIN synthesis.
*   **DNS Guard**: Safe DNS resolution and domain-level query filtering.
*   **Android 14 (API 34) Ready**: Fully compliant with Android 14 foreground service policies and permission handling.
*   **Stealth Theme Engine**: Custom, dynamic light and dark (Stealth) modes that sync instantly across native components and the UI.

---

## 🛠️ Architecture & Tech Stack

```mermaid
graph TD
    UI[Flutter UI / Presentation] -->|Riverpod Providers| State[State Management]
    State -->|Drift ORM| DB[(SQLite Local DB)]
    State -->|Platform Channels| NativeBridge[Dart Platform Bridge]
    NativeBridge -->|MethodChannel| KotlinVpn[Kotlin VPN Service]
    KotlinVpn -->|Packet Interceptor| Rules[Rule Repository]
    Rules -->|Drops Multicast/LAN| WAN[Internet Gateway]
```

*   **Frontend**: Flutter (Dart), Flutter Riverpod (State management), GoRouter (Declarative navigation).
*   **Database**: SQLite via Drift ORM for quick, asynchronous write-ahead logging of connection history.
*   **Android Native**: Kotlin-based `VpnService` backend that registers a virtual network interface, parses IP/TCP/UDP packet headers, and applies security rules.

---

## 📂 Project Structure

```
Network Cloak/
├── android/                   # Kotlin VPN implementation & unit tests
│   └── app/src/main/kotlin/com/networkcloak/network_cloak/
│       ├── NetworkCloakVpnService.kt   # Core VpnService runner & packet loop
│       ├── RuleRepository.kt           # Local rules, per-app logic & Cloak engine
│       ├── PlatformChannelHandler.kt   # Method channel communication & TrafficStats
│       └── MainActivity.kt             # Flutter Activity & VPN permission handler
├── lib/                       # Flutter Application source code
│   ├── app/
│   │   ├── theme/             # NcColors, NcTextStyles, AppTheme (Light & Dark)
│   │   └── router.dart        # GoRouter navigation schema
│   ├── data/
│   │   └── database/          # AppDatabase using Drift SQLite
│   ├── domain/                # Shared model definitions and enums
│   ├── platform/              # Platform Channel bridge integrations
│   └── presentation/          # Feature-based presentation screens
│       ├── watchtower/        # Real-time traffic speed graph and logs
│       ├── firewall/          # Firewall configuration and rule editors
│       ├── settings/          # Cloak Engine options, Appearance, and About
│       └── onboarding/        # First-run guided setup
└── test/                      # Flutter Dart widget & unit tests
```

---

## ⚙️ Getting Started

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.10.7 or later)
*   [Android SDK](https://developer.android.com/studio) (API Level 21+ required)

### Run the App
1.  Clone the repository and navigate to the project directory:
    ```bash
    cd "Network Cloak"
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Generate data models and database code bindings:
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```
4.  Run the application on a connected device/emulator:
    ```bash
    flutter run
    ```

---

## 🧪 Testing

### Flutter (Dart) Tests
Run unit and widget tests:
```bash
flutter test
```

### Static Analysis
```bash
flutter analyze
```
