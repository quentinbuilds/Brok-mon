class_name CatchCopy
extends RefCounted
## Catching-screen handshake copy. Person 5 owns odds; these are display strings.


static func connecting(wild_name: String) -> String:
	return "Connecting to\nwild %s..." % wild_name


static func handshake() -> String:
	return "Handshaking..."


static func waiting() -> String:
	return "Waiting for 200 OK..."


static func prompt() -> String:
	return "A: catch   B: fail"


static func beat_text(beat: int, wild_name: String) -> String:
	match beat:
		0:
			return connecting(wild_name)
		1:
			return handshake()
		2:
			return waiting()
		_:
			return "%s\n\n%s" % [waiting(), prompt()]


static func success() -> String:
	return "Caught!\nAdded to dataset."


static func party_full(wild_name: String) -> String:
	return "Party full.\n%s released\ninto the test set." % wild_name


static func failure(catch_multiplier: float) -> String:
	if catch_multiplier > 1.2:
		return "Too furious to\nnegotiate."
	if catch_multiplier < 0.8:
		return "Overthinking\nthe contract."
	return "Connection reset\nby peer."
