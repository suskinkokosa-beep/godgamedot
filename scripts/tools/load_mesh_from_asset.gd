extends MeshInstance3D
@export var mesh_path: String = ""

func _ready():
    if mesh_path == "":
        return
    var res = ResourceLoader.load(mesh_path)
    if res:
        mesh = res
