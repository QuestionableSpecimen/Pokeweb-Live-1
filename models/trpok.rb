class Trpok < Pokenarc
	def self.get_all
		@@narc_name = "trpok"
		super
	end

	def self.get_all_mods

		@@narc_name = "trpok"
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
			
			pok["level_0"] || 0
	
		end

		collection = collection.filter do |n|
			
			n["ivs_0"] and n["ivs_0"] > 250
		end

		collection
	end

	def self.write_data data, batch=false
		@@narc_name = "trpok"
		@@upcases = ["species", "move"]
		p data
		super
	end

	def self.get_poks_for count, trainer_poks
		poks = []
		(0..100).each do |n|
			if trainer_poks["species_id_#{n}"]
				poks << trainer_poks["species_id_#{n}"].gsub(". ", "-").downcase
			end
		end
		poks
	end

	def self.fill_lvl_up_moves lvl, trainer, pok_index

		file_path = "#{$rom_name}/json/trpok/#{trainer}.json"
		trpok = JSON.parse(File.open(file_path, "r"){|f| f.read})

		pok_id = trpok["raw"]["species_id_#{pok_index}"]


		learnset_path = "#{$rom_name}/json/learnsets/#{pok_id}.json"
		learnset = JSON.parse(File.open(learnset_path, "r"){|f| f.read})

		moves = []

		(0..19).to_a.reverse.each do |n|
			lvl_learned = learnset["raw"]["lvl_learned_#{n}"]
			if lvl_learned && lvl_learned.to_i <= lvl.to_i
				moves << [learnset["raw"]["move_id_#{n}"],learnset["readable"]["move_id_#{n}"]]
			end
			if moves.length == 4
				break
			end
		end

		moves.each_with_index do |move, i|
			trpok["raw"]["move_#{i + 1}_#{pok_index}"] = move[0]
			trpok["readable"]["move_#{i + 1}_#{pok_index}"] = move[1]
		end

		File.open(file_path, "w") { |f| f.write trpok.to_json }
		
		moves.map {|m| m[1].name_titleize}

	end

	def self.create data
		file_name = data["file_name"]
		n = data["sub_index"]

		file_path = "#{$rom_name}/json/trpok/#{file_name}.json"
		json_data = JSON.parse(File.open(file_path, "r"){|f| f.read})


		new_readable_data = {"ivs_#{n}": 0, "ability_#{n}": 0, "level_#{n}": 0, "padding_#{n}": 0, "species_id_#{n}": "-", "form_#{n}": 0, "gender_#{n}": "Default"}

		json_data["readable"] = json_data["readable"].merge(new_readable_data)
		json_data["readable"]["count"] += 1

		File.open(file_path, "w") { |f| f.write json_data.to_json }

		json_data
	end

	def self.delete data
		file_name = data["file_name"]
		n = data["sub_index"]

		file_path = "#{$rom_name}/json/trpok/#{file_name}.json"
		json_data = JSON.parse(File.open(file_path, "r"){|f| f.read})

		#remove current pokemon
		json_data["readable"].each do |field, value|
			if field.split("_")[-1] == "#{n}"
				json_data["readable"].delete field
			end
		end

		#move everything above it down a slot
		json_clone = json_data["readable"].clone
		json_clone.each do |field, value|
			n = n.to_i
			((n+1)..(json_clone["count"] - 1)).each do |i|

				if field[-1] == i.to_s
					json_data["readable"].delete field 
					field_clone = field.dup
					field_clone[-1] = (i-1).to_s
					json_data["readable"][field_clone] = value
				end
			end
		end


		
		json_data["readable"]["count"] -= 1
		File.open(file_path, "w") { |f| f.write json_data.to_json }

		trdata_path = "#{$rom_name}/json/trdata/#{file_name}.json"
		tr_data = JSON.parse(File.open(trdata_path, "r"){|f| f.read})
		tr_data["readable"]["num_pokemon"] = json_data["readable"]["count"]
		tr_data["raw"]["num_pokemon"] = json_data["readable"]["count"]
		File.open(trdata_path, "w") { |f| f.write tr_data.to_json }
	end


	def self.get_nature_info_for(file_name, sub_index, desired_iv=255)
		p "getting info"
		file_path = "#{$rom_name}/json/trpok/#{file_name}.json"
		trpok = JSON.parse(File.open(file_path, "r"){|f| f.read})
		ability_slot = trpok["readable"]["ability_#{sub_index}"]
		trpok = trpok["raw"]

		file_path = "#{$rom_name}/json/trdata/#{file_name}.json"
		trdata = JSON.parse(File.open(file_path, "r"){|f| f.read})["raw"]


		pok_id = trpok["species_id_#{sub_index}"]


		file_path = "#{$rom_name}/json/personal/#{pok_id}.json"
		personal = JSON.parse(File.open(file_path, "r"){|f| f.read})["readable"]

		pok_name = personal["name"].name_titleize

		trainer_id = file_name.to_i
		trainer_class = trdata["class"]
		pok_id = pok_id
		pok_iv = trpok["ivs_#{sub_index}"]
		pok_lvl = trpok["level_#{sub_index}"]
		ability_gender = trpok["ability_#{sub_index}"]
		personal_gender = personal["gender"]
		ability_slot = ability_slot


		natures = RomInfo.natures

		nature_info = [[],[], "Trainer #{trainer_id}'s #{pok_name}", nil, [], []]

		255.downto(0).each do |n|
			pid = get_pid(trainer_id, trainer_class, pok_id, n, pok_lvl, ability_gender, personal_gender, false, ability_slot)

			nature_info[0] << "♀: #{n} IVs: #{convert_pid_to_nature(pid, natures)}"
			nature_info[4] << pid
			# nature_info[0] << "♀: #{convert_pid_to_nature(pid, natures)}"
		end

		255.downto(0).each do |n|
			pid = get_pid(trainer_id, trainer_class, pok_id, n, pok_lvl, ability_gender, personal_gender, true, ability_slot)

			nature_info[1] << "♂: #{n} IVs: #{convert_pid_to_nature(pid, natures)}"
			nature_info[5] << pid
			# nature_info[1] << "♂: #{convert_pid_to_nature(pid, natures)}"
		end

		nature_info[3] = trpok["ivs_#{sub_index}"]
		nature_info
	end

	def self.get_nature_for(file_name, sub_index, desired_iv=255)
		file_path = "#{$rom_name}/json/trpok/#{file_name}.json"
		trpok = JSON.parse(File.open(file_path, "r"){|f| f.read})
		ability_slot = trpok["readable"]["ability_#{sub_index}"]
		trpok = trpok["raw"]

		file_path = "#{$rom_name}/json/trdata/#{file_name}.json"
		trdata = JSON.parse(File.open(file_path, "r"){|f| f.read})["raw"]


		pok_id = trpok["species_id_#{sub_index}"]

		file_path = "#{$rom_name}/json/personal/#{pok_id}.json"
		personal = JSON.parse(File.open(file_path, "r"){|f| f.read})["readable"]

		pok_name = personal["name"].name_titleize

		trainer_id = file_name.to_i
		trainer_class = trdata["class"]
		pok_id = pok_id
		pok_iv = trpok["ivs_#{sub_index}"]
		pok_lvl = trpok["level_#{sub_index}"]
		ability_gender = trpok["ability_#{sub_index}"]
		personal_gender = personal["gender"]
		ability_slot = ability_slot


		natures = RomInfo.natures

		n = 255
		pid = get_pid(trainer_id, trainer_class, pok_id, n, pok_lvl, ability_gender, personal_gender, false, ability_slot)

		convert_pid_to_nature(pid, natures)
		
	end

	def self.get_abilities_for tr_id

		file_path = "#{$rom_name}/json/trpok/#{tr_id}.json"
		raw = JSON.parse(File.open(file_path, "r"){|f| f.read})["raw"]
		poks = JSON.parse(File.open(file_path, "r"){|f| f.read})["readable"]


		poks_array = []

		(0..(poks["count"] - 1)).each do |i|			
			pok_id = raw["species_id_#{i}"]
			file_path = "#{$rom_name}/json/personal/#{pok_id}.json"
			personal = JSON.parse(File.open(file_path, "r"){|f| f.read})["readable"]

		
			ability_id = poks["ability_#{i}"]
			ability_id += 1 if ability_id < 1
			ability = personal["ability_#{ability_id}"]
			poks_array << ability
		end

		poks_array


		
	end







	def self.convert_pid_to_nature pid, natures
		nature = natures[(pid >> 8) % 25]
	end

	def self.get_pid(trainer_id, trainer_class, pok_id, pok_iv, pok_lvl, ability_gender, personal_gender, trainer_gender, ability_slot)

		seed = trainer_id + pok_id + pok_iv + pok_lvl

		trainer_class.times do 
			seed = seed * 0x5D588B656C078965 + 0x269EC3
		end

		pid = (((seed >> 32) & 0xFFFFFFFF) >> 16 << 8) + get_gender_ab(ability_gender, personal_gender, trainer_gender, ability_slot)
	end

	def self.get_gender_ab(ability_gender, personal_gender, trainer_gender, ability_slot)
		result = trainer_gender ? 120 : 136
		g = ability_gender & 0xF
		a = (ability_gender & 0xF0) >> 4

		if ability_gender != 0

			if g!= 0
				result = personal_gender
				if g == 1
					result += 2
				else
					result -= 2
				end
			end

			case ability_slot
			when 0
				result
			when 1
				result &= 0xFFFFFFFE
			else 
				result |= 1
			end
		end
		result
	end


	def self.export_all_showdown
		data = []
		sets = {}
		(0..849).each do |n|
			file_path = "#{$rom_name}/json/trpok/#{n}.json"
			raw = JSON.parse(File.open(file_path, "r"){|f| f.read})["raw"]


				data << export_showdown(n)

		end
		sets["data"] = data.flatten
		File.write("public/dist/sets.json", JSON.dump(sets))
		format_exports(sets)
	end


	def self.format_exports exports
		poks = exports["data"]
		formatted = {}
		#for each pokemon
		poks.each do |pok|
			species_name = ""
			set_name = ""
			set_data = ""

			
			pok.each do |species, sets|
				
		

				species_name = species
				sets.each do |set|
					set_name = set[0]
					set_data = pok[species_name][set_name]
	
				end
			end

			if formatted[species_name]
				while formatted[species_name][set_name] do 
					set_name += "*"
				end
			else
				formatted[species_name] = {}
			end

			formatted[species_name][set_name] = set_data
		end


		open("public/dist/js/data/sets/gen5.js", "w") do |f| 
			f.puts "var SETDEX_BW ="
			f.puts JSON.dump(formatted)
		end


	  # text = File.read("public/dist/js/data/sets/gen9.js")
	  # new_contents = text.gsub("=>", ":")
	  # File.open("public/dist/js/data/sets/gen9.js", "w") {|file| file.puts new_contents }

	end


# sets = {}
#         // import sets
#         $.getJSON("sets.json", function(json) {
#             poks = json["data"]
        
#             // for every pokemon
#             for (let i = 0; i < poks.length; i++ ) {
                
#                 var name
#                 var setName
#                 var setData

#                 //get species name
#                 for (species in poks[i]) {
#                     name = species

#                     // get setname
#                     for (sname in poks[i][species]) {
#                         setName = sname
#                         setData = poks[i][species][setName]
#                     }
#                 }
#                 // if pokemon exists
#                 if (sets[name]) {
#                     while (sets[name][setName]) {
#                         setName = setName += "*"
#                     }
#                 } else {
#                     sets[name] = {}
#                 }

#                 sets[name][setName] = setData            
#             }
#         });


	def self.export_showdown tr_id

		file_path = "#{$rom_name}/json/trpok/#{tr_id}.json"
		raw = JSON.parse(File.open(file_path, "r"){|f| f.read})["raw"]
		poks = JSON.parse(File.open(file_path, "r"){|f| f.read})["readable"]



		poks_array = []

		(0..(poks["count"] - 1)).each do |i|
			
			species = poks["species_id_#{i}"].downcase.titleize
			
			level = poks["level_#{i}"]
			tr_name = "Lvl #{level}"
			
			pok_id = raw["species_id_#{i}"]
			file_path = "#{$rom_name}/json/personal/#{pok_id}.json"
			personal = JSON.parse(File.open(file_path, "r"){|f| f.read})["readable"]
			
			form = poks["form_#{i}"]

			

			ability_id = poks["ability_#{i}"]

			ability_id += 1 if ability_id < 1
			ability = personal["ability_#{ability_id}"]

			item = poks["item_id_#{i}"]

			nature = get_nature_for(tr_id, i)

			moves = []
			(1..4).each do |n|
				moves << sub_showdown(poks["move_#{n}_#{i}"].move_titleize)
			end

			pok = {}

			pok[species] = {}

			pok[species][tr_name] =  {}

			pok[species][tr_name]["level"] = level
			pok[species][tr_name]["item"] = item.titleize
			pok[species][tr_name]["nature"] = nature
			pok[species][tr_name]["moves"] = moves
			pok[species][tr_name]["ability"] = ability.titleize
			pok[species][tr_name]["form"] = form
			pok[species][tr_name]["evs"] = {"df" => 0}

			poks_array << pok





		end

		poks_array


		
	end

	def self.showdown_subs
		{
		    "Bubblebeam": "Bubble Beam",
		    "Doubleslap": "Double Slap",
		    "Solarbeam": "Solar Beam",
		    "Sonicboom": "Sonic Boom",
		    "Poisonpowder": "Poison Powder",
		    "Thunderpunch": "Thunder Punch",
		    "Thundershock": "Thunder Shock",
		    "Ancientpower": "Ancient Power",
		    "Extremespeed": "Extreme Speed",
		    "Dragonbreath": "Dragon Breath",
		    "Dynamicpunch": "Dynamic Punch",
		    "Grasswhistle": "Grass Whistle",
		    "Featherdance": "Feather Dance",
		    "Faint Attack": "Feint Attack",
		    "Smellingsalt": "Smelling Salts",
		    "Roar Of Time": "Roar of Time",
		    "U-Turn": "U-turn",
		    "V-Create": "V-create",
		    "Sand-Attack": "Sand Attack",
		    "Selfdestruct": "Self-Destruct",
		    "Softboiled": "Soft-Boiled",
		    "Vicegrip": "Vise Grip",
		    "Hi Jump Kick": "High Jump Kick"
		}
	end

	def self.sub_showdown(move)
		subs = showdown_subs
		if showdown_subs[move.to_sym]
			return showdown_subs[move.to_sym]
		else
			return move
		end
	end
end


# "Abomasnow":{"UU Barack Aboma (Swords Dance)":{"level":100,"ability":"Soundproof","item":"Abomasite","nature":"Adamant","evs":{"hp":76,"at":252,"sp":180},"moves":["Swords Dance","Wood Hammer","Ice Shard","Earthquake"]}



