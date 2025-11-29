# Эпоха Поселений (Epoch Settlements) - Godot 4.x

## Overview
"Эпоха Поселений" is a multiplayer and single-player 3D first-person game built on Godot 4.4.1. It combines elements of survival, building, combat, economics, and settlement management. The game aims to provide a rich, dynamic world where players can establish and grow settlements, interact with various factions, and face environmental and combat challenges.

## Replit Setup
This project is configured to run in the Replit environment with the following setup:
- **Godot Version:** 4.4.1 (installed via Nix package godot_4)
- **Display:** VNC (Virtual Network Computing) for graphical desktop output
- **Workflow:** Configured to run the main menu scene at startup
- **Renderer:** OpenGL ES 3.2 (compatibility mode) - optimized for cloud/headless environments

### Recent Changes (November 29, 2025)
- Imported GitHub repository to Replit
- Installed Godot 4.4.1 engine
- Configured VNC workflow for desktop GUI display
- Verified project runs successfully with OpenGL ES fallback
- Fixed temperature system - now uses biomes, weather, and day/night cycle
- Extended BiomeSystem with 25+ biomes and is_cold_biome/is_hot_biome functions
- Added resource gathering - trees and rocks now respond to tool attacks
- Enhanced localization with 100+ translated strings for full UI coverage
- Created realistic procedural character model with anatomical proportions
- Improved first-person arms with detailed finger anatomy and weapon handling
- Enhanced MobAI with behavior types (passive, neutral, aggressive, territorial, predator)
- Added sound reaction system for mobs with hearing range and alert levels
- Improved patrol system with waypoints and day/night behavior
- Expanded combat engine with combo system, parrying, blocking, and stamina costs
- Added zone-based damage multipliers and damage type effectiveness
- Extended quest system with 15+ quests, achievements, and daily quests
- Quest categories: main, side, daily, challenge, exploration, combat, crafting
- Added achievement system with 12+ achievements and unlock rewards
- Extended build system with 25+ building parts and upgrades
- Added structure damage, repair, and visual degradation systems
- Added structure upgrade paths (wood → stone → metal)
- **Graphics Modernization Session:**
  - Created TerrainMaterialGenerator with PBR terrain shader (triplanar mapping, biome blending)
  - Added TerrainTextures with procedural grass/dirt/rock/sand/snow albedo and normal maps
  - Created TreeGenerator with 9 tree types (oak, birch, pine, palm, etc.) and LOD support
  - Created RockGenerator with 30 rock variants and ore node support (iron, copper, gold, etc.)
  - Created MobModelGenerator with procedural animal models for 19 mob types
  - Created AtmosphereSystem with fog effects, weather integration, OpenGL ES compatibility
  - Created WeatherParticles with rain, snow, and sandstorm particle effects
  - Integrated TreeGenerator into ChunkGenerator._create_harvestable_tree()
  - Integrated RockGenerator into ChunkGenerator._create_harvestable_rock() and _create_ore_node()
  - Integrated MobModelGenerator into MobSpawner._create_procedural_mob()
  - Added AtmosphereSystem as autoload with DayNightCycle integration
  - Added WeatherParticles as autoload with AtmosphereSystem integration

## User Preferences
- Язык: русский
- Качество графики: сравнимое с Rust

## System Architecture
The game is built using Godot 4.4.1 and primarily uses GDScript. It features a client-server architecture for multiplayer functionality.

### UI/UX Decisions
- **HUD:** Displays player stats (health, stamina, hunger, thirst, sanity, blood, temperature), 8-slot hotbar, crosshair, crouch indicator, XP/level notifications, jump indicator, and FPS counter.
- **Minimap:** Located in the top-right, showing biomes, player marker with direction, and a compass.
- **Inventory:** Grid-based with item names, quantity, weight display, use buttons, and drag-and-drop functionality for hotbar. Features item icons (emojis) and color-coding by item type.
- **Settings:** Configurable graphics (quality, resolution, shadows, bloom, fog, anti-aliasing), controls (mouse sensitivity, FOV), and audio (master, music, effects volumes). Supports language selection (Russian/English).
- **Save/Load UI:** Menu for loading and deleting saves with date and level information.

### Technical Implementations
- **World Generation:** Procedural generation of heights and biomes using noise (FastNoiseLite) for mountains, plains, oceans, and rivers. Features 25+ biomes.
- **Chunk-based Terrain:** `ChunkGenerator` creates 3D terrain meshes with collision, vertex colors based on biomes, and automatic tree/rock spawning. `WorldStreamer` handles dynamic loading/unloading of chunks and structures around the player.
- **Structure Generation:** `StructureGenerator` creates villages, towns, mines, and camps with NPCs and guards.
- **Mob Spawning:** `MobSpawner` dynamically spawns 19 types of mobs based on biome-specific tables, with pack behavior and despawning logic.
- **Player Systems:** Includes HP, stamina, hunger, thirst, temperature, sanity, and blood stats with debuffs, XP, leveling, and a PerkSystem with 18 unique perks across 7 categories.
- **Inventory System:** 40 backpack slots, 8 hotbar slots, 8 equipment slots, item database with Russian names, and item usage logic.
- **Combat System:** Hitbox-based damage, weapon resources, combo system, armor calculation, and projectile support.
- **First-Person View:** `FirstPersonArms` provides realistic animated arms with detailed finger anatomy, weapon/tool handling, swing animations, and camera sway. `FirstPersonLegs` shows visible legs when looking down.
- **Character Model:** `CharacterModel` creates anatomically correct procedural humanoid with customizable skin/hair colors, skeleton-based structure, and movement animations.
- **Faction System:** Default factions (player, town, wild, bandits, monsters, neutral) with reputation (from -100 to +100) affecting trading and access to settlements. Features 10 factions and 9 reputation ranks with Russian names.
- **Settlement System:** Settlements can level up (Camp → Village → Town → City → Capital) with population classes (workers, guards, craftsmen, traders), resources, economy, happiness, and ability to declare wars/alliances.
- **Crafting System:** Categorized recipes with icons, search functionality, ingredient details, and resource availability checks.
- **Save/Load System:** `SaveManager` handles saving player position, stats, inventory, progression, and time of day across multiple slots. Includes auto-save and quick save/load.
- **Audio System (`AudioManager`):** Procedural sound generation for footsteps (various materials), attack/hit sounds, item pickup, and UI sounds.
- **VFX System (`VFXManager`):** Visual effects for damage numbers, hit particles, item pickup, crafting, level-up, healing, and death.
- **Notification System:** Pop-up notifications for various events (info, success, warning, error, XP, level-up, item, achievement) with animation and queueing.
- **Mob AI:** States for idle, patrol, chase, attack, and flee, with integration for VFX and audio.
- **Environmental Systems:** Dynamic day/night cycle with 4 periods, and a weather system with 8 types of weather effects.
- **Biome System:** `BiomeSystem` provides 25+ biome definitions with temperature, humidity, and danger levels. Includes is_cold_biome(), is_hot_biome(), and resource/spawn modifiers.
- **Temperature System:** Dynamically calculates player temperature based on biome, weather, time of day, and equipped clothing.
- **Localization System:** `LocalizationService` supports Russian and English with 100+ translated strings, language persistence, and TranslationServer integration.
- **Graphics:** Utilizes OpenGL ES 3.2 (compatibility mode). Terrain materials use Burley diffuse and Schlick-GGX specular, with added sand, snow, and terrain materials, and ambient occlusion. ConcavePolygonShape3D collisions for terrain.

### Feature Specifications
- **World Size:** 16384x16384 units.
- **Item Database:** 100+ items with Russian names.
- **Crafting Recipes:** 60+ recipes in 9 categories.
- **Debuffs:** 12+ effects (starvation, freezing, bleeding, etc.).
- **Biomes:** 25+ unique biomes with temperature/humidity/danger data.

## Key Scripts
- `scripts/player/character_model.gd` - Procedural humanoid model with skeleton
- `scripts/player/first_person_arms.gd` - Realistic first-person arms with weapons
- `scripts/systems/biome_system.gd` - Biome data and queries
- `scripts/systems/temperature_system.gd` - Player temperature calculation
- `scripts/systems/localization_service.gd` - Multi-language support
- `scripts/world/resource_node.gd` - Gatherable resource nodes (trees, rocks)
- `scripts/world/terrain_material_generator.gd` - PBR terrain shader material system
- `scripts/world/terrain_textures.gd` - Procedural terrain texture generation
- `scripts/world/tree_generator.gd` - Procedural tree models with LOD
- `scripts/world/rock_generator.gd` - Procedural rock and ore models
- `scripts/mobs/mob_model_generator.gd` - Procedural mob models for 19 types
- `scripts/world/atmosphere_system.gd` - Dynamic fog and weather effects
- `scripts/world/weather_particles.gd` - Rain/snow/sand particle systems
- `scripts/world/chunk_generator.gd` - Terrain mesh and object spawning
- `scripts/world/mob_spawner.gd` - Mob spawning with procedural models
- `localization/ru.csv` and `localization/en.csv` - Translation files

## External Dependencies
The project primarily utilizes the Godot Engine's built-in functionalities and its scripting language, GDScript.
- **FastNoiseLite:** Used for procedural world generation.
- **TranslationServer:** Integrated for language localization.

## Known Limitations
- Subsurface scattering not available in OpenGL ES mode (cosmetic only)
- VNC display in Replit may have slight performance overhead
