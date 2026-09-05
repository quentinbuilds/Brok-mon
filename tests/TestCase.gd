class_name TestCase
extends RefCounted
## Minimal base class for headless tests. Subclasses define test_* methods.
## Tests may be coroutines (use `await tree.process_frame`).

var tree: SceneTree
var failures: Array[String] = []
var _current: String = ""

func before_each() -> void:
	pass

func after_each() -> void:
	pass

func assert_true(cond: bool, msg: String = "") -> void:
	if not cond:
		_fail("expected true. %s" % msg)

func assert_false(cond: bool, msg: String = "") -> void:
	if cond:
		_fail("expected false. %s" % msg)

func assert_eq(actual, expected, msg: String = "") -> void:
	if actual != expected:
		_fail("expected %s, got %s. %s" % [str(expected), str(actual), msg])

func assert_ne(actual, unexpected, msg: String = "") -> void:
	if actual == unexpected:
		_fail("expected something other than %s. %s" % [str(unexpected), msg])

func _fail(text: String) -> void:
	failures.append("%s: %s" % [_current, text])

## Runs every test_* method. Returns [passed, failed].
func run(p_tree: SceneTree) -> Array[int]:
	tree = p_tree
	var passed := 0
	var failed := 0
	for m in get_method_list():
		var name: String = m["name"]
		if not name.begins_with("test_"):
			continue
		_current = name
		var before := failures.size()
		before_each()
		await call(name)
		after_each()
		if failures.size() == before:
			passed += 1
			print("  PASS %s" % name)
		else:
			failed += 1
			for f in failures.slice(before):
				print("  FAIL %s" % f)
	return [passed, failed]
