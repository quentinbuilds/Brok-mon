class_name NpcTalk
extends RefCounted
## One-liners for overworld NPCs. Lookup by node name or `talk_id` meta.
## Person 2 can keep using group "npc"; this file stays out of tileset/camera.

const LINES := {
	"wizard": "I cast Fetch.\nIt failed.",
	"skeleton": "I died waiting\nfor cooldown.",
	"elder": "Back in '98 we\nhad 4 shades.",
	"sign": "PROF. TOKEN'S LAB\nclosed. Generating.",
	"youth": "Dad says this cart\nhas no battery.",
	"goblin": "Don't @ me.",
	"viking": "I ragebaited a\nboss once.",
	"knight": "My armor is\nmostly comments.",
	"explorer": "The map is 25\ntiles wide. Peak.",
}

## Extra lines, played in order on repeat visits. LINES stays the one an NPC opens with, so a
## first meeting always reads the same and the tests above stay deterministic; talk to someone
## twice and they start riffing.
const VARIATIONS := {
	"wizard": [
		"My spellbook is\njust a changelog.",
		"I have mana. It\nis on a free tier.",
		"Rolled a nat 20.\nStill got rate limited.",
	],
	"skeleton": [
		"No skin in the\ngame. Literally.",
		"I'm big boned.\nThat's all I am.",
		"Been dead since\nthe last standup.",
	],
	"elder": [
		"We walked uphill\nto both gyms.",
		"My grandson is a\nprompt engineer.",
		"Kids these days\nhave save files.",
	],
	"sign": [
		"NOTICE: sign is\nself aware now.",
		"BEWARE: tall grass\nand tall claims.",
		"THIS SIGN LEFT\nBLANK ON PURPOSE.",
	],
	"youth": [
		"My dad IS the\nfinal boss. Sadly.",
		"I trade creatures\nfor lunch money.",
		"Mum says I peaked\nin the tutorial.",
	],
	"goblin": [
		"I'm not short.\nI'm compressed.",
		"Stole your item.\nIt was character\nbuilding.",
		"Goblin mode is a\nlifestyle, actually.",
	],
	"viking": [
		"I pillaged a\nvillage. Left a\nfive star review.",
		"My longboat has\nno seatbelts.",
		"Valhalla has a\nwaiting list now.",
	],
	"knight": [
		"I refactored my\nhonour. It's cleaner.",
		"Slayed a dragon.\nIt was a merge\nconflict.",
		"This armour has\nno pockets. Tragic.",
	],
	"explorer": [
		"Mapped the whole\nisland. Twice.\nStill lost.",
		"I found a beach.\nIt found me back.",
		"North is wherever\nI'm facing. Trust.",
	],
}

## Dialogue portrait per NPC, from world/characters/portraits/. Ids without one show the box
## with no portrait rather than a wrong face; a sign, for example, has nothing to show.
const PORTRAITS := {
	"wizard": "Wizard1",
	"skeleton": "Punk",
	"elder": "old_man",
	"youth": "Kid1",
	"goblin": "Goblin",
	"viking": "Viking",
	"knight": "Knight",
	"explorer": "Detective",
	"cap_beard": "Luimberjack",
	"pigtails": "Girl",
	"pink_dress": "Lady",
	"grey_shirt": "Glasses",
	"vest_man": "FarmerBoy",
	"maroon": "Boy2",
	"mohawk": "Punk",
	"rusty_hair": "Girl2",
}

const PORTRAIT_DIR := "res://world/characters/portraits/"

const FALLBACK := "..."
const NPC_GROUP := "npc"
const TALK_RANGE := 16.0

## How close the player must be for the "A TALK" badge to appear. Wider than TALK_RANGE so the
## prompt shows up a moment before the button would actually do anything.
const PROMPT_RANGE := 24.0


static func id_of(node: Node) -> String:
	if node != null and node.has_meta("talk_id"):
		return str(node.get_meta("talk_id")).to_lower()
	if node == null:
		return ""
	return node.name.to_lower()


static func line_for(id: String) -> String:
	var key := id.to_lower()
	if LINES.has(key):
		return str(LINES[key])
	return FALLBACK


static func line_for_node(node: Node) -> String:
	return line_for(id_of(node))


## Everything an NPC can say, opener first.
static func lines_for(id: String) -> PackedStringArray:
	var key := id.to_lower()
	var all := PackedStringArray([line_for(key)])
	for extra in VARIATIONS.get(key, []):
		all.append(String(extra))
	return all


## The nth thing an NPC says, wrapping once they run out. Callers keep the counter so the
## rotation survives walking away and coming back.
static func line_at(id: String, index: int) -> String:
	var all := lines_for(id)
	return all[posmod(index, all.size())]


static func line_at_node(node: Node, index: int) -> String:
	return line_at(id_of(node), index)


## "" when this id has no face to show.
static func portrait_path(id: String) -> String:
	var key := id.to_lower()
	if not PORTRAITS.has(key):
		return ""
	return "%s%s.png" % [PORTRAIT_DIR, PORTRAITS[key]]


static func portrait_path_for_node(node: Node) -> String:
	return portrait_path(id_of(node))


## Nearest NPC within the wider prompt radius, for the floating "A TALK" badge.
static func nearest_in_prompt_range(from: Vector2, nodes: Array) -> Node:
	var best: Node = null
	var best_d := PROMPT_RANGE
	for n in nodes:
		if n == null or (n is CanvasItem and not (n as CanvasItem).visible):
			continue
		var d := from.distance_to(position_of(n))
		if d <= best_d:
			best_d = d
			best = n
	return best


static func position_of(node: Node) -> Vector2:
	if node is Node2D:
		return (node as Node2D).position
	if node is Control:
		return (node as Control).position
	return Vector2(INF, INF)


static func nearest(from: Vector2, nodes: Array) -> Node:
	var best: Node = null
	var best_d := TALK_RANGE
	for n in nodes:
		if n == null:
			continue
		var d := from.distance_to(position_of(n))
		if d <= best_d:
			best_d = d
			best = n
	return best
