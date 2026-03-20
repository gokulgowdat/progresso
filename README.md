# 🌌 PROGRESSO SYSTEM

> *"Human strength lies in the ability to change yourself." - Saitama*

[![Flutter](https://img.shields.io/badge/Flutter-Cross--Platform-02569B?logo=flutter)](https://flutter.dev/)
[![Version](https://img.shields.io/badge/Version-1.0.0--Genesis-EBFB7E?labelColor=171717)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg)]()

**Progresso System** is a cross-platform, offline-first, gamified life-management Vault. It is designed to turn your real-world ambitions into tangible RPG mechanics. Built natively in Flutter, it tracks your physical conditioning, intellectual growth, deep work focus, and unwavering consistency.

Welcome to the System, Hunter. Your awakening begins now.

---

## 📸 System Interface
*(Upload your screenshots to GitHub and replace these placeholder links!)*
<p float="left">
  <img src="https://via.placeholder.com/250x500.png?text=Mobile+Dashboard" width="24%" />
  <img src="https://via.placeholder.com/250x500.png?text=Status+Window" width="24%" />
  <img src="https://via.placeholder.com/250x500.png?text=Boss+Raids" width="24%" />
  <img src="https://via.placeholder.com/250x500.png?text=Penalty+Zone" width="24%" />
</p>

---

## 📑 Table of Contents
1. [Core Mechanics: The Status Window](#-core-mechanics-the-status-window)
2. [The Hunter's Journey (Getting Started)](#-the-hunters-journey-getting-started)
3. [Feature Arsenal](#-feature-arsenal)
4. [Installation Guide](#-installation-guide)
5. [The Synchronization Protocol](#-the-synchronization-protocol)
6. [Vault Backup & Restore](#-vault-backup--restore)
7. [FAQ & Troubleshooting](#-faq--troubleshooting)
8. [Technology Stack](#-technology-stack)
9. [Developer & Source Control](#-developer--source-control)

---

## 📊 Core Mechanics: The Status Window

Your real-world actions directly influence your System Attributes. You can view your current build at any time in the **User Profile Status Window**, which generates a dynamic Radar Chart of your capabilities.

* **💪 STR (Strength):** Tracks your physical conditioning. Logging *Exercise Hours* directly increases your raw power.
* **🧠 INT (Intelligence):** Tracks your mental grind. Logging *Learn/Work Hours* directly expands your intellect.
* **⚡ AGI (Agility):** Tracks your execution speed. Completing *Daily Quests* (To-Do list items) boosts your agility.
* **🛡️ WIL (Willpower):** Tracks your unbreakable discipline. Your Willpower is calculated as `Current Daily Streak × 5`. If you break the chain, your streak resets, and your Willpower crashes. Never miss a day.

**Leveling Up:** Your overall "Awakened Level" is determined by your current unbroken daily streak.

---

## 🗺️ The Hunter's Journey (Getting Started)

**Day 1: System Initialization**
1. **Set Your Identity:** Navigate to the Status Window. Enter your Hunter Name and upload your Profile Emblem.
2. **Establish Domains:** Go to the Domains Tab. Create 2 or 3 high-level categories for your life (e.g., `University`, `Fitness`, `Programming`).
3. **Write Your First Quests:** Go to the Daily Tasks Tab. Assign yourself 3 tasks for today.
4. **Log Your First Hours:** Use the Analytics tab to log any hours you spent exercising or studying today. Watch your STR and INT stats rise.
5. **Survive to Midnight:** Complete your tasks before the day ends to protect your Streak and level up.

---

## ⚔️ Feature Arsenal

### 📁 Domain & Skill Trees
Break down your massive life goals into manageable Skill Trees. 
* Create **Root Domains** and nest **Sub-Directories** or specific **Skills** inside them.
* Track your progression from 0% to 100% mastery. Each Domain visually grades your progress from E-Rank (Red) up to S-Rank (Gold).

### ⏱️ Deep Work Focus Timer
Select any Skill from your Domain Tree and initiate a Focus Session. The System overlay tracks your deep work and automatically logs the hours to your INT or STR stats upon completion.

### 📅 Daily Quest Board & Tactical Postpone
Plan your day with precision. Add daily tasks for Today, Tomorrow, or pick a specific date from the built-in calendar. If life happens, use **Tactical Postpone** to push a quest to a future date with two clicks.

### 🐉 Boss Raids (Epic Time-Boxed Goals)
Some goals require sustained effort over weeks or months. Initiate a Boss Raid by setting a massive objective and a strict deadline. 
* Claim **Victory** if you achieve it before the timer runs out. 
* **Retreat** (Fail) if the deadline passes. 

### ☠️ Hard Mode: The Penalty Zone
For those who need extreme loss aversion. Enable **Hard Mode** in the Settings. 
* If you fail to complete your assigned Daily Quests before midnight, the System will lock you out. 
* You will be thrown into the **Penalty Zone** and forced to accept a physical punishment quest before the System unlocks your Vault again.

### 🏆 Achievement Vault
Unlock dozens of custom badges as you hit milestones. Reach 100% Global Progress, log 10,000 hours, maintain a 365-day streak, and rise from an F-Rank Recruit to a National Level Monarch.

---

## 🚀 Installation Guide

The Progresso System is fully compiled and ready for deployment across all major operating systems. Navigate to the **[Releases](../../releases)** tab to download the latest artifacts.

### 📱 Android
1. Download the `progresso_system_android.apk` file.
2. Open the file to install it. *(Note: You may need to grant permission to "Install unknown apps" in Android settings).*

### 🪟 Windows
1. Download the `progresso_system_windows_x64.zip` file.
2. Extract the folder anywhere on your PC.
3. Open the extracted folder and double-click `progresso_system.exe`.

### 🐧 Linux
**Debian / Ubuntu / Linux Mint:**
```bash
sudo dpkg -i progresso_1.0.0_amd64.deb
```
**Arch Linux / Other Distros:**
```bash
tar -xf progresso_system_linux_x64.tar.gz
cd bundle
./progresso_system
```

---

## 📡 The Synchronization Protocol (Local Wi-Fi)

Progresso respects your privacy. It uses **Zero Cloud Databases**; your data belongs entirely to you. To keep your PC and Phone synced:

1. Ensure both devices are connected to the **same Wi-Fi network**.
2. Open **Settings** on the device with the *most up-to-date* data (the Host).
3. Look at the `WI-FI AUTO-SYNC` module to find the Host's **System IP** (e.g., `192.168.1.7`).
4. Open Settings on your second device (the Client).
5. Type the Host's IP address into the Target IP box and click **INITIATE SYNC**.
6. The System will compare Epoch timestamps and securely overwrite the older data over your local LAN.

---

## 💾 Vault Backup & Restore

Always secure your progress. 
1. Go to **Settings > Vault Backup**.
2. Click **EXPORT VAULT DATA** to save your entire System history as a portable `.prg` JSON file. 
3. If you move to a new device or wipe your system, use **RESTORE FROM BACKUP** and load your `.prg` file to instantly recover your Hunter Status.

---

## ❓ FAQ & Troubleshooting

**Q: My Wi-Fi Sync says "Device not found or blocked by firewall."**
> **A:** Ensure both devices are on the exact same Wi-Fi. If you are syncing to a Windows PC, Windows Defender Firewall might block port `8080`. Go to your Firewall settings and allow `progresso_system.exe` to communicate on Private Networks.

**Q: I turned on Hard Mode and now I'm locked out!**
> **A:** That is the point of the Penalty Zone. You must click the red "I HAVE SURVIVED" button acknowledging you have completed your punishment before the System will grant you access to your data again.

**Q: Can I change my Rank manually?**
> **A:** No. The System does not lie. Your rank is mathematically tied to the actual work you log.

---

## 💻 Technology Stack
* **Framework:** Flutter (Dart)
* **State Management:** Provider
* **Data Persistence:** SharedPreferences (Local JSON Engine)
* **Networking:** Dart `dart:io` Http Server (Local LAN Sync)
* **UI Elements:** Custom Canvas Painters (Radar Charts), Native File Pickers.

---

## 🛠️ Developer & Source Control

For contributors looking to compile the System from source.

### Rebuilding Artifacts from Source

**1. Android APK:**
```bash
flutter clean && flutter pub get
flutter build apk --release
```

**2. Linux (.deb & .tar.gz):**
```bash
flutter clean && flutter pub get
flutter build linux --release

# Forge Arch Tarball:
cd build/linux/x64/release/ && tar -czvf progresso_system_linux_x64.tar.gz bundle/

# Forge Debian Installer:
dpkg-deb --build progresso_1.0.0_amd64
```

**3. Windows (.exe via GitHub Actions):**
Push your code to the `main` branch, navigate to the **Actions** tab on GitHub, select **Windows Cloud Forge**, and click **Run Workflow**.

### Pushing Code Updates
```bash
git add .
git commit -m "Update: Describe your changes here"
git push origin main
```

---
*Developed by gokulgowdat and ZetaChrome (Abel M Punnoose). Embrace the grind.*