extends Node

var male_names_ru := [
        "Алексей", "Иван", "Дмитрий", "Сергей", "Андрей", "Николай", "Михаил", "Владимир",
        "Павел", "Александр", "Константин", "Григорий", "Борис", "Виктор", "Олег", "Игорь",
        "Фёдор", "Пётр", "Василий", "Степан", "Тимофей", "Максим", "Артём", "Егор",
        "Никита", "Роман", "Кирилл", "Даниил", "Антон", "Евгений", "Леонид", "Геннадий",
        "Ярослав", "Вячеслав", "Станислав", "Матвей", "Богдан", "Руслан", "Марк", "Семён"
]

var female_names_ru := [
        "Анна", "Мария", "Елена", "Ольга", "Наталья", "Татьяна", "Ирина", "Екатерина",
        "Светлана", "Юлия", "Виктория", "Дарья", "Алина", "Валерия", "Ксения", "Полина",
        "Александра", "Анастасия", "Людмила", "Галина", "Надежда", "Вера", "Любовь", "Софья",
        "Марина", "Лариса", "Тамара", "Зинаида", "Клавдия", "Варвара", "Агния", "Милена",
        "Ева", "Алиса", "Арина", "Василиса", "Злата", "Яна", "Диана", "Кира"
]

var male_names_en := [
        "John", "William", "James", "Robert", "Michael", "David", "Richard", "Thomas",
        "Charles", "Christopher", "Daniel", "Matthew", "Anthony", "Mark", "Donald", "Steven",
        "Paul", "Andrew", "Joshua", "Kenneth", "Kevin", "Brian", "George", "Timothy",
        "Ronald", "Edward", "Jason", "Jeffrey", "Ryan", "Jacob", "Gary", "Nicholas",
        "Eric", "Jonathan", "Stephen", "Larry", "Justin", "Scott", "Brandon", "Benjamin"
]

var female_names_en := [
        "Mary", "Patricia", "Jennifer", "Linda", "Barbara", "Elizabeth", "Susan", "Jessica",
        "Sarah", "Karen", "Lisa", "Nancy", "Betty", "Margaret", "Sandra", "Ashley",
        "Dorothy", "Kimberly", "Emily", "Donna", "Michelle", "Carol", "Amanda", "Melissa",
        "Deborah", "Stephanie", "Rebecca", "Sharon", "Laura", "Cynthia", "Kathleen", "Amy",
        "Angela", "Shirley", "Anna", "Brenda", "Pamela", "Emma", "Nicole", "Helen"
]

var surnames_ru := [
        "Иванов", "Петров", "Сидоров", "Козлов", "Новиков", "Морозов", "Волков", "Соловьёв",
        "Васильев", "Зайцев", "Павлов", "Семёнов", "Голубев", "Виноградов", "Богданов", "Воробьёв",
        "Фёдоров", "Михайлов", "Беляев", "Тарасов", "Белов", "Комаров", "Орлов", "Киселёв",
        "Макаров", "Андреев", "Ковалёв", "Ильин", "Гусев", "Титов", "Кузьмин", "Кудрявцев"
]

var surnames_en := [
        "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
        "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas",
        "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson", "White",
        "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson", "Walker", "Young"
]

var medieval_titles_ru := [
        "", "", "", "Старший", "Младший", "Мудрый", "Храбрый", "Сильный", "Быстрый", "Тихий"
]

var medieval_titles_en := [
        "", "", "", "the Elder", "the Younger", "the Wise", "the Brave", "the Strong", "the Swift", "the Quiet"
]

var profession_prefixes_ru := {
        "farmer": ["Пахарь", "Землепашец"],
        "guard": ["Воин", "Защитник"],
        "trader": ["Купец", "Торговец"],
        "builder": ["Зодчий", "Мастер"],
        "blacksmith": ["Кузнец", "Молотобоец"],
        "healer": ["Лекарь", "Целитель"]
}

var profession_prefixes_en := {
        "farmer": ["Farmer", "Tiller"],
        "guard": ["Warrior", "Defender"],
        "trader": ["Merchant", "Trader"],
        "builder": ["Builder", "Craftsman"],
        "blacksmith": ["Smith", "Ironworker"],
        "healer": ["Healer", "Medic"]
}

func generate_name(gender: String = "male", lang: String = "ru", include_surname: bool = true, include_title: bool = false) -> String:
        var first_name := ""
        var surname := ""
        var title := ""
        
        if lang == "ru":
                if gender == "female":
                        first_name = female_names_ru[randi() % female_names_ru.size()]
                        if include_surname:
                                surname = surnames_ru[randi() % surnames_ru.size()]
                                if surname.ends_with("ов") or surname.ends_with("ев") or surname.ends_with("ёв"):
                                        surname += "а"
                                elif surname.ends_with("ин"):
                                        surname += "а"
                else:
                        first_name = male_names_ru[randi() % male_names_ru.size()]
                        if include_surname:
                                surname = surnames_ru[randi() % surnames_ru.size()]
                
                if include_title and randf() < 0.2:
                        title = medieval_titles_ru[randi() % medieval_titles_ru.size()]
        else:
                if gender == "female":
                        first_name = female_names_en[randi() % female_names_en.size()]
                else:
                        first_name = male_names_en[randi() % male_names_en.size()]
                
                if include_surname:
                        surname = surnames_en[randi() % surnames_en.size()]
                
                if include_title and randf() < 0.2:
                        title = medieval_titles_en[randi() % medieval_titles_en.size()]
        
        var full_name = first_name
        if surname != "":
                full_name += " " + surname
        if title != "":
                if lang == "ru":
                        full_name += " " + title
                else:
                        full_name += " " + title
        
        return full_name

func generate_npc_name(role: String = "citizen", lang: String = "ru") -> String:
        var gender = "female" if randf() < 0.5 else "male"
        
        var use_title = role in ["guard", "trader", "builder"]
        var name = generate_name(gender, lang, true, use_title)
        
        return name

func generate_random_nickname() -> String:
        var adjectives := ["Swift", "Bold", "Dark", "Light", "Iron", "Silver", "Golden", "Shadow", "Storm", "Fire"]
        var nouns := ["Wolf", "Bear", "Eagle", "Dragon", "Knight", "Hunter", "Warrior", "Ranger", "Blade", "Shield"]
        
        return adjectives[randi() % adjectives.size()] + nouns[randi() % nouns.size()] + str(randi() % 1000)
