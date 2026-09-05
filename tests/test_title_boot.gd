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
	# The copyright gag is gone: two lines never fit the prompt label and spilled out of it.
	assert_eq(title.get_node("Prompt").text, "", "no copyright line on the label beat")
	assert_false(title.get_node("PromptPanel").visible, "and no empty cream bar either")
	assert_true(title.get_node("Title").visible, "the logo is up on its own")
	title.update(TitleState.LABEL_SECS)
	assert_eq(title.beat, TitleState.Beat.TITLE)
	assert_true(title.get_node("Prompt").text.contains("PRESS A"))
	assert_true(title.get_node("PromptPanel").visible, "prompt returns with its panel")
	assert_false(title.get_node("Prompt").text.contains("
"), "one line, so it fits the label")
	title.queue_free()
	await tree.process_frame


## The prompt says one thing and keeps saying it. It used to flicker to a second line every couple
## of seconds; that read as a rendering fault rather than a joke, so it is gone.
func test_the_prompt_does_not_change_once_the_title_settles() -> void:
	var title := _title()
	await tree.process_frame
	title.enter({})
	title._set_beat(TitleState.Beat.TITLE)
	for _i in 20:
		title.update(0.25)
		assert_eq(title.get_node("Prompt").text, TitleState.TITLE_PROMPT, "the prompt changed")
	title.queue_free()
	await tree.process_frame
