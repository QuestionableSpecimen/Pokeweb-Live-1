class Trdata < Pokenarc


	def self.write_data data, batch=false
		@@narc_name = "trdata"
		@@upcases = []
		if data["field"][0..3] == "text"
			return update_text(data)
		end
		super
	end

	def self.items trdata
		items = []
		(1..4).each do |n|
			if trdata["item_#{n}"] != "None"
				items << trdata["item_#{n}"]
			end
		end
		if items.length > 0
			"Items: #{items.length}x #{items[0]}"
		else
			nil
		end
	end

	def self.batch_set_flag flag, value=1
		trainer_count = get_all.length
		data = {"field" => flag, "int" => true, "narc" => "trdata", "value" => value}

		(0..trainer_count - 1).each do |tr|
			data["file_name"] = tr.to_s
			write_data data
		end
		`python python/trdata_writer.py update #{(0..trainer_count - 1).to_a.join(",")} #{$rom_name}`
	end

	def self.update_names
		tr_names = File.read("#{$rom_name}/texts/tr_names.txt").split("\n")
		tr_classes = File.read("#{$rom_name}/texts/tr_classes.txt").split("\n")

		(0..1066).each do |n|
			file_path = "#{$rom_name}/json/trdata/#{n}.json"
			json_data = JSON.parse(File.open(file_path, "r") {|f| f.read})

			json_data["readable"]["name"] = tr_names[n]
			json_data["readable"]["class"] = tr_classes[json_data["raw"]["class"]]

			File.open(file_path, "w") { |f| f.write json_data.to_json }

			p n
		end
	end

	def self.sprite tr_name, tr_class, tr_class_id, g_table
		tr_class = tr_class.downcase.gsub(" ", "").gsub("_m", "").gsub("♂","").gsub("♀", "f").gsub("é","e").gsub("[pk][mn]", "pkmn_")
		tr_name = tr_name.downcase


		
		sprite_name = ""
		
		# return the name of the trainer if it has a unique sprite
		if File.exist?("./public/images/trainer_sprites/#{tr_name.gsub("boy", "silver")}.png") && tr_name != "grunt"
			sprite_name = "trainer_sprites/#{tr_name.gsub("boy", "silver")}.png"
			return sprite_name
		end


		if tr_class_id == 89 && $gen == 4
			return "trainer_sprites/galactic_f.png"
		end

		if tr_class[-2] == "_"
			sprite_name = "trainer_sprites/#{tr_class.gsub("pkmn", "pokemon")}.png"
		elsif g_table[tr_class_id.to_i] == "female" && File.exist?("./public/images/trainer_sprites/#{tr_class}_f.png")	
			sprite_name = "trainer_sprites/#{tr_class.gsub("pkmn", "pokemon")}_f.png"
		else
			sprite_name = "trainer_sprites/#{tr_class.gsub("pkmn", "pokemon")}.png"
		end
	
		if $gen == 4 && File.exist?("./public/images/#{sprite_name.gsub(".png", "-gen4.png")}")
			sprite_name = sprite_name.gsub(".png", "-gen4.png")
			if g_table[tr_class_id.to_i] == "female" && File.exist?("trainer_sprites/#{tr_class.gsub("pkmn", "pokemon")}_f-gen4.png")
				sprite_name = "trainer_sprites/#{tr_class.gsub("pkmn", "pokemon")}_f-gen4.png"
			end
		end

		sprite_name
	end

	def self.gender_table
		genders = File.open("Reference_Files/trainer_genders.txt", "r").readlines
		
		if $gen == 4 
			genders = File.open("texts/#{SessionSettings.base_rom}_genders.txt", "r").readlines
		end

		genders.map do |line|
			gender = nil
			if line[-2] == "1"
				gender = "female"
			else
				gender = "not female"
			end
			gender
		end
	end

	def self.get_all 
		@@narc_name = "trdata"
		super
	end

	def self.get_data file_name
		@@narc_name = "trdata"
		super
	end


	def self.reset file_name, to_copy=0
		tr = get_data("#{$rom_name}/json/trdata/#{file_name}.json")
		tr_name = tr["name"]
		tr_class = tr["class_id"]
		`cp #{$rom_name}/json/trdata/#{to_copy}.json #{$rom_name}/json/trdata/#{file_name}.json`
		`cp #{$rom_name}/json/trpok/#{to_copy}.json #{$rom_name}/json/trpok/#{file_name}.json`
		write_data({"field" => "name", "value" => tr_name, "file_name" => file_name})
	end


	def self.text_types 
		texts = {}
		texts[0] = "Pre Bttl"
		texts[1] = "Bttl - After Loss"
		texts[2] = "Fld - After Loss"
		texts[3] = "Pre Bttl Dbls 1"
		texts[5] = "Fld - After Loss Dbls 1"
		texts[6] = "Reject Dbls 1"
		texts[7] = "Pre Bttl Dbls 2"
		texts[9] = "Fld - After Loss Dbls 2"
		texts[10] = "Reject Dbls 2"
		texts[13] = "Before Heal"
		texts[14] = "After Heal"
		texts[15] = "After Bttl Item"
		texts[16] = "More Item"
		texts[17] = "After 1st Hit (Non KO)"
		texts[19] = "Last Pok"
		texts[20] = "Last Pok Less than 1/2 HP"
		texts[24] = "Reject Triple"
		texts
	end

	def self.text_type_ids
		[0,1,2,3,5,6,7,9,10,13,14,15,16,17,19,20,24]
	end


	def self.get_texts file_name, offsets, text_table, text_bank
		return {} if !offsets[file_name]
		offset = offsets[file_name] / 4
		text_table = text_table[offset..-1]
		texts = {}

		text_table.each_with_index do |text, i|
			break if text_table[i][0] != file_name
			texts[text_table[i][1]] = text_bank[offset + i]
		end
		texts
	end

	def self.update_text data
		offset_path = "#{$rom_name}/texts/trtexts_offsets.json"
		text_table_path = "#{$rom_name}/texts/trtexts.json"
		offsets = JSON.parse(File.open(offset_path, "r"){|f| f.read})
		text_table = JSON.parse(File.open(text_table_path, "r"){|f| f.read})

		text_type = data["field"].split("_")[1].to_i
		idx = data["field"].split("_")[-1].to_i
		tr_id = data["file_name"].to_i
		bank = Text.get_bank "message_texts", 381
		has_text = get_texts(tr_id, offsets, text_table, bank)[text_type]
		

		
		# if field is not empty
		if data["value"] != ""
			p has_text
			# add text if it doesn't already exist otherwise update it
			if !has_text

				# update a/0/8/9 text table
				text_table.insert(idx, [tr_id, text_type])
				
				# update a/0/9/0 offset table
				current_offset = offsets[tr_id]
				offsets.each_with_index do |offset, i|
					if offset > current_offset
						offsets[i] += 4
					end
				end

				File.open(offset_path, "w") { |f| f.write offsets.to_json }
				File.open(text_table_path, "w") { |f| f.write text_table.to_json }


				# update text bank
				Text.insert_text idx, data["value"]
			else
				p "updateing"
				bank[idx][1] = data["value"]
				banks = Text.get_all("message_texts")
				banks[381] = bank

				File.open("#{$rom_name}/message_texts/texts.json", "w") { |f| f.write banks.to_json }
			end
		else	

			# Delete text if value is empty
			if has_text
				
				# remove entry from text table
				text_table.delete_at(idx)

				# update all offsets
				current_offset = offsets[tr_id]
				offsets.each_with_index do |offset, i|
					if offset > current_offset
						offsets[i] -= 4
					end
				end
				File.open(offset_path, "w") { |f| f.write offsets.to_json }
				File.open(text_table_path, "w") { |f| f.write text_table.to_json }
				
				Text.delete_text idx

				# if not empty, increment everything >= current idx
				# if empty deincrement everything if initial value wasn't empty
				# else don't do anything

			else
				p "Already Empty"
				return 
			end
		end
	end


	def self.get_all_mods
		@@narc_name = "trdata"
		collection = []
		files = Dir["#{$rom_name}/json/#{@@narc_name}/*.json"]
		file_count = files.length

		(0..file_count - 1).each do |n|
			
			file = File.open("#{$rom_name}/json/#{@@narc_name}/#{n}.json", "r:ISO8859-1") {|f| f.read }
			json = JSON.parse(file)
			entry = json["readable"]
			entry["id"] = n
			collection[n] = entry
		end
		
		
		
		collection.sort_by! do  |pok|
			
			
			file_path = "#{$rom_name}/json/trpok/#{pok['id']}.json"
			raw = JSON.parse(File.open(file_path, "r"){|f| f.read})["raw"]
			raw["level_0"] || 0
		


		end

		collection = collection.filter do |n|
			file_path = "#{$rom_name}/json/trpok/#{n['id']}.json"
			raw = JSON.parse(File.open(file_path, "r"){|f| f.read})["raw"]
			raw["ivs_0"] and raw["ivs_0"] > 250
		end

		collection
	end



	def self.names
		if SessionSettings.base_rom == "BW"
			file_name = "#{$rom_name}/message_texts/texts.json"
			names = JSON.parse(File.open(file_name, "r"){|f| f.read})[190]

			# File.open('Reference_Files/trainer_names.txt', "r").read.split("\n")
		else
			file_name = "#{$rom_name}/message_texts/texts.json"
			names = JSON.parse(File.open(file_name, "r"){|f| f.read})[382]
		end
	end

	def self.class_names
		File.open("#{$rom_name}/texts/tr_classes.txt", "r").read.split("\n")	
	end

	def self.sprite_name_for(trainer, names, i)
		sprite_name = trainer["class"].downcase.gsub(" ", "_").gsub("pkmn", "pokemon").gsub("__", "_")

		class_prefix = sprite_name.split("_")[0]
		if class_prefix == "leader" || class_prefix == "elite" || class_prefix == "champion" ||class_prefix == "subway"
			sprite_name = names[i]
		end

		"trainer_sprites/#{sprite_name}.png"
	end

	def self.ais
		["Prioritize Effectiveness",
		"Evaluate Attacks",
		"Expert",
		"Prioritize Status",
		"Risky Attacks",
		"Prioritize Damage",
		"Partner",
		"Double Battle",
		"Prioritize Healing",
		"Utilize Weather",
		"Harassment",
		"Roaming Pokemon",
		"Safari Zone",
		"Catching Demo"]
	end

	def self.has_items? trainer
		"checked" if trainer["has_items"] > 0
	end

	def self.has_moves? trainer
		"checked" if trainer["has_moves"] > 0
	end


	def self.export_showdown
		
	end

	def self.get_locations
		overworlds = Overworld.get_all

		tr_count = files = Dir["#{$rom_name}/json/trdata/*.json"]
		file_count = files.length


	

		overworlds.each_with_index do |overworld, i|
			npc_count = overworld["npc_count"]

			(0..npc_count-1).each do |n|
				script_id = overworld["npc_#{n}_script_id"]
				if (script_id > 3000 and script_id < (3000 + file_count)) or (script_id > 5000 and script_id < (5000 + file_count))

					file_path = "#{$rom_name}/json/trdata/#{script_id % 1000}.json"
					json_data = JSON.parse(File.open(file_path, "r") {|f| f.read})

					location = Header.find_location_by_map_id(i)
					json_data["readable"]["location"] = location
					File.open(file_path, "w") { |f| f.write json_data.to_json }
				end
			end
		end
	end


end

