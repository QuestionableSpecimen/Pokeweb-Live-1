import ndspy
import ndspy.rom
import ndspy.narc
import code 
import copy
import sys
import rom_data
import tools
import json

# code.interact(local=dict(globals(), **locals()))

def output_narc(rom, rom_name):
	
	with open(f'{rom_name}/session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings["rom_name"]

		for ani in ["move_animations", "battle_animations"]:
			narc_id = settings[ani]
			narcfile_path = f'{rom_name}/narcs/{ani}-{narc_id}.narc'
			rom.files[narc_id] = ndspy.narc.NARC.fromFile(narcfile_path).save()
			print(len(ndspy.narc.NARC.fromFile(narcfile_path).files))
			print("length")


	return tools.output_narc("moves", rom, rom_name)

def write_readable_to_raw(file_name, narc_name="moves", skip_ani=False):
	tools.write_readable_to_raw(file_name, narc_name, to_raw)


def to_raw(readable):
	raw = copy.deepcopy(readable)


	raw["type"] = rom_data.TYPES.index(readable["type"].lower().capitalize())

	raw["effect_category"] = rom_data.EFFECT_CATEGORIES.index(readable["effect_category"])
	
	raw["category"] = rom_data.CATEGORIES.index(readable["category"].lower().capitalize())

	#special case for tri attack
	if readable["result_effect"] == "Chance of either Paralyzing; Burning; or Freezing target":
		raw["result_effect"] = 65535
	else:
	
		raw["result_effect"] = rom_data.RESULT_EFFECTS.index(raw["result_effect"].lower().capitalize())

	# code.interact(local=dict(globals(), **locals()))
	raw["effect"] = rom_data.EFFECTS.index(raw["effect"])

	raw["status"] = rom_data.STATUSES.index(raw["status"])

	if readable["recoil"] > 0:
		raw["recoil"] = 256 - readable["recoil"]

	raw["target"] = rom_data.TARGETS.index(raw["target"])

	raw["stat_1"] = rom_data.STATS.index(readable["stat_1"])
	raw["stat_2"] = rom_data.STATS.index(readable["stat_2"])
	raw["stat_3"] = rom_data.STATS.index(readable["stat_3"])

	if readable["magnitude_1"] < 0:
		raw["magnitude_1"] = readable["magnitude_1"] + 256

	if readable["magnitude_2"] < 0:
		raw["magnitude_2"] = readable["magnitude_2"] + 256

	if readable["magnitude_3"] < 0:
		raw["magnitude_3"] = readable["magnitude_3"] + 256

	binary_hits = ""
	hits = ["max_hits", "min_hits"]
	for hit in hits:
		binary_hits += bin(readable[hit])[2:].zfill(4)
	raw["hits"] = int(binary_hits, 2)

	binary_props = ""
	rom_data.PROPERTIES.reverse()

	
	for prop in rom_data.PROPERTIES:
		binary_props += bin(readable[prop])[2:].zfill(1)
	raw["properties"] = int(binary_props, 2)

	# set animation
	animations_file_path = f'{rom_data.ROM_NAME}/narcs/move_animations-{rom_data.ANIMATION_ID}.narc'
	b_animations_file_path = f'{rom_data.ROM_NAME}/narcs/battle_animations-{rom_data.B_ANIMATION_ID}.narc'

	# for non expanded moves
	if readable["animation"] != 0:

		if readable["index"] < 673:
			animations = ndspy.narc.NARC.fromFile(animations_file_path)
			animations.files[readable["index"]] = animations.files[readable["animation"]]
			# code.interact(local=dict(globals(), **locals()))
			with open(animations_file_path, 'wb') as f:
				f.write(animations.save())
		else: # for expanded moves
			animations = ndspy.narc.NARC.fromFile(animations_file_path)
			b_animations = ndspy.narc.NARC.fromFile(b_animations_file_path)
			# code.interact(local=dict(globals(), **locals()))
			if rom_data.BASE_ROM == "BW2":
				offset = 561
			else:
				offset = 561
			try:
				b_animations.files[readable["index"] - offset] = animations.files[readable["animation"]]
				print(readable["animation"])
			except:
				print("animation out of bounds")
				b_animations.files[readable["index"] - offset] = animations.files[1]
			
			print(len(b_animations.files))
			with open(b_animations_file_path, 'wb') as f:
				f.write(b_animations.save())



	return raw
	
################ If run with arguments #############

if len(sys.argv) > 2 and sys.argv[1] == "update":
	rom_data.set_global_vars(sys.argv[3])
	file_names = sys.argv[2].split(",")
	 
	for file_name in file_names:
		write_readable_to_raw(int(file_name))
	

