extends Node

signal law_enacted(settlement_id, law_type)
signal law_repealed(settlement_id, law_type)
signal crime_committed(settlement_id, criminal, crime_type)
signal punishment_applied(settlement_id, criminal, punishment)

enum LawType {
        TAXATION_LOW,
        TAXATION_MEDIUM,
        TAXATION_HIGH,
        CONSCRIPTION,
        CURFEW,
        MARTIAL_LAW,
        FREE_TRADE,
        TRADE_RESTRICTIONS,
        WEAPON_BAN,
        MAGIC_BAN,
        SLAVERY_ALLOWED,
        SLAVERY_BANNED,
        RELIGIOUS_FREEDOM,
        STATE_RELIGION,
        PROPERTY_RIGHTS,
        COMMUNAL_PROPERTY
}

enum CrimeType {
        THEFT,
        ASSAULT,
        MURDER,
        TRESPASSING,
        SMUGGLING,
        TREASON,
        DESERTION,
        VANDALISM,
        POACHING
}

enum PunishmentType {
        FINE,
        IMPRISONMENT,
        FORCED_LABOR,
        EXILE,
        EXECUTION,
        FLOGGING,
        REPUTATION_LOSS
}

var settlement_laws := {}
var wanted_criminals := {}
var crime_records := {}

var law_effects := {
        LawType.TAXATION_LOW: {
                "name": "Низкие налоги",
                "happiness_bonus": 10,
                "income_mult": 0.5,
                "growth_bonus": 5
        },
        LawType.TAXATION_MEDIUM: {
                "name": "Средние налоги",
                "happiness_bonus": 0,
                "income_mult": 1.0,
                "growth_bonus": 0
        },
        LawType.TAXATION_HIGH: {
                "name": "Высокие налоги",
                "happiness_bonus": -15,
                "income_mult": 2.0,
                "growth_bonus": -5
        },
        LawType.CONSCRIPTION: {
                "name": "Воинская повинность",
                "happiness_bonus": -10,
                "military_mult": 1.5,
                "production_mult": 0.9
        },
        LawType.CURFEW: {
                "name": "Комендантский час",
                "happiness_bonus": -5,
                "crime_mult": 0.5,
                "trade_mult": 0.8
        },
        LawType.MARTIAL_LAW: {
                "name": "Военное положение",
                "happiness_bonus": -25,
                "crime_mult": 0.2,
                "military_mult": 2.0,
                "production_mult": 0.7
        },
        LawType.FREE_TRADE: {
                "name": "Свободная торговля",
                "happiness_bonus": 5,
                "trade_mult": 1.5,
                "income_mult": 1.2
        },
        LawType.TRADE_RESTRICTIONS: {
                "name": "Торговые ограничения",
                "happiness_bonus": -5,
                "trade_mult": 0.5,
                "local_production_mult": 1.3
        },
        LawType.WEAPON_BAN: {
                "name": "Запрет оружия",
                "happiness_bonus": -10,
                "crime_mult": 0.7,
                "rebellion_risk": 0.3
        },
        LawType.PROPERTY_RIGHTS: {
                "name": "Право собственности",
                "happiness_bonus": 5,
                "investment_mult": 1.3,
                "inequality": 1.2
        },
        LawType.COMMUNAL_PROPERTY: {
                "name": "Общинная собственность",
                "happiness_bonus": 0,
                "investment_mult": 0.8,
                "inequality": 0.5,
                "cooperation_bonus": 20
        }
}

var crime_punishments := {
        CrimeType.THEFT: {
                "name": "Кража",
                "default_punishment": PunishmentType.FINE,
                "fine_amount": 50,
                "reputation_loss": 10
        },
        CrimeType.ASSAULT: {
                "name": "Нападение",
                "default_punishment": PunishmentType.FINE,
                "fine_amount": 100,
                "reputation_loss": 20
        },
        CrimeType.MURDER: {
                "name": "Убийство",
                "default_punishment": PunishmentType.EXECUTION,
                "fine_amount": 1000,
                "reputation_loss": 100
        },
        CrimeType.TRESPASSING: {
                "name": "Проникновение",
                "default_punishment": PunishmentType.FINE,
                "fine_amount": 20,
                "reputation_loss": 5
        },
        CrimeType.SMUGGLING: {
                "name": "Контрабанда",
                "default_punishment": PunishmentType.IMPRISONMENT,
                "fine_amount": 200,
                "reputation_loss": 15
        },
        CrimeType.TREASON: {
                "name": "Измена",
                "default_punishment": PunishmentType.EXECUTION,
                "fine_amount": 5000,
                "reputation_loss": 200
        },
        CrimeType.DESERTION: {
                "name": "Дезертирство",
                "default_punishment": PunishmentType.FORCED_LABOR,
                "fine_amount": 150,
                "reputation_loss": 30
        },
        CrimeType.VANDALISM: {
                "name": "Вандализм",
                "default_punishment": PunishmentType.FINE,
                "fine_amount": 75,
                "reputation_loss": 10
        },
        CrimeType.POACHING: {
                "name": "Браконьерство",
                "default_punishment": PunishmentType.FINE,
                "fine_amount": 30,
                "reputation_loss": 5
        }
}

func _ready():
        pass

func enact_law(settlement_id: int, law_type: int) -> bool:
        var ss = get_node_or_null("/root/SettlementSystem")
        if not ss:
                return false
        
        var settlement = ss.get_settlement(settlement_id)
        if not settlement:
                return false
        
        if not settlement_laws.has(settlement_id):
                settlement_laws[settlement_id] = []
        
        var conflicting = _get_conflicting_laws(law_type)
        for conflict in conflicting:
                if conflict in settlement_laws[settlement_id]:
                        repeal_law(settlement_id, conflict)
        
        if law_type not in settlement_laws[settlement_id]:
                settlement_laws[settlement_id].append(law_type)
                _apply_law_effects(settlement_id, law_type)
                emit_signal("law_enacted", settlement_id, law_type)
                return true
        
        return false

func repeal_law(settlement_id: int, law_type: int) -> bool:
        if not settlement_laws.has(settlement_id):
                return false
        
        if law_type in settlement_laws[settlement_id]:
                settlement_laws[settlement_id].erase(law_type)
                _remove_law_effects(settlement_id, law_type)
                emit_signal("law_repealed", settlement_id, law_type)
                return true
        
        return false

func _get_conflicting_laws(law_type: int) -> Array:
        match law_type:
                LawType.TAXATION_LOW:
                        return [LawType.TAXATION_MEDIUM, LawType.TAXATION_HIGH]
                LawType.TAXATION_MEDIUM:
                        return [LawType.TAXATION_LOW, LawType.TAXATION_HIGH]
                LawType.TAXATION_HIGH:
                        return [LawType.TAXATION_LOW, LawType.TAXATION_MEDIUM]
                LawType.FREE_TRADE:
                        return [LawType.TRADE_RESTRICTIONS]
                LawType.TRADE_RESTRICTIONS:
                        return [LawType.FREE_TRADE]
                LawType.PROPERTY_RIGHTS:
                        return [LawType.COMMUNAL_PROPERTY]
                LawType.COMMUNAL_PROPERTY:
                        return [LawType.PROPERTY_RIGHTS]
                LawType.SLAVERY_ALLOWED:
                        return [LawType.SLAVERY_BANNED]
                LawType.SLAVERY_BANNED:
                        return [LawType.SLAVERY_ALLOWED]
                LawType.RELIGIOUS_FREEDOM:
                        return [LawType.STATE_RELIGION]
                LawType.STATE_RELIGION:
                        return [LawType.RELIGIOUS_FREEDOM]
        return []

func _apply_law_effects(settlement_id: int, law_type: int):
        var ss = get_node_or_null("/root/SettlementSystem")
        if not ss:
                return
        
        var settlement = ss.get_settlement(settlement_id)
        if not settlement:
                return
        
        var effects = law_effects.get(law_type, {})
        
        if effects.has("happiness_bonus"):
                settlement.happiness += effects.happiness_bonus

func _remove_law_effects(settlement_id: int, law_type: int):
        var ss = get_node_or_null("/root/SettlementSystem")
        if not ss:
                return
        
        var settlement = ss.get_settlement(settlement_id)
        if not settlement:
                return
        
        var effects = law_effects.get(law_type, {})
        
        if effects.has("happiness_bonus"):
                settlement.happiness -= effects.happiness_bonus

func report_crime(settlement_id: int, criminal, crime_type: int):
        emit_signal("crime_committed", settlement_id, criminal, crime_type)
        
        if not crime_records.has(settlement_id):
                crime_records[settlement_id] = []
        
        var record = {
                "criminal": criminal.name if criminal else "Unknown",
                "crime_type": crime_type,
                "time": Time.get_unix_time_from_system(),
                "resolved": false
        }
        
        crime_records[settlement_id].append(record)
        
        if criminal and not _is_wanted(criminal):
                _add_to_wanted(settlement_id, criminal, crime_type)

func _add_to_wanted(settlement_id: int, criminal, crime_type: int):
        var criminal_id = criminal.get_instance_id() if criminal else -1
        
        if not wanted_criminals.has(settlement_id):
                wanted_criminals[settlement_id] = {}
        
        var crime_data = crime_punishments.get(crime_type, {})
        
        wanted_criminals[settlement_id][criminal_id] = {
                "criminal": criminal,
                "crime_type": crime_type,
                "bounty": crime_data.get("fine_amount", 50),
                "since": Time.get_unix_time_from_system()
        }

func _is_wanted(criminal) -> bool:
        var criminal_id = criminal.get_instance_id() if criminal else -1
        
        for settlement_id in wanted_criminals:
                if wanted_criminals[settlement_id].has(criminal_id):
                        return true
        
        return false

func apply_punishment(settlement_id: int, criminal, crime_type: int) -> Dictionary:
        var crime_data = crime_punishments.get(crime_type, {})
        var punishment_type = crime_data.get("default_punishment", PunishmentType.FINE)
        
        var result = {
                "punishment_type": punishment_type,
                "fine_paid": 0,
                "reputation_lost": 0
        }
        
        match punishment_type:
                PunishmentType.FINE:
                        var fine = crime_data.get("fine_amount", 50)
                        result.fine_paid = fine
                        if criminal and criminal.has_method("pay_fine"):
                                criminal.pay_fine(fine)
                
                PunishmentType.REPUTATION_LOSS:
                        var loss = crime_data.get("reputation_loss", 10)
                        result.reputation_lost = loss
                        var faction_sys = get_node_or_null("/root/FactionSystem")
                        if faction_sys and criminal:
                                var ss = get_node_or_null("/root/SettlementSystem")
                                if ss:
                                        var settlement = ss.get_settlement(settlement_id)
                                        if settlement:
                                                faction_sys.modify_relation("player", settlement.faction, -loss)
                
                PunishmentType.EXILE:
                        if criminal and criminal.has_method("exile_from"):
                                criminal.exile_from(settlement_id)
        
        _clear_wanted(settlement_id, criminal)
        
        emit_signal("punishment_applied", settlement_id, criminal, punishment_type)
        
        return result

func _clear_wanted(settlement_id: int, criminal):
        var criminal_id = criminal.get_instance_id() if criminal else -1
        
        if wanted_criminals.has(settlement_id) and wanted_criminals[settlement_id].has(criminal_id):
                wanted_criminals[settlement_id].erase(criminal_id)

func get_settlement_laws(settlement_id: int) -> Array:
        return settlement_laws.get(settlement_id, [])

func get_law_info(law_type: int) -> Dictionary:
        return law_effects.get(law_type, {})

func get_crime_info(crime_type: int) -> Dictionary:
        return crime_punishments.get(crime_type, {})

func get_wanted_list(settlement_id: int) -> Array:
        if not wanted_criminals.has(settlement_id):
                return []
        return wanted_criminals[settlement_id].values()

func get_total_law_effects(settlement_id: int) -> Dictionary:
        var total = {
                "happiness_bonus": 0,
                "income_mult": 1.0,
                "trade_mult": 1.0,
                "military_mult": 1.0,
                "production_mult": 1.0,
                "crime_mult": 1.0,
                "growth_bonus": 0
        }
        
        var laws = get_settlement_laws(settlement_id)
        
        for law_type in laws:
                var effects = law_effects.get(law_type, {})
                
                if effects.has("happiness_bonus"):
                        total.happiness_bonus += effects.happiness_bonus
                if effects.has("income_mult"):
                        total.income_mult *= effects.income_mult
                if effects.has("trade_mult"):
                        total.trade_mult *= effects.trade_mult
                if effects.has("military_mult"):
                        total.military_mult *= effects.military_mult
                if effects.has("production_mult"):
                        total.production_mult *= effects.production_mult
                if effects.has("crime_mult"):
                        total.crime_mult *= effects.crime_mult
                if effects.has("growth_bonus"):
                        total.growth_bonus += effects.growth_bonus
        
        return total
