class Item < Pokenarc


	def self.get_all
		@@narc_name = "items"
		super
	end


	def self.write_data data, batch=false
		@@narc_name = "items"
		@@upcases = []
		super
	end

	def self.get_showdown_names_from items
		names = items.map do |m|
			item_name = Trpok.item_titlize(m["name"])
		end
	end

	def self.expanded_fields
		col_1 = [[255, "item_type"], [255, "gain_values"], [255, "item_group"], [255, "battle_item_group"], [65535, "type_attribute"], [255, "name_order_id"], [1, "nature_gift_power"], [1, "battle_happiness"], [1, "ow_happiness"], [1, "hold_happiness"]]

		col_2 = [[255, "hp_atk_boost" ], [255, "def_spatk_boost"], [255, "spd_spdef_boost"], [255, "acc_crit_pp_boost"], [255, "hp_ev_gain"], [255, "atk_ev_gain"], [255, "def_ev_gain"], [255, "spd_ev_gain"], [255, "spatk_ev_gain"], [255, "spdef_ev_gain"], [255, "hp_gain"], [255, "pp_gain"]]

		col_3 = [[255, "battle_flags"], [255,"berry_flags"], [255,"held_flags"], [255,"usability_flag"], [255,"consumable_flag"], [255,"status_removal_flag"], [255,"unknown_flag_1"]]
		[col_1,col_2,col_3]
	end

	def self.locations
		loc_list = File.read("#{$rom_name}/texts/item_locations.txt").split("\n")
		locations = {}

		loc_list.each do |line|
			item_name = line.split("=>")[0].strip.downcase.gsub(" ", "")
			loc = line.split("=>")[1].strip

			locations[item_name] = loc
		end

		locations
	end


end



