#
# © 2026-present Godot Mobile Plugins (https://github.com/godot-mobile-plugins)
#

@tool
extends EditorPlugin

var gmp_menu: PopupMenu
var plugins_data: Dictionary = {}
var gmp_window: GmpPluginWindow
var local_json_version: String = "1.0"


func _enter_tree():
	# 1. Create the PopupMenu
	gmp_menu = PopupMenu.new()
	gmp_menu.name = "GMP"

	# 2. Parse gmp.json and populate menu
	_load_plugins_data()

	# 3. Connect the selection signal
	gmp_menu.id_pressed.connect(_on_menu_item_pressed)

	# 4. Inject into the Root Menu Bar (Next to Scene, Project, Editor, Help)
	var menu_bar = _get_editor_menu_bar()
	if menu_bar:
		menu_bar.add_child(gmp_menu)
	else:
		# Fallback to standard Godot Tools menu if the UI tree changes in future versions
		push_warning("GMP Addon: Could not find root MenuBar. Falling back to Project > Tools.")
		add_tool_submenu_item("GMP", gmp_menu)

	# 5. Check for updates to gmp.json remotely
	_check_and_update_gmp_json()


func _load_plugins_data():
	if gmp_menu:
		gmp_menu.clear()
	plugins_data.clear()

	# Explicitly target the shared menu directory
	var json_path = "res://addons/GMPShared/menu/gmp.json"

	if not FileAccess.file_exists(json_path):
		push_error("GMP Addon: Could not find gmp.json at " + json_path)
		return

	var file = FileAccess.open(json_path, FileAccess.READ)
	var json = JSON.new()
	var err = json.parse(file.get_as_text())

	if err != OK:
		push_error("GMP Addon: Failed to parse gmp.json. Error at line " + str(json.get_error_line()))
		return

	var data = json.get_data()
	if not typeof(data) == TYPE_DICTIONARY:
		push_error("GMP Addon: gmp.json root is not a dictionary.")
		return

	if data.has("version"):
		local_json_version = str(data["version"])

	var item_id = 0
	for key in data:
		if key == "version":
			continue

		var plugin_info = data[key]
		var plugin_name = plugin_info.get("name", "Unnamed Plugin")

		# Add to menu and store data for window mapping
		gmp_menu.add_item(plugin_name, item_id)
		plugins_data[item_id] = plugin_info
		item_id += 1


func _check_and_update_gmp_json():
	var json_http = HTTPRequest.new()
	add_child(json_http)

	# Download directly to a temporary file first
	var temp_path = "user://temp_gmp.json"
	json_http.download_file = temp_path

	json_http.request_completed.connect(
		func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
			if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
				var file = FileAccess.open(temp_path, FileAccess.READ)
				if file:
					var json = JSON.new()
					if json.parse(file.get_as_text()) == OK:
						var remote_data = json.get_data()
						if typeof(remote_data) == TYPE_DICTIONARY and remote_data.has("version"):
							var remote_ver = str(remote_data["version"])
							file.close()  # Always close before doing file-system operations

							# Compare remote version to local version
							if GmpPluginWindow._compare_versions(remote_ver, local_json_version) > 0:
								var target_path = "res://addons/GMPShared/menu/gmp.json"

								# Replace at the file level
								if FileAccess.file_exists(target_path):
									DirAccess.remove_absolute(target_path)

								var err = DirAccess.copy_absolute(temp_path, target_path)

								if err == OK:
									# Force the editor to acknowledge the replaced file
									EditorInterface.get_resource_filesystem().scan()

									# Re-populate UI layout with updated contents
									_load_plugins_data()
								else:
									push_error("GMP Addon: Failed to copy updated gmp.json to res://")

			# Clean up the temporary file and HTTP node
			if FileAccess.file_exists(temp_path):
				DirAccess.remove_absolute(temp_path)

			json_http.queue_free()
	)

	json_http.request("https://raw.githubusercontent.com/godot-mobile-plugins/gmp-menu/refs/heads/main/src/gmp.json")


func _exit_tree():
	# 1. Remove the menu safely
	if gmp_menu:
		if gmp_menu.get_parent():
			gmp_menu.get_parent().remove_child(gmp_menu)
		gmp_menu.queue_free()

	# 2. Clean up any open plugin windows
	if is_instance_valid(gmp_window):
		gmp_window.queue_free()


func _on_menu_item_pressed(id: int):
	if plugins_data.has(id):
		_open_sub_window(GmpPluginData.new(plugins_data[id]))


func _open_sub_window(plugin_data: GmpPluginData):
	if is_instance_valid(gmp_window):
		gmp_window.queue_free()

	gmp_window = GmpPluginWindow.new(plugin_data)
	gmp_window.close_requested.connect(func(): gmp_window.queue_free())
	EditorInterface.get_base_control().add_child(gmp_window)
	gmp_window.popup()

	# Download Action
	gmp_window.download_btn.pressed.connect(
		func():
			var selected_version := gmp_window.get_selected_version()
			var platform_str = gmp_window.get_selected_platform()

			var url = (
				"%s/releases/download/v%s/%s-%s-v%s.zip"
				% [
					plugin_data.get_repository(),
					selected_version.get_version(),
					plugin_data.get_directory(),
					platform_str,
					selected_version.get_version()
				]
			)

			print("URL: %s" % url)
			gmp_window.plugin_archive_request.download_file = "user://gmp_download.zip"
			var err = gmp_window.plugin_archive_request.request(url)

			if err == OK:
				gmp_window.download_btn.disabled = true
				gmp_window.download_btn.text = "Downloading..."
				gmp_window.progress_bar.value = 0
				gmp_window.progress_bar.show()
				gmp_window.install_btn.hide()
				gmp_window.progress_timer.start()
			else:
				push_error("GMP Addon: Failed to start download request.")
	)

	gmp_window.progress_timer.timeout.connect(
		func():
			var body_size = gmp_window.plugin_archive_request.get_body_size()
			var downloaded = gmp_window.plugin_archive_request.get_downloaded_bytes()
			if body_size > 0:
				gmp_window.progress_bar.max_value = body_size
				gmp_window.progress_bar.value = downloaded
	)

	gmp_window.plugin_archive_request.request_completed.connect(
		func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
			gmp_window.progress_timer.stop()
			if result == HTTPRequest.RESULT_SUCCESS and response_code in [200, 301, 302, 303]:
				gmp_window.progress_bar.value = gmp_window.progress_bar.max_value
				gmp_window.download_btn.text = "Download Complete"
				gmp_window.install_btn.show()
			else:
				push_error("GMP Addon: Download failed with response code: " + str(response_code))
				gmp_window.download_btn.text = "Download Failed"
				gmp_window.download_btn.disabled = false
				gmp_window.progress_bar.hide()
	)

	# Install Action
	gmp_window.install_btn.pressed.connect(
		func():
			gmp_window.install_btn.disabled = true
			gmp_window.install_btn.text = "Installing..."

			var reader = ZIPReader.new()
			var err = reader.open("user://gmp_download.zip")
			if err == OK:
				for file_path in reader.get_files():
					# Ignore the root directory in the archive
					var slash_idx = file_path.find("/")
					if slash_idx == -1 or slash_idx == file_path.length() - 1:
						continue

					var stripped_path = file_path.substr(slash_idx + 1)
					var target_path = "res://" + stripped_path

					# Ensure directory architecture is built
					if stripped_path.ends_with("/"):
						DirAccess.make_dir_recursive_absolute(target_path)
					else:
						var base_dir = target_path.get_base_dir()
						if not DirAccess.dir_exists_absolute(base_dir):
							DirAccess.make_dir_recursive_absolute(base_dir)

						var content = reader.read_file(file_path)
						var fa = FileAccess.open(target_path, FileAccess.WRITE)
						if fa:
							fa.store_buffer(content)
							fa.close()
				reader.close()

				# Force Godot to scan the file system so new files appear immediately
				EditorInterface.get_resource_filesystem().scan()

				gmp_window.install_btn.text = "Install Complete!"

				# Update UI to reflect the installation
				var newly_installed_version := gmp_window.get_selected_version()
				gmp_window.set_installed_version_label(newly_installed_version.get_version())
				gmp_window.uninstall_btn.show()
			else:
				gmp_window.install_btn.text = "Extraction Failed"
				push_error("GMP Addon: Failed to open downloaded zip archive.")
	)

	# Uninstall Action
	gmp_window.uninstall_btn.pressed.connect(
		func():
			gmp_window.uninstall_btn.disabled = true
			gmp_window.uninstall_btn.text = "Uninstalling..."

			var plugin_dir = gmp_window.plugin_info.get_directory()
			if not plugin_dir.is_empty():
				# Remove addon dir
				_remove_recursive("res://addons/" + plugin_dir)

				# Remove iOS directories and files matching plugin_dir*
				var ios_path = "res://ios/plugins"
				if DirAccess.dir_exists_absolute(ios_path):
					var dir = DirAccess.open(ios_path)
					if dir:
						dir.list_dir_begin()
						var file_name = dir.get_next()
						while file_name != "":
							if file_name != "." and file_name != ".." and file_name.begins_with(plugin_dir):
								if dir.current_is_dir():
									_remove_recursive(ios_path + "/" + file_name)
								else:
									DirAccess.remove_absolute(ios_path + "/" + file_name)
							file_name = dir.get_next()
						dir.list_dir_end()

				# Force Godot to scan the file system
				EditorInterface.get_resource_filesystem().scan()

				# Update UI
				gmp_window.set_installed_version_label("None", Color(0.6, 0.6, 0.6))
				gmp_window.uninstall_btn.hide()
				gmp_window.uninstall_btn.text = "Uninstall"
				gmp_window.uninstall_btn.disabled = false

				gmp_window.reset_download_ui()
	)

	gmp_window.readme_request.request(plugin_data.get_readme_url())


# --- Helper Methods ---


static func _remove_recursive(path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		var dir = DirAccess.open(path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name != "." and file_name != "..":
					var child_path = path + "/" + file_name
					if dir.current_is_dir():
						_remove_recursive(child_path)
					else:
						DirAccess.remove_absolute(child_path)
				file_name = dir.get_next()
			dir.list_dir_end()
		DirAccess.remove_absolute(path)


func _get_editor_menu_bar() -> MenuBar:
	var base_control = get_editor_interface().get_base_control()
	return _find_node_by_class(base_control, "MenuBar") as MenuBar


func _find_node_by_class(node: Node, class_name_str: String) -> Node:
	if node.is_class(class_name_str):
		return node
	for child in node.get_children():
		var found = _find_node_by_class(child, class_name_str)
		if found:
			return found
	return null


class GmpPluginData:
	extends RefCounted

	const NAME_PROPERTY := &"name"
	const DIRECTORY_PROPERTY := &"directory"
	const DESCRIPTION_PROPERTY := &"description"
	const AUTHOR_PROPERTY := &"author"
	const REPOSITORY_PROPERTY := &"repository"
	const VERSIONS_PROPERTY := &"versions"
	const SPONSORSHIP_URL_PROPERTY := &"sponsorship_url"

	var plugin_data: Dictionary

	func _init(plugin_data: Dictionary):
		self.plugin_data = plugin_data

	func get_name() -> String:
		return plugin_data.get(NAME_PROPERTY, "GMP Plugin")

	func get_directory() -> String:
		return plugin_data.get(DIRECTORY_PROPERTY, "GMPPlugin")

	func get_description() -> String:
		return plugin_data.get(DESCRIPTION_PROPERTY, "GMP Plugin")

	func get_author() -> String:
		return plugin_data.get(AUTHOR_PROPERTY, "Godot Mobile Plugins")

	func get_repository() -> String:
		return plugin_data.get(REPOSITORY_PROPERTY, "")

	func get_versions() -> Array:
		return plugin_data.get(VERSIONS_PROPERTY, [])

	func get_version(a_index: int) -> GmpPluginVersion:
		var __versions := get_versions()
		return GmpPluginVersion.new(__versions[a_index]) if a_index < __versions.size() else null

	func get_sponsorship_url() -> String:
		return plugin_data.get(SPONSORSHIP_URL_PROPERTY, "")

	func get_readme_url() -> String:
		var repo_url := get_repository()
		var raw_repo_url := repo_url.replace("github.com", "raw.githubusercontent.com")
		return raw_repo_url + "/refs/heads/main/docs/README.md"


class GmpPluginVersion:
	extends RefCounted

	const VERSION_PROPERTY := &"version"
	const MIN_GODOT_PROPERTY := &"min_godot"
	const MAX_GODOT_PROPERTY := &"max_godot"
	const ANDROID_PROPERTY := &"ios"
	const IOS_PROPERTY := &"android"
	const MULTI_PROPERTY := &"multi"

	var version_data: Dictionary

	func _init(version_data: Dictionary):
		self.version_data = version_data

	func get_version() -> String:
		return version_data.get(VERSION_PROPERTY, "Unknown")

	func has_min_godot() -> bool:
		return version_data.has(MIN_GODOT_PROPERTY)

	func get_min_godot() -> String:
		return version_data.get(MIN_GODOT_PROPERTY)

	func has_max_godot() -> bool:
		return version_data.has(MAX_GODOT_PROPERTY)

	func get_max_godot() -> String:
		return version_data.get(MAX_GODOT_PROPERTY)

	func get_android() -> bool:
		return version_data.has(ANDROID_PROPERTY) and version_data.get(ANDROID_PROPERTY)

	func get_ios() -> bool:
		return version_data.has(IOS_PROPERTY) and version_data.get(IOS_PROPERTY)

	func get_multi() -> bool:
		return version_data.has(MULTI_PROPERTY) and version_data.get(MULTI_PROPERTY)


class GmpPluginWindow:
	extends Window
	const LINK_COLOR := Color.CORNFLOWER_BLUE

	var plugin_info: GmpPluginData

	var download_btn: Button
	var install_btn: Button
	var uninstall_btn: Button
	var installed_version_label: Label
	var editor_version_val: Label
	var compatibility_val: Label
	var version_dropdown: OptionButton
	var android_radio: CheckBox
	var ios_radio: CheckBox
	var progress_bar: ProgressBar
	var progress_timer: Timer
	var plugin_archive_request: HTTPRequest
	var readme_request: HTTPRequest

	func _init(plugin_info: GmpPluginData):
		self.plugin_info = plugin_info
		download_btn = Button.new()
		install_btn = Button.new()
		uninstall_btn = Button.new()
		installed_version_label = Label.new()
		editor_version_val = Label.new()
		compatibility_val = Label.new()
		version_dropdown = OptionButton.new()
		android_radio = CheckBox.new()
		ios_radio = CheckBox.new()
		progress_bar = ProgressBar.new()
		progress_timer = Timer.new()
		plugin_archive_request = HTTPRequest.new()
		readme_request = HTTPRequest.new()

		var window_title = plugin_info.get_name()

		self.title = window_title

		# Size constraints: 600x500 or screen size if smaller
		var screen_idx = DisplayServer.window_get_current_screen()
		var screen_size = DisplayServer.screen_get_size(screen_idx)
		self.size = Vector2i(ceil(screen_size.x * 0.7), ceil(screen_size.y * 0.7))

		self.transient = true  # Keeps the window on top of the editor
		self.exclusive = false

		# Center the window relative to the editor
		var editor_rect = EditorInterface.get_base_control().get_global_rect()
		self.position = editor_rect.position + (editor_rect.size / 2) - (Vector2(self.size) / 2)

		# Setup Support Nodes for Downloading
		self.add_child(plugin_archive_request)

		progress_timer.wait_time = 0.1
		progress_timer.autostart = false
		self.add_child(progress_timer)

		# Setup UI Container structure
		var margin_container = MarginContainer.new()
		margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin_container.add_theme_constant_override("margin_left", 20)
		margin_container.add_theme_constant_override("margin_right", 20)
		margin_container.add_theme_constant_override("margin_top", 20)
		margin_container.add_theme_constant_override("margin_bottom", 20)
		self.add_child(margin_container)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 15)
		margin_container.add_child(vbox)

		# Plugin Name
		var name_label = Label.new()
		name_label.text = window_title
		name_label.add_theme_font_size_override("font_size", 60)
		var font_variation := FontVariation.new()
		font_variation.variation_embolden = 1.5
		name_label.add_theme_font_override("font", font_variation)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(name_label)

		# Plugin Description
		var desc_label = Label.new()
		desc_label.text = plugin_info.get_description()
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(desc_label)

		# Plugin Author
		var author_hbox = HBoxContainer.new()
		author_hbox.add_theme_constant_override("separation", 40)

		var author_title_label = Label.new()
		author_title_label.text = "Author:"
		author_hbox.add_child(author_title_label)

		var author_value_label = Label.new()
		author_value_label.text = plugin_info.get_author()
		author_hbox.add_child(author_value_label)
		vbox.add_child(author_hbox)

		# Links (Repository & Issues)
		var repo_url = plugin_info.get_repository()
		var links_hbox = HBoxContainer.new()
		links_hbox.add_theme_constant_override("separation", 80)
		links_hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		var repo_link = LinkButton.new()
		repo_link.text = "View Repository"
		repo_link.uri = repo_url
		repo_link.add_theme_color_override("font_color", LINK_COLOR)
		links_hbox.add_child(repo_link)

		var issues_link = LinkButton.new()
		issues_link.text = "View Issues"
		issues_link.uri = repo_url + "/issues"
		issues_link.add_theme_color_override("font_color", LINK_COLOR)
		links_hbox.add_child(issues_link)
		vbox.add_child(links_hbox)

		vbox.add_child(HSeparator.new())

		# Main Split Layout (Left: README, Right: Controls)
		var split_hbox = HBoxContainer.new()
		split_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		split_hbox.add_theme_constant_override("separation", 20)
		vbox.add_child(split_hbox)

		# --- LEFT PANEL: README ---
		var left_vbox = VBoxContainer.new()
		left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		left_vbox.size_flags_stretch_ratio = 1.2
		split_hbox.add_child(left_vbox)

		var readme_scroll = ScrollContainer.new()
		readme_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		left_vbox.add_child(readme_scroll)

		var readme_label = RichTextLabel.new()
		readme_label.bbcode_enabled = true
		readme_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		readme_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		readme_label.text = "Loading README..."
		readme_label.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))
		readme_scroll.add_child(readme_label)

		# Fetch README Data
		self.add_child(readme_request)

		readme_request.request_completed.connect(
			func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
				if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
					readme_label.text = (
						"[center][b][font_size=36]README.md[/font_size][/b][/center]\n"
						+ _markdown_to_bbcode(body.get_string_from_utf8())
					)
				else:
					readme_label.text = (
						"[color=red]Failed to load README. Ensure it exists at:[/color]\n"
						+ plugin_info.get_readme_url()
					)
		)

		# --- RIGHT PANEL: CONTROLS ---
		var right_vbox = VBoxContainer.new()
		right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		right_vbox.size_flags_stretch_ratio = 0.8
		split_hbox.add_child(right_vbox)

		# --- INSTALLED VERSION LOGIC ---
		var installed_title_label = Label.new()
		installed_title_label.text = "INSTALLED VERSION"
		installed_title_label.add_theme_font_size_override("font_size", 36)
		installed_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		right_vbox.add_child(installed_title_label)

		installed_version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		installed_version_label.add_theme_font_size_override("font_size", 30)

		var plugin_dir = plugin_info.get_directory()
		var installed_version_text = "None"

		if not plugin_dir.is_empty():
			var addon_path = "res://addons/" + plugin_dir
			if DirAccess.dir_exists_absolute(addon_path):
				var cfg_path = addon_path + "/plugin.cfg"
				if FileAccess.file_exists(cfg_path):
					var config = ConfigFile.new()
					if config.load(cfg_path) == OK:
						installed_version_text = config.get_value("plugin", "version", "Unknown")

		installed_version_label.text = installed_version_text
		if installed_version_text == "None":
			installed_version_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		right_vbox.add_child(installed_version_label)

		uninstall_btn.text = "Uninstall"
		uninstall_btn.custom_minimum_size = Vector2(200, 0)
		uninstall_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		uninstall_btn.visible = (installed_version_text != "None")
		right_vbox.add_child(uninstall_btn)

		right_vbox.add_child(HSeparator.new())

		# --- AVAILABLE VERSIONS LOGIC ---
		var available_title_label = Label.new()
		available_title_label.text = "AVAILABLE VERSIONS"
		available_title_label.add_theme_font_size_override("font_size", 36)
		available_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		right_vbox.add_child(available_title_label)

		# Versions Context Menu
		var versions_array = plugin_info.get_versions()
		var version_hbox = HBoxContainer.new()
		var version_title = Label.new()
		version_title.text = "Select Version:"

		for v in versions_array:
			version_dropdown.add_item(v.get("version", "Unknown"))

		version_hbox.add_child(version_title)
		version_hbox.add_child(version_dropdown)
		right_vbox.add_child(version_hbox)

		# Min/Max Godot Version Labels
		var min_godot_hbox = HBoxContainer.new()
		var min_godot_title = Label.new()
		min_godot_title.text = "Min Godot:"
		var min_godot_val = Label.new()
		min_godot_hbox.add_child(min_godot_title)
		min_godot_hbox.add_child(min_godot_val)
		right_vbox.add_child(min_godot_hbox)

		var max_godot_hbox = HBoxContainer.new()
		var max_godot_title = Label.new()
		max_godot_title.text = "Max Godot:"
		var max_godot_val = Label.new()
		max_godot_hbox.add_child(max_godot_title)
		max_godot_hbox.add_child(max_godot_val)
		right_vbox.add_child(max_godot_hbox)

		var editor_version_hbox = HBoxContainer.new()
		var editor_version_title = Label.new()
		editor_version_title.text = "Editor Version:"
		editor_version_hbox.add_child(editor_version_title)
		editor_version_hbox.add_child(editor_version_val)
		editor_version_hbox.add_child(compatibility_val)
		right_vbox.add_child(editor_version_hbox)

		right_vbox.add_child(HSeparator.new())

		# Archive Type Radio Buttons
		var platform_vbox = VBoxContainer.new()
		var platform_title = Label.new()
		platform_title.text = "Archive Type:"
		platform_vbox.add_child(platform_title)

		var platform_hbox = HBoxContainer.new()
		var radio_group = ButtonGroup.new()

		android_radio.text = "Android"
		android_radio.button_group = radio_group

		ios_radio.text = "iOS"
		ios_radio.button_group = radio_group

		var multi_radio = CheckBox.new()
		multi_radio.text = "Multi"
		multi_radio.button_group = radio_group

		platform_hbox.add_child(android_radio)
		platform_hbox.add_child(ios_radio)
		platform_hbox.add_child(multi_radio)
		platform_vbox.add_child(platform_hbox)
		right_vbox.add_child(platform_vbox)

		right_vbox.add_child(HSeparator.new())

		# Download & Installation UI
		download_btn.text = "Download Plugin"
		download_btn.custom_minimum_size = Vector2(200, 0)
		download_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		right_vbox.add_child(download_btn)

		progress_bar.hide()
		progress_bar.custom_minimum_size = Vector2(200, 20)
		progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		right_vbox.add_child(progress_bar)

		install_btn = Button.new()
		install_btn.text = "Install"
		install_btn.hide()
		install_btn.custom_minimum_size = Vector2(200, 0)
		install_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		right_vbox.add_child(install_btn)

		# State Update Logic
		var update_version_display = func(idx: int):
			var selected_version_data := plugin_info.get_version(idx)

			# Fetch and format current editor version
			var v_info = Engine.get_version_info()
			var current_editor_version = str(v_info.major) + "." + str(v_info.minor)
			if v_info.patch > 0:
				current_editor_version += "." + str(v_info.patch)
			editor_version_val.text = current_editor_version

			var is_compatible = true

			if selected_version_data.has_min_godot():
				min_godot_val.text = selected_version_data.get_min_godot()
				min_godot_hbox.show()
				if _compare_versions(current_editor_version, selected_version_data.get_min_godot()) < 0:
					is_compatible = false
			else:
				min_godot_hbox.hide()

			if selected_version_data.has_max_godot():
				max_godot_val.text = selected_version_data.get_max_godot()
				max_godot_hbox.show()
				if _compare_versions(current_editor_version, selected_version_data.get_max_godot()) > 0:
					is_compatible = false
			else:
				max_godot_hbox.hide()

			# Set Compatibility Text and Color
			if is_compatible:
				compatibility_val.text = "✅ Compatible"
				compatibility_val.add_theme_color_override("font_color", Color.GREEN)
			else:
				compatibility_val.text = "❌ Incompatible"
				compatibility_val.add_theme_color_override("font_color", Color.RED)

			# Platform radio buttons logic
			android_radio.visible = selected_version_data.get_android()
			ios_radio.visible = selected_version_data.get_ios()
			multi_radio.visible = selected_version_data.get_multi()

			if selected_version_data.get_android():
				android_radio.button_pressed = true
			elif selected_version_data.get_ios():
				ios_radio.button_pressed = true
			elif selected_version_data.get_multi():
				multi_radio.button_pressed = true

			reset_download_ui()

		version_dropdown.item_selected.connect(update_version_display)
		if versions_array.size() > 0:
			update_version_display.call(0)
		else:
			version_dropdown.disabled = true
			download_btn.disabled = true

		var delimiter_label = Label.new()
		delimiter_label.text = ""
		delimiter_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		right_vbox.add_child(delimiter_label)

		right_vbox.add_child(HSeparator.new())

		var sponsorship_label = Label.new()
		sponsorship_label.text = "If this plugin saves you time or effort, consider supporting its continued development."
		sponsorship_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sponsorship_label.add_theme_color_override("font_color", Color.PLUM)
		right_vbox.add_child(sponsorship_label)

		var sponsorship_link = LinkButton.new()
		sponsorship_link.text = "Support the Project"
		sponsorship_link.uri = plugin_info.get_sponsorship_url()
		sponsorship_link.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		sponsorship_link.add_theme_color_override("font_color", LINK_COLOR)
		right_vbox.add_child(sponsorship_link)

		right_vbox.add_child(HSeparator.new())

		var gmp_menu_label = Label.new()
		var gmp_menu_version := "0.0"

		# Load the plugin.cfg to read the version
		var menu_config := ConfigFile.new()
		var cfg_path := "res://addons/GMPShared/menu/plugin.cfg"
		if menu_config.load(cfg_path) == OK:
			gmp_menu_version = menu_config.get_value("plugin", "version", "0.0")

		gmp_menu_label.text = "GMP Menu v%s" % gmp_menu_version

		var footer_hbox = HBoxContainer.new()
		footer_hbox.size_flags_horizontal = Control.SIZE_SHRINK_END
		right_vbox.add_child(footer_hbox)

		gmp_menu_label.size_flags_horizontal = Control.SIZE_SHRINK_END
		footer_hbox.add_child(gmp_menu_label)

		# --- PLUGIN UPGRADE LOGIC ---
		var menu_update_request = HTTPRequest.new()
		self.add_child(menu_update_request)
		menu_update_request.request_completed.connect(
			func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
				if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
					var prop_text = body.get_string_from_utf8()
					var remote_version = _parse_property(prop_text, "pluginVersion")

					if not remote_version.is_empty() and _compare_versions(remote_version, gmp_menu_version) > 0:
						var upgrade_btn = Button.new()
						upgrade_btn.text = "Upgrade"
						upgrade_btn.add_theme_color_override("font_color", Color.GREEN)
						footer_hbox.add_child(upgrade_btn)

						upgrade_btn.pressed.connect(
							func():
								upgrade_btn.disabled = true
								upgrade_btn.text = "Upgrading..."

								var menu_download_request = HTTPRequest.new()
								self.add_child(menu_download_request)

								var dl_url = (
									"https://github.com/godot-mobile-plugins/gmp-menu/releases/download/v%s/"
									+ "GmpMenu-v%s.zip" % [remote_version, remote_version]
								)
								menu_download_request.download_file = "user://gmp_menu_upgrade.zip"

								menu_download_request.request_completed.connect(
									func(
										dl_result: int,
										dl_code: int,
										dl_headers: PackedStringArray,
										dl_body: PackedByteArray
									):
										if dl_result == HTTPRequest.RESULT_SUCCESS and dl_code in [200, 301, 302, 303]:
											var reader = ZIPReader.new()
											var zip_err = reader.open("user://gmp_menu_upgrade.zip")
											if zip_err == OK:
												for file_path in reader.get_files():
													var slash_idx = file_path.find("/")
													if slash_idx == -1 or slash_idx == file_path.length() - 1:
														continue

													var stripped_path = file_path.substr(slash_idx + 1)
													var target_path = "res://" + stripped_path

													if stripped_path.ends_with("/"):
														DirAccess.make_dir_recursive_absolute(target_path)
													else:
														var base_dir = target_path.get_base_dir()
														if not DirAccess.dir_exists_absolute(base_dir):
															DirAccess.make_dir_recursive_absolute(base_dir)

														var content = reader.read_file(file_path)
														var fa = FileAccess.open(target_path, FileAccess.WRITE)
														if fa:
															fa.store_buffer(content)
															fa.close()
												reader.close()
												EditorInterface.get_resource_filesystem().scan()
												upgrade_btn.text = "Restart Editor"
											else:
												upgrade_btn.text = "Extract Failed"
												upgrade_btn.disabled = false
										else:
											upgrade_btn.text = "Download Failed"
											upgrade_btn.disabled = false
										menu_download_request.queue_free()
								)
								menu_download_request.request(dl_url)
						)
				menu_update_request.queue_free()
		)
		ready.connect(
			func():
				menu_update_request.request(
					(
						"https://raw.githubusercontent.com/godot-mobile-plugins/gmp-menu/refs/heads/main/config/"
						+ "plugin.properties"
					)
				)
		)

	func get_selected_version() -> GmpPluginVersion:
		return plugin_info.get_version(version_dropdown.selected)

	func get_selected_platform() -> String:
		var platform_str := "Multi"
		if android_radio.button_pressed:
			platform_str = "Android"
		elif ios_radio.button_pressed:
			platform_str = "iOS"
		return platform_str

	func set_installed_version_label(a_text: String, a_color: Color = Color.SNOW) -> void:
		installed_version_label.text = a_text
		if a_color == Color.SNOW:
			installed_version_label.remove_theme_color_override("font_color")
		else:
			installed_version_label.add_theme_color_override("font_color", a_color)

	func reset_download_ui() -> void:
		# Reset Download/Install UI on version change
		download_btn.text = "Download Plugin"
		download_btn.disabled = false
		progress_bar.hide()
		progress_bar.value = 0
		install_btn.hide()

	static func _compare_versions(v1: String, v2: String) -> int:
		var parts1 = v1.split(".")
		var parts2 = v2.split(".")
		var max_len = max(parts1.size(), parts2.size())

		for i in range(max_len):
			# to_int() cleanly handles strings like "7-dev3" by returning 7
			var p1 = parts1[i].to_int() if i < parts1.size() else 0
			var p2 = parts2[i].to_int() if i < parts2.size() else 0

			if p1 < p2:
				return -1
			if p1 > p2:
				return 1

		return 0

	static func _parse_property(text: String, key: String) -> String:
		var lines = text.split("\n")
		for line in lines:
			var trimmed = line.strip_edges()
			if trimmed.begins_with("#") or trimmed.begins_with(";"):
				continue
			var eq_idx = trimmed.find("=")
			if eq_idx != -1:
				var k = trimmed.substr(0, eq_idx).strip_edges()
				if k == key:
					return trimmed.substr(eq_idx + 1).strip_edges()
		return ""

	static func _markdown_to_bbcode(md: String) -> String:
		var bbcode = md

		# 1. Clean up HTML layout constructs
		bbcode = bbcode.replace("<br>", "\n")
		bbcode = bbcode.replace("&nbsp;", " ")
		bbcode = bbcode.replace('<div align="center">', "[center]")
		bbcode = bbcode.replace("</div>", "[/center]")
		bbcode = bbcode.replace('<p align="center">', "[center]")
		bbcode = bbcode.replace("</p>", "[/center]")

		# 2. Strip HTML anchors
		var anchor_rx = RegEx.new()
		anchor_rx.compile('<a name="[^"]+"></a>')
		bbcode = anchor_rx.sub(bbcode, "", true)

		# 3. Simplify HTML images to avoid web texture load errors in Godot
		var html_img_rx = RegEx.new()
		html_img_rx.compile("<img[^>]*>")
		bbcode = html_img_rx.sub(bbcode, "[i]🖼️[/i]", true)

		# 4. Convert HTML links
		var html_link_rx = RegEx.new()
		html_link_rx.compile('<a[^>]*href="([^"]+)"[^>]*>(.*?)</a>')
		bbcode = html_link_rx.sub(bbcode, "[url=$1]$2[/url]", true)

		# 5. Simplify Markdown images to avoid web texture load errors
		var md_img_rx = RegEx.new()
		md_img_rx.compile("!\\[(.*?)\\]\\((.*?)\\)")
		bbcode = md_img_rx.sub(bbcode, "[i]🖼️: $1[/i]", true)

		# 6. Convert Markdown links
		var md_link_rx = RegEx.new()
		md_link_rx.compile("\\[([^\\]]+)\\]\\((.*?)\\)")
		bbcode = md_link_rx.sub(bbcode, "[url=$2]$1[/url]", true)

		# 7. Bold
		var bold_rx = RegEx.new()
		bold_rx.compile("\\*\\*(.*?)\\*\\*")
		bbcode = bold_rx.sub(bbcode, "[b]$1[/b]", true)

		# 8. Italic (Using _text_)
		var italic_rx = RegEx.new()
		italic_rx.compile("(^|\\s)_(.*?)_(\\s|$)")
		bbcode = italic_rx.sub(bbcode, "$1[i]$2[/i]$3", true)

		# 9. Inline Code (Fix for Monospace font error)
		var code_rx = RegEx.new()
		code_rx.compile("`(.*?)`")
		bbcode = code_rx.sub(bbcode, "[code]$1[/code]", true)

		# 10. Line-by-line parsing for blocks and tables
		var lines = bbcode.split("\n")
		bbcode = ""
		var in_code_block = false
		var in_table = false

		for line in lines:
			# Code Blocks
			if line.begins_with("```"):
				if in_table:
					in_table = false
					bbcode += "[/table]\n"
				in_code_block = !in_code_block
				bbcode += "[code]\n" if in_code_block else "[/code]\n"
				continue

			if in_code_block:
				bbcode += line + "\n"
				continue

			# Headers
			if line.begins_with("# "):
				line = "[b][font_size=36]" + line.substr(2) + "[/font_size][/b]"
			elif line.begins_with("## "):
				line = "[b][font_size=30]" + line.substr(3) + "[/font_size][/b]"
			elif line.begins_with("### "):
				line = "[b][font_size=24]" + line.substr(4) + "[/font_size][/b]"

			# Unordered Lists
			if line.begins_with("- "):
				line = "  • " + line.substr(2)

			# Tables
			if line.begins_with("|") and line.ends_with("|"):
				if line.find("---") != -1:
					continue  # Skip the markdown table separator line

				var cells = line.split("|", false)
				if not in_table:
					in_table = true
					bbcode += "[table=" + str(cells.size()) + "]\n"

				for cell in cells:
					bbcode += "[cell]" + cell.strip_edges() + "[/cell]"
				bbcode += "\n"
				continue
			elif in_table:
				in_table = false
				bbcode += "[/table]\n"

			bbcode += line + "\n"

		if in_table:
			bbcode += "[/table]\n"

		# 11. Remove consecutive empty lines
		var final_lines = bbcode.split("\n")
		var cleaned_bbcode = ""

		var alpha_rx = RegEx.new()
		alpha_rx.compile("[a-zA-Z]")

		var tag_rx = RegEx.new()
		tag_rx.compile("\\[.*?\\]")

		var consecutive_empty_count = 0

		var structural_tags = [
			"[table",
			"[/table]",
			"[cell]",
			"[/cell]",
			"[code]",
			"[/code]",
			"[center]",
			"[/center]",
			"[right]",
			"[/right]",
			"[fill]",
			"[/fill]",
			"[indent]",
			"[/indent]",
			"[ul]",
			"[/ul]",
			"[ol]",
			"[/ol]"
		]

		for i in range(final_lines.size()):
			var current_line = final_lines[i]

			if i == final_lines.size() - 1 and current_line == "":
				break

			var is_structural = false
			for tag in structural_tags:
				if tag in current_line:
					is_structural = true
					break

			if is_structural:
				consecutive_empty_count = 0
				cleaned_bbcode += current_line + "\n"
				continue

			var text_without_tags = tag_rx.sub(current_line, "", true)

			if alpha_rx.search(text_without_tags) == null:
				consecutive_empty_count += 1
				if consecutive_empty_count >= 2:
					continue
			else:
				consecutive_empty_count = 0

			cleaned_bbcode += current_line + "\n"

		return cleaned_bbcode
