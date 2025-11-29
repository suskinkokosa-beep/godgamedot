# Эпоха Поселений (Epoch Settlements) - Godot 4.x

## Overview
"Эпоха Поселений" is a multiplayer and single-player 3D first-person game built on Godot 4.4.1. It combines elements of survival, building, combat, economics, and settlement management. The game aims to provide a rich, dynamic world where players can establish and grow settlements, interact with various factions, and face environmental and combat challenges.

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
- **World Generation:** Procedural generation of heights and biomes using noise (FastNoiseLite) for mountains, plains, oceans, and rivers. Features 12+ biomes.
- **Chunk-based Terrain:** `ChunkGenerator` creates 3D terrain meshes with collision, vertex colors based on biomes, and automatic tree/rock spawning. `WorldStreamer` handles dynamic loading/unloading of chunks and structures around the player.
- **Structure Generation:** `StructureGenerator` creates villages, towns, mines, and camps with NPCs and guards.
- **Mob Spawning:** `MobSpawner` dynamically spawns 19 types of mobs based on biome-specific tables, with pack behavior and despawning logic.
- **Player Systems:** Includes HP, stamina, hunger, thirst, temperature, sanity, and blood stats with debuffs, XP, leveling, and a PerkSystem with 18 unique perks across 7 categories.
- **Inventory System:** 40 backpack slots, 8 hotbar slots, 8 equipment slots, item database with Russian names, and item usage logic.
- **Combat System:** Hitbox-based damage, weapon resources, combo system, armor calculation, and projectile support.
- **First-Person View:** `FirstPersonArms` and `FirstPersonLegs` provide visible animated arms and legs, item switching animations, attack animations, head bob, and camera sway.
- **Faction System:** Default factions (player, town, wild, bandits, monsters, neutral) with reputation (from -100 to +100) affecting trading and access to settlements. Features 10 factions and 9 reputation ranks with Russian names.
- **Settlement System:** Settlements can level up (Camp → Village → Town → City → Capital) with population classes (workers, guards, craftsmen, traders), resources, economy, happiness, and ability to declare wars/alliances.
- **Crafting System:** Categorized recipes with icons, search functionality, ingredient details, and resource availability checks.
- **Save/Load System:** `SaveManager` handles saving player position, stats, inventory, progression, and time of day across multiple slots. Includes auto-save and quick save/load.
- **Audio System (`AudioManager`):** Procedural sound generation for footsteps (various materials), attack/hit sounds, item pickup, and UI sounds.
- **VFX System (`VFXManager`):** Visual effects for damage numbers, hit particles, item pickup, crafting, level-up, healing, and death.
- **Notification System:** Pop-up notifications for various events (info, success, warning, error, XP, level-up, item, achievement) with animation and queueing.
- **Mob AI:** States for idle, patrol, chase, attack, and flee, with integration for VFX and audio.
- **Environmental Systems:** Dynamic day/night cycle with 4 periods, and a weather system with 8 types of weather effects.
- **Graphics:** Utilizes OpenGL ES 3.2 (compatibility mode). Terrain materials use Burley diffuse and Schlick-GGX specular, with added sand, snow, and terrain materials, and ambient occlusion. ConcavePolygonShape3D collisions for terrain.

### Feature Specifications
- **World Size:** 16384x16384 units.
- **Item Database:** 100+ items with Russian names.
- **Crafting Recipes:** 60+ recipes in 9 categories.
- **Debuffs:** 12+ effects (starvation, freezing, bleeding, etc.).

## External Dependencies
The project primarily utilizes the Godot Engine's built-in functionalities and its scripting language, GDScript.
- **FastNoiseLite:** Used for procedural world generation.
- **TranslationServer:** Integrated for language localization.