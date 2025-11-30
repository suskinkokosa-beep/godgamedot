# Epoch Settlements Alpha - Godot Game

## Overview
**Epoch Settlements** is a survival settlement-building game developed with Godot 4.4.1. It features 3D survival gameplay with a first-person perspective, comprehensive building and crafting systems, combat mechanics including combo chains, and multiplayer networking. The game incorporates AI-controlled mobs and NPCs, procedurally generated terrain with diverse biomes, dynamic weather and day/night cycles, and intricate faction and quest systems. Localization is supported for English and Russian. The business vision is to deliver a rich, immersive survival experience with deep strategic elements and social interaction potential.

## User Preferences
None configured yet.

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