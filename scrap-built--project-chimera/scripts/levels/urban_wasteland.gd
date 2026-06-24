extends Node2D

## Urban Wasteland — Level 1
## Post-apocalyptic urban combat zone with ruined walls and enemy ambushes.
## Tiles, collision, and navigation are built procedurally in _ready().

const TILE_SIZE := 16

# Level bounds (tile coordinates)
const LV_LEFT   := 0
const LV_RIGHT  := 14
const LV_TOP    := -11
const LV_BOTTOM := 0

@onready var nav_region  : NavigationRegion2D = $NavigationRegion2D
@onready var floor_layer : TileMapLayer = $NavigationRegion2D/Floor
@onready var wall_layer  : TileMapLayer = $NavigationRegion2D/Walls

# Internal wall obstacles — {p = tile_pos, s = tile_size}
var _obstacles := [
    {"p": Vector2i(5, -5), "s": Vector2i(5, 2)},    # Central horizontal barrier
    {"p": Vector2i(12, -9), "s": Vector2i(2, 2)},   # Right cover block
    {"p": Vector2i(2, -9), "s": Vector2i(3, 2)},    # Left ruins
]


# ── Lifecycle ──────────────────────────────────────────────────────────

func _ready() -> void:
    _create_tilesets()
    _generate_floor()
    _generate_wall_visuals()
    _generate_scatter_decorations()
    _create_wall_collision()
    _create_navigation()


func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        get_tree().change_scene_to_file("res://scenes/levels/hub.tscn")


# ── TileSet Setup ─────────────────────────────────────────────────────

func _create_tilesets() -> void:
    var tex := load("res://assets/sprites/neo_zero/tileset.png") as Texture2D

    var src := TileSetAtlasSource.new()
    src.texture = tex
    src.texture_region_size = Vector2i(16, 16)

    # Floor tiles (row 0 of the tileset — ground variants)
    for x in range(12):
        src.create_tile(Vector2i(x, 0))

    # Wall edge/corner tiles used for border and obstacle visuals
    var wall_coords := [
        # Row 2 — accents
        Vector2i(6, 2), Vector2i(7, 2), Vector2i(14, 2), Vector2i(16, 2),
        # Row 3 — wall tops
        Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(5, 3),
        Vector2i(8, 3), Vector2i(14, 3), Vector2i(15, 3), Vector2i(16, 3),
        # Row 4 — wall middles
        Vector2i(1, 4), Vector2i(3, 4), Vector2i(5, 4), Vector2i(8, 4),
        Vector2i(14, 4), Vector2i(15, 4), Vector2i(16, 4),
        # Row 5 — wall bottoms
        Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5),
        Vector2i(6, 5), Vector2i(7, 5), Vector2i(14, 5), Vector2i(15, 5), Vector2i(16, 5),
        # Row 6 — detail
        Vector2i(6, 6), Vector2i(7, 6),
        # Rows 7-8 — structural / rubble
        Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7),
        Vector2i(5, 7), Vector2i(6, 7), Vector2i(7, 7),
        Vector2i(1, 8), Vector2i(2, 8), Vector2i(3, 8), Vector2i(4, 8),
        Vector2i(6, 8), Vector2i(7, 8),
    ]

    for coord in wall_coords:
        if not src.has_tile(coord):
            src.create_tile(coord)

    var ts := TileSet.new()
    ts.tile_size = Vector2i(16, 16)
    ts.add_source(src)

    floor_layer.tile_set = ts
    wall_layer.tile_set = ts


# ── Floor Generation ──────────────────────────────────────────────────

func _generate_floor() -> void:
    for x in range(LV_LEFT, LV_RIGHT + 1):
        for y in range(LV_TOP, LV_BOTTOM + 1):
            if _point_in_obstacle(x, y):
                continue
            floor_layer.set_cell(Vector2i(x, y), 0, _pick_floor_tile(x, y))


func _pick_floor_tile(x: int, y: int) -> Vector2i:
    # Deterministic pseudo-random selection among 12 ground tile variants
    var h := absi((x * 7 + y * 13 + (x * y) * 3) % 12)
    return Vector2i(h, 0)


func _point_in_obstacle(x: int, y: int) -> bool:
    for obs in _obstacles:
        var p: Vector2i = obs["p"]
        var s: Vector2i = obs["s"]
        if x >= p.x and x < p.x + s.x and y >= p.y and y < p.y + s.y:
            return true
    return false


# ── Wall Visual Generation ────────────────────────────────────────────

func _generate_wall_visuals() -> void:
    _draw_border()
    for obs in _obstacles:
        _draw_wall_block(obs["p"], obs["s"])


func _draw_border() -> void:
    # Top & bottom full rows
    for x in range(LV_LEFT - 1, LV_RIGHT + 2):
        wall_layer.set_cell(Vector2i(x, LV_TOP - 1), 0, Vector2i(2, 3))
        wall_layer.set_cell(Vector2i(x, LV_BOTTOM + 1), 0, Vector2i(2, 5))

    # Left & right columns
    for y in range(LV_TOP, LV_BOTTOM + 1):
        wall_layer.set_cell(Vector2i(LV_LEFT - 1, y), 0, Vector2i(1, 4))
        wall_layer.set_cell(Vector2i(LV_RIGHT + 1, y), 0, Vector2i(3, 4))

    # Corners
    wall_layer.set_cell(Vector2i(LV_LEFT - 1,  LV_TOP - 1),    0, Vector2i(1, 3))
    wall_layer.set_cell(Vector2i(LV_RIGHT + 1, LV_TOP - 1),    0, Vector2i(3, 3))
    wall_layer.set_cell(Vector2i(LV_LEFT - 1,  LV_BOTTOM + 1), 0, Vector2i(1, 5))
    wall_layer.set_cell(Vector2i(LV_RIGHT + 1, LV_BOTTOM + 1), 0, Vector2i(3, 5))


func _draw_wall_block(pos: Vector2i, size: Vector2i) -> void:
    for lx in range(size.x):
        for ly in range(size.y):
            var coord := Vector2i(pos.x + lx, pos.y + ly)
            var top := (ly == 0)
            var bot := (ly == size.y - 1)
            var lft := (lx == 0)
            var rgt := (lx == size.x - 1)

            var tile: Vector2i
            if   top and lft: tile = Vector2i(1, 3)
            elif top and rgt: tile = Vector2i(3, 3)
            elif top:         tile = Vector2i(2, 3)
            elif bot and lft: tile = Vector2i(1, 5)
            elif bot and rgt: tile = Vector2i(3, 5)
            elif bot:         tile = Vector2i(2, 5)
            elif lft:         tile = Vector2i(1, 4)
            elif rgt:         tile = Vector2i(3, 4)
            else:             tile = Vector2i(2, 3)

            wall_layer.set_cell(coord, 0, tile)


# ── Scatter Decorations ───────────────────────────────────────────────

func _generate_scatter_decorations() -> void:
    # Add rubble/detail tiles for visual variety
    var scatter_tiles: Array[Vector2i] = [
        Vector2i(4, 7), Vector2i(5, 7), Vector2i(6, 7), Vector2i(7, 7),
        Vector2i(1, 8), Vector2i(3, 8), Vector2i(6, 8),
    ]

    # Deterministic scatter pattern
    var scatter_positions: Array[Vector2i] = [
        Vector2i(1, -2), Vector2i(8, -3), Vector2i(11, -1),
        Vector2i(3, -4), Vector2i(13, -4), Vector2i(7, -8),
        Vector2i(1, -7), Vector2i(10, -10), Vector2i(6, -10),
        Vector2i(14, -7), Vector2i(9, -2), Vector2i(0, -5),
        Vector2i(11, -5), Vector2i(4, -1), Vector2i(8, -10),
    ]

    for i in range(scatter_positions.size()):
        var pos: Vector2i = scatter_positions[i]
        if not _point_in_obstacle(pos.x, pos.y):
            var tile: Vector2i = scatter_tiles[i % scatter_tiles.size()]
            wall_layer.set_cell(pos, 0, tile)


# ── Physics Collision ─────────────────────────────────────────────────

func _create_wall_collision() -> void:
    var body := $WallCollision as StaticBody2D

    # Pixel bounds of the playable floor
    var px_l := float(LV_LEFT * TILE_SIZE)
    var px_r := float((LV_RIGHT + 1) * TILE_SIZE)
    var px_t := float(LV_TOP * TILE_SIZE)
    var px_b := float((LV_BOTTOM + 1) * TILE_SIZE)
    var cx   := (px_l + px_r) / 2.0
    var cy   := (px_t + px_b) / 2.0
    var w    := px_r - px_l
    var h    := px_b - px_t

    # Border collision rectangles
    _add_rect(body, Vector2(cx, px_t - 8),  Vector2(w + 32, 16))   # top
    _add_rect(body, Vector2(cx, px_b + 8),  Vector2(w + 32, 16))   # bottom
    _add_rect(body, Vector2(px_l - 8, cy),  Vector2(16, h + 32))   # left
    _add_rect(body, Vector2(px_r + 8, cy),  Vector2(16, h + 32))   # right

    # Internal obstacle collision
    for obs in _obstacles:
        var op: Vector2i = obs["p"]
        var os: Vector2i = obs["s"]
        var ox := float(op.x * TILE_SIZE)
        var oy := float(op.y * TILE_SIZE)
        var ow := float(os.x * TILE_SIZE)
        var oh := float(os.y * TILE_SIZE)
        _add_rect(body, Vector2(ox + ow / 2.0, oy + oh / 2.0), Vector2(ow, oh))


func _add_rect(body: StaticBody2D, pos: Vector2, size: Vector2) -> void:
    var shape := RectangleShape2D.new()
    shape.size = size
    var col := CollisionShape2D.new()
    col.shape = shape
    col.position = pos
    body.add_child(col)


# ── Navigation ────────────────────────────────────────────────────────

func _create_navigation() -> void:
    var nav_poly := NavigationPolygon.new()

    var px_l := float(LV_LEFT * TILE_SIZE)
    var px_r := float((LV_RIGHT + 1) * TILE_SIZE)
    var px_t := float(LV_TOP * TILE_SIZE)
    var px_b := float((LV_BOTTOM + 1) * TILE_SIZE)

    # Outer walkable boundary (clockwise)
    nav_poly.add_outline(PackedVector2Array([
        Vector2(px_l, px_t), Vector2(px_r, px_t),
        Vector2(px_r, px_b), Vector2(px_l, px_b)
    ]))

    # Obstacle holes (counter-clockwise winding)
    for obs in _obstacles:
        var op: Vector2i = obs["p"]
        var os: Vector2i = obs["s"]
        var ox := float(op.x * TILE_SIZE)
        var oy := float(op.y * TILE_SIZE)
        var ow := float(os.x * TILE_SIZE)
        var oh := float(os.y * TILE_SIZE)
        nav_poly.add_outline(PackedVector2Array([
            Vector2(ox, oy),      Vector2(ox, oy + oh),
            Vector2(ox + ow, oy + oh), Vector2(ox + ow, oy)
        ]))

    nav_poly.make_polygons_from_outlines()
    nav_region.navigation_polygon = nav_poly
