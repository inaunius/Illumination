class_name DataSaveLoad
extends Node



const SETTINGS_NAME = "Settings"
const SETTINGS_PATH = "user://Settings/"
const FULL_SETTINGS_PATH =  SETTINGS_PATH + SETTINGS_NAME + FILE_EXTENSION 

const SAVES_PATH = "user://Saves/"
const FILE_EXTENSION = ".tres"

@export var _level_parent : Node 
@export var _level_loader : LevelLoader

var _savables : Array[Node]
var _save_readers : Array[Node]


func _ready():
	_level_loader.loading_finished.connect(
		func():
			_update_savables()
			_update_save_readers())	
	
	DirAccess.make_dir_absolute(SAVES_PATH)
	DirAccess.make_dir_absolute(SETTINGS_PATH)

func save_current_data():
	_update_savables()
	var saved_data =  SavedData.new() 
	var all_pulled_data : Dictionary
	
	for node in _savables:
		var pulled_data : Resource = node.on_save_data()
		var data_key : String = node.DATA_KEY
		
		all_pulled_data[data_key] = pulled_data
	
	saved_data.level_name = _level_loader.get_active_level_name()
	saved_data.data = all_pulled_data
	saved_data.name = _compose_save_name()
	
	var save_full_path : String = _get_full_save_path_by_name(saved_data.name)
	print(save_full_path)
	ResourceSaver.save(saved_data, save_full_path)	

func load_data(save_name: String):
	_update_save_readers()
	var full_save_path = _get_full_save_path_by_name(save_name)

	if !ResourceLoader.exists(full_save_path):
		printerr("Save with the name %s name doesn't exist!" % save_name)
		return
	
	var loaded_save = ResourceLoader.load(full_save_path) as SavedData
	
	var active_level_name = _level_loader.get_active_level_name()
	var save_level_name = loaded_save.level_name 
	if save_level_name != active_level_name:
		printerr("The save \"%s\" is not for the active level \"%s\", it's for \"%s\"!" % [active_level_name, loaded_save.level_name])
	
	print(len(_save_readers))
	for node in _save_readers:
		node.on_load_data(loaded_save.data[node.DATA_KEY])


func delete_save(name: String):
	DirAccess.remove_absolute(_get_full_save_path_by_name(name))
	
func get_all_saves() -> Array[SavedData]:
	var all_saves : Array[SavedData]
	var save_dir = DirAccess.open(SAVES_PATH)
	
	for file in save_dir.get_files():
		if file.contains(FILE_EXTENSION):
			var save_full_path = SAVES_PATH + file
			var save = ResourceLoader.load(save_full_path) as SavedData
			all_saves.append(save)
			
	return all_saves

	save_dir.list_dir_end()

func load_settings() -> SettingsData:
	if ResourceLoader.exists(FULL_SETTINGS_PATH):
		return ResourceLoader.load(FULL_SETTINGS_PATH)
	else:
		ResourceSaver.save(SettingsData.new(), FULL_SETTINGS_PATH)
		return null

func save_settings(settings: SettingsData):
	print(FULL_SETTINGS_PATH)
	ResourceSaver.save(settings, FULL_SETTINGS_PATH)

func _update_savables():
	_savables = []
	for node in _get_all_children(_level_parent):
		if node.has_method("on_save_data") && "DATA_KEY" in node:
			_savables.append(node)
			print(node.name + "ADDED TO SAVABLES")
	
func _update_save_readers():
	_save_readers = []
	for node in _get_all_children(_level_parent):
		if node.has_method("on_load_data") && "DATA_KEY" in node:
			_save_readers.append(node)
			print(node.name + "ADDED TO SAVE READERS")

func _get_full_save_path_by_name(name: String) -> String:
	return SAVES_PATH + name + FILE_EXTENSION

func _compose_save_name() -> String:
	var save_number : int = 1
	
	while (ResourceLoader.exists(_get_full_save_path_by_name(str(save_number)))):
		save_number += 1
		
	return str(save_number)
	
func _get_all_children(node: Node) -> Array[Node]:
	var children : Array[Node]
	
	for child in node.get_children():
		children.append(child)
		children.append_array(_get_all_children(child))
		
	return children
		
