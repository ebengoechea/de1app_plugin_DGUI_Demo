#######################################################################################################################
### A plugin to demo usage of the DGUI DE1app plugin. Shows the extra "widget bundles" and editing pages it offers,
###	and exemplifies with its code how pages & widgets creation is much simplified.
### 
### The demo contains one page, reachable by tapping the "smiley" icon on the Insight or DSx home pages.
###	Run it under both skins to check how it adapts general page aspect (fonts and colors) to the skin in use.
###
###	Most benefits of the DGUI framework are obtained when the following conventions are followed:
###		1) Each page/context is a namespace, and the page/context name matches the fully qualified namespace name.
###		2) The page namespace has array variables "widgets" and "data":
###			- widgets: stores references to each widget in the page, with user-friendly names.
###			- data: stores the state variables used in the page. 
###			- if a widget shows a variable in the data array, the widget name matches the data variable name.
###		3) The page namespace has the following standard procs:
###			- load_page: used from client code to load and show the page. All necessary parameters are passed to this
###				proc.
###			- show_page: normally called at the end of the load_page proc, makes visual adjustments to the page
###				after it is shown with "page_to_show_when_off <namespace>". It's a good idea to add a context
###				action that directly invokes show_page.
###			- setup_ui: creates all the page widgets.
###			- page_done: invoked when the default "Done" button is tapped, if applicable.
###			- page_cancel: invoked when the default "Cancel" button is tapped, if applicable.
###
### By Enrique Bengoechea 
#######################################################################################################################

set plugin_name "DGUI_Demo"

namespace eval ::plugins::DGUI_Demo {
	# Plugin standard variables
	variable author "Enrique Bengoechea"
	variable contact "enri.bengoechea@gmail.com"
	variable version 1.01
	variable github_repo ebengoechea/de1app_plugin_DGUI_Demo
	variable name "Describe GUI Demo"
	variable description "A demo for the 'Describe GUI' (DGUI) plugin.
Enable and tap the smiley on DSx or Insight home pages. Do not run with other skins."

	# An array to keep references to all widgets used in the page. DGUI procs auto-add to this array. 
	variable widgets
	array set widgets {}
		
	# State variables for the page. DGUI procs uses this array when creating widgets, if available.
	# It's not necessary to explicitly define page_name as it will be done by add_page, but makes things clearer.
	variable data
	array set data {
		page_name "::plugins::DGUI_Demo"
		page_title {}
		optional_value {}
		my_tds {}
		beverage {}
		is_this_true 0
		stars 2
		show_text_status off
	}
}

# Auto-invoked when the plugin is loaded by the extensions system.
proc ::plugins::DGUI_Demo::main {} {
	# Ensure the DGUI plugin is loaded before DGUI_Demo
	if { [plugins available DGUI] } {
		plugins load DGUI
	} else {
		info_page [translate "The DGUI plugin must be installed for DGUI_Demo to work"] [translate Ok]
		plugins disable DGUI_Demo
		return
	}
	
	# Create the example page
	setup_ui
	
	# Create the UI integration points with DSx or Insight. 
	if { $::settings(skin) eq "DSx" } {
		setup_ui_DSx
	} elseif { $::settings(skin) eq "MimojaCafe" } {
		setup_ui_MimojaCafe
	} else {
		setup_ui_Insight
	}
}

proc ::plugins::DGUI_Demo::preload {} {
	if { [plugins available DGUI] } {
		plugins preload DGUI		
		# Let as use, for example, "add_page" instead of the fully qualified "::plugins::DGUI::add_page".
		namespace import ::plugins::DGUI::*
	} 
}

# Sets up integration points with the DSx skin.
proc ::plugins::DGUI_Demo::setup_ui_DSx {} {
	# Add an icon on the top-left DSx home page to open the demo page.
	# Icons are fontawesome symbols, in sizes "small", "medium" or "big". You can use the unicode character value,
	#	or a symbolic name that you have added first with a call to ::plugins::DGUI::define_symbol
	add_symbol $::DSx_standby_pages 100 60 "\uf581" -size small -has_button 1 \
		-button_cmd { ::plugins::DGUI_Demo::load_page "A demo plugin for DGUI under DSx" }
}

# Sets up integration points with the Insight skin.
proc ::plugins::DGUI_Demo::setup_ui_Insight {} {
	# Add an icon on the bottom-right Insight home page to open the demo page.
	add_symbol "off" 2460 1240 "\uf581" -size small -has_button 1 \
		-button_cmd { ::plugins::DGUI_Demo::load_page "A demo plugin for DGUI under Insight" }
}

# Sets up integration points with the MimojaCafe skin.
proc ::plugins::DGUI_Demo::setup_ui_MimojaCafe {} {
	# Add an icon on the top-left MimojaCafe home page to open the demo page.
	# Icons are fontawesome symbols, in sizes "small", "medium" or "big". You can use the unicode character value,
	#	or a symbolic name that you have added first with a call to ::plugins::DGUI::define_symbol
	add_symbol "off" 15 65 "\uf581" -size small -has_button 1 \
		-button_cmd { ::plugins::DGUI_Demo::load_page "A demo plugin for DGUI under MimojaCafe" }
}

# This is what client code should use to open/launch the page. 
proc ::plugins::DGUI_Demo::load_page { page_title args } {
	variable widgets
	variable data
	set ns [namespace current]
	array set opts $args
	
	set data(page_title) $page_title
	set data(optional_value) [::plugins::DGUI::value_or_default opts(-optional_value) "A default"]
	
	# 'set_previous_page' will store the page/context that invoked this page, so we can automatically go back to
	# it when the "Done" or "Cancel" buttons are tapped. If a specific code has to be executed when the page is closed,
	# a 'callback_cmd' can be added to the load_page arguments, like the pages included with ::plugins::DGUI do.
	set_previous_page $ns
	page_to_show_when_off $ns
	
	# Some items like scrollbars or dropdown symbols need to be positioned dynamically the first time the page is
	# drawn, because by default all items are positions with fixed pixel coordinates, but text widgets like entries,
	# multiline entries or listboxes are defined in number of characters, whose actual size depends on the font used.
	# The DGUI plugin offers several helper functions for this, like 'set_scrollbar_dims', 'relocate_dropdown_arrows',
	# or 'relocate_text_wrt'.
#	set_scrollbars_dims $ns "items"
	relocate_dropdown_arrows widgets beverage
	
	# At this point, show_page will be run, but instead of calling it directly it's invoked through a context action
	# defined at the end of the setup_ui proc, so we guarantee it is always run when the page is shown, even if
	# 'load_page' is not explicitly called (e.g. if we call a "fake modal" dialog page from our page and then return).
}

proc ::plugins::DGUI_Demo::show_page {} {
	set ns [namespace current]
	# To draw the half-stars we need to show/hide them. Because showing the page shows *every* widget in the page,
	# we have to redraw the control for it to be properly shown.
	draw_rating $ns stars
	
	# Similar with the "Hello world!" text, showing the page makes it visible by default, so we ensure it only
	# appears if it has to.
	show_text_action_click
}

# This proc creates the page and its widgets. It needs to be called only once, on plugin startup.
# A page (or "context") in the DE1app is just a background image with widgets on it, that are created hidden by
# 	default by calls to 'add_visual_item_to_context' in gui.tcl, and then are shown when a page is loaded by a call to
# 	'page_to_show_when_off'. Every widget hangs from a global top-level canvas item called '.can', which acts as 
# 	geometry manager.
# The usual code for creating a page widget in DSx or Insight is composed of very long lines that define each and 
# 	every widget element. Very flexible but full of unnecessary duplication which makes maintenance really hard. 
# One of the main purposes of the DGUI "mini framework" is to simplify these calls as much as possible, so that
# 	client code for creating pages is minimal, and changes can be done globally with minimal effort. 
proc ::plugins::DGUI_Demo::setup_ui {} {
	variable data
	variable widgets
	set page [namespace current]

	# 'add_page' creates the page using a default per-skin background, gives it a variable title if data(page_title) is 
	# available (and none is explicitly provided) and creates done/cancel buttons unless arguments are added  to not
	# add them.
	::plugins::DGUI::add_page $page
	
	# Creates an entry box to modify a TDS value. Because field_name is a standard shot metadata field, its label, 
	# 	default, minimum and maximum values, or clicker increments are looked up automatically in the data dictionary 
	# 	provided by the SDB package, if available. Of course, any of these and other parameters can be directly set as 
	# 	named arguments to the proc. 
	# The default aspect of the entry textbox and other widgets is automatically defined to be consistent with the
	# 	skin in use, so the programmer only has to define options that *differ* from the default ones.
	# Automatic validation is provided if the field is found in the data dictionary or named options such as	
	# 	-data_type, n_decimals etc. are specified.
	# This call generates several widgets: the actual entry box, its label, each clicker arrow and its button 
	#	"clickable" areas. All of them are stored in the page namespace widgets array, using standard conventions.
	# -clicker=1 instructs to create "clicker" arrows around the entry to modify its numeric value.
	# -editor_page=1 instructs to launch a dedicated page editor to modify the value, in this case, because it detects
	#	it's a numeric value, the numeric edition page with the big numbers pad.
	add_entry $page drink_tds 100 200 850 200 5 -textvariable ::plugins::DGUI_Demo::data(my_tds) \
		-clicker 1 -editor_page 1
	
	add_text $page 1200 200 "Double tap the entry box to launch the full-page numeric editor" \
		-fill $::plugins::DGUI::remark_color -width 600
	
	# Creates a "fake combobox" where the items are selected in a full-page item selector. 
	# This is automatically done if instead of "beverage_chooser" we use a shot field from the data dictionary in the
	#	SDB plugin. Because we're not doing it this time, we have to force it with -data_type category and provide 
	#	the values ourselves.
	add_select_entry $page beverage 100 350 325 350 15 -label [translate "Beverage"] \
		-items "espresso latte capuccino cortado" -page_title [translate "Choose a beverage"]

	add_text $page 1200 350 "Double tap the entry box or tap the arrow to launch the full-page item selector" \
		-fill $::plugins::DGUI::remark_color -width 600
	
	# Creates a checkbox that uses fontawesome icons for the box, instead of the ugly & small Tk checkbox.
	add_checkbox $page is_this_true 100 500 {} -label [translate "Is this true?"] 
	
	add_text $page 1200 500 "A nice checkbox instead of the ugly tiny Tk one" -fill $::plugins::DGUI::remark_color \
		-width 600
	
	# Creates a star rating control. Actually any fontawesome symbol can be used instead of stars, though in that 
	# 	case the "half" symbol is likely not available. Any number of total stars can be used, and it can map to any
	# 	arbitrary integer numeric variable behind.
	add_rating $page stars 100 650 300 650 400 -label [translate "Rate me!"] -min_value 0 -max_value 12 -n_ratings 6 \
		-use_halfs 1
	
	add_text $page 1200 650 "Rating control with full & half-stars or other symbol, maps to an integer variable" \
		-fill $::plugins::DGUI::remark_color -width 600
	
	# Creates an action button with a symbol, label and state. Symbol & state are optional.
	# It is generally recommended that commands on buttons and other widgets just invoke a proc, instead of having
	# 	a long script, for code clarity, maintenance and efficiency (as procs can be byte-code optimized).
	# Note that widget commands and bind actions do not run in the page namespace/context, so fully qualified 
	#	names must always be used on them.
	add_button2 $page show_text_action 100 800 [translate "Show text"] {$::plugins::DGUI_Demo::data(show_text_status)} \
		eye ::plugins::DGUI_Demo::show_text_action_click
	add_text $page 600 800 [translate "Hello world!"] -widget_name hello_world

	add_text $page 1200 800 "Versioned Barney's \"rounded rectangle\" button of any size with optional symbol and status" \
		-fill $::plugins::DGUI::remark_color -width 600
	
	# Final message
	if { $::settings(skin) eq "Insight" } {
		set message "Run me under the DSx skin to check how this same page modifies its aspect dynamically to adapt to the skin without any change in the code!"
	} else {
		set message "Run me under the Insight skin to check how this same page modifies its aspect dynamically to adapt to the skin without any change in the code!"
	}
	add_text $page 1280 1200 [translate $message] -font_size 10 -fill $::plugins::DGUI::remark_color -anchor center \
		-justify center -width 1000
	
	# Ensure 'show_page' is always executed after showing the page.
	::add_de1_action $page ${page}::show_page
}

proc ::plugins::DGUI_Demo::show_text_action_click {} {
	variable data
	set ns [namespace current]
	
	if { $data(show_text_status) eq "on" } {
		show_widgets hello_world $ns 
		set data(show_text_status) off
	} else {
		hide_widgets hello_world $ns
		set data(show_text_status) on
	}
}

proc ::plugins::DGUI_Demo::page_cancel {} {
	variable data
	say [translate {cancel}] $::settings(sound_button_in)
	page_to_show_when_off $data(previous_page)
}

proc ::plugins::DGUI_Demo::page_done {} {
	variable data
	say [translate {done}] $::settings(sound_button_in)
	
	# Something meaningful would be returned or done here if this wasn't a demo...
	page_to_show_when_off $data(previous_page)

}