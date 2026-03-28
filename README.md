# 🌌 PROGRESSO HQ: THE HUNTER SYSTEM

> *"Human strength lies in the ability to change yourself. The System is merely the ledger of that change." - Saitama*

<div align="center">

[![Flutter](https://img.shields.io/badge/Engine-Flutter_3.x-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev/)
[![Version](https://img.shields.io/badge/System_Version-v1.1.0_(Awakening)-EBFB7E?style=for-the-badge&labelColor=171717)]()
[![Platform](https://img.shields.io/badge/Platform-Win_|_Lin_|_And-8A2BE2?style=for-the-badge)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)]()
[![Size](https://img.shields.io/badge/Vault_Size-Offline_First-4CAF50?style=for-the-badge)]()

</div>

**Progresso HQ** is a local-first, cross-platform, gamified life-management Vault. It is designed to ruthlessly track your real-world ambitions and translate them into tangible RPG mechanics. 

Built natively in Flutter, it tracks your physical conditioning, intellectual growth, deep work focus, and unwavering consistency across all your devices without relying on third-party cloud servers. Your data belongs to you, secured on your local hardware, and synced peer-to-peer across your personal network.

Welcome to the System, Hunter. Your awakening begins now.

---

## 📑 The Master Ledger
1. [Visual Reconnaissance (System UI)](#-visual-reconnaissance-system-ui)
2. [System Architecture & Philosophy](#-system-architecture--philosophy)
3. [Core Mechanics: The Status Window](#-core-mechanics-the-status-window)
4. [The Feature Arsenal](#-the-feature-arsenal)
5. [v1.1.0: The Synchronization Architecture](#-v110-the-synchronization-architecture-p2p)
6. [Hard Mode & The Penalty Zone](#-hard-mode--the-penalty-zone-logic)
7. [Deployment & Installation](#-deployment--installation)
8. [The Hunter's Journey (Onboarding)](#-the-hunters-journey-onboarding)
9. [Developer Sandbox & Source Control](#-developer-sandbox--source-control)
10. [Data Models & Technical Stack](#-data-models--technical-stack)
11. [FAQ & Troubleshooting](#-faq--troubleshooting)
12. [Roadmap & Future Horizons](#-roadmap--future-horizons)

---

## 📸 Visual Reconnaissance (System UI)

The System interface dynamically adapts its Canvas geometry based on the host Node. Below is the visual evidence of the Vault's capabilities.

<details open>
<summary><b>🖥️ Desktop Nodes (Windows / Linux) — 13 Core Interfaces</b> <i>[Click to Collapse]</i></summary>
<br>
<p align="center">
  <img src="screenshots/01_domain_pc.png" width="32%" alt="Domain Architecture" />
  <img src="screenshots/02_tasks_pc.png" width="32%" alt="Daily Tasks" />
  <img src="screenshots/03_questlog_pc.png" width="32%" alt="Quest Log" />
</p>
<p align="center">
  <img src="screenshots/04_analytics_pc.png" width="32%" alt="System Analytics" />
  <img src="screenshots/05_achievements_pc.png" width="32%" alt="Achievement Vault" />
  <img src="screenshots/06_mindmap_pc.png" width="32%" alt="Mind Web Engine" />
  
</p>
<p align="center">
  <img src="screenshots/07_mindmap_balanced_pc.png" width="32%" alt="Balanced Mind Map" />
  <img src="screenshots/08_mindmap_timeline_pc.png" width="32%" alt="Timeline Mind Map" />
  <img src="screenshots/09_mindmap_viewdomain.png" width="24%" alt="View Domain Map" />
</p>
<p align="center">
  <img src="screenshots/10_music_pc.png" width="24%" alt="System Music Player" />
  <img src="screenshots/11_manual_pc.png" width="24%" alt="Hunter Manual" />
  <img src="screenshots/12_settings_pc.png" width="24%" alt="System Settings" />
  <img src="screenshots/13_profile_pc.png" width="32%" alt="Hunter Profile" />
</p>
</details>

<details>
<summary><b>📱 Mobile Nodes (Android) — 12 Core Interfaces</b> <i>[Click to Expand]</i></summary>
<br>
<p align="center">
  <img src="screenshots/a_domain_android.jpeg" width="24%" alt="Mobile Domain" />
  <img src="screenshots/b_tasks_android.jpeg" width="24%" alt="Mobile Tasks" />
  <img src="screenshots/c_logs_android.jpeg" width="24%" alt="Mobile Logs" />
  <img src="screenshots/d_analytics_android.jpeg" width="24%" alt="Mobile Analytics" />
</p>
<p align="center">
  <img src="screenshots/e_achievements_android.jpeg" width="24%" alt="Mobile Achievements" />
  <img src="screenshots/f_mindmap_android.jpeg" width="24%" alt="Mobile Mind Web" />
  <img src="screenshots/g_mindmap_create_android.jpeg" width="24%" alt="Create Mind Map" />
</p>
<p align="center">
  <img src="screenshots/h_mindmap_viewdomain_android.jpeg" width="24%" alt="Mobile View Domain" />
  <img src="screenshots/i_manual_android.jpeg" width="24%" alt="Mobile Manual" />
  <img src="screenshots/j_music_android.jpeg" width="24%" alt="Mobile Music Player" />
  <img src="screenshots/k_settiings_android.jpeg" width="24%" alt="Mobile Settings" />
  <img src="screenshots/l_profile_android.jpeg" width="24%" alt="Mobile Profile" />
</p>
</details>


---

## 🏛️ System Architecture & Philosophy

The modern world is obsessed with cloud synchronization. Progresso HQ violently rejects this paradigm. 

### The Local-First Manifesto
* **Absolute Privacy:** Your goals, your failures, and your daily habits are stored exclusively on your hardware's internal storage (`SharedPreferences` & local Documents directory). No tracking, no telemetry, no centralized database.
* **Zero Latency:** Because the System doesn't wait for server responses, interactions (completing a quest, rendering a complex mind map) happen in under 16 milliseconds (60+ FPS).
* **Guaranteed Uptime:** You can manage your life, log your focus hours, and view your stats deep in the wilderness with zero internet connection. 

---

## 📊 Core Mechanics: The Status Window

Your real-world actions directly influence your System Attributes. You can view your current build at any time in the **User Profile Status Window**, which generates a dynamic Radar Chart (painted pixel-by-pixel via Flutter's `CustomPaint` engine).

### The Mathematical Formulas
* **💪 STR (Strength):** Tracks physical conditioning.
  * *Workflow:* Log *Exercise Hours* in the Analytics Tab.
  * *Math:* Every 1 hour logged = +10 STR EXP.
* **🧠 INT (Intelligence):** Tracks your mental grind and skill acquisition.
  * *Workflow:* Complete *Deep Work Timer* sessions linked to Cognitive Domains.
  * *Math:* Every 1 hour logged = +10 INT EXP.
* **⚡ AGI (Agility):** Tracks execution speed and daily throughput.
  * *Workflow:* Complete *Daily Quests* from your task board.
  * *Math:* Base completion = +5 AGI EXP. Completing tasks *before* 12:00 PM yields a 1.5x early-bird multiplier.
* **🛡️ WIL (Willpower):** Tracks unbreakable discipline. This is your most volatile stat.
  * *Workflow:* Do not miss a day of completing at least one task.
  * *Math:* Calculated linearly as `Current Unbroken Streak × 5`. 
  * *Risk:* If you break the chain, your streak resets to 0, and your Willpower crashes instantly. Never miss a day.

### Awakened Level System
Your overall "Awakened Level" is not an average of your stats; it is mathematically determined by the consistency of your grind. 
`Base Level = 1 + (Total Lifetime Quests Completed / 10) + (Max Historical Streak * 0.5)`

---

## ⚔️ The Feature Arsenal

### 🕸️ The Mind Web Engine (v1.1.0 Innovation)
Break down massive life goals into interactive visual maps. 
* **The Logic:** You create **Root Domains** (e.g., Programming). Inside, you nest **Sub-Directories** (e.g., Web Dev, Mobile Dev). Inside those, you nest **Skills** (e.g., Flutter, React).
* **Layout Mathematics:** The System algorithms calculate parent-child node coordinates to generate three distinct map styles:
  * *Org-Chart:* Top-down strict hierarchy.
  * *Timeline:* Left-to-right sequential prerequisites.
  * *Hub:* Centralized radial node distribution.
* **Visual Mastery:** Track progression from 0% to 100% mastery. The UI dynamically interpolates colors from E-Rank (Red/Black) up to S-Rank (Gold/White) based on the completion ratio of sub-skills.

### ⏱️ Deep Work Focus Timer
Select any Skill from your Mind Web and initiate a Focus Session. 
* *Workflow:* The System overlay takes over your screen, utilizing Flutter's `TickerProvider` to maintain frame-perfect countdowns. 
* *Reward:* Upon completion, the elapsed time is automatically written to the local SharedPreferences ledger, instantly updating your INT or STR stats and generating a log entry.

### 📅 Daily Quest Board & Tactical Postpone
Plan your day with lethal precision. 
* Add daily tasks for Today, Tomorrow, or pick a specific date from the built-in calendar engine. 
* **Tactical Postpone:** If the battlefield changes, swipe right on a task to access the Tactical Postpone action, pushing the quest to a future date, effectively altering its `assignedDate` property in the JSON array without breaking your active streak.

### 🎯 Epic Milestones (Time-Boxed Campaigns)
Some goals require sustained effort over weeks or months. 
* *Workflow:* Forge an Epic Milestone by setting a massive long-term objective, assigning a difficulty weight, and locking in a strict Unix-timestamp deadline.
* *Conquest:* Claim victory if you achieve the objective before the countdown timer hits zero, securing a massive EXP injection to your core stats.
* *Defeat:* If the system clock passes the deadline, the Milestone is mathematically marked as a failure and permanently etched into your graveyard logs as a missed opportunity.

### 🏆 Achievement Vault
Unlock custom badges as you hit milestones. The System runs a silent background listener after every action to check conditions: 
* Reaching 100% Global Progress in a Domain.
* Logging 10,000 hours total.
* Maintaining a 365-day streak.
* Rising from an F-Rank Recruit to a National Level Monarch.

---

## 📡 v1.1.0: The Synchronization Architecture (P2P)

How do you sync a Desktop and Mobile app without a cloud database? By turning your devices into local network servers.

### The Master/Slave Node Hierarchy
To absolutely prevent data collisions and duplicated arrays, Progresso utilizes a strict, unidirectional data flow:
1. **Master Node (Source of Truth):** You designate one device (usually your PC) as the Master. Its internal JSON ledger is considered absolute.
2. **Slave Nodes (Field Devices):** Your mobile devices act as Slaves. 
3. **The Overwrite Protocol:** When a sync is initiated, the Master's entire `SystemData` state is serialized, transmitted, and ruthlessly overwrites the Slave node's state. There is no complex merging—only assimilation to the Master's state.

### The UDP/mDNS Radar Scan Workflow
Gone are the days of manually typing `192.168.x.x` IP addresses. 
1. **The Pulse:** Ensure both devices are on the same Wi-Fi network. Open the Sync Panel on both.
2. **The Beacon:** The Master Node opens a background `ServerSocket` and begins broadcasting a UDP Datagram containing its identity (`"PROGRESSO_MASTER_NODE_ALIVE"`).
3. **The Catch:** The Slave node listens on the designated UDP port. When it catches the beacon, it extracts the Master's local IP address.
4. **The Handshake:** The Slave node makes an HTTP GET request to the Master's exposed REST API endpoint.
5. **The Payload:** The Master compresses the entire SharedPreferences JSON (including Base64 encoded profile pictures) and transmits it over the local LAN in milliseconds. 
6. **Rehydration:** The Slave node decrypts the payload, updates its local storage, and triggers a global `notifyListeners()` via Provider to instantly refresh the UI.

---

## ☠️ Hard Mode & The Penalty Zone Logic

For those who need extreme loss aversion.

* **The Trigger:** If Hard Mode is enabled in settings, the `SystemController` runs a check every time the app is brought to the foreground. It checks if `DateTime.now()` has passed `23:59:59` of the previous day, AND if the `dailyTasks` array contains items where `isCompleted == false`.
* **The Lockout:** If triggered, the System physically blocks the Flutter `Navigator`. It pushes an impenetrable, full-screen overlay route called the **Penalty Zone**.
* **The Escape:** You cannot access your Dashboard, your Stats, or your Settings. You are forced to accept a physical punishment quest (e.g., 100 Pushups, 5km run). Only by clicking the red "I HAVE SURVIVED" button do you trigger the boolean flag that destroys the overlay and grants you access to your Vault again.

---

## 🚀 Deployment & Installation

The Progresso System is fully compiled and ready for deployment. Navigate to the **[Releases](../../releases)** tab to download the latest artifacts for your operating system.

### 🪟 Windows (.exe)
1. Download `Progresso-HQ-Windows-v1.1.0.zip`.
2. Extract the entire folder anywhere on your PC. *(Crucial: Do not drag the `.exe` out of the folder, it requires the surrounding `.dll` data files).*
3. Run `progresso_system.exe`.

### 🐧 Linux (Native Binaries)
**Debian / Ubuntu / Linux Mint (.deb):**
```bash
# Install the Debian package directly via the package manager
sudo dpkg -i progresso-system_1.1.0_amd64.deb
```
**Arch Linux (Source Tarball):**
Download `progresso-system-arch-release.tar.gz` and build the native `.pkg.tar.zst` using the provided blueprint:
```bash
tar -xzf progresso-system-arch-release.tar.gz
cd progresso-system-arch-release
makepkg -si
```

### 📱 Android (.apk)
1. Download `Progresso_HQ_Vault_v1.1.0.apk` directly to your phone.
2. Open the file via your file manager. 
3. *(Note: Ensure "Install from Unknown Sources" is enabled in your Android security settings).*

---

## 🗺️ The Hunter's Journey (Onboarding)

**Day 1: System Initialization Protocol**
1. **Set Your Identity:** Navigate to the Status Window. Enter your Hunter Name and upload your Profile Emblem.
2. **Forge the Mind Web:** Go to the Domains Tab. Create 3 high-level categories for your life (e.g., `University`, `Fitness`, `Programming`).
3. **Write Your First Quests:** Go to the Daily Tasks Tab. Assign yourself 3 tasks for today.
4. **Log Your First Hours:** Use the Analytics tab to log 1 hour of physical exercise. Watch your STR rise.
5. **Survive to Midnight:** Complete your tasks before the day ends to establish your Streak (WIL = 5).

**Day 7: The Awakening**
By day 7, if you haven't missed a day, your WIL will sit at 35. You will unlock your first Achievement Badge, and your overall Awakened Level will increase, unlocking higher-tier UI colors.

---

## 🛠️ Developer Sandbox & Source Control

For developers looking to compile the System natively, adapt the UI algorithms, or contribute to the offline architecture.

### 1. Environment Setup
Ensure you have the [Flutter SDK](https://flutter.dev/docs/get-started/install) installed and set to the `stable` channel.
```bash
git clone [https://github.com/gokulgowdat/progresso.git](https://github.com/gokulgowdat/progresso.git)
cd progresso
flutter clean && flutter pub get
```

### 2. Repository Architecture
```text
progresso_system/
├── android/               # Native Android build scripts (Gradle)
├── linux/                 # Native Linux C++ runners & CMake
├── windows/               # Native Windows C++ runners & MSVC
├── assets/                # Local fonts and default SVGs/PNGs
├── lib/                   # The Core Dart Codebase
│   ├── models/            # JSON Serialization (Task, Domain, SystemData)
│   ├── screens/           # Main scaffold routes (Dashboard, MindMapEditor)
│   ├── tabs/              # Sub-routes for the bottom navigation bar
│   ├── services/          # Business Logic (SyncEngine, StorageEngine)
│   ├── theme/             # Dynamic Dark/Light mode color palettes
│   └── widgets/           # Reusable UI components (DomainCard, TimerOverlay)
├── .github/workflows/     # CI/CD Windows Cloud Forge Pipeline
└── pubspec.yaml           # Flutter package dependencies
```

### 3. Forging Local Artifacts from Source

**Android APK (ARM64 Optimized):**
```bash
flutter build apk --release --target-platform android-arm64
```

**Linux Native Executable:**
```bash
flutter build linux --release
```

**Windows (.exe) via CI/CD:**
This repository utilizes **GitHub Actions**. By pushing code to the `main` branch, you can trigger the *Windows Release Forge* workflow from the Actions tab. A dedicated cloud server will compile the C++ binaries and automatically generate a downloadable `.zip` artifact in the workflow summary.

---

## 🗄️ Data Models & Technical Stack

### State Management: `Provider`
The entire application state is held in a single `SystemController` injected at the root of the app. This allows deeply nested Mind Map nodes to instantly update the global Status Window without expensive prop-drilling.

### The JSON Payload
Here is a simplified look at how a Hunter's life is serialized and saved locally (and transmitted during LAN Sync):
```json
{
  "hunterName": "Gokul",
  "isDarkMode": true,
  "currentStreak": 14,
  "stats": {
    "str": 140,
    "int": 320,
    "agi": 85
  },
  "mindMaps": [
    {
      "id": "dom_001",
      "title": "Computer Science",
      "layoutStyle": "org",
      "nodes": [ ... ]
    }
  ],
  "dailyTasks": [
    {
      "id": "tsk_001",
      "title": "Push Code to GitHub",
      "isCompleted": true,
      "assignedDate": "2026-03-28T00:00:00.000"
    }
  ]
}
```

---

## ❓ FAQ & Troubleshooting

**Q: My Wi-Fi Sync says "Device not found or blocked by firewall."**
> **A:** The UDP Radar relies on local network broadcasting. If you are syncing to a Windows PC, Windows Defender Firewall might aggressively block port `8080` or UDP broadcasts. Go to your Firewall settings, click "Allow an app through firewall", and ensure `progresso_system.exe` has checkmarks for both Private and Public networks. Also, ensure your Wi-Fi router doesn't have "Client Isolation" turned on.

**Q: I turned on Hard Mode and now I'm completely locked out. How do I bypass it?**
> **A:** You don't. That is the fundamental design of the Penalty Zone. Do your pushups, click "I HAVE SURVIVED", and do not fail your daily quests again.

**Q: Why isn't my profile picture syncing to my phone?**
> **A:** Image files cannot be sent directly via standard JSON text. Progresso handles this by intercepting your image upload, converting the raw bytes into a `Base64` string, and saving it as a massive text block in the JSON file. If your image was massive (e.g., a 10MB 4K photo), the payload might be too large for the current buffer. Compress your profile image to a smaller JPEG and try again.

---

## 🔮 Roadmap & Future Horizons

The System is never truly complete. Here are the planned architectural upgrades for future versions:

* **[ ] v1.2.0 - The Armory Update:** Implement an inventory system where completing specific Boss Raids drops "Loot" (custom cosmetic borders for your Radar Chart or UI themes).
* **[ ] v1.3.0 - The Guild Protocol:** Expand the LAN sync to support multi-hunter data viewing. Allow devices on the same network to view each other's Awakened Level and compare Stats.
* **[ ] v1.4.0 - Data Export Engine:** Build a CSV exporter so Hunters can pull their raw Analytics data into Excel or Python for advanced statistical tracking.
* **[ ] v1.5.0 - iOS Deployment:** Adapt the native Android/Linux architecture to support Apple's strict filesystem constraints and release the `.ipa` Vault for iPhone Hunters.

---

<div align="center">
  <i>Forged by gokulgowdat and ZetaChrome (Abel M Punnoose).</i><br>
  <b>Embrace the grind. Protect your streak. Awaken your potential.</b>
</div>