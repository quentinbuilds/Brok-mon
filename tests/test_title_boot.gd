extends TestCase
## Title cartridge boot: BOOT -> LABEL -> TITLE, then A starts the game.


func _title() -> TitleState:
	var packed := load("res://title/TitleState.tscn") as PackedScene
	var node := packed.instantiate()
	tree.root.add_child(node)
	return node as TitleState


func test_boot_advances_to_label_then_title() -> void:
	var title := _title()
	await tree.process_frame
	title.enter({})
	assert_eq(title.beat, TitleState.Beat.BOOT)
	title.update(TitleState.BOOT_SECS)
	assert_eq(title.beat, TitleState.Beat.LABEL)
	assert_true(title.get_node("Label").text.contains("QUENTIN SOFT"))
	assert_true(title.get_node("Label").text.contains("NOBODY"))
	title.update(TitleState.LABEL_SECS)
	assert_eq(title.beat, TitleState.Beat.TITLE)
	assert_true(title.get_node("Label").text.contains("PRESS A"))
	title.queue_free()
	await tree.process_frame


func test_title_glitch_mentions_consent() -> void:
	var title := _title()
	await tree.process_frame
	title.enter({})
	title._set_beat(TitleState.Beat.TITLE)
	title._elapsed = 0.0
	title.update(0.05)
	assert_true(title.get_node("Label").text.contains("CONSENT"))
	title.queue_free()
	await tree.process_frame
