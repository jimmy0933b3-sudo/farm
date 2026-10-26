extends RefCounted
## Offline race logic shared by the lobby, game and smoke tests.

const TRACKS: Array = [
	{"id":"farm","name":"🌾 農場快樂盃","short":"農場","duration":54.0,"bg":"#A6DEA4"},
	{"id":"flower","name":"🌸 昆蟲迷你盃","short":"花園","duration":62.0,"bg":"#F7C9DB"},
	{"id":"rainbow","name":"🌈 彩虹冠軍盃","short":"彩虹","duration":68.0,"bg":"#B4D8FC"}
]

static func track_for(id: String) -> Dictionary:
	for track in TRACKS:
		if str(track["id"]) == id:
			return track
	return TRACKS[0]

static func candidates(animals: Array, _resident_ids: Array, collected_ids: Array) -> Array:
	# Every collected species is playable, independently of the 16-resident
	# Private Farm limit. This includes ocean creatures and ground insects.
	# Private Farm membership never restricts racing or grants a locked racer.
	var unlocked: Dictionary = {}
	for id in collected_ids:
		unlocked[str(id)] = true
	var found: Array = []
	for animal in animals:
		var id: String = str(animal.get("id",""))
		if unlocked.has(id):
			found.append(animal)
	# A brand new child with an empty album can still learn the controls
	# using the existing starter cow, without changing collection progress.
	if found.is_empty() and collected_ids.is_empty():
		for animal in animals:
			if str(animal.get("id",""))=="cow":
				found.append(animal)
				break
	return found

static func opponents(animals: Array, chosen: String, count: int = 3) -> Array:
	var pool: Array = []
	for animal in animals:
		if str(animal.get("id","")) != chosen:
			pool.append(animal)
	var result: Array = []
	while result.size() < count and not pool.is_empty():
		var index: int = (result.size() * 3 + chosen.length()) % pool.size()
		result.append(pool.pop_at(index))
	return result

static func stars_awarded(place: int, collected_stars: int) -> int:
	return maxi(1, 5 - clampi(place,1,4)) + clampi(collected_stars,0,12)

static func rank(player_distance: float, opponent_distances: Array) -> int:
	var result: int = 1
	for other in opponent_distances:
		if float(other) > player_distance:
			result += 1
	return result

static func lane_after_swipe(lane: int, delta: float) -> int:
	if absf(delta) < 35.0:
		return lane
	return clampi(lane + (1 if delta > 0.0 else -1),0,2)
