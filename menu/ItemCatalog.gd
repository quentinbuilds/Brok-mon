class_name ItemCatalog
extends RefCounted
## Menu-owned item definitions (sprites, names, kinds). GameData only stores counts
## keyed by id; capture_orb and potion reuse the core ids.

const SHEET_PATH := "res://assets/sprites/items/item_sheet.png"
const CELL := 132
const COUNT := 9
const DEMO_COUNT := 2
const KIND_ORB := &"orb"
const KIND_TONIC := &"tonic"

## id, display name, kind, atlas column, atlas row.
static func entries() -> Array[Dictionary]:
	return [
		{&"id": GameData.ITEM_CAPTURE_ORB, &"name": "Capture Orb", &"kind": KIND_ORB, &"col": 0, &"row": 0},
		{&"id": &"stripe_orb", &"name": "Stripe Orb", &"kind": KIND_ORB, &"col": 1, &"row": 0},
		{&"id": &"mesh_orb", &"name": "Mesh Orb", &"kind": KIND_ORB, &"col": 2, &"row": 0},
		{&"id": &"fin_orb", &"name": "Fin Orb", &"kind": KIND_ORB, &"col": 0, &"row": 1},
		{&"id": &"grove_orb", &"name": "Grove Orb", &"kind": KIND_ORB, &"col": 1, &"row": 1},
		{&"id": &"dusk_tonic", &"name": "Dusk Tonic", &"kind": KIND_TONIC, &"col": 2, &"row": 1},
		{&"id": &"shock_orb", &"name": "Shock Orb", &"kind": KIND_ORB, &"col": 0, &"row": 2},
		{&"id": &"bloom_orb", &"name": "Bloom Orb", &"kind": KIND_ORB, &"col": 1, &"row": 2},
		{&"id": GameData.ITEM_POTION, &"name": "Tonic", &"kind": KIND_TONIC, &"col": 2, &"row": 2},
	]


static func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for e in entries():
		out.append(e[&"id"])
	return out


static func region_of(entry: Dictionary) -> Rect2:
	return Rect2(int(entry[&"col"]) * CELL, int(entry[&"row"]) * CELL, CELL, CELL)


static func sheet() -> Texture2D:
	return load(SHEET_PATH) as Texture2D


static func texture_for(entry: Dictionary) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet()
	atlas.region = region_of(entry)
	atlas.filter_clip = true
	return atlas


## Seeds the seven extra catalog ids once per GameData.reset(). Does not touch
## capture_orb / potion start counts and does not restock spent extras.
static func ensure_demo_items() -> void:
	for e in entries():
		var id: StringName = e[&"id"]
		if id == GameData.ITEM_CAPTURE_ORB or id == GameData.ITEM_POTION:
			continue
		if not GameData.inventory.has(id):
			GameData.add_item(id, DEMO_COUNT)
