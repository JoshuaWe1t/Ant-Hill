# Ant-Hill

```
res://
├── assets/                  # Общие ассеты, не привязанные к конкретной сущности
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   ├── fonts/
│   ├── textures/            # Общие текстуры, тайлсеты, окружение
│   └── themes/              # Темы UI (.tres)
│
├── core/                    # Архитектурная база и глобальные скрипты
│   ├── autoload/            # Синглтоны (EventBus, GameManager, AudioManager)
│   │   ├── event_bus.gd
│   │   └── game_manager.gd
│   │   └── debug_manager.gd # Синглтон: хоткеи, сбор метрик, логирование
│   ├── state_machine/       # Общие базовые классы (StateMachine, State)
│   └── utils/               # Хелперы, константы, математические функции
│
├── debug/                       # Все инструменты отладки в одном месте
│   ├── console/                 # Внутриигровая консоль команд
│   │   ├── debug_console.tscn
│   │   └── debug_console.gd
│   ├── overlays/                # FPS, счетчик сущностей, сетка, коллизии
│   │   ├── debug_overlay.tscn
│   │   └── debug_overlay.gd
│   └── cheats/                  # Быстрый спавн предметов, пропуск уровней
│       └── cheat_commands.gd
|
├── entities/                # Игровые объекты (актёры)
│   ├── player/
│   │   ├── player.tscn
│   │   ├── player.gd
│   │   └── sprites/         # Спрайты, нужные только игроку
│   └── enemies/
│       ├── drone/
│       │   ├── drone.tscn
│       │   └── drone.gd
│       └── guard/
│           ├── guard.tscn
│           └── guard.gd
│
├── interactables/           # Интерактивные объекты мира (двери, улики, терминалы)
│   ├── door/
│   │   ├── door.tscn
│   │   └── door.gd
│   └── terminal/
│
├── scenes/                  # Крупные экраны и уровни игры
│   ├── levels/
│   │   ├── level_01/
│   │   │   ├── level_01.tscn
│   │   │   └── level_01.gd
│   │   └── level_02/
│   └── menus/
│       ├── main_menu/
│       │   ├── main_menu.tscn
│       │   └── main_menu.gd
│       └── pause_menu/
│
└── ui/                      # Элементы интерфейса
    ├── hud/
    │   ├── hud.tscn
    │   └── hud.gd
    ├── dialogue/            # Окна диалогов, субтитры
    └── components/          # Переиспользуемые кнопки, полоски здоровья, кастомные контейнеры
```