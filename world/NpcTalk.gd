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

const FALLBACK := "..."
const NPC_GROUP := "npc"
const TALK_RANGE := 16.0


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
