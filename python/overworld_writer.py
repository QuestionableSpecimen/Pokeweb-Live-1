import ndspy
import ndspy.rom
import ndspy.narc
import code 
import io
import os
import json
import copy
import sys


# code.interact(local=dict(globals(), **locals()))

######################### CONSTANTS #############################
def set_global_vars(rom_name):
	global MAP_NARC_ID, ROM_NAME, NARC_FORMAT, MOVEMENTS, HEADER_FORMAT, FURNITURE_FORMAT, NPC_FORMAT, WARP_FORMAT, TRIGGER_FORMAT, DIRECTIONS, NARC_FILE_ID
	
	with open(f'{rom_name}/session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']
		NARC_FILE_ID = settings["overworlds"]
		MAP_NARC_ID = settings["maps"]

	MOVEMENTS = open(f'Reference_Files/movements.txt', mode="r").read().splitlines()

	DIRECTIONS = ['Up', 'Down', 'Left', 'Right' ]

	NARC_FORMAT = {}

	HEADER_FORMAT = [[4, 'file_length'],
	[1, 'furniture_count'],
	[1, 'npc_count'],
	[1, 'warp_count'],
	[1, 'trigger_count']]

	FURNITURE_FORMAT = [[2, 'script_id'],
	[2, 'unknown_1' ],
	[2, 'unknown_2'],
	[2, 'unknown_3'],
	[2, 'x_cord'],
	[2, 'x_cord_padding'],
	[2, 'y_cord'],
	[2, 'y_cord_padding'],
	[4, 'z_cord']]

	NPC_FORMAT = [[2, 'overworld_id'],
	[2, 'overworld_sprite'],
	[2, 'movement_permissions'],
	[2, 'movement_permissions_2'],
	[2, 'overworld_flag'],
	[2, 'script_id'],
	[2, 'direction'],
	[2, 'sight'],
	[2, 'unknown_1'],
	[2, 'unknown_2'],
	[2, 'horizontal_leash'],
	[2, 'vertical_leash'],
	[2, 'unknown_3'],
	[2, 'unknown_4'],
	[2, 'x_cord'],
	[2, 'y_cord'],
	[2, 'unknown_5'],
	[2, 'z_cord']]

	WARP_FORMAT = [[2, 'map_id'],
	[2, 'use_warp_cords'],
	[1, 'contact_direction'],
	[1, 'transition_type'],
	[4, 'exit_x'],
	# [2, 'exit_x_padding'],
	[4, 'exit_y'],
	# [2, 'exit_y_padding'],
	[2, 'x_extension'],
	[2, 'y_extension'],
	[2, 'directionality']]

	TRIGGER_FORMAT = [[2, 'entity_id'],
	[2, 'to_trigger_value'],
	[2, 'to_check_value'],
	[2, 'unknown_1'],
	[2, 'unknown_2'],
	[2, 'x_cord'],
	[2, 'y_cord'],
	[2, 'z_cord'],
	[2, 'unknown_3'],
	[2, 'unknown_4'],
	[2, 'unknown_5']]

	NARC_FORMAT["furniture"] = FURNITURE_FORMAT
	NARC_FORMAT["npc"] = NPC_FORMAT
	NARC_FORMAT["warp"] = WARP_FORMAT
	NARC_FORMAT["trigger"] = TRIGGER_FORMAT

#################################################################


def output_narc(rom, rom_name):
	set_global_vars(rom_name)
	json_files = os.listdir(f'{rom_name}/json/overworlds')
	
	# ndspy copy of narcfile to edit
	narc = ndspy.narc.NARC(rom.files[NARC_FILE_ID])
	narc.endiannessOfBeginning = ">"

	for f in json_files:
		file_name = int(f.split(".")[0])
		write_narc_data(file_name, NARC_FORMAT, narc, "overworlds", rom_name)

	rom.files[NARC_FILE_ID] = narc.save()


	####### maps ##########
	json_files = os.listdir(f'{rom_name}/json/maps')
	narc = ndspy.narc.NARC(rom.files[MAP_NARC_ID])
	narc.endiannessOfBeginning = ">"


	for f in json_files:
		file_name = int(f.split(".")[0])
		write_map_narc_data(file_name, narc, "maps", rom_name)


	# create custom name table
	narc.filenames = ndspy.fnt.Folder(files=[f"file_{i}" for i in range(len(narc.files))])

	rom.files[MAP_NARC_ID] = narc.save()

	
	return rom


def write_map_narc_data(file_name, narc, narc_name, rom_name):
	file_path = f'{rom_name}/json/{narc_name}/{file_name}.json'

	with open(file_path, "r", encoding='ISO8859-1') as outfile:  	
		json_data = json.load(outfile)	
		

		if "edited" in json_data:
			print(f"edited {file_name}")

			# get start of map data
			stream = io.BytesIO(narc.files[file_name])
			stream.seek(8)
			offset = read_bytes(stream, 4)
			stream.seek(offset)
			
			# get height and width
			width = read_bytes(stream, 2)
			height = read_bytes(stream, 2)
		
			# only write flags and movements
			for idx, n in enumerate(range(0, width * height)):
				for m in range(0,4):		
					if m == 2 or m == 3:
						tile_val = json_data[f'layer_{m}'][idx]
						stream.write(int(tile_val).to_bytes(2, 'little'))
					else:
						stream.seek(stream.tell() + 2)

			# code.interact(local=dict(globals(), **locals()))

			stream.seek(0)
			narc.files[file_name] = stream.read()


def write_narc_data(file_name, narc_format, narc, narc_name, rom_name):
	file_path = f'{rom_name}/json/{narc_name}/{file_name}.json'
	narcfile_path = f'{rom_name}/narcs/{narc_name}-{NARC_FILE_ID}.narc'

	stream = bytearray() # bytearray because is mutable

	with open(file_path, "r", encoding='ISO8859-1') as outfile:  	
		json_data = json.load(outfile)	

		
		for entry in HEADER_FORMAT: 
			if entry[1] in json_data["raw"]:
				data = json_data["raw"][entry[1]]
				write_bytes(stream, entry[0], data)

		for overworld in ['furniture', 'npc', 'warp', 'trigger']:
			n = 0
			m = 0

			while n < json_data['raw'][f'{overworld}_count']:
				
				# if entity has been deleted
				if f'{overworld}_{m}_{ NARC_FORMAT[overworld][0][1]}' not in json_data["raw"]:
					m += 1
					if f'{overworld}_{m}_{ NARC_FORMAT[overworld][0][1]}' not in json_data["raw"]:
						m += 1
					if f'{overworld}_{m}_{ NARC_FORMAT[overworld][0][1]}' not in json_data["raw"]:
						m += 1
					if f'{overworld}_{m}_{ NARC_FORMAT[overworld][0][1]}' not in json_data["raw"]:
						m += 1
					if f'{overworld}_{m}_{ NARC_FORMAT[overworld][0][1]}' not in json_data["raw"]:
						m += 1
					if f'{overworld}_{m}_{ NARC_FORMAT[overworld][0][1]}' not in json_data["raw"]:
						m += 1
					if f'{overworld}_{m}_{ NARC_FORMAT[overworld][0][1]}' not in json_data["raw"]:
						m += 1
				else:
					found = True

				for entry in NARC_FORMAT[overworld]:
					data = json_data["raw"][f'{overworld}_{m}_{entry[1]}']
					write_bytes(stream, entry[0], data)

				m += 1
				if found:
					n += 1

		write_bytes(stream, json_data["raw"]["footer_length"], json_data["raw"]["footer"])



	if file_name >= len(narc.files):
		# narc_entry_data = bytearray()
		# narc_entry_data[0:len(stream)] = stream
		narc.files.append(stream)
	else:
		# narc_entry_data = bytearray(narc.files[file_name])
		# narc_entry_data[0:len(stream)] = stream
		narc.files[file_name] = stream
	

def write_bytes(stream, n, data):
	stream += (int(data).to_bytes(n, 'little'))		
	return stream

def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')

################ If run with arguments #############
