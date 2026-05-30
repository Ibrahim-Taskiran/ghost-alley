# 👻 Ghost Alley

[![Godot Engine](https://img.shields.io/badge/Godot-4.6%2B-blue?logo=godot-engine&logoColor=white)](https://godotengine.org)
[![Physics Engine](https://img.shields.io/badge/Physics-Jolt%20Physics-orange)](https://github.com/godot-jolt/godot-jolt)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Ghost Alley** is a premium 3D Isometric Survival Action RPG prototype built with **Godot Engine 4.x**. Set in a dark, atmospheric alleyway, players must scavenge for resources, manage vital survival needs, craft defensive gear, and survive the terrifying day-night transition where the infected grow stronger and more aggressive.

---

## 🌟 Key Features

### 1. 🎒 Backpack & Pockets Inventory (Two-way Swap)
* **Backpack Layer (Slots 0-15)**: 16 basic storage slots in the main inventory overlay (**I key**).
* **Pocket Layer (Slots 16-20 / Hotbar)**: 5 rapid-access slots represented as elegant `40x40` pixel squares at the bottom-left of the HUD.
* **True Drag-and-Drop Transfer**: Moving items between the backpack and pockets physically transfers them (removing them from the previous slot). Swapping items automatically transfers the old item back to the backpack!
* **Pocket Hotkey Consumption**: Items placed in pockets can be used/eaten directly by pressing hotkeys **`1` to `5`**.

### 2. 🔨 Modular Base Building & Defenses
* **Moduler Construction Grid (1.0 Snapping)**: Build walls, doors, floors, and roofs dynamically from pocket slots (**B key** or direct pocket placement).
* **Interactive Doors**: Press **`E`** near doors to toggle open/close (disables collision dynamically), or **`Shift + E`** to repair them.
* **Electricity & Savunma (Turrets)**: Place an electric **Generator** to power **Projectors** and **Automatic Turrets** (12m range, target-tracking head, deals 18 HP damage every 0.8s).
* **Sığınak Bayrağı (Safezone)**: Place a Shelter Flag to declare a safe sector, stopping zombie respawns inside that zone forever.

### 3. 🗺️ Real-time Minimap & Tactical Map (M Key)
* **HUD Minimap (Bottom-Right)**: Features a real-time top-down 3D orthogonal camera centering the player with a red direction pointer. Stays locked to the bottom-right on window resizing.
* **Tactical Map (M Key)**: Press **`M`** to toggle a premium 550x550 tactical overlay showing a massive 200m area. Safely blocks player inputs during use with complete interface collision protection.

### 4. ☣️ 5x Map Scale & Environmental Hazards
* **500x500 Scale**: Extended coordinates rescaled to 500x500 units for four core sectors (Outskirts, Commercial, Industrial, City Center).
* **Toxic Waste Barrels**: Glows bright neon green in industrial sectors, dealing **12 HP/s radiation damage** (triggering infection) in a 3.5m radius.
* **Car Barricades & Bridges**: Add complex exploration routes, blocking paths or providing elevated vantage points.

### 5. 🕒 Dynamic Day/Night Cycle & Panic
* **Day (17m) / Night (7m)** time-progression engine with real-time solar rotations and color gradients.
* **Night Buffs**: At nightfall (23:00 to 06:00), zombies automatically receive a **+50% Movement Speed** and **+30% Attack Damage** boost.

### 6. 💀 Sinister Death & Loot Recovery
* **Loot Drop**: All backpack and pocket items are dropped as a physical loot box where the player dies.
* **Respawn**: Resetting at the latest placed Shelter Flag (or initial spawn point) with ihtiyaç (needs) set to 50%.

---

## 🎮 Game Controls

| Control | Action |
|---|---|
| **Left Click (Ground)** | Click-to-move pathfinding (Vector3 physics-based) |
| **E Key** | Collect world items / Toggle nearby doors |
| **Shift + E** | Repair nearby damaged structures/doors |
| **X Key** | Deconstruct/Recycle nearby structures |
| **I Key** | Toggle Inventory grid (Sırt Çantası) |
| **Tab Key** | Toggle Crafting terminal |
| **B Key** | Toggle Construction Mode |
| **1 to 5 Keys** | Consume food/water/medicine or Equip weapons from pocket slots |
| **Right Click (Inventory)** | Opens context menu to Use, Recycle, or Discard item |
| **Shift + Left Click (Inv)** | Drop inventory item to the ground |
| **M Key** | Toggle Fullscreen Tactical Map |
| **Escape** | Pause game |

---

## 📁 Project Directory Structure

```text
ghost-alley/
├── assets/                  # 3D models, textures, and sound files
│   ├── models/
│   ├── textures/
│   └── sounds/
├── resources/               # Tres resources (materials, environments)
│   ├── environments/        # WorldEnvironment configurations
│   └── materials/           # Visual shaders & material overrides
├── scenes/                  # TSCN scene configurations
│   ├── enemies/             # Zombie prefabs
│   ├── items/               # Pickups and world items
│   ├── player/              # Player CharacterBody3D and camera configurations
│   ├── ui/                  # HUD, Inventory, Crafting, & Death overlays
│   └── world/               # Main scene (alley setup, lights, structures)
├── scripts/                 # GDScript game logic
│   ├── camera/              # Isometric orthographic camera controllers
│   ├── data/                # Database configurations (Autoloads)
│   ├── enemies/             # Zombie AI controllers (4-state state machines)
│   ├── items/               # World item collision scripts
│   ├── player/              # Movement controllers and node routing
│   ├── systems/             # Time managers, inventory structures, survival bbars
│   └── ui/                  # Arayüz signal-to-ui controllers
├── project.godot            # Main Engine configuration file
└── README.md                # Project documentation
```

---

## 🛠️ Technical Specifications

* **Game Engine**: Godot Engine 4.6 (Forward+ Rendering)
* **Physics Engine**: Godot Jolt (3D Physics)
* **Rendering API**: Direct3D 12 (Windows) / Vulkan
* **Camera Projection**: Orthographic Isometric Skew (45° angle)
* **Language**: GDScript 2.0 (Fully typed)

---

## 🚀 Getting Started

1. **Prerequisites**: Ensure you have **Godot Engine 4.6 (or higher)** installed on your machine.
2. **Clone Repository**:
   ```bash
   git clone https://github.com/Ibrahim-Taskiran/ghost-alley.git
   ```
3. **Open Project**: Launch Godot Engine, click **Import**, select `project.godot` inside the cloned directory.
4. **Run Project**: Press **F5** to start the main world scene (`res://scenes/world/world.tscn`).

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
