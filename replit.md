# Epoch Settlements Alpha - Godot Game

## Overview
**Epoch Settlements** is a survival settlement-building game built with Godot 4.5. This is an alpha version featuring:
- 3D survival gameplay with first-person view
- Building and crafting systems
- Combat mechanics with combo chains
- Multiplayer networking support
- AI-controlled mobs and NPCs
- Procedurally generated terrain with biomes
- Weather and day/night cycles
- Faction and quest systems
- Localization support (English and Russian)

## Project Architecture

### Engine
- **Godot Engine**: Version 4.5 (running v4.4.1 in Replit)
- **Rendering**: GL Compatibility mode (OpenGL ES 3.2)
- **Main Scene**: `res://scenes/ui/main_menu.tscn`

### Directory Structure
- `assets/` - 3D models, textures, materials, shaders, weapons, icons
  - `art_pack/` - Character models, animals, structures, environment props
  - `materials/` - Terrain and surface materials
  - `shaders/` - Custom GLSL shaders for grass, terrain, water
  - `weapons/` - Weapon resource definitions
- `scenes/` - Godot scene files (.tscn)
  - `ui/` - User interface scenes (HUD, inventory, crafting, menus)
  - `player/` - Player character scene
  - `world/` - World and terrain chunks
  - `mobs/` - Enemy mob scenes
  - `npcs/` - NPC character scenes
  - `props/` - Reusable prop prefabs
  - `buildings/` - Building structure scenes
- `scripts/` - GDScript game logic
  - `systems/` - Core game systems (autoloaded singletons)
  - `player/` - Player movement, combat, and character logic
  - `ai/` - AI behaviors for mobs and NPCs
  - `combat/` - Combat engine and mechanics
  - `world/` - Procedural world generation
  - `ui/` - UI controllers
  - `mobs/` - Mob AI and spawning
  - `npcs/` - NPC behaviors (traders, guards, citizens)
- `localization/` - CSV-based translation files (en.csv, ru.csv)
- `docs/` - Documentation and guides

### Core Systems (Autoloads) - 34 Total
The game uses autoloaded singleton systems defined in `project.godot`:

**Core Gameplay:**
- **Inventory** - Player inventory management (40 slots, 8 hotbar)
- **CraftSystem** - 60+ recipes, 4 workbench tiers
- **BuildSystem** - 20+ building types, snapping, upgrade system
- **CombatEngine** - Combo system, block, parry, 8 hit zones

**World Systems:**
- **WorldGenerator** - 24 biomes, procedural terrain
- **ChunkGenerator** - Chunk-based world streaming
- **MobSpawner** - Enemy spawning logic
- **WeatherSystem** - 8 weather types

**Player Systems:**
- **PlayerProgression** - XP, levels, 6 attributes, 10 skills
- **DebuffSystem** - 12+ status effects
- **StatsSystem** - Character statistics

**Game Management:**
- **GameManager** - Global game state
- **SaveManager** - Save/load with building serialization
- **SettingsManager** - Game settings
- **GameBalance** - Centralized balance data

**UI & Feedback:**
- **TutorialSystem** - 15-step interactive tutorial
- **NotificationSystem** - In-game notifications
- **AudioManager** - Sound effects management
- **VFXManager** - Visual effects

**Social Systems:**
- **FactionSystem** - 10 factions, reputation
- **SettlementSystem** - 5 settlement levels
- **QuestSystem** - 12+ quests, 12+ achievements, daily quests
- **DialogueSystem** - NPC dialogues with choices and actions

**Network:**
- **Network** - Multiplayer host/join
- **MovementServer/Client** - Synchronized movement

## Running in Replit

### Setup
1. Godot 4 is installed via Nix packages (`godot_4`)
2. VNC components installed: `tigervnc`, `xorg.xinit`, `xorg.xorgserver`
3. The game runs through VNC (Virtual Network Computing) to display the GUI in your browser
4. Workflow: "Run Godot Game" runs on DISPLAY=:1 (where Xvnc server is active) with OpenGL ES 3.2 rendering
5. To view the game, click the VNC preview in the Replit interface

### Controls (from project.godot)
- **WASD** - Movement
- **Space** - Jump (double jump supported)
- **Shift** - Sprint
- **Ctrl** - Crouch
- **E** - Interact
- **I** - Inventory
- **C** - Crafting menu
- **B** - Building menu
- **F5** - Quick save
- **F9** - Quick load
- **Left Mouse** - Attack
- **Escape** - Menu

### Networking
- Server uses `Network.host()` to start hosting
- Clients use `Network.join(ip)` to connect
- Movement is synchronized via MovementServer and MovementClient

## Development Notes

### Recent Changes (Nov 29, 2024)

**Session 4 - Major Enhancements:**
- ✅ Expanded AudioManager with 15+ new procedural sounds (building, environment, weather, events)
- ✅ Created LootDropSystem - visual loot drops with rarity glow, animations, auto-pickup
- ✅ Created CompassUI - directional compass with marker tracking
- ✅ Created ThreatIndicator - radial enemy proximity warning
- ✅ Created AchievementPopup - animated achievement notifications
- ✅ Created LoadingScreen - loading screen with 20 Russian tips
- ✅ Integrated all new UI components into HUD

**Session 3 - Bug Fixes & New Features:**
- ✅ Fixed settings menu back button freeze - proper cleanup and navigation
- ✅ Fixed resource gathering crash - added null checks and deferred calls
- ✅ Improved main menu - Rust theme, title, animated entrance
- ✅ Created DialogueSystem (`scripts/npcs/dialogue_system.gd`) - NPC dialogue trees with choices
- ✅ Expanded VFXManager - gather, build, fire, smoke, explosion, water effects
- ✅ Quest system already has 12+ quests, 12+ achievements, 5 daily templates

**Session 2 - Major Updates:**
- ✅ Created TutorialSystem (`scripts/ui/tutorial_system.gd`) - 15-step interactive tutorial
- ✅ Created RustTheme (`scripts/ui/rust_theme.gd`) - Rust-style UI theming
- ✅ Created GameBalance (`scripts/systems/game_balance.gd`) - Centralized balance data
- ✅ Enhanced SaveManager - Now saves/loads buildings, weather state
- ✅ Added free resources guide (`docs/FREE_RESOURCES_GUIDE.md`)
- ✅ Balance data includes: player stats, survival rates, weapon stats, armor, food, mobs, loot tables, XP requirements, trader prices

**Session 1:**
- ✅ Installed Godot 4 engine and VNC components
- ✅ Configured VNC workflow for GUI display (DISPLAY=:1)
- ✅ Created .gitignore for Godot projects (excluding *.translation assets)
- ✅ Verified game launches successfully with OpenGL ES 3.2 fallback
- ✅ Project import completed and ready for use

### Known Issues
- Using OpenGL ES 3.2 with Mesa software rendering (llvmpipe) - expected in cloud environment
- Subsurface scattering unavailable (requires Forward+ renderer, we're using Compatibility mode)
- Texture import errors on first run - need to open project in Godot editor for import
- Missing quality 3D models (using placeholders)
- Missing sound effects files

### Project Completion Status
```
Code Systems:     ~85% complete
3D Models:        ~10% complete (placeholders)
Sound Effects:    ~40% complete (procedural sounds)
UI Polish:        ~75% complete (compass, threats, achievements)
Tutorial:         ~90% complete (system created)
Save System:      ~85% complete (buildings now saved)
Balance:          ~80% complete (data centralized)
Dialogue:         ~70% complete (system + basic dialogues)
VFX:              ~75% complete (15+ effect types)
Loot System:      ~80% complete (visual drops, rarity)

Overall:          ~65% complete
```

### Priority Tasks
1. **High**: Replace placeholder 3D models with quality GLB/GLTF assets
2. **High**: Add sound effects (footsteps, combat, ambient)
3. **Medium**: Polish UI with Rust theme
4. **Medium**: Test and refine tutorial flow
5. **Low**: Add more quests and content

## User Preferences
None configured yet.

## Free Resources
See `docs/FREE_RESOURCES_GUIDE.md` for links to:
- Quaternius (CC0 models)
- Mixamo (free animations)
- OpenGameArt (CC0 sounds)
- Freesound (CC0 audio)
