---
title: Elden Ring Seamless Co-op
description: Install the Seamless Co-op mod on a Steam Deck and play through the entire game with a friend.
date: 2026-03-23
---

Install the [Seamless Co-op mod](https://www.nexusmods.com/eldenring/mods/510) by LukeYui on a Steam Deck. This lets you play through the entire game cooperatively — no summoning pools, no fog walls, no sending your friend home after a boss.

**Prerequisite:** [SSH access to the Steam Deck](/guides/steam-deck-ssh-setup.html) makes most of these steps much easier. Only one step requires Desktop Mode.

## Overview

1. Download the mod
2. Extract it into the Elden Ring `Game/` directory
3. Configure the password and settings
4. Add the mod launcher as a non-Steam game and force Proton (requires Desktop Mode)
5. Disable Elden Ring auto-updates

## 1. Download the Mod

Download from either source (same files):

- **Nexus Mods:** [nexusmods.com/eldenring/mods/510](https://www.nexusmods.com/eldenring/mods/510) (Manual Download)
- **GitHub:** [LukeYui/EldenRingSeamlessCoopRelease](https://github.com/LukeYui/EldenRingSeamlessCoopRelease/releases)

Over SSH, you can download the latest release directly on the Deck. Check the [GitHub releases page](https://github.com/LukeYui/EldenRingSeamlessCoopRelease/releases) for the current version, then:

```bash
# Replace the URL with the latest release link
curl -LO "https://github.com/LukeYui/EldenRingSeamlessCoopRelease/releases/download/v1.9.5/Seamless.Co-op.v1.9.5-510-1-9-5-1772481623.zip" -o /tmp/ersc.zip
```

## 2. Extract into the Game Directory

The mod goes into the `Game/` subfolder — not the Elden Ring root.

```bash
ELDEN_RING="$HOME/.local/share/Steam/steamapps/common/ELDEN RING/Game"

# Verify the path exists
ls "$ELDEN_RING/eldenring.exe"

# Extract
unzip /tmp/ersc.zip -d "$ELDEN_RING"
```

After extraction, you should have:

```
Game/
├── ersc_launcher.exe
└── SeamlessCoop/
    ├── crashpad/
    │   └── crashpad_handler.exe
    ├── locale/
    │   └── english.json
    ├── ersc.dll
    └── ersc_settings.ini
```

## 3. Configure the Mod

Edit the settings file:

```bash
nano "$ELDEN_RING/SeamlessCoop/ersc_settings.ini"
```

Key settings:

| Setting | What it does | Default |
|---|---|---|
| `cooppassword` | **All players must use the same password** | *(empty — must set this)* |
| `allow_invaders` | Allow PvP invasions during co-op | `1` (on) |
| `allow_summons` | Allow spirit summons in multiplayer | `1` (on) |
| `skip_splash_screens` | Skip intro logos on boot | `0` (off) |
| `enemy_health_scaling` | Enemy HP increase per extra player (%) | `35` |
| `boss_health_scaling` | Boss HP increase per extra player (%) | `100` |
| `save_file_extension` | Co-op save file extension | `co2` |

You can set the password over SSH without a text editor:

```bash
sed -i 's/^cooppassword =.*/cooppassword = YOUR_PASSWORD_HERE/' \
  "$ELDEN_RING/SeamlessCoop/ersc_settings.ini"
```

The co-op save (`.co2`) is separate from your normal save (`.sl2`), so your solo progress is safe.

## 4. Add as a Non-Steam Game (Desktop Mode required)

This step requires the Steam UI — it can't be done over SSH.

1. Switch to **Desktop Mode** (hold Power > Switch to Desktop)
2. Open **Steam**
3. Click **Add a Game** (bottom-left) > **Add a Non-Steam Game**
4. Click **Browse**, navigate to `~/.local/share/Steam/steamapps/common/ELDEN RING/Game/` and select **`ersc_launcher.exe`**
5. Right-click the new library entry > **Properties** > **Compatibility**
6. Check **"Force the use of a specific Steam Play compatibility tool"**
7. Select **Proton 8.0** (or Proton 9 / Experimental — all work, 8.0 is most stable)

> Without forcing Proton, the launcher will try to run as a native Linux binary and fail.

If using other mods alongside Seamless Co-op, add this to **Launch Options**:

```
WINEDLLOVERRIDES="dinput8.dll=n,b" %command%
```

## 5. Disable Elden Ring Auto-Updates

**The mod breaks every time FromSoftware patches the game.** Only update when a new mod version is available.

In Steam: right-click Elden Ring > **Properties** > **Updates** > **"Only update this game when I launch it"**

This way, always launch via the mod's `ersc_launcher` and the base game won't auto-update out from under you.

## 6. Import Your Existing Character (Optional)

The mod uses a separate save file. To bring over your character:

```bash
# Find your vanilla save
find ~/.local/share/Steam/steamapps/compatdata/1245620 -name "ER0000.sl2" 2>/dev/null

# Copy it as a co-op save into the mod's prefix
# (the exact path depends on the non-Steam shortcut's app ID)
cp <path-to-ER0000.sl2> <co-op-prefix-path>/ER0000.co2
```

## Playing

Once everything is set up, launch the game from the **Seamless Co-op launcher** in your Steam library (not the regular Elden Ring entry).

In-game items added by the mod:

| Item | Purpose |
|---|---|
| **Tiny Great Pot** | Host opens a session |
| **Effigy of Malenia** | Join a session |
| **Separation Mist** | Leave a session (use before quitting) |

## Updating the Mod

When a new version is released:

```bash
ELDEN_RING="$HOME/.local/share/Steam/steamapps/common/ELDEN RING/Game"

# Back up your settings (password, scaling, etc.)
cp "$ELDEN_RING/SeamlessCoop/ersc_settings.ini" /tmp/ersc_settings.ini.bak

# Remove old version
rm "$ELDEN_RING/ersc_launcher.exe"
rm -rf "$ELDEN_RING/SeamlessCoop"

# Download and extract new version (update the URL)
curl -LO "https://github.com/LukeYui/EldenRingSeamlessCoopRelease/releases/download/<version>/<filename>.zip" -o /tmp/ersc.zip
unzip /tmp/ersc.zip -d "$ELDEN_RING"

# Restore your settings
cp /tmp/ersc_settings.ini.bak "$ELDEN_RING/SeamlessCoop/ersc_settings.ini"

# Clean up
rm /tmp/ersc.zip /tmp/ersc_settings.ini.bak
```

Your save file and the non-Steam game entry are unaffected.

## Troubleshooting

| Problem | Fix |
|---|---|
| Play button flashes then nothing | Normal — game window may open behind the debug console. Wait a moment. |
| Game doesn't launch | Files must be in `Game/`, not the parent `ELDEN RING/` folder. Check Proton is forced in Compatibility settings. |
| Can't connect to friend | Same mod version? Same password exactly? Check `ersc_settings.ini` on both Decks. |
| Crashes on startup | Disable Discord or other overlays — they conflict with the mod's DLL hooks. |
| WiFi drops during co-op | Steam Deck WiFi can be flaky — a USB-C Ethernet adapter helps. |
| Mod stops working after game update | Expected. Wait for a new mod release, then follow the update steps above. |
