extends Node2D

# Hız kahramanı esintili maymun; variant renkleri, dikenleri ve ayakkabıları belirler.
# Tamamı kodla çizilir; koordinatlar gövdeye göredir ve yüz sağa bakar.

enum Pose { STANDING, WRITING }

const INK := Color("#0f172a")
const SKIN := Color("#fde2b8")
const WHITE := Color("#ffffff")
const BANDANA := Color("#ef4444")
const PAPER := Color("#f8fafc")
const PAPER_LINE := Color("#94a3b8")
const COVER := Color("#7c3aed")
const PENCIL := Color("#fbbf24")

const OUTLINE := 3.0
const ELLIPSE_POINTS := 24
const QUILLS: Array[Vector2] = [
	Vector2(16, -26), Vector2(-14, -60), Vector2(-12, -32), Vector2(-50, -46), Vector2(-27, -15),
	Vector2(-64, -12), Vector2(-31, 3), Vector2(-56, 26), Vector2(-22, 21), Vector2(4, 12),
]
# Dread'ler ayrı parçalardır; başın arkasından aşağı sarkar.
const DREAD_CAP: Array[Vector2] = [
	Vector2(20, -24), Vector2(-4, -36), Vector2(-28, -26), Vector2(-38, -2), Vector2(-26, 14), Vector2(4, 8),
]
# x, y: başlangıç; z, w: uç.
const DREADS: Array[Vector4] = [
	Vector4(-20, -22, -48, 8), Vector4(-28, -10, -54, 26), Vector4(-26, 2, -46, 44), Vector4(-16, 14, -28, 50),
]
const DREAD_WIDTH := 13.0
const TUFT: Array[Vector2] = [
	Vector2(18, -22), Vector2(14, -48), Vector2(2, -32), Vector2(-12, -52), Vector2(-14, -30),
	Vector2(-34, -38), Vector2(-26, -14), Vector2(-14, 12), Vector2(6, 6),
]
const UP_SPIKES: Array[Vector2] = [
	Vector2(22, -22), Vector2(16, -62), Vector2(2, -34), Vector2(-10, -70), Vector2(-14, -34),
	Vector2(-34, -58), Vector2(-30, -20), Vector2(-22, 10), Vector2(10, 0),
]
const SPIKE_STRIPES: Array[Vector4] = [
	Vector4(15, -56, 11, -36), Vector4(-9, -62, -7, -38), Vector4(-31, -52, -24, -32),
]
const SPIKE_STRIPE_WIDTH := 4.0
const FLAME_SPIKES: Array[Vector2] = [
	Vector2(24, -20), Vector2(26, -58), Vector2(10, -36), Vector2(4, -82), Vector2(-10, -40),
	Vector2(-26, -72), Vector2(-28, -32), Vector2(-48, -46), Vector2(-32, -6), Vector2(-18, 12), Vector2(10, 4),
]
const FLAME_TIPS: Array[int] = [1, 3, 5, 7]
const FLAME_FLICKER := 4.0
const FLAME_SPEED := 9.0
const AURA_CENTER := Vector2(0, -22)
const AURA_RADII: Array[float] = [96.0, 80.0, 66.0]
const AURA_COLOR := Color(1.0, 0.82, 0.2, 0.16)
const AURA_PULSE := 5.0
const AURA_SPEED := 3.0
const TWIN_TAIL_WIDTH := 13.0
const TWIN_TAIL_SPREAD := 0.42
const TWIN_TAIL_SWAY := 0.12
const TWIN_TAIL_SPEED := 5.0
const HOVER_JET_COLOR := Color("#f97316")
const HOVER_JET_LENGTH := 10.0
const HOVER_JET_FLICKER := 4.0
const HOVER_JET_SPEED := 14.0

const DEFAULT_VARIANT := "sonic"
const VARIANTS := {
	"sonic": {
		"fur": Color("#2563eb"), "fur_dark": Color("#1d4ed8"), "iris": Color("#16a34a"), "brow": INK,
		"shoe": Color("#dc2626"), "strap": WHITE, "buckle": Color("#facc15"), "sole": WHITE,
		"quills": QUILLS, "bandana": true,
	},
	"knuckles": {
		"fur": Color("#dc2626"), "fur_dark": Color("#b91c1c"), "iris": Color("#7c3aed"), "brow": INK,
		"shoe": Color("#facc15"), "strap": Color("#22c55e"), "buckle": WHITE, "sole": Color("#15803d"),
		"quills": DREAD_CAP, "bandana": false,
	},
	"tails": {
		"fur": Color("#fbbf24"), "fur_dark": Color("#f97316"), "iris": Color("#0284c7"), "brow": INK,
		"shoe": Color("#dc2626"), "strap": WHITE, "buckle": Color("#facc15"), "sole": WHITE,
		"quills": TUFT, "bandana": false,
	},
	"shadow": {
		"fur": Color("#27272a"), "fur_dark": Color("#18181b"), "iris": Color("#dc2626"), "brow": Color("#ef4444"),
		"shoe": WHITE, "strap": Color("#dc2626"), "buckle": Color("#facc15"), "sole": Color("#dc2626"),
		"quills": UP_SPIKES, "bandana": false,
	},
	"super": {
		"fur": Color("#fde047"), "fur_dark": Color("#f59e0b"), "iris": Color("#be123c"), "brow": INK,
		"shoe": Color("#dc2626"), "strap": WHITE, "buckle": Color("#facc15"), "sole": WHITE,
		"quills": FLAME_SPIKES, "bandana": false,
	},
}

const WRITE_SPEED := 9.0
const WRITE_REACH := 4.0
const BREATH_SPEED := 2.4
const BREATH_AMOUNT := 0.028
# Nefes ve esneme ayak hizasına göre yapılır; ayakkabılar yerde kalır.
const FEET_Y := 62.0
const BLINK_SECONDS := 0.13
const BLINK_MIN_GAP := 2.0
const BLINK_MAX_GAP := 5.5
const HOP_HEIGHT := 48.0
const HOP_SECONDS := 0.17
const SQUASH_SCALE := Vector2(1.18, 0.82)
const STRETCH_SCALE := Vector2(0.88, 1.14)
const SETTLE_SECONDS := 0.35

@export var pose := Pose.STANDING:
	set(value):
		pose = value
		queue_redraw()

@export var variant := DEFAULT_VARIANT:
	set(value):
		variant = value if VARIANTS.has(value) else DEFAULT_VARIANT
		_look = VARIANTS[variant]
		queue_redraw()

var _look: Dictionary = VARIANTS[DEFAULT_VARIANT]
var _time := 0.0
var _next_blink := randf_range(BLINK_MIN_GAP, BLINK_MAX_GAP)
var _hop := 0.0
var _squash := Vector2.ONE
var _body := Transform2D.IDENTITY
var _bounce_tween: Tween

var writing := false:
	set(value):
		writing = value
		queue_redraw()


func _init(initial_variant := DEFAULT_VARIANT) -> void:
	variant = initial_variant


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	_next_blink -= delta
	if _next_blink <= 0.0:
		_next_blink = randf_range(BLINK_MIN_GAP, BLINK_MAX_GAP)
	queue_redraw()


func play_bounce() -> void:
	if _bounce_tween:
		_bounce_tween.kill()
	_hop = 0.0
	_bounce_tween = create_tween()
	_bounce_tween.tween_property(self, "_hop", -HOP_HEIGHT, HOP_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_bounce_tween.parallel().tween_property(self, "_squash", STRETCH_SCALE, HOP_SECONDS)
	_bounce_tween.tween_property(self, "_hop", 0.0, HOP_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_bounce_tween.tween_property(self, "_squash", SQUASH_SCALE, HOP_SECONDS / 2.0)
	_bounce_tween.tween_property(self, "_squash", Vector2.ONE, SETTLE_SECONDS).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# Kendi scale değeri yerleşimi kuran sahnelere aittir; esneme yalnızca çizime uygulanır.
func _body_transform() -> Transform2D:
	var breath := sin(_time * BREATH_SPEED) * BREATH_AMOUNT
	var stretch := _squash * Vector2(1.0 - breath, 1.0 + breath)
	return Transform2D(0.0, stretch, 0.0, Vector2(0.0, FEET_Y * (1.0 - stretch.y) + _hop))


func _draw() -> void:
	_body = _body_transform()
	draw_set_transform_matrix(_body)
	if variant == "super":
		_draw_aura()
	if pose == Pose.WRITING:
		_draw_writing()
	else:
		_draw_standing()


func _draw_standing() -> void:
	_draw_tail(PackedVector2Array([Vector2(-12, 16), Vector2(-34, 22), Vector2(-48, 8), Vector2(-42, -8), Vector2(-30, -6)]))
	_draw_limb(Vector2(-9, 22), Vector2(-15, 44), 15.0, _look.fur_dark)
	_draw_limb(Vector2(9, 22), Vector2(15, 44), 15.0, _look.fur)
	_draw_sneaker(Vector2(-16, 47))
	_draw_sneaker(Vector2(14, 47))
	_draw_limb(Vector2(-25, -8), Vector2(-40, 12), 15.0, _look.fur_dark)
	_draw_limb(Vector2(-40, 12), Vector2(-31, 26), 13.0, _look.fur_dark)
	_shape(_ellipse(Vector2(-31, 28), Vector2(9, 9)), WHITE)
	_draw_torso(PackedVector2Array([Vector2(-28, -18), Vector2(28, -18), Vector2(14, 26), Vector2(-14, 26)]), Vector2(0, -2))
	# Kaldırılmış kol kasları gösterir.
	_draw_limb(Vector2(25, -8), Vector2(46, -10), 17.0, _look.fur)
	_draw_limb(Vector2(46, -10), Vector2(44, -34), 14.0, _look.fur)
	_shape(_ellipse(Vector2(36, -13), Vector2(11, 8)), _look.fur_dark)
	_shape(_ellipse(Vector2(44, -38), Vector2(10, 10)), WHITE)
	_draw_head(Vector2(0, -46), 0.0)


func _draw_writing() -> void:
	var stroke := sin(_time * WRITE_SPEED) * WRITE_REACH if writing else 0.0
	_draw_tail(PackedVector2Array([Vector2(-20, -6), Vector2(-46, -6), Vector2(-62, -22), Vector2(-54, -38), Vector2(-42, -34)]))
	# Arkadaki bacak ve defteri tutan kol.
	_draw_limb(Vector2(0, -8), Vector2(58, -16), 16.0, _look.fur_dark)
	_draw_limb(Vector2(58, -16), Vector2(70, 32), 14.0, _look.fur_dark)
	_draw_sneaker(Vector2(72, 36))
	_draw_limb(Vector2(16, -50), Vector2(50, -36), 12.0, _look.fur_dark)
	_draw_torso(PackedVector2Array([Vector2(-24, -4), Vector2(16, -4), Vector2(26, -56), Vector2(-20, -60)]), Vector2(6, -32))
	# Öndeki bacak.
	_draw_limb(Vector2(-4, -6), Vector2(40, -12), 18.0, _look.fur)
	_draw_limb(Vector2(40, -12), Vector2(38, 34), 15.0, _look.fur)
	_draw_sneaker(Vector2(38, 38))
	_draw_notebook(stroke)
	# Yazan kol.
	var hand := Vector2(40 + stroke, -40)
	_draw_limb(Vector2(4, -48), Vector2(14, -24), 15.0, _look.fur)
	_shape(_ellipse(Vector2(7, -38), Vector2(9, 12)), _look.fur_dark)
	_draw_limb(Vector2(14, -24), hand, 13.0, _look.fur)
	_draw_pencil(hand)
	_shape(_ellipse(hand, Vector2(9, 9)), WHITE)
	_draw_head(Vector2(10, -88), 0.16)


func _draw_torso(points: PackedVector2Array, chest: Vector2) -> void:
	_shape(points, _look.fur)
	_shape(_ellipse(chest + Vector2(-9, -3), Vector2(10, 9)), SKIN)
	_shape(_ellipse(chest + Vector2(9, -3), Vector2(10, 9)), SKIN)
	_shape(_ellipse(chest + Vector2(0, 15), Vector2(10, 10)), SKIN)


func _draw_head(center: Vector2, tilt: float) -> void:
	draw_set_transform_matrix(_body * Transform2D(tilt, center))
	if _look.bandana:
		_draw_bandana_tails()
	_draw_quills()
	_shape(_ellipse(Vector2(-29, 2), Vector2(12, 12)), _look.fur)
	_shape(_ellipse(Vector2(-29, 2), Vector2(6, 6)), SKIN)
	_shape(_ellipse(Vector2.ZERO, Vector2(30, 30)), _look.fur)
	_shape(_ellipse(Vector2(29, 0), Vector2(9, 11)), _look.fur)
	_shape(_ellipse(Vector2(29, 0), Vector2(4, 6)), SKIN)
	_shape(_ellipse(Vector2(8, 12), Vector2(19, 14)), SKIN)
	_draw_eyes()
	# Kararlı bakış: içe doğru inen kaşlar.
	draw_line(Vector2(-9, -15), Vector2(9, -9), _look.brow, 4.0, true)
	draw_line(Vector2(27, -15), Vector2(11, -9), _look.brow, 4.0, true)
	draw_circle(Vector2(12, 7), 3.0, INK, true, -1.0, true)
	draw_polyline(PackedVector2Array([Vector2(0, 17), Vector2(8, 20), Vector2(17, 18), Vector2(23, 13)]), INK, 2.5, true)
	if _look.bandana:
		_shape(PackedVector2Array([Vector2(-29, -13), Vector2(-16, -22), Vector2(4, -26), Vector2(26, -20), Vector2(29, -13), Vector2(5, -18), Vector2(-14, -15)]), BANDANA)
	draw_set_transform_matrix(_body)


func _draw_quills() -> void:
	if variant == "knuckles":
		for dread: Vector4 in DREADS:
			_draw_limb(Vector2(dread.x, dread.y), Vector2(dread.z, dread.w), DREAD_WIDTH, _look.fur_dark)
	var points := PackedVector2Array(_look.quills)
	if variant == "super":
		for tip: int in FLAME_TIPS:
			points[tip].x += sin(_time * FLAME_SPEED + tip) * FLAME_FLICKER
			points[tip].y += cos(_time * FLAME_SPEED * 1.3 + tip) * FLAME_FLICKER
	_shape(points, _look.fur_dark)
	if variant == "shadow":
		for stripe: Vector4 in SPIKE_STRIPES:
			draw_line(Vector2(stripe.x, stripe.y), Vector2(stripe.z, stripe.w), _look.strap, SPIKE_STRIPE_WIDTH, true)


func _draw_aura() -> void:
	var pulse := sin(_time * AURA_SPEED) * AURA_PULSE
	for radius: float in AURA_RADII:
		draw_circle(AURA_CENTER, radius + pulse, AURA_COLOR, true, -1.0, true)


func _draw_eyes() -> void:
	if _next_blink < BLINK_SECONDS:
		_shape(_ellipse(Vector2(1, -5), Vector2(10, 11)), _look.fur)
		_shape(_ellipse(Vector2(18, -5), Vector2(9, 11)), _look.fur)
		draw_line(Vector2(-7, -3), Vector2(9, -3), _look.brow, 3.0, true)
		draw_line(Vector2(11, -3), Vector2(25, -3), _look.brow, 3.0, true)
		return
	_shape(_ellipse(Vector2(1, -5), Vector2(10, 11)), WHITE)
	_shape(_ellipse(Vector2(18, -5), Vector2(9, 11)), WHITE)
	draw_circle(Vector2(5, -3), 4.5, _look.iris, true, -1.0, true)
	draw_circle(Vector2(21, -3), 4.5, _look.iris, true, -1.0, true)
	draw_circle(Vector2(6, -3), 2.2, INK, true, -1.0, true)
	draw_circle(Vector2(22, -3), 2.2, INK, true, -1.0, true)


func _draw_bandana_tails() -> void:
	var flutter := sin(_time * 4.0) * 2.0
	_shape(PackedVector2Array([Vector2(-28, -14), Vector2(-58, -30 + flutter), Vector2(-52, -14 + flutter), Vector2(-27, -8)]), BANDANA)


func _draw_tail(points: PackedVector2Array) -> void:
	if variant == "tails":
		var sway := sin(_time * TWIN_TAIL_SPEED) * TWIN_TAIL_SWAY
		_draw_fluffy_tail(points, -TWIN_TAIL_SPREAD + sway)
		_draw_fluffy_tail(points, TWIN_TAIL_SPREAD - sway)
		return
	draw_polyline(points, INK, 9.0 + OUTLINE * 2.0, true)
	draw_polyline(points, _look.fur_dark, 9.0, true)


func _draw_fluffy_tail(points: PackedVector2Array, angle: float) -> void:
	var turned := PackedVector2Array()
	for point: Vector2 in points:
		turned.append(points[0] + (point - points[0]).rotated(angle))
	draw_polyline(turned, INK, TWIN_TAIL_WIDTH + OUTLINE * 2.0, true)
	draw_polyline(turned, _look.fur_dark, TWIN_TAIL_WIDTH, true)
	_shape(_ellipse(turned[-1], Vector2(9, 9)), WHITE)


func _draw_limb(from: Vector2, to: Vector2, width: float, color: Color) -> void:
	var outer := width / 2.0 + OUTLINE
	draw_line(from, to, INK, outer * 2.0, true)
	draw_circle(from, outer, INK, true, -1.0, true)
	draw_circle(to, outer, INK, true, -1.0, true)
	draw_line(from, to, color, width, true)
	draw_circle(from, width / 2.0, color, true, -1.0, true)
	draw_circle(to, width / 2.0, color, true, -1.0, true)


func _draw_sneaker(ankle: Vector2) -> void:
	_shape(PackedVector2Array([ankle + Vector2(-13, -8), ankle + Vector2(8, -8), ankle + Vector2(26, 2), ankle + Vector2(32, 10), ankle + Vector2(-14, 10)]), _look.shoe)
	_shape(PackedVector2Array([ankle + Vector2(-1, -8), ankle + Vector2(8, -8), ankle + Vector2(14, -4), ankle + Vector2(6, 9), ankle + Vector2(-5, 9)]), _look.strap)
	_shape(_ellipse(ankle + Vector2(3, 0), Vector2(4, 3)), _look.buckle)
	_shape(PackedVector2Array([ankle + Vector2(-15, 9), ankle + Vector2(33, 9), ankle + Vector2(34, 15), ankle + Vector2(-15, 15)]), _look.sole)
	if variant == "shadow":
		var jet := HOVER_JET_LENGTH + sin(_time * HOVER_JET_SPEED + ankle.x) * HOVER_JET_FLICKER
		_shape(PackedVector2Array([ankle + Vector2(-8, 16), ankle + Vector2(20, 16), ankle + Vector2(6, 16 + jet)]), HOVER_JET_COLOR)


func _draw_notebook(stroke: float) -> void:
	var corners := PackedVector2Array([Vector2(24, -36), Vector2(70, -46), Vector2(76, -20), Vector2(30, -12)])
	var pages := PackedVector2Array([Vector2(27, -38), Vector2(69, -47), Vector2(74, -24), Vector2(32, -16)])
	_shape(corners, COVER)
	_shape(pages, PAPER)
	for i: int in 3:
		var from := pages[0].lerp(pages[3], 0.25 + i * 0.25)
		var to := pages[1].lerp(pages[2], 0.25 + i * 0.25)
		draw_line(from, from.lerp(to, 0.8 + stroke * 0.02), PAPER_LINE, 1.5, true)


func _draw_pencil(hand: Vector2) -> void:
	var tip := hand + Vector2(16, 12)
	draw_line(hand + Vector2(-8, -10), tip, INK, 7.0, true)
	draw_line(hand + Vector2(-8, -10), tip, PENCIL, 4.0, true)


func _shape(points: PackedVector2Array, fill: Color) -> void:
	draw_colored_polygon(points, fill)
	var line := points.duplicate()
	line.append(points[0])
	draw_polyline(line, INK, OUTLINE, true)


func _ellipse(center: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in ELLIPSE_POINTS:
		var angle := TAU * i / ELLIPSE_POINTS
		points.append(center + Vector2(cos(angle), sin(angle)) * radii)
	return points
