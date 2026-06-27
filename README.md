# Quickshell Wayland Bar

A highly customizable, beautiful, and dynamic top bar and shell environment for Wayland compositors (like Hyprland, Sway), built entirely using [Quickshell](https://git.outfoxxed.me/outfoxxed/quickshell) and QML.

## ✨ Features

- **Dynamic Top Bar**: A responsive top bar that adapts to your environment.
- **Control Center**: Quick access to toggles, sliders (volume, brightness), and system stats.
- **Network & Bluetooth Management**: Dedicated panels for managing Wi-Fi (`WifiPanel.qml`) and Bluetooth (`BtPanel.qml`) connections directly from the shell.
- **Notification Island**: An elegant, dynamic notification system with watcher and island popup integrations.
- **Media Card**: Control your currently playing media and view album art.
- **Calendar & Weather**: Beautiful drop-down cards for weather information and calendar/date checking.
- **Wallpaper Switcher**: Interactive wallpaper card to manage and switch your background.
- **IPC Support**: Change states and toggle windows (e.g., toggle workspaces, wallpaper, weather) easily using Quickshell's IPC handlers.

## 📸 Structure

- `shell.qml`: The main entry point defining the Quickshell `ShellRoot`, IPC handlers, and window layouts.
- `Bar.qml` & `BarContent.qml`: Core top bar layout and logic.
- `ControlCenter.qml`: Expanding quick-settings menu.
- `NotificationIsland.qml` / `NotificationWatcher.qml`: Notification daemons and UI.
- `Theme.qml`: Centralized theming and styling configuration.

## 🚀 Prerequisites

Before running this shell, ensure you have the following installed on your system:
- A Wayland compositor (Hyprland is highly recommended).
- [Quickshell](https://outfoxxed.me/quickshell) installed and accessible in your `$PATH`.
- Necessary Qt and QML dependencies as required by Quickshell.

## 🛠️ Usage

To launch the shell, simply run Quickshell pointing to the root of this directory:

```bash
quickshell -c ./shell.qml
```

### IPC Commands

You can use `quickshell`'s IPC feature to bind keyboard shortcuts in your compositor (e.g., in `hyprland.conf`) to toggle various cards:

- **Toggle Workspaces/Center Mode**: `quickshell ipc bar toggleWorkspaces`
- **Toggle Wallpaper Card**: `quickshell ipc bar toggleWallpaper`
- **Toggle Weather Card**: `quickshell ipc bar toggleWeather`

## 🎨 Theming

All theme colors, dimensions, and visual properties are handled in QML. You can modify `Theme.qml` (if present) or the specific component files to match your system's color palette, borders, and typography.

## 🤝 Contributing

Feel free to fork this repository, make changes, and submit pull requests. If you find any bugs or have feature requests, please open an issue!

## 📝 License

Distributed under the MIT License. See `LICENSE` for more information.
