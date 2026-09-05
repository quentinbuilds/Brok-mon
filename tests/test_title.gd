extends TestCase
## Title auto-advances to OVERWORLD without waiting for A.

var world: Node
var overlay: Node

func _gs() -> Node:
	return tree.root.get_node("GameState")

func before_each() -> void:
	world = Node.new()
	overlay = Node.new()
	tree.root.add_child(world)
	tree.root.add_child(overlay)
	_gs().bind(world, overlay)

func after_each() -> void:
	_gs().unbind()
	world.free()
	overlay.free()

func test_title_auto_advances_to_overworld() -> void:
	assert_true(_gs().transition_to(GameState.State.TITLE))
	await tree.process_frame
	assert_eq(_gs().current, GameState.State.OVERWORLD)
	assert_eq(overlay.get_child_count(), 0, "title overlay cleared")
	assert_eq(world.get_child_count(), 1, "overworld in world layer")
