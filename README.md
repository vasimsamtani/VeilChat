# 🛡️ VeilChat

<div align="center">

![VeilChat Banner](screenshots/00_Splash_Screen.png#gh-dark-mode-only)

### *Zero-Leakage Privacy-First WhatsApp Client, Duress Cloaking Enclave & Stealth Suite*

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![Baileys](https://img.shields.io/badge/WhatsApp-Multi--Device_Bridge-25D366?style=for-the-badge&logo=whatsapp&logoColor=white)](https://github.com/WhiskeySockets/Baileys)
[![Security](https://img.shields.io/badge/Encryption-AES--256--GCM-FF5722?style=for-the-badge&logo=shield&logoColor=white)](#-security-architecture)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

<br/>

[Key Features](#-key-features) • [Screenshots](#-visual-showcase--screenshots) • [Architecture](#-architecture) • [Getting Started](#-getting-started) • [Default PINs](#-default-credentials--pins) • [Project Structure](#-project-structure)

</div>

---

## 📖 Overview

**VeilChat** is an advanced, privacy-hardened alternative client and security enclave for **WhatsApp**. Built with **Flutter** and powered by a local **Node.js Multi-Device Daemon** (`@whiskeysockets/baileys`), VeilChat addresses the vulnerabilities of standard messaging clients—such as shoulder-surfing, forensic exposure, coerced unlocks, and invasive telemetry.

With VeilChat, sensitive contacts are veiled behind **animated shimmer redaction masks**, incoming notifications are **camouflaged** as routine system alerts, and a **Dual-PIN Duress Architecture** provides believable deniability under coercion: unlocking with a decoy PIN displays a realistic, benign conversation with zero forensic residue of confidential data.

---

## 📸 Visual Showcase & Screenshots

### 1. App Launch & Multi-Device Pairing

| Screen 0: Splash & Brand Launch | Screen 1: WhatsApp Bridge & Pairing |
|:---:|:---:|
| <img src="screenshots/00_Splash_Screen.png" width="280" alt="Splash Screen" /> | <img src="screenshots/01_WhatsApp_Bridge_Setup.png" width="280" alt="WhatsApp Bridge Setup" /> |
| *Liquid Glass branded launch with cryptographic key verification* | *Direct multi-device QR pairing over local WebSocket daemon with laser scan animation* |

---

### 2. Veiled Chat Feed & Biometric / PIN Unlock

| Screen 2: Unified Veiled Chat Feed | Screen 3: Biometric & Keypad Modal |
|:---:|:---:|
| <img src="screenshots/02_Unified_Veiled_Chat_Feed.png" width="280" alt="Unified Veiled Chat Feed" /> | <img src="screenshots/03_Biometric_Keypad_Modal.png" width="280" alt="Biometric & Keypad Modal" /> |
| *In-feed Shimmer Redaction disguises preview text and prevents shoulder-surfing* | *Secure biometric and dual-PIN keypad with tactile randomized response* |

---

### 3. Real Unlocked View vs. Decoy Duress Mode

| Screen 4: Real Unlocked Conversation | Screen 5: Decoy Mode (Coercion Protection) |
|:---:|:---:|
| <img src="screenshots/04_Unlocked_Conversation_View.png" width="280" alt="Unlocked Conversation View" /> | <img src="screenshots/05_Decoy_Mode_Chat.png" width="280" alt="Decoy Mode Chat" /> |
| *Confidential chat with live countdown radial timer, quick panic lock, and vault saver* | *Innocent dummy conversation displayed when entering the decoy PIN under duress* |

---

### 4. Privacy & Tactical Camouflage Settings

<div align="center">

| Screen 6: Privacy & Camouflage Settings |
|:---:|
| <img src="screenshots/06_Privacy_Camouflage_Settings.png" width="300" alt="Privacy & Camouflage Settings" /> |
| *Tactical Enclave status, Ghost Mode toggles, auto-lock timeouts, and stealth notification disguises* |

</div>

---

## ✨ Key Features

### 🎭 Dual-PIN Duress Architecture (Plausible Deniability)
- **Primary PIN (`1234`)**: Unlocks confidential conversations, encrypted media, and genuine chat history.
- **Decoy PIN (`9999`)**: If forced to unlock under physical coercion or inspection, the decoy PIN opens a harmless, pre-populated casual chat (e.g. lunch plans), showing no forensic indicator that another PIN exists or that confidential messages are hidden.
- **Biometric Authentication**: Fingerprint and Face ID support for rapid single-touch access.

### 🛡️ In-Feed Shimmer Redaction & Cloaking
- Sensitive conversations are cloaked directly in the chat feed with continuous **animated shimmering redaction bars**.
- Contact names and message previews remain protected from casual shoulder-surfers.
- Per-conversation lock toggles enable selective privacy for specific contacts.

### ⏱️ Radial Auto-Relock Timer & Panic Button
- **Configurable Auto-Lock**: Choose between **15s, 30s, 60s, or 120s** auto-lock timeouts.
- **Live Progress Ring**: A subtle radial progress indicator in the app bar counts down the remaining seconds of unlocked access.
- **Instant Panic Lock**: A dedicated top-bar lock button instantly scrubs unlocked memory and pops back to the redacted feed.
- **Lifecycle Auto-Lock**: Minimizing, backgrounding, or switching away from the app instantly re-locks all chats.

### 👻 Ghost Mode & WhatsApp Stealth Suite
- **Ghost Read Receipts**: Read incoming messages silently; senders only receive double grey ticks (no blue checkmarks).
- **Stealth Story / Status Viewer**: Inspect contacts' WhatsApp stories without appearing on their viewer list.
- **Concealed Presence**: Disables outbound "typing..." and "recording audio..." presence indicators.
- **View-Once Auto-Vault**: Intercepts ephemeral "View-Once" images and audio clips and saves them to an encrypted offline vault.
- **Anti-Revoke Message Keeper**: Retains inbound messages locally even if the sender executes "Delete for Everyone".

### 🔔 Stealth Notification Camouflage
- Incoming notification alerts from locked contacts are masked as innocuous system notices:
  - *Google Calendar: Team Sync in 15m*
  - *System Update: Synced successfully*
  - *News Alert: Markets close higher today*

### 🌉 Native Multi-Device Daemon
- Powered by a local Node.js daemon running `@whiskeysockets/baileys`.
- Direct communication using the WhatsApp Noise Protocol Framework over WebSocket (`ws://localhost:5055`).
- Does **not** require an open browser tab or an always-on phone connection once linked.

### 🎨 Liquid Glass & Tactical Enclave Design
- Cyberpunk-inspired dark aesthetic (`#111319` obsidian background).
- Cyber Cyan, Emerald Neon, and Primary Violet neon accents with frosted glassmorphic cards (`GlassCard`).

---

## 🏛️ Architecture

```mermaid
flowchart TD
    subgraph MobileApp["VeilChat Flutter Client (Dart)"]
        UI["UI Layer\n(Shimmer Redaction, Dual-PIN Modal, Chat Feed)"]
        SecService["ChatSecurityService\n(PIN Validator, Auto-Lock Timer, Vault)"]
        BridgeService["WhatsAppBridgeService\n(WebSocket Client ws://localhost:5055)"]
        Theme["VeilTheme\n(Liquid Glass Dark Palette)"]
        
        UI --> SecService
        UI --> BridgeService
        SecService <--> BridgeService
    end

    subgraph LocalDaemon["Local Bridge Daemon (Node.js)"]
        WS["WebSocket Server\n(Port 5055 IPC)"]
        Baileys["Baileys Engine\n(@whiskeysockets/baileys)"]
        AuthState["Multi-File Auth Keystore\n(auth_info_baileys/)"]
        ChatCache["Encrypted Chat Store\n(chats_store.json)"]
        
        WS <--> Baileys
        Baileys <--> AuthState
        Baileys <--> ChatCache
    end

    subgraph WA["WhatsApp Cloud Infrastructure"]
        WANoise["WhatsApp Noise Protocol\n(Multi-Device E2EE Servers)"]
    end

    BridgeService <== "WebSocket IPC (JSON Events)" ==> WS
    Baileys <== "Encrypted Noise Protocol" ==> WANoise
```

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your machine:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.13 or newer)
- [Dart SDK](https://dart.dev/get-dart) (v3.0 or newer)
- [Node.js](https://nodejs.org/) (v18.x or v20.x LTS) & `npm`
- An active WhatsApp account on your mobile phone

---

### Step 1: Clone the Repository

```bash
git clone https://github.com/vasimsamtani/VeilChat.git
cd VeilChat
```

---

### Step 2: Start the WhatsApp Bridge Daemon

You can start the bridge using the bundled Windows script or manually via npm:

#### Option A: Quick Launch (Windows)
Double-click `start_bridge.bat` or run:
```cmd
start_bridge.bat
```

#### Option B: Terminal (Cross-Platform)
```bash
cd server
npm install
npm start
```

The bridge server will listen on `ws://localhost:5055` and output a terminal pairing QR code if no previous session exists.

---

### Step 3: Run the Flutter Client

Open a new terminal window at the root of the repository:

```bash
# Get Flutter dependencies
flutter pub get

# Launch on your preferred device (Windows, Android, iOS, macOS, Web)
flutter run
```

---

### Step 4: Link Your WhatsApp Account

1. In VeilChat, navigate to the **WhatsApp Bridge** screen (tap the QR scanner icon in the top bar).
2. Open **WhatsApp** on your mobile phone.
3. Go to **Settings** > **Linked Devices** > **Link a Device**.
4. Scan the animated QR code rendered on the VeilChat screen.
5. Your chats will synchronize with zero-knowledge local encryption!

---

## 🔑 Default Credentials & PINs

VeilChat comes pre-configured with the following default PINs (both can be changed inside **Privacy & Stealth Controls**):

| Mode | PIN | Purpose |
|:---|:---:|:---|
| **Primary Real PIN** | `1234` | Unlocks genuine confidential chats and vault |
| **Decoy / Duress PIN** | `9999` | Displays fake, harmless conversation during coerced access |

> [!TIP]
> You can customize both the **Primary PIN** and **Decoy PIN**, as well as the auto-lock duration (15s–120s), in **Settings > Privacy & Stealth Controls**.

---

## 📁 Project Structure

```
VeilChat/
├── assets/                     # App icons and graphical assets
├── lib/
│   ├── data/
│   │   ├── models/
│   │   │   └── chat_model.dart             # Chat and Message data models
│   │   └── services/
│   │       ├── chat_security_service.dart   # PIN auth, countdown timers, decoy logic
│   │       └── whatsapp_bridge_service.dart # WebSocket IPC communication with Baileys
│   ├── ui/
│   │   ├── core/
│   │   │   ├── theme.dart                   # Liquid Glass cyber theme & color tokens
│   │   │   └── widgets/
│   │   │       ├── glass_card.dart          # Frosted glass container widget
│   │   │       └── shimmer_redaction.dart   # Shimmer effect for redacted messages
│   │   └── features/
│   │       ├── auth/
│   │       │   └── security_keypad_modal.dart # Custom secure numeric keypad
│   │       ├── bridge/
│   │       │   └── bridge_screen.dart       # Laser QR scanner & device linking
│   │       ├── chat_list/
│   │       │   └── chat_list_screen.dart    # Redacted feed, filter tabs, ambient strip
│   │       ├── conversation/
│   │       │   └── conversation_screen.dart # Chat view, radial timer, decoy handler
│   │       ├── settings/
│   │       │   └── privacy_settings_screen.dart # Tactical Enclave, Ghost Mode, PINs
│   │       └── splash/
│   │           └── splash_screen.dart       # Animated brand launch screen
│   └── main.dart                            # Application lifecycle & Provider setup
├── server/
│   ├── auth_info_baileys/                   # Multi-device session credentials (git-ignored)
│   ├── bridge.js                            # WebSocket server + Baileys socket integration
│   ├── Dockerfile                           # Container definition for bridge daemon
│   └── package.json                         # Node.js dependencies (@whiskeysockets/baileys)
├── screenshots/                             # High-resolution screenshots for README
├── start_bridge.bat                         # Quick-start script for Windows
├── pubspec.yaml                             # Flutter dependencies & metadata
└── README.md                                # Repository documentation
```

---

## 🔒 Security & Privacy Philosophy

1. **Zero External Telemetry**: VeilChat sends zero diagnostic metrics, analytics, or crash reports to third-party servers.
2. **Local Keystore Enclave**: WhatsApp credentials remain strictly on your local machine in `server/auth_info_baileys/`.
3. **In-Memory Scrubbing**: Confidential decrypted chats exist only in temporary memory and are immediately scrubbed upon timeout or app backgrounding.
4. **Plausible Deniability**: The decoy subsystem is designed so that entering the decoy PIN does not generate alerts, delays, or indicators that an alternate state exists.

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.

---

<div align="center">
  <sub>Built with ❤️ for privacy advocates, security researchers, and stealth communicators.</sub>
</div>
