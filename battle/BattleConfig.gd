class_name BattleConfig
extends RefCounted
## Tunables for the battle system. Balance here, not in gameplay code.

const SCREEN := Vector2i(200, 120)

const DARKEST := Color8(0x0f, 0x38, 0x0f)
const DARK := Color8(0x30, 0x62, 0x30)
const LIGHT := Color8(0x8b, 0xac, 0x0f)
const LIGHTEST := Color8(0x9b, 0xbc, 0x0f)

const DAMAGE_VARIANCE_MIN := 0.85
const DAMAGE_VARIANCE_MAX := 1.0
const MIN_DAMAGE := 1

const RUN_BASE_CHANCE := 0.55
const RUN_CHANCE_PER_FAIL := 0.15
const RUN_CHANCE_MAX := 0.95

const RAGE_LEVEL_MIN := -3
const RAGE_LEVEL_MAX := 3
const RAGE_ENRAGE_CHANCE := 0.5
const RAGE_CATCH_PER_LEVEL := 0.25
const RAGE_ATTACK_PER_LEVEL := 0.12
const RAGE_DEFENSE_PER_LEVEL := 0.12
const RAGE_CATCH_MULT_MIN := 0.1
const RAGE_CATCH_MULT_MAX := 3.0
const RAGE_STAT_MULT_MIN := 0.25
const RAGE_STAT_MULT_MAX := 3.0

const POTION_HEAL := 20

const MAX_MOVES := 4
const MAX_LEVEL := 15
const EXP_BASE := 8
const EXP_PER_LEVEL := 2
const EXP_YIELD_BASE := 12
const EXP_YIELD_PER_LEVEL := 2
const HP_PER_LEVEL := 2
const ATK_PER_LEVEL := 1
const DEF_PER_EVEN_LEVEL := 1

const FIGHT_COLS := 2
const FIGHT_ROWS := 2
const FIGHT_COL_WIDTH := 90

## Iris time when the player blacks out. Slower than a normal transition: losing should land.
const BLACKOUT_FADE := 0.8

const TEXT_CHARS_PER_SEC := 35.0
const TEXT_CHARS_PER_SEC_FAST := 140.0
const MESSAGE_HOLD := 0.35

const WINDUP_TIME := 0.10
const LUNGE_TIME := 0.12
const HITSTOP_FRAMES := 3
const FLASH_FRAMES := 3
const SHAKE_TIME := 0.18
const SHAKE_PIXELS := 2.0
const HP_DRAIN_TIME := 0.40
const FAINT_TIME := 0.55
const INTRO_WIPE_TIME := 0.45
const SLIDE_IN_TIME := 0.35

const IDLE_BOB_PIXELS := 1.0
const IDLE_BOB_SPEED := 2.2

const ANGER_ICON_TIME := 3.0
const ANGER_ICON_CYCLE := 0.25

const LOW_HP_FRACTION := 0.2
const LOW_HP_FLASH_CYCLE := 0.22

const HORIZON_Y := 52
const ENEMY_PANEL := Rect2i(4, 4, 92, 24)
const ENEMY_SPRITE_RECT := Rect2i(148, 8, 40, 40)
const ENEMY_PLATFORM_CENTER := Vector2(168, 51)
const ENEMY_PLATFORM_RADIUS := Vector2(22, 5)
const PLAYER_SPRITE_RECT := Rect2i(16, 32, 48, 48)
const PLAYER_PLATFORM_CENTER := Vector2(40, 81)
const PLAYER_PLATFORM_RADIUS := Vector2(28, 6)
const PLAYER_PANEL := Rect2i(104, 46, 92, 32)
const BOTTOM_BOX := Rect2i(0, 84, 200, 36)
const BOX_BORDER := 2

const MENU_COLS := 3
const MENU_ROWS := 2
const MENU_ORIGIN := Vector2i(10, 91)
const MENU_COL_WIDTH := 62
const MENU_ROW_HEIGHT := 13

const TEXT_ORIGIN := Vector2i(6, 88)
const TEXT_LINE_HEIGHT := 10
const TEXT_MAX_LINES := 3
const TEXT_MAX_WIDTH := 186.0
const FONT_SIZE := 8

const HP_BAR_SIZE := Vector2i(60, 6)
const RAGE_PIP_SIZE := Vector2i(4, 5)
