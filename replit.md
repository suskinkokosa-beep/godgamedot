# Epoch Settlements Alpha - Godot 4 Game Project

## Overview

This is a multiplayer survival/settlement game built with Godot 4. The project runs in the Replit environment with VNC display.

## Running the Game

The game starts automatically via the "Run Godot Game" workflow in VNC mode.
Game launches with Main Menu where you can:
- Start Game - Begin single player
- Multiplayer - Host or join server
- Settings - Change language and sensitivity
- Quit - Exit game

**In-Game Controls:**
- **WASD** - Move
- **Shift** - Sprint
- **Ctrl** - Crouch
- **Space** - Jump (double jump available)
- **E** - Interact
- **I** - Inventory
- **ESC** - Return to menu
- **Left Click** - Attack
- **Mouse** - Look around

## Project Structure

### Key Scenes

- **scenes/ui/main_menu.tscn** - Main menu (startup scene)
- **scenes/main.tscn** - Game world with player, environment, NPCs
- **scenes/player/player.tscn** - Player character
- **scenes/environment.tscn** - Environment (lighting, ground)
- **scenes/npcs/npc_citizen.tscn** - NPC citizens
- **scenes/mobs/mob_basic.tscn** - Basic enemy mobs

### Core Systems (Autoloaded Singletons)

All systems load automatically at startup:

- **Inventory** - Player inventory and equipment management
- **Network** - Multiplayer networking system (ENet-based)
- **GameManager** - Global game state, language settings, day/night cycle
- **LocalizationService** - Multi-language support (English, Russian)
- **StatsSystem** - Player stats and leveling
- **PlayerProgression** - XP, skills, character progression
- **SpawnTable** - Biome-based entity spawning
- **FactionSystem** - Faction relations management
- **WeatherSystem** - Dynamic weather (server-controlled)
- **BiomeSystem** - Biome mapping and temperature
- **TemperatureSystem** - Temperature damage and effects
- **TerrainGenerator** - Procedural terrain with biome colors
- **ChunkStreamer** - Chunk-based world streaming
- **CombatEngine** - Combat calculations and damage system
- **CraftSystem** - Crafting with tiered workbenches and recipes
- **BuildSystem** - Building placement with snapping and validation
- **SettlementSystem** - Settlement levels, population, economy, wars
- **QuestSystem** - Quest management with objectives and rewards

### Game World Features

- **Biomes**: spawn_town, forest, plains, desert, tundra
- **Factions**: player, town, wild, bandits
- **NPCs**: Citizens that wander, trade, patrol
- **Mobs**: Basic enemies that patrol and attack
- **Terrain**: Procedural generation with collision

## Technical Details

### Godot 4 Compatibility

Project uses Godot 4.4.1 with OpenGL ES 3.2 (software rendering via Mesa llvmpipe).

**Godot 4 API:**
- `PhysicsRayQueryParameters3D` for raycasting
- `Transform3D` instead of `Transform`
- `@rpc("any_peer", "call_remote")` for network functions
- `object.get("property")` for property checking
- Ternary: `value if condition else other`

### Input Configuration

Input actions in project.godot:
- move_forward (W), move_back (S), move_left (A), move_right (D)
- sprint (Shift), crouch (Ctrl)
- interact (E), inventory (I), escape (ESC)
- attack (Left Mouse Button)

## Localization

Supported languages:
- English (en)
- Russian (ru)

Change in Settings menu or via code:
```gdscript
GameManager.set_language("ru")
```

## Multiplayer

### From Menu
- Click "Multiplayer"
- Host Server: Creates server on port 7777
- Join Server: Enter IP and connect

### Via Code
```gdscript
Network.host(7777)  # Host
Network.join("ip", 7777)  # Join
```

## Dependencies

- Godot 4.4.1 (installed via Nix: godot_4)
- No external plugins required

## Recent Changes

- **2025-11-29**: Jump Mechanics and Loot System
  - Added jump action (Space key) with double jump support
  - Implemented coyote time (0.15s) and jump buffer (0.1s) for responsive controls
  - Created LootSystem with loot tables for different mob types (basic, wolf, bear, bandit)
  - Added loot tables for chests (common, rare)
  - Updated HUD with jump indicator showing remaining jumps
  - Added controls hint panel in HUD

- **2025-11-29**: UI and AI Improvements
  - Updated crafting UI with integration to CraftSystem (localized names, cost display)
  - Added building UI with placement preview and resource costs
  - Extended HUD with all survival stats (health, stamina, hunger, thirst, sanity, temperature)
  - Added HUD debuff display with icons
  - Added QuestSystem with tutorial quests and per-player progression
  - Fixed QuestSystem to use per-player completed_quests storage (Dictionary instead of Array)
  - Improved mob AI with states (idle, patrol, chase, attack, flee)
  - Improved NPC AI with roles (farmer, guard, trader, builder) and schedules
  - NPCs now interact with settlements and produce resources

- **2025-11-29**: Survival Systems Expansion
  - Added CraftSystem with tiered workbenches (Tier 0-3)
  - Added BuildSystem with building placement, snapping and validation
  - Added SettlementSystem with levels (Camp→Capital), population classes, wars
  - Extended PlayerProgression with survival stats (hunger, thirst, blood, sanity, temperature)
  - Added debuff system with stamina/speed/vision penalties
  - Added death penalties (inventory loss, temporary debuffs)
  - Added ResourceNode system with tool requirements and XP rewards
  - Fixed autoload conflicts (removed class_name from singleton scripts)

- **2025-11-29**: Replit Environment Setup
  - Successfully imported GitHub project into Replit
  - Installed Godot 4.4.1 via Nix package manager
  - Configured VNC workflow for game display
  - Added proper .gitignore for Godot projects
  - All autoload systems loading correctly
  - Game running successfully in VNC mode

- **2025-11-29**: Major update
  - Added Main Menu with Start/Multiplayer/Settings/Quit
  - Added HUD with controls info and crosshair
  - Added game world initialization (biomes, factions, spawn tables)
  - Added NPC and mob spawning system
  - Fixed all scripts for Godot 4 compatibility
  - Fixed multiplayer.is_server() for single player mode
  - Fixed has_variable to use object.get() 
  - Added terrain generation with biome-colored chunks
  - Added collision detection for ground and entities

## Known Issues

1. VNC display shows OpenGL warnings (expected for software rendering)
2. Some prop scenes need conversion to Godot 4 format

## User Preferences

- Language: Russian preferred for UI
- Development focus: Single player functionality first
