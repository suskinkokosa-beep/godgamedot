Epoch Settlements — BETA scaffolding added.

New systems added:
- GameManager (scripts/systems/game_manager.gd) — global manager & language persistence
- LocalizationService (scripts/systems/localization_service.gd) — loads CSV-based translations
- Localization files at res://localization/en.csv and res://localization/ru.csv

INSTALL:
1) Register autoloads in Project Settings -> Autoload:
   - scripts/systems/game_manager.gd as GameManager
   - scripts/systems/localization_service.gd as LocalizationService
2) LocalizationService will load 'en' by default. Use GameManager.set_language("ru") to switch.
3) UI scripts can call LocalizationService.t("inventory") to get translated string.

Note: This is initial beta scaffolding. More systems (AI improvements, combat tweaks, UI polish, content expansion) will be added iteratively.

New Autoload: scripts/systems/stats.gd as StatsSystem
Inventory updated with equipment slots and weight.
Stats UI scene at scenes/ui/stats_window.tscn

AI & Factions added: FactionSystem, enhanced mob AI, WorldDirector spawner, Trader NPC and TradeWindow UI.

WeatherSystem, BiomeSystem and TemperatureSystem added. Weather is server-controlled; Biomes are point-based; TemperatureSystem applies damage at extremes.

Network 2.0: MovementServer and MovementClient added. Add MovementServer as autoload on server and MovementClient on clients; add NetworkInterpolator node under networked entities for smooth motion.

Art pack integrated into project/assets/art_pack. Prefab scenes created at scenes/props/*.tscn and art preview scene at scenes/art_preview.tscn

Player System 2.0 added: PlayerProgression, ActionXP, Skills UI. Register PlayerProgression and ActionXP as autoloads. Skills window: scenes/ui/skills_window.tscn

AI System 2.0 added: BaseAI, Wolf AI, Monster AI, NPC Citizen, Guard and Trader behaviors, SpawnTable. Register SpawnTable as autoload; add mob scenes in scenes/mobs/*.tscn

Combat 2.0 core added: CombatEngine, HitboxZone, Projectile, ComboChain, Weapon resources and Armor helper. Place hitbox scenes under characters and equip weapon .tres resources under assets/weapons.

Combat integration: AttackHit prefab and PlayerAttackController added. Player can call perform_attack_local("light") or ("heavy"). Attach PlayerAttackController as a child of player scene or as a node named 'PlayerAttackController' in scene root.

World 2.0: TerrainGenerator, BiomeMap, NoiseUtil, SeedManager and ChunkStreamer added. Use SeedManager.set_seed(seed) before running to generate deterministic world. Terrain uses OpenSimplexNoise and will create prop prefabs from scenes/props depending on biome.
