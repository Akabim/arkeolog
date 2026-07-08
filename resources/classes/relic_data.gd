extends Resource
class_name RelicData

@export var relic_id: String = "stone_1"
@export var relic_name: String = "Prasasti Sukabumi"

@export_category("Textures")
@export var base_texture: Texture2D
@export var writing_texture: Texture2D
@export var dirt_texture: Texture2D
@export var rocks: Array[RockData] = []

@export_category("Translation & Clues")
@export var inscription: String = "aksara kuno..."
@export var translation: String = "Utusan kehormatan..."
@export var clue: String = "Utara / Atas"
@export var decipher_options: Array[String] = []
