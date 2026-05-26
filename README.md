# 👻 Ghost Alley

[![Godot Engine](https://img.shields.io/badge/Godot-4.6%2B-blue?logo=godot-engine&logoColor=white)](https://godotengine.org)
[![Physics Engine](https://img.shields.io/badge/Physics-Jolt%20Physics-orange)](https://github.com/godot-jolt/godot-jolt)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Ghost Alley** is a premium 3D Isometric Survival Action RPG prototype built with **Godot Engine 4.x**. Set in a dark, atmospheric alleyway, players must scavenge for resources, manage vital survival needs, craft defensive gear, and survive the terrifying day-night transition where the infected grow stronger and more aggressive.

---

## 🌟 Key Features

### 1. 🕒 Dynamic Day/Night Cycle
* **Day (17m) / Night (7m)** time-progression engine.
* Real-time celestial rotation, sun intensity fading, and sky color gradient transitions.
* **Night Panic Buffs**: At nightfall (23:00 to 06:00), zombies automatically receive a **+50% Movement Speed** and **+30% Attack Damage** boost.

### 2. 🍖 Real-time Survival & Infection
* **Vitality Meters**: Continuous depletion of **Hunger**, **Thirst**, and **Sleep** meters mapped to in-game time.
* **Physical Penalties**: Starvation causes immediate movement speed reduction (-30%) and health damage. Dehydration causes rapid health deterioration.
* **Zombie Infection**: Zombie attacks carry a **20% chance of infection**. If not treated with Antibiotics within **3 game days**, the infection becomes fatal.

### 3. 🎒 Grid-based Inventory & Interactions
* Slot-based container inventory featuring stack limits and weight calculations.
* Dynamic **3D World Pickups** glowing with color-coded materials matching item types (Emerald for Food, Crimson for Meds, Purple for Weapons).
* Proximity-based item gathering (**E key**) and drag/drop world item discarding (**Shift + Left Click**).

### 4. 🔨 Engineering & Crafting
* Two-panel crafting terminal (**Tab key**) showcasing recipe feasibility based on ingredient availability and character statistics.
* **Level 1 Recipes**: Craft essential gear like Wood Clubs, Bandages, and Hunting Knives.

### 5. ⭐ XPSystem & Progression
* Experience gain from killing infected (+20 XP), gathering resources (+5 XP), and crafting items (+10-20 XP).
* Stat attribution upon level-up: Kalma attributes (**Strength, Military, Engineering, Intelligence**) randomly receive permanent +1 boosts.

### 6. 💀 Sinister Death & Respawn
* Sinematic dark red death overlay displaying statistics like survived days.
* **Loot Drop**: All inventory items are dropped as physical loot boxes exactly where the character dies.
* **Respawn**: Resetting to the initial spawn point with health restored and needs set to 50%.

---

## 🎮 Game Controls

| Control | Action |
|---|---|
| **Left Click (Ground)** | Click-to-move pathfinding (Vector3 physics-based) |
| **E Key** | Collect nearby world items |
| **I Key** | Toggle Inventory grid menu |
| **Tab Key** | Toggle Crafting menu |
| **Right Click (Inventory)** | Consume food/water/medicine or Equip weapons |
| **Shift + Left Click** | Drop inventory item to the ground |
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
