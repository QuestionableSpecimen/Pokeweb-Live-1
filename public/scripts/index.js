$( document ).ready(function() {
    

///////////////////// EVENT BINDINGS //////////////////////////
    
    //////////////// Rom Buttons //////////////////
    
    $(document).on('click', '#load-rom', function(){
        var rom_name = $('#rom-select').val()
        $(this).text('loading...')
        $.post( "extract?rom_name=" + rom_name , {rom_name: rom_name }, function( data ) {
          window.location.href = data["url"]
        });
    })

    $(document).on('click', '#save-rom', function(){
    	btn = $(this)
    	btn.text('Exporting...')
        
        $.post( "/rom/save", function( data ) {
        	alert("saved to /exports folder")
        	btn.text('Export')
        });
    })


    //////////////// Filters ////////////////////////


    $('.small-filters button').on('click', function(){
    	$(this).toggleClass('-active')
    	filter()
    })
    $('#search-text-btn').on('click', function(){	
    	filter()
    })
    $('#search-text').on('keypress',function(e) {
	    if(e.which == 13) {
	        filter()
	    }
	});
	///////////////////////////////////////////////////////////////////////


	////////////////////// POKEMON PERSONAL CARD UI ////////////////////////
	
	// delay to bind to replaced svgs


	$(document).on('click', '.expand-action', function(){
		expanded_card = $(this).attr('data-expand')
		var card = $(this).parents('.filterable')
		// console.log($(this).parents('.filterable').find('.expanded-card-content'))
		// if hiding tab
		if (card.find('.expanded-' + expanded_card + ":visible").length > 0) {
			card.find('.expanded-card-content').removeClass('show-flex')
			$(this).removeClass('-active')
			card.find('.expanded-tab-icons').removeClass('show-flex')
		} else { // else switching tabs
			card.find('.expanded-card-content').removeClass('show-flex')
			
			card.find('.expanded-tab-icons').addClass('show-flex')
			card.find('.expanded-' + expanded_card).first().addClass('show-flex');
			card.find('.expanded-tab-icon').removeClass('-active')
			card.find('.expanded-tab-icon').first().addClass('-active')

			card.find('.card-icon, .expand-action').removeClass('-active')
			$(this).addClass('-active')
		}
	})	

	$(document).on('click', '.expanded-tab-icon', function(){
		expanded_tab = $(this).attr('data-show')
		var card = $(this).parents('.filterable')
		var tab_group = '.expanded-' + card.find('.expand-action.-active').attr('data-expand')

		if (card.find('.expanded-' + expanded_tab + ":visible").length > 0) {
			// do nothing
		} else { // else switching tabs
			card.find('.expanded-card-content').removeClass('show-flex')
			
			card.find('.expanded-' + expanded_tab + tab_group).addClass('show-flex');
			card.find('.expanded-tab-icon').removeClass('-active')
			$(this).addClass('-active')
		}
	})	

	
	
	/////////////////////////////// DATA UPLOAD ON EDIT ///////////////////////////////


	$(document).on('focusout', "[contenteditable='true']", function(){
		var value = $(this).text().trim()
		$(this).text(value)
		var field_name = $(this).attr('data-field-name')
		var index = $(this).parents('.filterable').attr('data-index')
		var narc = $(this).attr('data-narc')

		var data = {}

		data["file_name"] = index
		data["field"] = field_name
		data["value"] = value
		data["narc"] = narc
		
		if ($(this).attr('data-type') && $(this).attr('data-type').includes("int")) {
			data["int"] = true
			max_value = parseInt($(this).attr('data-type').split("-")[1])
			
			//validate int value less than max if int field
			if ((!parseInt(value) || parseInt(value) > max_value ) && parseInt(value) != 0) {
				$(this).css('border', '1px solid red')
				return
			}
		} else {
			// validate string in autofill bank if string field
			valid_fields = autofills[$(this).attr('data-autofill')]
			valid_fields = JSON.stringify(valid_fields).toLowerCase()

			if (!valid_fields.includes(value.toLowerCase()) || value == "-" || value == "") {
				$(this).css('border', '1px solid red')
				return
			}
		}

		// validate required fields
		if ($(this).attr('data-require')) {
			required_field = "." + $(this).attr('data-require')
			required_input = $(this).parents('.expanded-field').find(required_field)

			if (required_input.text() == "" || required_input.text() == "-" ) {
				required_input.css('border', '1px solid red')
			}
		}

		$(this).css('border', '')
		console.log(data)
		
		// send data to server
		$.post( "/personal", {"data": data }, function( e ) {     
          console.log('upload successful')
        });
	})

	//high light text on click
	$(document).on('click', "[contenteditable='true']", function(e){
		$(this).selectText()
	})

	// upload choice when clicking 
	$(document).on('click', ".choosable", function(e){
		var value = $(this).attr('data-value')
		var field_name = $(this).parent().attr('data-field-name')
		var index = $(this).parents('.filterable').attr('data-index')
		var narc = $(this).parent().attr('data-narc')

		var data = {}

		data["file_name"] = index
		data["field"] = field_name
		data["value"] = value
		data["narc"] = narc

		$(this).parent().children().removeClass('chosen').addClass('unchosen')
		$(this).addClass('chosen').removeClass('unchosen')

		console.log(data)
		$.post( "/personal", {"data": data }, function( e ) {     
          console.log('upload successful')
        });
	})

	$(document).on('click', ".move-prop", function(e){
		$(this).toggleClass('-active')

		var value = ($(this).hasClass('-active') ? 1 : 0)
		var field_name = $(this).attr('data-field-name')
		var index = $(this).parents('.filterable').attr('data-index')
		var narc = $(this).parent().attr('data-narc')

		var data = {}

		data["file_name"] = index
		data["field"] = field_name
		data["value"] = value
		data["narc"] = narc
		data["int"] = true
		
		console.log(data)
		$.post( "/personal", {"data": data }, function( e ) {     
          console.log('upload successful')
        });	
	})

	$(document).on('click', ".cell", function(e){
		$(this).toggleClass('-active')

		var value = []
		var field_name = $(this).attr('data-field-name')
		var index = $(this).parents('.filterable').attr('data-index')
		var narc = $(this).attr('data-narc')

		cells = $(this).parent().children()
		cells.each(function(n) {
			
			if ($(cells[n]).hasClass('-active')){
				value.push(1)
			} else {
				value.push(0)
			}
		}) 

		var data = {}

		data["file_name"] = index
		data["field"] = field_name
		data["value"] = value
		data["narc"] = narc
		
		console.log(data)
		$.post( "/personal", {"data": data }, function( e ) {     
          console.log('upload successful')
        });	
	})





	//blur box on enter
	$(document).on('keypress', "[contenteditable='true']", function(e){
		if(e.which == 13) {
	        $(this).blur()
	    }
	})

	// add pokemon type class to change color 
	$(document).on('focusout', ".pokemon-type[contenteditable='true'], .move-type .btn", function(){
		var value = $(this).text().trim()
		$(this).removeClassPrefix("-").addClass("-" + value.toLowerCase())
		
		if ($(this).parents('.move-type').length > 0) {
			$(this).addClass('-active')
		}
	})

	// expand move data 
	$(document).on('focusout', ".move-name[contenteditable='true']", function(){
		var value = $(this).text().trim()
		move_data = Object.values(moves).find(e => e[1]["name"].toLowerCase().toCamelCase() == value.toLowerCase().toCamelCase() )

		if (move_data) {
			type = move_data[1]["type"] 
			power = move_data[1]["power"]
			acc = move_data[1]["accuracy"]
			effect = move_data[1]["effect"]
			
			type_name_length = 3
			if ($('.tm-list').length > 0) {
				type_name_length = type.length
			}

			row = $(this).parents('.expanded-field')

			row.find('button, .btn').removeClass().addClass('btn').addClass('-active').addClass("-" +type.toLowerCase()).text(type.toUpperCase().slice(0,type_name_length))
			row.find('.mov-cat img').show().attr("src", "/images/move-" + type.toLowerCase() + ".png")

			row.find('.move-power').text(power)
			row.find('.move-accuracy').text(acc)
			row.find('.move-effect').text(effect)
		}
	})

	// adjust base stat bar length
	$(document).on('focusout', "td[contenteditable='true']", function(){
		var value = $(this).text().trim()

		value = parseInt(value)
		var width = value / 2.55
		$(this).parent().find(".pokemon-card__graph").css('width', width.toString() + "%")
	})

	$(document).on('focusout', ".enc-name[contenteditable='true']", function(){
		var value = $(this).text().trim()
		var card = $(this).parents('.filterable')
		var all_encs = card.find('.enc-name')

		var encs = all_encs.map(function(e) {	
			return $(all_encs[e]).text() 
		}).toArray()


		let unique_encs = encs.filter((c, index) => {
		    return (encs.indexOf(c) === index && c != "-");
		});
		
		card.find(".wild").remove()
		
		$.each(unique_encs, function(i,v) {
			if (v != "") {
				var sprite = "<div class='wild'><img src='/images/pokesprite/" + v + ".png'></div>"
				card.find(".encounter-wilds").append(sprite)
			}
			
		})
	})


	$(document).on('autocomplete:request', "[contenteditable='true']", function(event, query, callback) {
	  var suggestions = autofills[$(this).attr('data-autofill')].filter(function(e){
	  	return e.toLowerCase().includes(query.toLowerCase())
	  });
	  callback(suggestions);
	})


})

//////////////////////////////  FUNCTIONS //////////////////////////////////////////

function filter() {
	cards = $('.filterable')
	
	gen_filters = ""
	type_filters = ""
	text_filters = ""
	cat_filters = ""

	//ex: "134"
	gen_filters = $('.gen-filters button.-active').text() 

	// ex: "fighing, rock"
	$('.type-filters button.-active').each(function(){
		type_filters += $(this).attr('data-ptype') + " "
	})

	// ex "hello world"
	text_filters = $('#search-text').val()

	selected_cats = $('.cat-filters button.-active img')
	selected_cats.map(n => cat_filters += $(selected_cats[n]).attr('data-mcat'))


	// show all cards if no filters selected
	if (gen_filters || type_filters || text_filters || cat_filters) {
		cards.hide()
	} else {
		cards.show()
		return
	}
	
	if ($('#personals').length > 0) {
		search_results = pokemons.filter(function(e) {
			if (!e) {
				return false
			}
			gen = e["gen"]
			type_1 = e["type_1"].toLowerCase()
			type_2 = e["type_2"].toLowerCase()

			gen_match = false
			type_match = false
			text_match = false
			
			if (gen_filters) {
				gen_match = gen_filters.includes(gen)
			} else { // when no gen filter
				gen_match = true
			}

			if (type_filters) {
				type_match = (type_filters.includes(type_1) || type_filters.includes(type_2))
			} else { // when no type filter
				type_match = true
			}
			
			if (text_filters) {
				texts = text_filters.split(",")
				for (text in texts) {
					// console.log(texts)
					text = texts[text]
					text_match = JSON.stringify(e).toLowerCase().includes(text.toLowerCase())
					if (text_match ) {break;}
				} 
			} else { // when no text filter
				text_match = true
			}

			if (type_match && gen_match && text_match) {
				$(cards[e["index"] - 1]).show()
			}

			return type_match && gen_match && text_match
		})
	}

	if ($('#moves').length > 0) {		
		move_list = Object.values(moves).sort(function(a,b) {
			parseInt(a["index"]) - parseInt(b["index"]);
		})
		var tms = true
		if ($("[data-index='tms']").length == 0) {
			tms = false
			
		}
		search_results = move_list.filter(function(e) {
			
			if (!tms) {
				e = e[1]
			}
			

			if (!e || !e["type"]) {
				return false
			}


			type = e["type"].toLowerCase()
			cat = e["category"].toLowerCase()

			type_match = false
			text_match = false
			cat_match = false

			if (cat_filters) {
				cat_match = cat_filters.includes(cat)
			} else { // when no type filter
				cat_match = true
			}
			
			if (type_filters) {
				type_match = type_filters.includes(type)
			} else { // when no type filter
				type_match = true
			}
			
			if (text_filters) {
				texts = text_filters.split(",")
				for (text in texts) {
					// console.log(texts)
					text = texts[text]
					text_match = JSON.stringify(e).toLowerCase().includes(text.toLowerCase())
					if (text_match ) {break;}
				} 
			} else { // when no text filter
				text_match = true
			}

			if (type_match && text_match && cat_match) {
				// $(cards[e["index"]]).show()
				if (tms) {
					$(".filterable[data-move-index='" + e["index"] + "']").show()
				} else {
					$(cards[e["index"]]).show()
				}
				
			}

			return type_match && cat_match && text_match
		})
	}

	if ($('#headers').length > 0) {		
		var list = Object.values(headers).sort(function(a,b) {
			parseInt(a["index"]) - parseInt(b["index"]);
		})

		search_results = list.filter(function(e) {
			text_match = false

			if (text_filters) {
				texts = text_filters.split(",")
				for (text in texts) {
					// console.log(texts)
					text = texts[text]
					
					if (e["location_name"]) {
						text_match = e["location_name"].toLowerCase().includes(text.toLowerCase())
					}
					
					if (text_match ) {break;}
				} 
			} else { // when no text filter
				text_match = true
			}

			if (text_match) {
				$(cards[list.indexOf(e)]).show()
			}
			return text_match
		})
	}

	if ($('#encounters').length > 0) {		
		var list = Object.values(encounters).sort(function(a,b) {
			parseInt(a["index"]) - parseInt(b["index"]);
		})

		search_results = list.filter(function(e) {
			text_match = false

			if (text_filters) {
				texts = text_filters.split(",")
				for (text in texts) {
					text = texts[text]

					text_match = JSON.stringify(e).toLowerCase().includes(text.toLowerCase())
					if (text_match ) {break;}
				} 
			} else { // when no text filter
				text_match = true
			}

			if (text_match) {
				$(cards[list.indexOf(e)]).show()
			}
			return text_match
		})
	}
	
}

