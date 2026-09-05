extends SceneTree
## Headless test runner. Discovers res://tests/test_*.gd, runs them, exits 1 on failure.
## Usage: tests/run.sh

const WATCHDOG_SECONDS := 120.0

func _initialize() -> void:
	create_timer(WATCHDOG_SECONDS).timeout.connect(func():
		print("\nTIMEOUT: test run exceeded %d s" % int(WATCHDOG_SECONDS))
		quit(3))
	# Wait one frame so autoloads are fully in the tree before tests touch them.
	await process_frame
	var total_passed := 0
	var total_failed := 0
	var dir := DirAccess.open("res://tests")
	if dir == null:
		push_error("cannot open res://tests")
		quit(2)
		return
	var files: Array[String] = []
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.begins_with("test_") and f.ends_with(".gd"):
			files.append(f)
		f = dir.get_next()
	files.sort()
	for file in files:
		print("== %s" % file)
		var script = load("res://tests/%s" % file)
		if script == null or not script.can_instantiate():
			print("  FAIL could not load %s" % file)
			total_failed += 1
			continue
		var case = script.new()
		var counts: Array[int] = await case.run(self)
		total_passed += counts[0]
		total_failed += counts[1]
	print("\n%d passed, %d failed" % [total_passed, total_failed])
	quit(1 if total_failed > 0 else 0)
