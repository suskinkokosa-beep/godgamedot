# Epoch Settlements Alpha - Godot 4 Game Project

## Overview

This is a multiplayer survival/settlement game built with Godot 4. The project was migrated from Godot 3.x to Godot 4.4.1 to run in the Replit environment.

## Project Structure

### Core Systems (Autoloaded Singletons)

The following systems are automatically loaded at startup:

- **Inventory** - Player inventory and equipment management
- **Network** - Multiplayer networking system (ENet-based)
- **GameManager** - Global game state, language settings, and day/night cycle
- **LocalizationService** - Multi-language support (English, Russian)
- **StatsSystem** - Player stats and leveling
- **PlayerProgression** - XP, skills, and character progression
- **ActionXP** - Maps actions to XP rewards
- **SpawnTable** - Biome-based entity spawning
- **FactionSystem** - Faction relations management
- **WeatherSystem** - Dynamic weather (server-controlled)
- **BiomeSystem** - Biome mapping and temperature
- **TemperatureSystem** - Temperature damage and effects
- **MovementServer/Client** - Anti-cheat movement validation
- **SeedManager** - World generation seed management
- **ChunkStreamer** - Chunk-based world streaming
- **CombatEngine** - Combat calculations and damage system

### Key Features

1. **Multiplayer Networking**
   - Host/join functionality via Network system
   - Server-authoritative gameplay
   - Client prediction with server reconciliation

2. **Survival Mechanics**
   - Health, stamina, hunger, thirst
   - Temperature effects based on biome and weather
   - Day/night cycle (600 seconds per day)

3. **Combat System**
   - Light/heavy/ranged attacks
   - Stamina-based cooldowns
   - Armor mitigation
   - Hitbox zones (head, body, legs)

4. **Building System**
   - Placement preview with snapping
   - Server-side validation
   - Foundation, walls, doors, windows

5. **Crafting & Economy**
   - Recipe-based crafting
   - Resource gathering
   - Trading with NPCs

## Technical Details

### Godot 4 Migration

This project was converted from Godot 3.x to Godot 4.4.1. Major changes include:

- **File API**: Migrated from `File` to `FileAccess`
- **RPC System**: Updated from `@rpc("remote")` to `@rpc("any_peer", "call_remote")`
- **Time API**: `OS.get_unix_time()` → `Time.get_unix_time_from_system()`
- **Network API**: `is_network_server()` → `multiplayer.is_server()`
- **Property Check**: `has_variable()` → `"property" in object`
- **Modulo Operator**: Float modulo now uses `fmod()` function
- **Ternary Operator**: Changed from `? :` to `if/else` syntax

### Scene Files

**Note**: The original scene files were created in Godot 3.x format and require manual re-import in the Godot 4 editor to be fully functional. The current main scene (`test_world.tscn`) is a minimal placeholder to allow the engine and scripts to run.

To use the full game scenes:
1. Open the project in Godot 4 editor
2. Re-save all `.tscn` files to convert them to Godot 4 format
3. Update `project.godot` to set main scene back to `res://scenes/world.tscn`

## Running the Game

### Development Mode (Headless)

The workflow "Run Godot Game" starts the game in VNC mode, which allows GUI interaction via Replit's VNC viewer.

### Server Setup

To host a multiplayer server:
```gdscript
GameManager.start_server()
# or directly:
Network.host(port)  # default port 7777
```

### Client Setup

To join a server:
```gdscript
GameManager.start_client("server_ip")
# or directly:
Network.join("server_ip", port)
```

## Assets

The project includes:
- 3D models (characters, animals, structures, weapons, environment props)
- PBR textures (wood, metal, stone, fabric)
- Material resources (.tres files)
- Weapon definitions

## Localization

Supported languages are stored in `localization/*.csv`:
- `en.csv` - English
- `ru.csv` - Russian

Change language with:
```gdscript
GameManager.set_language("ru")
```

## Development Notes

- The project uses server-authoritative architecture for security
- Movement includes anti-cheat validation (speed checks, teleport prevention)
- Combat damage is calculated server-side only
- World generation uses seed-based procedural generation
- Chunks are streamed based on player position

## Dependencies

- Godot 4.4.1 (installed via Nix)
- No external plugins required

## Recent Changes

- **2024-11-28**: Migrated from Godot 3.x to Godot 4.4.1
  - Fixed all API compatibility issues
  - Removed class_name conflicts with autoloads
  - Created minimal test scene for engine validation
  - Configured autoload singletons
  - Updated all RPC, Time, File, and Network APIs

## Known Issues

1. Original scene files need re-import in Godot 4 editor
2. Some scenes reference resources that may need re-linking
3. VNC display shows graphics warnings (expected in headless environment)

## Next Steps

To fully restore the game:
1. Open project in Godot 4 editor locally or in a GUI environment
2. Let Godot re-import all resources and scenes
3. Re-save all scene files
4. Test multiplayer functionality
5. Verify world generation and chunk streaming
6. Test all combat and survival mechanics
