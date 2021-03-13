
# THIS FILE CONTAINS METHODS USED BY THE FRONTEND ERB

class String
  def titleize
  	if !self 
  		return "-"
  	end
    gsub("-", " ").split(/([ _-])/).map(&:capitalize).join
  end

  def squish!
    gsub!("\n", '')
    self
  end
end

class NilClass
	def titleize
		"-"
	end

	def downcase
		"-"
	end
end

# adds addtional move data to learnset data
def expand_learnset_data(moves, learnset)
	move_data = []

	(0..19).each do |move|
		if learnset["move_id_#{move}_index"]
			
			ls_data = {"move_name" => learnset["move_id_#{move}"], "lvl_learned" => learnset["lvl_learned_#{move}"], "move_id" => learnset["move_id_#{move}_index"], "index" => move }
			# all data for this specific move
			# p ls_data
			all_move_data = moves[ls_data["move_id"]]
			# copy these fields to be presented
			["type", "category", "power", "accuracy"].each do |field|
				ls_data[field] = all_move_data[field]
			end
			move_data << ls_data
		else
			move_data << {"index" => move }
		end
	end

	# sort by lvl learned, and break ties move index
	move_data.sort_by do |n| 
		if n["lvl_learned"]
			n["lvl_learned"].to_i + n["index"].to_i
		else
			101 + n["index"].to_i
		end
	end
end



def to_gen(pok_id)
	case pok_id
	when 0..151
	  gen = "gen1"
	when 152..251
	  gen = "gen2"
	when 252..386
	  gen = "gen3"
	when 387..493
	  gen = "gen4"
	when 494..649
	  gen = "gen5"
	when 650..721
	  gen = "gen6"
	when 722..809
	  gen = "gen7"
	when 810..898
	  gen = "gen8"
	else
	  gen = ""
	end
	gen
end


def img(name, classes="", data=["", ""])
"<img src='/images/#{name}' alt='#{name}' class='#{classes}' data-#{data[0]}='#{data[1]}' />"
end

def svg(name, classes="", data=["", ""], html="")
	div_start = "<div class='#{classes}' data-#{data[0]}='#{data[1]}'>"
	div_end = "</div>"
	svg = erb(name.to_sym, :layout => false, :locals => { :classes => classes, :data => data })

	div_start + html + svg + div_end
end