import re

file_path = "/home/abim/Documents/arkeolog/src/entities/player/player.tscn"

with open(file_path, "r") as f:
    content = f.read()

# Define idle_scythe and walk_scythe animations
idle_scythe_text = """[sub_resource type="Animation" id="Animation_idle_scythe"]
resource_name = "idle_scythe"
length = 1.6
loop_mode = 1
tracks/0/type = "value"
tracks/0/imported = false
tracks/0/enabled = true
tracks/0/path = NodePath("Visual/Badan:position")
tracks/0/interp = 2
tracks/0/loop_wrap = true
tracks/0/keys = {
"times": PackedFloat32Array(0, 0.8, 1.6),
"transitions": PackedFloat32Array(1, 1, 1),
"update": 0,
"values": [Vector2(0, 0), Vector2(0, 2), Vector2(0, 0)]
}
tracks/1/type = "value"
tracks/1/imported = false
tracks/1/enabled = true
tracks/1/path = NodePath("Visual/Kepala:position")
tracks/1/interp = 2
tracks/1/loop_wrap = true
tracks/1/keys = {
"times": PackedFloat32Array(0, 0.8, 1.6),
"transitions": PackedFloat32Array(1, 1, 1),
"update": 0,
"values": [Vector2(0, 0), Vector2(0, 4), Vector2(0, 0)]
}
tracks/2/type = "value"
tracks/2/imported = false
tracks/2/enabled = true
tracks/2/path = NodePath("Visual/Topi:position")
tracks/2/interp = 2
tracks/2/loop_wrap = true
tracks/2/keys = {
"times": PackedFloat32Array(0, 0.8, 1.6),
"transitions": PackedFloat32Array(1, 1, 1),
"update": 0,
"values": [Vector2(0, 0), Vector2(0, 4.5), Vector2(0, 0)]
}
tracks/3/type = "value"
tracks/3/imported = false
tracks/3/enabled = true
tracks/3/path = NodePath("Visual/Badan/HandL:position")
tracks/3/interp = 1
tracks/3/loop_wrap = true
tracks/3/keys = {
"times": PackedFloat32Array(0, 1.6),
"transitions": PackedFloat32Array(1, 1),
"update": 0,
"values": [Vector2(-100.195, -116.895), Vector2(-100.195, -116.895)]
}
tracks/4/type = "value"
tracks/4/imported = false
tracks/4/enabled = true
tracks/4/path = NodePath("Visual/Badan/HandR:position")
tracks/4/interp = 1
tracks/4/loop_wrap = true
tracks/4/keys = {
"times": PackedFloat32Array(0, 1.6),
"transitions": PackedFloat32Array(1, 1),
"update": 0,
"values": [Vector2(-131, -155.105), Vector2(-131, -155.105)]
}
tracks/5/type = "value"
tracks/5/imported = false
tracks/5/enabled = true
tracks/5/path = NodePath("Visual/Badan/HandL:rotation")
tracks/5/interp = 1
tracks/5/loop_wrap = true
tracks/5/keys = {
"times": PackedFloat32Array(0, 1.6),
"transitions": PackedFloat32Array(1, 1),
"update": 0,
"values": [0.0, 0.0]
}
tracks/6/type = "value"
tracks/6/imported = false
tracks/6/enabled = true
tracks/6/path = NodePath("Visual/Badan/HandR:rotation")
tracks/6/interp = 1
tracks/6/loop_wrap = true
tracks/6/keys = {
"times": PackedFloat32Array(0, 1.6),
"transitions": PackedFloat32Array(1, 1),
"update": 0,
"values": [0.0, 0.0]
}
"""

walk_scythe_text = """[sub_resource type="Animation" id="Animation_walk_scythe"]
resource_name = "walk_scythe"
length = 0.5
loop_mode = 1
tracks/0/type = "value"
tracks/0/imported = false
tracks/0/enabled = true
tracks/0/path = NodePath("Visual/KakiKiri:position")
tracks/0/interp = 2
tracks/0/loop_wrap = true
tracks/0/keys = {
"times": PackedFloat32Array(0, 0.125, 0.25, 0.375, 0.5),
"transitions": PackedFloat32Array(1, 1, 1, 1, 1),
"update": 0,
"values": [Vector2(-126, -123), Vector2(-126, -130), Vector2(-126, -123), Vector2(-126, -123), Vector2(-126, -123)]
}
tracks/1/type = "value"
tracks/1/imported = false
tracks/1/enabled = true
tracks/1/path = NodePath("Visual/KakiKanan:position")
tracks/1/interp = 2
tracks/1/loop_wrap = true
tracks/1/keys = {
"times": PackedFloat32Array(0, 0.125, 0.25, 0.375, 0.5),
"transitions": PackedFloat32Array(1, 1, 1, 1, 1),
"update": 0,
"values": [Vector2(-129, -125), Vector2(-129, -125), Vector2(-129, -125), Vector2(-129, -132), Vector2(-129, -125)]
}
tracks/2/type = "value"
tracks/2/imported = false
tracks/2/enabled = true
tracks/2/path = NodePath("Visual/Badan:position")
tracks/2/interp = 2
tracks/2/loop_wrap = true
tracks/2/keys = {
"times": PackedFloat32Array(0, 0.125, 0.25, 0.375, 0.5),
"transitions": PackedFloat32Array(1, 1, 1, 1, 1),
"update": 0,
"values": [Vector2(0, 0), Vector2(0, 3), Vector2(0, 0), Vector2(0, 3), Vector2(0, 0)]
}
tracks/3/type = "value"
tracks/3/imported = false
tracks/3/enabled = true
tracks/3/path = NodePath("Visual/Kepala:position")
tracks/3/interp = 2
tracks/3/loop_wrap = true
tracks/3/keys = {
"times": PackedFloat32Array(0, 0.125, 0.25, 0.375, 0.5),
"transitions": PackedFloat32Array(1, 1, 1, 1, 1),
"update": 0,
"values": [Vector2(0, 0), Vector2(0, 4.5), Vector2(0, 0), Vector2(0, 4.5), Vector2(0, 0)]
}
tracks/4/type = "value"
tracks/4/imported = false
tracks/4/enabled = true
tracks/4/path = NodePath("Visual/Topi:position")
tracks/4/interp = 2
tracks/4/loop_wrap = true
tracks/4/keys = {
"times": PackedFloat32Array(0, 0.125, 0.25, 0.375, 0.5),
"transitions": PackedFloat32Array(1, 1, 1, 1, 1),
"update": 0,
"values": [Vector2(0, 0), Vector2(0, 5.5), Vector2(0, 0), Vector2(0, 5.5), Vector2(0, 0)]
}
tracks/5/type = "value"
tracks/5/imported = false
tracks/5/enabled = true
tracks/5/path = NodePath("Visual/Badan/HandL:position")
tracks/5/interp = 1
tracks/5/loop_wrap = true
tracks/5/keys = {
"times": PackedFloat32Array(0, 0.5),
"transitions": PackedFloat32Array(1, 1),
"update": 0,
"values": [Vector2(-100.195, -116.895), Vector2(-100.195, -116.895)]
}
tracks/6/type = "value"
tracks/6/imported = false
tracks/6/enabled = true
tracks/6/path = NodePath("Visual/Badan/HandR:position")
tracks/6/interp = 1
tracks/6/loop_wrap = true
tracks/6/keys = {
"times": PackedFloat32Array(0, 0.5),
"transitions": PackedFloat32Array(1, 1),
"update": 0,
"values": [Vector2(-131, -155.105), Vector2(-131, -155.105)]
}
tracks/7/type = "value"
tracks/7/imported = false
tracks/7/enabled = true
tracks/7/path = NodePath("Visual/Badan/HandL:rotation")
tracks/7/interp = 1
tracks/7/loop_wrap = true
tracks/7/keys = {
"times": PackedFloat32Array(0, 0.5),
"transitions": PackedFloat32Array(1, 1),
"update": 0,
"values": [0.0, 0.0]
}
tracks/8/type = "value"
tracks/8/imported = false
tracks/8/enabled = true
tracks/8/path = NodePath("Visual/Badan/HandR:rotation")
tracks/8/interp = 1
tracks/8/loop_wrap = true
tracks/8/keys = {
"times": PackedFloat32Array(0, 0.5),
"transitions": PackedFloat32Array(1, 1),
"update": 0,
"values": [0.0, 0.0]
}
tracks/9/type = "value"
tracks/9/imported = false
tracks/9/enabled = true
tracks/9/path = NodePath("Visual/Tas:position")
tracks/9/interp = 2
tracks/9/loop_wrap = true
tracks/9/keys = {
"times": PackedFloat32Array(0, 0.125, 0.25, 0.375, 0.5),
"transitions": PackedFloat32Array(1, 1, 1, 1, 1),
"update": 0,
"values": [Vector2(0, 0), Vector2(-2, 4), Vector2(0, 0), Vector2(2, 4), Vector2(0, 0)]
}
tracks/10/type = "value"
tracks/10/imported = false
tracks/10/enabled = true
tracks/10/path = NodePath("Visual/Tas:rotation")
tracks/10/interp = 2
tracks/10/loop_wrap = true
tracks/10/keys = {
"times": PackedFloat32Array(0, 0.125, 0.25, 0.375, 0.5),
"transitions": PackedFloat32Array(1, 1, 1, 1, 1),
"update": 0,
"values": [0.0, -0.06, 0.0, 0.06, 0.0]
}
tracks/11/type = "value"
tracks/11/imported = false
tracks/11/enabled = true
tracks/11/path = NodePath("Visual/Topi:rotation")
tracks/11/interp = 2
tracks/11/loop_wrap = true
tracks/11/keys = {
"times": PackedFloat32Array(0, 0.125, 0.25, 0.375, 0.5),
"transitions": PackedFloat32Array(1, 1, 1, 1, 1),
"update": 0,
"values": [0.0, 0.06, 0.0, -0.06, 0.0]
}
"""

# Insert idle_scythe and walk_scythe sub-resources before AnimationLibrary
library_index = content.find('[sub_resource type="AnimationLibrary" id="AnimationLibrary_player"]')
if library_index != -1:
    content = content[:library_index] + idle_scythe_text + "\n" + walk_scythe_text + "\n" + content[library_index:]

# Now update the library dictionary to register idle_scythe and walk_scythe
library_pattern = r'(&"idle_shovel": SubResource\("Animation_idle_shovel"\),)'
content = content.replace(
    '&"idle_shovel": SubResource("Animation_idle_shovel"),',
    '&"idle_scythe": SubResource("Animation_idle_scythe"),\n&"idle_shovel": SubResource("Animation_idle_shovel"),'
)

content = content.replace(
    '&"walk": SubResource("Animation_walk"),',
    '&"walk": SubResource("Animation_walk"),\n&"walk_scythe": SubResource("Animation_walk_scythe"),'
)

with open(file_path, "w") as f:
    f.write(content)

print("SUCCESS: Added idle_scythe and walk_scythe to player.tscn!")
