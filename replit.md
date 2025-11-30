# Epoch Settlements Alpha - Godot Game

## Overview
**Epoch Settlements** is a survival settlement-building game developed with Godot 4.4.1. It features 3D survival gameplay with a first-person perspective, comprehensive building and crafting systems, combat mechanics including combo chains, and multiplayer networking. The game incorporates AI-controlled mobs and NPCs, procedurally generated terrain with diverse biomes, dynamic weather and day/night cycles, and intricate faction and quest systems. Localization is supported for English and Russian. The business vision is to deliver a rich, immersive survival experience with deep strategic elements and social interaction potential.

## User Preferences
- Все ответы должны быть на русском языке
- Collision layers: Player (layer=2, mask=5), Mobs (layer=4, mask=7), NPCs (layer=4, mask=3)

## System Architecture

### Engine
- **Godot Engine**: Version 4.4.1
- **Rendering**: GL Compatibility mode (OpenGL ES 3.2)
- **Main Scene**: `res://scenes/ui/main_menu.tscn`

### Core Systems
The game is built around 40+ autoloaded singleton systems for managing core mechanics:
-   **Gameplay**: Inventory, Crafting (60+ recipes, 4 workbench tiers), Building (20+ types, snapping, upgrade), Combat (combo system, 8 hit zones).
-   **World**: World Generation (24 biomes, procedural terrain), Chunk-based World Streaming, Mob Spawning, Weather (8 types).
-   **Player**: Progression (XP, levels, attributes, skills), Debuffs (12+ status effects), Player Statistics.
-   **Management**: Global Game State, Save/Load (including building serialization), Settings, Centralized Game Balance.
-   **UI/Feedback**: Interactive Tutorial (15 steps), Notifications, Audio Management, Visual Effects.
-   **Social**: Faction System (10 factions, reputation), Settlement Management (5 levels), Quest System (12+ quests, achievements, daily quests), Dialogue System (NPC dialogues with choices), Trade System (routes, caravans, dynamic prices), War System (faction wars, sieges), Law System (crimes, punishments), Siege Equipment (8 types), Technology Tree (30+ technologies), World Director (global events, economy, NPC management).
-   **Network**: Multiplayer hosting/joining, synchronized movement.

### UI/UX Decisions
-   **Theming**: Features a "Rust" style UI theme.
-   **Interactive Elements**: Includes interactive prop scenes (barrel, chest, workbench, torch, anvil) and comprehensive UI components for inventory, crafting, building, trade, tech tree, compass, threat indicators, and achievement popups.
-   **Localization**: CSV-based translation for English and Russian.

### Technical Implementations
-   **Model Loading**: `ModelLoader` for 3D character and environmental models, supporting various resource types.
-   **World Spawning**: `WorldModelSpawner` handles procedural nature and settlement generation based on biomes, integrated with `ChunkGenerator` and `WorldGenerator`.
-   **AI**: `NPCAIBrain` with 12 states, 10 professions, needs system, daily schedules, trading, and memory. `AnimalAI` with FSM for animal behaviors.
-   **Animation**: `IdleAnimationController` for player animations.

## External Dependencies
-   **Godot Engine**: Version 4.4.1 installed via Nix package manager
-   **VNC**: TigerVNC 1.14.0, xorg.xinit, xorg.xorgserver, xorg.xdpyinfo for running Godot GUI in a browser environment on Replit

## Replit Environment Setup

### Installation (Completed November 30, 2025)
- Installed Godot 4.4.1 via Nix package manager
- Configured VNC server for desktop GUI access
- Created startup script: `start_godot_vnc.sh`
- Setup workflow: "Run Godot Game" with VNC output

### Running the Project
1. The workflow "Run Godot Game" starts automatically
2. Access the Godot editor via Replit's desktop view
3. VNC server runs on port 5900, display :0
4. Resolution: 1280x720 (configurable via RESOLUTION env var)

### Technical Notes
- Using software rendering (Mesa llvmpipe) with OpenGL ES 3.2
- All 40+ autoload systems are configured in project.godot
- Main menu scene: `res://scenes/ui/main_menu.tscn`

## Recent Changes (November 30, 2025)

### GitHub Import Setup - Replit Environment Configuration
- Re-installed Godot 4.4.1 and VNC dependencies via Nix packager
- Created `start_godot_vnc.sh` startup script with VNC configuration
- Configured "Run Godot Game" workflow with VNC output type
- Fixed NameGenerator autoload configuration (removed class_name to prevent singleton conflict)
- Updated GameManager to use NameGenerator as autoload singleton
- Created .gitignore for Godot-specific files
- Verified successful game launch with all 40+ autoload systems initialized
- Status: Game running successfully with ModelLoader (181 models), WorldModelSpawner, TextureLoader (38 texture sets), and MaterialFactory initialized

### Character Creation
- Added 3D character model preview using Superhero_Male/Female.gltf from art_pack2
- Gender toggle now swaps between male/female models in real-time

### NPC System
- NPCs now use NameGenerator for proper Russian/English names
- Added profession titles (Стражник, Торговец, Фермер, Охотник, Ремесленник)
- Name labels are color-coded by profession
- Dual-line labels: Name + Profession title

### Mob System
- Created wolf.tscn, bear.tscn, boar.tscn mob scenes with proper collision layers
- Mobs have generated names (e.g., "Серый Клык", "Косолапый", "Секач")
- Name labels color-coded by behavior type (red=aggressive, yellow=neutral, green=passive)
- Proper collision layers: Player (layer=2, mask=5), Mobs (layer=4, mask=7), NPCs (layer=4, mask=3)

### Fixed UI Scenes (Godot 3.x → 4.x syntax)
- skills_window.tscn, craft_window.tscn, lang_selector.tscn, stats_window.tscn, trade_window.tscn

### Blueprint Book System (Added November 30, 2025)
- Created `scripts/systems/blueprint_book.gd` - comprehensive blueprint management system
- 45+ blueprints organized by categories: survival, tools, weapons, building, armor, medical, materials
- 4 tier system: Базовые (Basic), Улучшенные (Improved), Продвинутые (Advanced), Мастерские (Master)
- Starter blueprints (tier 0) unlocked from start: stone_axe, stone_pickaxe, wooden_spear, bandage, torch, campfire, sleeping_bag
- Advanced blueprints unlock at workbenches: workbench_1, workbench_2, workbench_3, furnace
- Created `scripts/ui/blueprint_book_ui.gd` and `scenes/ui/blueprint_book.tscn` for UI
- Keyboard shortcut: B key opens blueprint book
- Bilingual support (Russian/English) for all names and descriptions

### Dynamic Quest System (November 30, 2025)
- Added dynamic quest generation based on biomes (forest, desert, tundra, swamp, mountains)
- Added faction-based quests (villagers, traders, guards, hunters)
- Added event-driven quests triggered by WorldDirector (blood_moon, invasion, rare_spawn, meteor_shower)
- Quests use unique IDs with timestamps to prevent duplicate registration
- Deep copy templates to prevent state sharing between players
- Check for existing active quests before generating new ones

### WorldDirector Integration (November 30, 2025)
- Added `_generate_event_quest()` - generates quests when global events start
- Added `generate_biome_quests_for_player()` - generates quests when player enters new biome
- Added `generate_faction_quest_for_player()` - generates faction reputation quests
- Added `trigger_random_world_event()` - triggers random events based on world state
- Added `notify_player_entered_biome()` - 30% chance to generate biome quest on entry
- Added `_calculate_area_difficulty()` - scales difficulty by distance from spawn and world state

### 3D Character Model Integration (November 30, 2025)
- First-person arms now use glTF model from art_pack2/Characters/Base Characters/Godot/Superhero_Male.gltf
- Added GLTFDocument runtime loading with fallback to procedural arms
- BoneAttachment3D used to attach items to hand bones for realistic item holding
- NPCs now load 3D character models (random male/female) with profession-based color tinting
- Fixed dialogue IDs in npc_controller.gd (guard_greeting, trader_greeting, farmer_greeting, hunter_greeting, citizen_greeting)

### Bug Fixes (November 30, 2025)
- Fixed material files syntax (metal_material.tres, wood_material.tres) for Godot 4 compatibility
- Fixed main_menu.gd to not create duplicate title labels
- Fixed WeatherSystem signal type mismatch (int → String) for weather_changed signal
- Fixed compass_ui.gd - removed @onready, using get_node_or_null with fallback creation
- Fixed achievement_popup.gd - removed @onready, using get_node_or_null with fallback creation
- Fixed NPC dialogue ID references (*_dialogue → *_greeting)