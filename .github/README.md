<div align="center">
    <h1> [ Quickshell/II ] </h1>
    <p>A premium Material 3 / Material You dotfiles for Hyprland, powered by Quickshell.</p>
</div>

<div align="center">
    <h2>• overview •</h2>
</div>

This repository is a heavily customized fork of **[ii-vynx](https://github.com/vaguesyntax/ii-vynx)**, which itself is based on the legendary **[illogical-impulse](https://github.com/end-4/dots-hyprland)**. 

It aims to provide a state-of-the-art Linux desktop experience by strictly adhering to **Material 3 (Material You)** design principles, featuring dynamic theming via Matugen and a highly modular architecture built on **Quickshell**.

<div align="center">
    <h2>• features & differences •</h2>
</div>

This fork introduces several new features and improvements over the original `ii-vynx` dots. Below is a highlight of the main changes:

### ⌨️ Keyboard Layout Management
- **New Indicator & Popup**: A completely redesigned keyboard layout widget for the bar.
- **Quick Switch**: Instant layout switching with a dedicated popup that respects the M3 design system.

<p align="center">
  <img width="452" height="283" alt="image" src="https://github.com/user-attachments/assets/8a6225d9-1d40-43a4-b73c-29bcb7badd80" alt="Keyboard Layout Management" />
</p>

### 🔋 Redesigned System Dialogs
- **Modern Dialogs**: Brand new, premium M3-style dialogs for **Battery**, **Bluetooth**, and **Wi-Fi**.
- **Enhanced Interactions**: Smooth transitions and detailed information at a glance.

<p align="center">
  <img width="351" height="698" alt="image" src="https://github.com/user-attachments/assets/126a5660-9bf6-4e57-a910-2c57127c39a7" alt="Redesigned System Dialogs" />
</p>

### 🔵 New Bluetooth Management
- **Device List**: Integrated Bluetooth device management directly within the shell.
- **Quick Actions**: Easily connect, disconnect, and monitor battery levels of peripherals.

<p align="center">
  <img width="388" height="512" alt="image" src="https://github.com/user-attachments/assets/9473e473-b5f5-4cd5-b634-d0f7c98334a6" />

</p>

### 📅 Cheatsheet & Timetable Integration
- **Event Creation**: You can now create events directly from the cheatsheet timetable.
- **Calendar Sync**: Seamless integration with local calendars (via `khal`) for a full agenda view.

<p align="center">
  <img width="1404" height="840" alt="image" src="https://github.com/user-attachments/assets/608bbf11-9819-4fe0-880c-014fe3845000" />

</p>

### 🎨 Intelligent Color Picker
- **Dynamic Palettes**: Capture colors from your screen and instantly generate Material You palettes.
- **Visual Feedback**: Real-time preview of how the colors look across different M3 layers.

<p align="center">
  <img width="421" height="554" alt="image" src="https://github.com/user-attachments/assets/89e2d851-fda4-4105-a66f-ebbf26d10949" />
</p>

### ⚙️ Native System Settings
- **Centralized Control**: A dedicated settings module to manage all shell options, UI tweaks, and system preferences without editing configuration files manually.

<p align="center">
  <img width="990" height="1002" alt="image" src="https://github.com/user-attachments/assets/0368bf0f-bc5b-482b-ae06-1d291c47e3e2" />

</p>

### 🎥 OBS-Integrated Screen Recording
- **Built-in Control**: Start and stop recordings directly from the bar.
- **OBS Backend**: Leverages the power of OBS Studio for high-quality recording with real-time status feedback in the shell.

### ✅ TickTick Todo Integration
- **Cloud Sync**: Full integration with **TickTick** for task management.
- **Live Sync**: View and manage your tasks directly from the dashboard, synced across your devices.

### ✨ Minor Improvements
Some minor design changes across the system

<div align="center">
    <h2>• warning •</h2>
</div>

These dots are based on **illogical-impulse**. You can access original **illogical-impulse** dots from [here](https://github.com/end-4/dots-hyprland).

While this repository is my daily driver, please be aware that it contains many custom tweaks and features that may still be in active development. Bugs and stability issues might occur. Join the conversation and report issues to help improve the project!

<div align="center">
    <h2>• installation •</h2>
</div>

1. Clone this repository with submodules:

```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git --recurse-submodules
```

2. Run the setup script and follow the instructions:

```bash
./setup-ii-vynx.sh
```

> [!TIP]
> You can see all available flags with `./setup-ii-vynx.sh --help`

<div align="center">
    <h2>• updating •</h2>
</div>

To keep your dots up to date, simply run the setup script again:

```bash
./setup-ii-vynx.sh
```

<div align="center">
    <h2>• documentation •</h2>
</div>

Please refer to the **[wiki](https://github.com/vaguesyntax/ii-vynx/wiki)** (shared with the upstream) for detailed component descriptions. Note that some features specific to this fork might not be fully documented there yet.

<div align="center">
    <h2>• credits •</h2>
</div>

- **[end-4](https://github.com/end-4):** Creator of illogical-impulse.
- **[vaguesyntax](https://github.com/vaguesyntax):** Creator of ii-vynx (the base for this fork).
- **[Quickshell](https://quickshell.org/):** The amazing Qt-Quick based widget system.
- **[Hyprland](https://hypr.land/):** The best Wayland compositor.

<div align="center">
    <br>
    <p><b>If you like this project, consider giving it a star! ⭐</b></p>
</div>
