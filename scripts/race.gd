extends Node3D
# Racescène voor één gemeente-level, à la A2 Racer: aftellen, de klok loopt af,
# elk checkpoint geeft extra tijd, verkeer in beide richtingen, medaille bij de finish.
# Vrij rijden (Game.free_ride): dezelfde stad, maar zonder tegenstanders, checkpoints,
# klok of geld. De HUD toont de eerstvolgende bezienswaardigheid.
const ScreenFit = preload("res://scripts/screen_fit.gd")
const Kit = preload("res://scripts/build_kit.gd")
const TrafficCar = preload("res://scripts/traffic_car.gd")
const NetGhosts = preload("res://scripts/net_ghosts.gd")
var net_ghosts: Node = null
const RivalDriver = preload("res://scripts/rival_driver.gd")
const Police = preload("res://scripts/police.gd")
const DutchStreets = preload("res://scripts/levels/dutch_streets.gd")
const Sfx = preload("res://scripts/sfx.gd")
const CarAudio = preload("res://scripts/car_audio.gd")
const TouchControls = preload("res://scripts/touch_controls.gd")
const StaticMerge = preload("res://scripts/static_merge.gd")

# De 7 tegenstanders: naam, kleur en niveau (fractie van de ideale snelheid).
# [naam, lak, niveau, model, strepen, startnummer]
const RIVALS := [
	["Sjef", Color("1f5fae"), 0.985, "coupe", Color("f4f4ee"), 2],
	["Mia", Color("f2c230"), 0.97, "hatch", Color("1a1a1a"), 3],
	["Jo", Color("2e8b57"), 0.955, "sedan", Color("f2c230"), 4],
	["Truus", Color("e07b28"), 0.94, "coupe", Color("1a1a1a"), 5],
	["Bert", Color("7a3fa0"), 0.925, "sedan", Color("f4f4ee"), 6],
	["Ilse", Color("e8e6e0"), 0.91, "hatch", Color("1f5fae"), 7],
	["Kevin", Color("0f7c84"), 0.89, "coupe", Color("e2363c"), 8],
]
const PLAYER_NAME := "Jij"
const GRID_CLEAR := 200.0   # meter vóór de startgrid zonder meerijdend verkeer (rondje)
const PLAYER_SLOT := 6        # startplek van de speler (0 = pole position)
const LEVEL_BOOST := 0.025    # tegenstanders per level 2,5% sterker (acceleratie, grip, remmen)
# Topsnelheid groeit minder hard per level (1,75% i.p.v. 2,5%) (25-11, jouw testrit): in de finale reden ze
# anders ~195 km/u tegen 166 km/u van de startauto, op de lange rechte stukken van de
# Buitenring niet bij te houden. Ze worden vooral sterker in de bochten.
const LEVEL_BOOST_SPEED := 0.0175
const SPEED_MARGIN := [0.02, 0.06]   # Makkelijk/Normaal: hoogstens zoveel sneller dan jouw topsnelheid
# Moeilijkheid (Makkelijk, Normaal, Moeilijk): niveau en auto van de tegenstanders, en de
# tijdslimiet per stuk. Normaal is na jouw testritten iets sneller gezet (ze waren te traag).
const DIFF_SKILL := [0.93, 1.015, 1.052]
const DIFF_CAR := [0.97, 1.0, 1.04]
const DIFF_LIMIT := [1.25, 1.0, 0.92]
# Tegenstanders groeien deels mee met jouw auto: van elk voordeel t.o.v. de startauto
# (snelheid, acceleratie, grip, remmen) krijgen zij dit deel ook. Een dure auto blijft
# sneller, maar wint niet meer vanzelf.
# Hoeveel van het voordeel van jouw auto (gekochte auto en upgrades) de tegenstanders
# ook krijgen. Moeilijk = alles: daar blijft het even zwaar wat je ook koopt (jouw keuze,
# 25-11); op Normaal en Makkelijk maken upgrades het merkbaar makkelijker.
const DIFF_CATCHUP := [0.3, 0.5, 1.0]
# Inhaalhulp per moeilijkheid: maximale extra topsnelheid/acceleratie voor een tegenstander
# die achter jou ligt. Op Moeilijk kan een level dit verhogen (level.hard_catch_up).
const CATCH_UP := [0.0, 0.0, 0.0]
const HARD_SLIP_PASS_SPEED := 6.6  # m/s boven de topsnelheid van een rivaal bij volle slipstream
const HARD_SLIP_EXIT_FADE := 3.0   # slipstreamsterkte per seconde na uitsturen
const HARD_SLIP_COAST := 1.05     # m/s² afbouw van de opgebouwde snelheid bij vol gas
# Geld: prijzengeld per plaats (fractie van het levelbedrag), flitspaal-bonus en boetes.
const PRIZE_BASE := 1000
const PRIZE_PER_LEVEL := 400
const PRIZE_SHARE := [1.0, 0.6, 0.4, 0.25, 0.15, 0.1, 0.05, 0.05]
const CAMERA_BONUS := 250
# Prijzengeld-factor per moeilijkheid (Makkelijk, Normaal, Moeilijk).
const PRIZE_DIFF := [0.6, 1.0, 1.5]
# Geflitst worden kost geen geld meer (25-11, zoals in de meeste racegames): het gevolg is
# dat de politie achter je aan komt. Alleen aangehouden worden kost een boete.
# Vangnet: boetes kunnen nooit meer dan dit deel van wat je in een race verdient opeten,
# zodat goed rijden altijd iets oplevert.
const FINE_CAP := 0.5
# Boetes groeien mee met het level (Heerlen de helft, finale volledig), net als het
# prijzengeld. En je raakt in een race nooit meer kwijt dan je die race verdient: je
# spaargeld blijft altijd veilig (zie _payout).

const GOLD_FACTOR := 1.06    # goud: binnen 6% van de ideale rit
const SILVER_FACTOR := 1.20  # zilver: binnen 20%
const LIMIT_FACTOR := 1.7    # tijdslimiet per stuk: ideale tijd + 70% (ruimte voor inhalen en tikken)
const LAUNCH := 2.4          # tijdverlies door de staande start (optrekken tot topsnelheid duurt ~5 s)
const PROFILE_STEP := 2.0
const OFF_ROAD_MARGIN := 3.0 # stoep telt nog als weg
const OFF_GRIP := 0.55
const OFF_SPEED := 0.5
const START_S := 14.0

enum State { COUNTDOWN, RACING, FINISHED, TIME_UP }

var level
var free := false             # vrij rijden
var landmark_i := -1          # vrij rijden: laatst gepasseerde bezienswaardigheid
var world: Node3D
var car: ArcadeCar
var state := State.COUNTDOWN
var countdown := 3.5
var last_beep := 0
var time_left := 0.0
var elapsed := 0.0
var next_cp := 0
var lap := 1
var laps := 1
var lap_bonus := 0.0          # extra tijd voor het eerste stuk van ronde 2, 3, ...
var cp_s: Array[float] = []
const CP_LEAD := 70.0      # zoveel meter vóór de bezienswaardigheid staat de checkpointpoort
var cp_nodes: Array[Node3D] = []
var cp_bonus: Array[float] = []
var gold_time := 0.0
var ideal_time := 0.0
var profile := PackedFloat32Array()
var near_i := 0
var silver_time := 0.0
var rivals: Array = []        # RivalDriver per tegenstander
var traffic: Array = []
var player_lap := 0           # keer over de finishlijn (voor de stand)
var player_s := 0.0
var finish_order: Array = []  # namen in volgorde van finishen
var race_pos := 8
var ref_car: ArcadeCar        # referentieauto van het level (ideale rit, tegenstanders)
var cash_cameras := 0
var cash_fines := 0
var cash_red := 0          # bonus voor door rood rijden
var cash_escape := 0       # bonus voor ontsnappen aan de politie
var police = null          # actieve politie-eenheid (police.gd) of null
var police_spare: ArcadeCar = null   # alvast gebouwde politieauto, onzichtbaar en stil
var police_cool := 0.0     # na een achtervolging even geen nieuwe
var radio_label: Label
var radio_timer := 0.0
var paid := false
var race_clock := 0.0          # loopt door na jouw finish, voor de tijden van de anderen
var result_cells: Array = []    # [positie, naam, tijd]-labels van de uitslag
# Flitsklassement (eindscherm): hoogste geflitste snelheid per coureur, en wie welke
# flitspaal heeft gesloopt.
var flits := {}                 # naam -> [km/u, plek]
var flits_measured := {}        # naam -> hoogste gemeten km/u (ook als niet te hard)
var flits_sloop: Array = []     # [plek, naam]
var flits_cells: Array = []
var flits_box: Control
var results_box: Control
var result_timer := 0.0

# HUD
var speed_gauge: SpeedGauge
var time_label: Label
var elapsed_label: Label
var cp_label: Label
var big_label: Label
var big_timer := 0.0
var panel: PanelContainer
var touch_ui: CanvasLayer = null   # aanraakknoppen (weg zolang het paneel in beeld is)
var panel_box: VBoxContainer
var pause_open := false
var pos_label: Label
# Mini-leaderboard rechtsboven: de coureur voor je, jijzelf en de coureur achter je, met
# het verschil in seconden. Daarvoor onthouden we per coureur elke GAP_STEP meter wanneer
# hij daar was (race_clock): het verschil met de auto voor je is hoe lang geleden hij op
# jouw plek reed, met de auto achter je hoe lang geleden jij op zijn plek was.
const GAP_STEP := 2.0
var gap_hist := {}          # naam -> [tijden per GAP_STEP, laatste index, vorige afstand, vorige tijd]
var board_timer := 0.0
var board: PanelContainer
var board_rows: Array = []  # [[pos, naam, verschil, achtergrond], ...]
var info_box: PanelContainer

var loading := true
signal loaded

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ev_load_t0 = Time.get_ticks_msec()
	free = Game.free_ride
	var info: Dictionary = Game.current_level()
	# laadscherm: eerst tonen, dan pas het level opbouwen (dat duurt op een telefoon even)
	var screen := _loading_screen(String(info["name"]))
	var bar: ColorRect = screen.get_meta("bar")
	Game.web_stage("laden: %s, level bouwen" % info["name"])
	await _loaded_step(bar, 0.04)
	world = Node3D.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	_environment()
	level = load(String(info["script"])).new()
	world.add_child(level)
	level.build()
	_ev_mark("bouwen")
	Game.web_stage("laden: %s, straten" % info["name"])
	await _loaded_step(bar, 0.55)
	_ev_mark("wacht1")
	DutchStreets.new().build(level, self)
	level.finish_streetscape()
	_ev_mark("straten")
	Game.web_stage("laden: %s, auto en checkpoints" % info["name"])
	await _loaded_step(bar, 0.7)
	_ev_mark("wacht2")
	_car()
	_checkpoints()
	if level.has_method("solid_trees"):
		level.solid_trees()
	StaticMerge.merge(level)
	_cull_details(level)
	_ev_mark("auto")
	Game.web_stage("laden: %s, verkeer" % info["name"])
	await _loaded_step(bar, 0.85)
	_ev_mark("wacht3")
	_traffic()
	_build_police_spare()
	_hud()
	# samen racen: eigen auto versturen en de anderen als spookauto tonen
	if Game.in_room():
		net_ghosts = NetGhosts.new()
		net_ghosts.name = "NetGhosts"
		add_child(net_ghosts)
		net_ghosts.setup(self)
	_ev_mark("verkeer")
	Game.web_stage("laden: %s, shaders voorbereiden" % info["name"])
	var prewarm_t0 := Time.get_ticks_msec()
	await _prewarm()
	_ev_prewarm_ms = Time.get_ticks_msec() - prewarm_t0
	_ev_mark("shaders")
	if Game.mp_active() and net_ghosts != null:
		world.process_mode = Node.PROCESS_MODE_DISABLED
		net_ghosts.mp_loaded()
	await _loaded_step(bar, 1.0)
	screen.queue_free()
	loading = false
	_ev_load_ms = Time.get_ticks_msec() - _ev_load_t0
	_ev_mark("klaar")
	Game.races_opened += 1
	_ev_nth = Game.races_opened
	Game.web_stage("%s: %s" % ["vrij rijden" if free else "race", info["name"]])
	if free:
		state = State.RACING
		car.controls_enabled = true
		_race_event_start()
		_big(String(Game.current_level()["name"]).to_upper(), 1.6, Color("f3df68"))
	loaded.emit()

func _loaded_step(bar: ColorRect, f: float) -> void:
	bar.anchor_right = f
	# twee frames wachten, zodat het laadscherm echt getekend is voor het volgende zware stuk
	await get_tree().process_frame
	await get_tree().process_frame

# Eenvoudig laadscherm in de stijl van het menu: titel, levelnaam en een voortgangsbalk.
func _loading_screen(level_name: String) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color("111723")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	layer.add_child(box)
	var title := Label.new()
	title.text = "PARKSTAD RACER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color("f3df68"))
	box.add_child(title)
	var name_l := Label.new()
	name_l.text = level_name
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 26)
	name_l.add_theme_color_override("font_color", Color.WHITE)
	box.add_child(name_l)
	var track := ColorRect.new()
	track.color = Color("2a3344")
	track.custom_minimum_size = Vector2(420, 10)
	track.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(track)
	var bar := ColorRect.new()
	bar.color = Color("f3df68")
	bar.anchor_bottom = 1.0
	bar.anchor_right = 0.0
	track.add_child(bar)
	var hint := Label.new()
	hint.text = "Laden..."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color("9aa3ab"))
	box.add_child(hint)
	layer.set_meta("bar", bar)
	return layer

# ---------------------------------------------------------------- opbouw
func _environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	# blauwe lucht met zon en wolkjes (sky.gdshader); de lucht zelf geeft geen licht of
	# reflecties, dat scheelt op telefoons een hoop rekenwerk
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = load("res://scripts/sky.gdshader")
	var sun_rot := Vector3(-48, -35, 0)
	# de zon aan de hemel staat in dezelfde richting als het zonlicht, maar wat lager, zodat
	# je hem ook echt ziet als je die kant op rijdt
	var to_sun: Vector3 = Basis.from_euler(sun_rot * PI / 180.0).z
	to_sun = Vector3(to_sun.x, 0.0, to_sun.z).normalized() * cos(deg_to_rad(14.0)) + Vector3(0, sin(deg_to_rad(14.0)), 0)
	sky_mat.set_shader_parameter("sun_dir", to_sun)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.ambient_light_color = Color("cfdaea")
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.55
	env.fog_enabled = true
	# verre dingen vervagen naar het lichtblauw van de horizon; de lucht zelf niet
	env.fog_light_color = Color("b4c9de")
	env.fog_density = 0.0016
	env.fog_sky_affect = 0.0
	we.environment = env
	world.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = sun_rot
	sun.light_color = Color("fff4e2")
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 220.0
	if Game.low_graphics():
		# telefoon: schaduwen alleen dichtbij, in één laag, en 3D op een lagere resolutie
		# (de knoppen en teksten blijven scherp)
		sun.directional_shadow_max_distance = 90.0
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		var w: float = float(DisplayServer.window_get_size().x)
		get_viewport().scaling_3d_scale = clampf(1300.0 / maxf(w, 1.0), 0.5, 1.0)
		# kleinere schaduwkaart (standaard 4096x4096): op 90 m schaduwafstand zie je het
		# verschil niet, en het scheelt de telefoon elk beeldje veel tekenwerk
		RenderingServer.directional_shadow_atlas_set_size(2048, true)
	else:
		get_viewport().scaling_3d_scale = 1.0
		RenderingServer.directional_shadow_atlas_set_size(4096, true)
	if Game.battery_saver():
		# Batterij sparen: geen zonschaduwen (scheelt een hele extra tekenronde per beeldje)
		sun.shadow_enabled = false
	world.add_child(sun)

# Kleine dingen (paaltjes, borden, bloembakken, ramen) hoeven in de verte niet getekend te
# worden: dat scheelt de grafische chip duizenden tekenopdrachten per frame. Hoe kleiner, hoe
# eerder ze wegvallen; heel kleine dingen werpen ook geen schaduw. Bewegende dingen in de
# groep "keep_far" (zoals de AWACS) blijven altijd zichtbaar.
func _cull_details(root: Node) -> void:
	var f: float = 0.7 if Game.low_graphics() else 1.0
	for g in root.find_children("*", "GeometryInstance3D", true, false):
		if g is MultiMeshInstance3D or g.visibility_range_end > 0.0 or _keep_far(g):
			continue
		var box: AABB = g.global_transform * g.get_aabb()
		var size: float = box.size.length()
		if size < 2.0:
			g.visibility_range_end = 160.0 * f
		elif size < 8.0:
			g.visibility_range_end = 320.0 * f
		elif size < 25.0:
			g.visibility_range_end = 650.0 * f
		if size < 1.2:
			g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _keep_far(n: Node) -> bool:
	while n != null:
		if n.is_in_group("keep_far"):
			return true
		n = n.get_parent()
	return false

# Voorbereiden tijdens het aftellen, zodat het spel later niet even hapert als iets voor het
# eerst gebeurt (vooral op een telefoon in de browser):
# - alle geluiden worden nu al opgebouwd en één keer onhoorbaar afgespeeld (sirene,
#   portofoon, flits, botsing ...);
# - elk soort oppervlak wordt één keer piepklein vlak voor de camera getekend, ook met een
#   lamp erbij (zwaailicht, flitser) en als 'veelvoud' (bomen), zodat de grafische chip die
#   tekeninstructies al klaar heeft;
# - alle letters van de borden en schermteksten worden alvast in het lettertype-geheugen gezet.
const PREWARM_SOUNDS := ["screech", "beep", "go", "bump", "crash", "coin", "flash", "checkpoint", "lap", "finish", "fail", "siren", "radio", "click"]
const PREWARM_CHARS := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,:;-+!?'\"()/%€"

func _prewarm() -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return
	var nodes: Array[Node] = []
	# geluiden
	for n in PREWARM_SOUNDS:
		var p := AudioStreamPlayer.new()
		p.stream = Sfx.get_stream(n)
		p.volume_db = -80.0
		p.bus = "SFX"
		add_child(p)
		p.play()
		nodes.append(p)
	# oppervlakken: één per soort shader, gewoon en als veelvoud
	var hold := Node3D.new()
	hold.name = "Prewarm"
	hold.position = Vector3(0, 0, -1.5)
	cam.add_child(hold)
	nodes.append(hold)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.0005, 0.0005)
	var seen := {}
	var lens := StandardMaterial3D.new()
	lens.emission_enabled = true
	lens.emission = Color("3a7bff")
	lens.emission_energy_multiplier = 4.0
	var extra: Array = [lens, Kit.mat(Color.WHITE, 1.0), Kit.two_sided_mat(Color.WHITE)]
	for m in extra:
		_prewarm_mat(hold, quad, m, false, seen)
		_prewarm_mat(hold, quad, m, true, seen)
	var label_chars := {}
	for g in world.find_children("*", "GeometryInstance3D", true, false):
		if g is Label3D:
			var key := "%d|%d" % [g.font_size, g.outline_size]
			label_chars[key] = String(label_chars.get(key, "")) + g.text
			continue
		var multi: bool = g is MultiMeshInstance3D
		var mesh: Mesh = null
		if multi:
			mesh = g.multimesh.mesh if g.multimesh != null else null
		elif g is MeshInstance3D:
			mesh = g.mesh
		if mesh == null:
			continue
		for i in mesh.get_surface_count():
			var m: Material = g.material_override
			if m == null and g is MeshInstance3D:
				m = (g as MeshInstance3D).get_active_material(i)
			if m == null:
				m = mesh.surface_get_material(i)
			if m != null:
				_prewarm_mat(hold, quad, m, multi, seen)
	# 3D-teksten: per lettergrootte alle letters die erin voorkomen plus het alfabet
	for key in label_chars:
		var parts: PackedStringArray = String(key).split("|")
		var l := Label3D.new()
		l.font_size = int(parts[0])
		l.outline_size = int(parts[1])
		l.pixel_size = 0.000001
		l.text = PREWARM_CHARS + String(label_chars[key]).substr(0, 400)
		hold.add_child(l)
	# lamp erbij, zoals het zwaailicht en de flitser
	var lamp := OmniLight3D.new()
	lamp.omni_range = 1.0
	lamp.light_energy = 0.05
	hold.add_child(lamp)
	# schermteksten: alle letters op elke gebruikte grootte, bijna doorzichtig
	var sizes := {}
	var text_layer := CanvasLayer.new()
	add_child(text_layer)
	nodes.append(text_layer)
	for lbl in find_children("*", "Label", true, false):
		var fs: int = (lbl as Label).get_theme_font_size("font_size")
		if not sizes.has(fs):
			sizes[fs] = true
			var t := Label.new()
			t.text = PREWARM_CHARS
			t.add_theme_font_size_override("font_size", fs)
			t.modulate = Color(1, 1, 1, 0.01)
			t.mouse_filter = Control.MOUSE_FILTER_IGNORE
			text_layer.add_child(t)
	for i in 8:
		await get_tree().process_frame
	for n in nodes:
		if is_instance_valid(n):
			n.queue_free()

func _prewarm_mat(hold: Node3D, quad: QuadMesh, m: Material, multi: bool, seen: Dictionary) -> void:
	# zelfde shader = zelfde tekeninstructies, dus één keer per shader is genoeg
	var shader: Variant = m.get_rid()
	if m is ShaderMaterial:
		shader = (m as ShaderMaterial).shader
	elif m is BaseMaterial3D:
		# de shader van een standaardmateriaal hangt af van deze eigenschappen, niet van kleur
		var b := m as BaseMaterial3D
		shader = [b.transparency, b.shading_mode, b.cull_mode, b.emission_enabled,
			b.albedo_texture != null, b.uv1_triplanar, b.uv1_world_triplanar,
			b.vertex_color_use_as_albedo, b.billboard_mode, b.texture_filter,
			b.no_depth_test, b.blend_mode, b.depth_draw_mode, b.diffuse_mode,
			b.specular_mode, b.disable_receive_shadows, b.normal_enabled, b.grow, b.alpha_scissor_threshold]
	var key := "%s|%s" % [shader, multi]
	if seen.has(key):
		return
	seen[key] = true
	if multi:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = quad
		mm.instance_count = 1
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = m
		hold.add_child(mmi)
	else:
		var mi := MeshInstance3D.new()
		mi.mesh = quad
		mi.material_override = m
		hold.add_child(mi)

# Grond onder de hele route, met gaten waar het level een verlaagd stuk heeft (pits): het
# vlak wordt dan in een raster van blokken gesneden en de cellen in een gat vallen weg.
func _ground(area: Rect2) -> void:
	var pits: Array = level.pits
	var xs: Array = [area.position.x, area.end.x]
	var zs: Array = [area.position.y, area.end.y]
	for p in pits:
		xs.append_array([p.position.x, p.end.x])
		zs.append_array([p.position.y, p.end.y])
	xs.sort()
	zs.sort()
	for i in range(xs.size() - 1):
		for j in range(zs.size() - 1):
			var w: float = xs[i + 1] - xs[i]
			var d: float = zs[j + 1] - zs[j]
			if w < 0.01 or d < 0.01:
				continue
			var c := Vector2(xs[i] + w * 0.5, zs[j] + d * 0.5)
			var hole := false
			for p in pits:
				if p.has_point(c):
					hole = true
			if not hole:
				Kit.box(world, "Ground", Vector3(c.x, -0.35, c.y), Vector3(w, 0.7, d), Color("5d7659"), true)

# Geblokte finishlijn: twee rijen wit-zwarte vakjes over de volle breedte van de rijbaan
# (bij de Buitenring over elke rijbaan apart, niet over de middenberm). Eerst was hij 14 m
# breed en vielen de zwarte vakjes weg tegen het asfalt.
func _finish_line(node: Node3D) -> void:
	var hw: float = float(level.road_hw)
	var spans: Array = [[-hw, -1.3], [1.3, hw]] if level.dual else [[-hw, hw]]
	var sq := 0.75
	var t_white: Array = []
	var t_black: Array = []
	for sp in spans:
		var a: float = sp[0]
		var b: float = sp[1]
		var n: int = maxi(2, int(round((b - a) / sq)))
		var w: float = (b - a) / float(n)
		for row in range(2):
			for k in range(n):
				var x0: float = a + float(k) * w
				var z0: float = -sq + float(row) * sq
				var dst: Array = t_white if (k + row) % 2 == 0 else t_black
				Kit._quad(dst, Vector3(x0, 0.06, z0), Vector3(x0 + w, 0.06, z0), Vector3(x0 + w, 0.06, z0 + sq), Vector3(x0, 0.06, z0 + sq))
	for pair in [[t_white, Color("f2f2ee")], [t_black, Color("0c0c0e")]]:
		var mi := MeshInstance3D.new()
		mi.name = "Finish line"
		mi.mesh = Kit._mesh_from(pair[0], Kit._two_sided(pair[1]))
		node.add_child(mi)

func _checkpoints() -> void:
	var r = level.route
	# grond onder de hele route
	var lo := Vector3(INF, 0, INF)
	var hi := Vector3(-INF, 0, -INF)
	for p in r.points:
		lo = Vector3(minf(lo.x, p.x), 0, minf(lo.z, p.z))
		hi = Vector3(maxf(hi.x, p.x), 0, maxf(hi.z, p.z))
	var mid: Vector3 = (lo + hi) * 0.5
	_ground(Rect2(mid.x - (hi.x - lo.x + 600) * 0.5, mid.z - (hi.z - lo.z + 600) * 0.5, hi.x - lo.x + 600, hi.z - lo.z + 600))

	var count: int = level.checkpoints.size()
	for i in range(count):
		var def: Dictionary = level.checkpoints[i]
		var s: float = r.closest_s(def["at"])
		# de poort staat een stukje vóór de bezienswaardigheid: eerst zie je de naam, dan
		# het gebouw (de finish blijft op de lijn)
		if i < count - 1:
			var prev_s: float = cp_s[i - 1] if i > 0 else 0.0
			s = maxf(s - CP_LEAD, prev_s + 20.0) if s - CP_LEAD > 0.0 else s
		cp_s.append(s)
		if free:
			continue
		var is_finish: bool = i == count - 1
		var node := Node3D.new()
		node.name = "Checkpoint_%d" % (i + 1)
		node.transform = Transform3D(r.basis_at(s), r.pos_at(s))
		world.add_child(node)
		var col := Color("dc4741") if is_finish else Color("e6bd48")
		var half: float = float(level.road_hw) + 2.0
		for x in [-half, half]:
			Kit.box(node, "Post", Vector3(x, 3.2, 0), Vector3(0.6, 6.4, 0.6), col)
		Kit.box(node, "Beam", Vector3(0, 6.6, 0), Vector3(half * 2.0 + 0.6, 1.4, 0.5), col)
		var title: String = String(def["name"])   # de finish heet al "START / FINISH"
		var l := Kit.label(node, title, Vector3(0, 6.6, 0.3), 0.012, Color("1a1a1a"), 80)
		l.modulate = Color("1a1a1a") if not is_finish else Color.WHITE
		if is_finish:
			_finish_line(node)
		var area := Area3D.new()
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(half * 2.0 + 8.0, 8, 5)
		cs.shape = shape
		cs.position.y = 3.0
		area.add_child(cs)
		node.add_child(area)
		area.body_entered.connect(_on_checkpoint.bind(i))
		cp_nodes.append(node)
	if free:
		return
	# Tijdlimiet en medailles volgen uit een ideale rit: overal zo hard als de bochten
	# (grip van de auto) toelaten, met optrekken en remmen ertussen. Geen verkeer.
	_ideal_profile(r)
	var prev: float = START_S
	for i in range(count):
		var leg: float = _leg_time(prev, cp_s[i]) + (LAUNCH if i == 0 else 0.0)
		cp_bonus.append(ceilf(leg * LIMIT_FACTOR * DIFF_LIMIT[Game.difficulty()] + (4.0 if i == 0 else 1.0)))
		prev = cp_s[i]
	time_left = cp_bonus[0]
	laps = int(level.laps)
	ideal_time = _leg_time(START_S, cp_s[count - 1]) + LAUNCH
	if laps > 1:
		# van de finishlijn rond naar het eerste checkpoint
		lap_bonus = ceilf(_leg_time(cp_s[count - 1], cp_s[0]) * LIMIT_FACTOR * DIFF_LIMIT[Game.difficulty()] + 1.0)
		ideal_time += float(laps - 1) * _leg_time(0.0, r.length)
	gold_time = snappedf(ideal_time * GOLD_FACTOR, 0.5)
	silver_time = snappedf(ideal_time * SILVER_FACTOR, 0.5)

# Ideaal snelheidsprofiel langs de route (elke PROFILE_STEP meter).
func _ideal_profile(r) -> void:
	if ref_car == null:
		ref_car = ArcadeCar.new()
		_apply_stats(ref_car, _rival_stats())
	profile = profile_for(ref_car, r)

# Snelheidsprofiel (m/s per PROFILE_STEP) voor een auto met deze rijwaarden: bochtsnelheid
# uit de grip, optrekken en remmen ervoor en erna. Ook voor de politie, die met jouw auto
# meegroeit en dus zijn eigen profiel heeft.
func profile_for(c: ArcadeCar, r) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var n: int = int(r.length / PROFILE_STEP)
	out.resize(n)
	for i in range(n):
		out[i] = c.corner_speed(r.curvature(float(i) * PROFILE_STEP))
	var b: float = c.braking
	var passes: int = 2 if r.closed else 1
	for _p in range(passes):
		for i in range(1, n + (n if r.closed else 0)):
			var cur: int = i % n
			var pre: int = (i - 1) % n
			out[cur] = minf(out[cur], sqrt(out[pre] * out[pre] + 2.0 * c.accel_at(out[pre]) * PROFILE_STEP))
		for i in range(n - 2 + (n if r.closed else 0), -1, -1):
			var cur: int = i % n
			var nxt: int = (i + 1) % n
			out[cur] = minf(out[cur], sqrt(out[nxt] * out[nxt] + 2.0 * b * PROFILE_STEP))
	return out

# Ideale tijd om van s0 vooruit naar s1 te rijden (rondt af over de finish op een rondje).
func _leg_time(s0: float, s1: float) -> float:
	var r = level.route
	var dist: float = s1 - s0
	if dist <= 0.0:
		dist += r.length
	var n: int = profile.size()
	var t := 0.0
	var d := 0.0
	while d < dist:
		var i: int = posmod(int((s0 + d) / PROFILE_STEP), n)
		t += PROFILE_STEP / maxf(profile[i], 1.0)
		d += PROFILE_STEP
	return t

func _exit_tree() -> void:
	if ref_car != null:
		ref_car.free()
	# weggegaan tijdens de race (menu, opnieuw, garage)
	if _ev_started and not _ev_ended:
		_race_event("quit", 0)

# Statistieken: start en afloop van elke race (anoniem, alleen in de webversie).
var _ev_started := false
var _ev_ended := false
var _ev_load_t0 := 0
var _ev_load_ms := 0
var _ev_prewarm_ms := 0
var _ev_steps := ""            # "bouwen 812, wacht1 40, ..." : ms per laadstap
var _ev_step_t := -1
var _ev_nth := 0               # hoeveelste race sinds het spel geopend is (1 = koude start, nog niets in de cache)
var _ev_frames := 0
var _ev_frame_time := 0.0
var _ev_slow := 0              # beeldjes trager dan 50 ms (haperingen)

func _ev_mark(step: String) -> void:
	var now := Time.get_ticks_msec()
	var from := _ev_load_t0 if _ev_step_t < 0 else _ev_step_t
	_ev_steps += ("" if _ev_steps == "" else ", ") + "%s %d" % [step, now - from]
	_ev_step_t = now

func _race_event_start() -> void:
	_ev_started = true
	Game.web_event("race_start", {"lvl": String(Game.current_level()["id"]), "mode": _ev_mode(),
		"diff": Game.difficulty(), "car": "john" if (Game.mp_active() and String(Game.mp.get("rule", "")) == "equal") else Game.selected_car(),
		"n": 1 + rivals.size() + (net_ghosts.rows().size() if net_ghosts != null else 0),
		"load_ms": _ev_load_ms, "prewarm_ms": _ev_prewarm_ms, "steps": _ev_steps, "nth": _ev_nth, "gpu": RenderingServer.get_video_adapter_name().substr(0, 60),
		"gfx": Game.graphics_mode()})

func _race_event(res: String, pos: int) -> void:
	if not _ev_started or _ev_ended:
		return
	_ev_ended = true
	Game.web_event("race_end", {"lvl": String(Game.current_level()["id"]), "mode": _ev_mode(), "diff": Game.difficulty(),
		"res": res, "pos": pos, "secs": snappedf(elapsed, 0.01), "cp": next_cp + (lap - 1) * cp_s.size(),
		"fps": snappedf(_ev_frames / _ev_frame_time, 0.1) if _ev_frame_time > 1.0 else 0.0,
		"slow": snappedf(100.0 * _ev_slow / _ev_frames, 0.01) if _ev_frames > 0 else 0.0,
		"gpu": RenderingServer.get_video_adapter_name().substr(0, 60)})

func _ev_mode() -> String:
	return "free" if free else ("mp" if Game.mp_active() else "race")

# Jouw auto uit de garage: model, kleur en rijwaarden inclusief upgrades.
func _apply_player_car(c: ArcadeCar) -> void:
	var id: String = Game.selected_car()
	var info: Dictionary = Game.Catalog.car(id)
	c.car_style = String(info["style"])
	c.body_color = Game.car_paint(id)
	c.stripe_color = info["stripe"]
	c.race_number = 1
	c.offroad = float(info.get("offroad", 0.0))
	if Game.mp_active() and String(Game.mp["rule"]) == "equal":
		# samen racen met gelijke auto's: de John Hatchback zonder upgrades, in je eigen kleur
		var john: Dictionary = Game.Catalog.car("john")
		c.car_style = String(john["style"])
		c.stripe_color = john["stripe"]
		c.offroad = 0.0
		_apply_stats(c, john)
		return
	_apply_stats(c, Game.car_stats(id))

func _apply_stats(c: ArcadeCar, st: Dictionary) -> void:
	c.max_forward_speed = float(st["speed"])
	c.acceleration = float(st["accel"])
	c.grip = float(st["grip"])
	c.braking = float(st["brake"])

# Tegenstanders: de startauto, per level iets sterker, plus een deel van het voordeel
# van jouw auto (DIFF_CATCHUP).
func _rival_stats() -> Dictionary:
	var base: Dictionary = Game.Catalog.CARS[0]
	var mine: Dictionary = Game.car_stats(Game.selected_car())
	var share: float = DIFF_CATCHUP[Game.difficulty()]
	var hard: float = float(level.hard_boost) if Game.difficulty() == 2 and level != null else 1.0
	var out := {}
	for k in ["speed", "accel", "grip", "brake"]:
		var boost: float = LEVEL_BOOST_SPEED if k == "speed" else LEVEL_BOOST
		var f: float = (1.0 + boost * float(Game.current_index)) * DIFF_CAR[Game.difficulty()] * hard
		var extra: float = maxf(float(mine[k]) - float(base[k]), 0.0)
		out[k] = float(base[k]) * f + extra * share
	# Makkelijk en Normaal: op de rechte stukken nooit (veel) sneller dan jouw auto, anders
	# rijdt een koploper in de finale (lange rechte stukken) onbereikbaar weg met de
	# startauto (jouw test, 25-11). In bochten blijven ze sterker (grip, acceleratie, remmen).
	if Game.difficulty() < 2:
		out["speed"] = minf(float(out["speed"]), float(mine["speed"]) * (1.0 + SPEED_MARGIN[Game.difficulty()]))
	return out

# Startopstelling: 4 rijen van 2, de speler op PLAYER_SLOT, de tegenstanders ervoor/ernaast.
func _car() -> void:
	var r = level.route
	var lanes: Array = level.traffic_lanes
	var grid_lanes: Array = [float(lanes[0]), -float(lanes[0])] if lanes.size() == 1 else [float(lanes[0]), float(lanes[1])]
	var rival_i := 0
	var rival_stats := _rival_stats()
	var hard_race := Game.difficulty() == 2 and not free
	for slot in range(8):
		var row: int = slot / 2
		var s: float = START_S + float(3 - row) * 10.0
		var l: float = grid_lanes[slot % 2] if slot % 2 == 0 else grid_lanes[1]
		var xf := Transform3D(r.basis_at(s), r.pos_at(s) + r.right_at(s) * l + Vector3(0, 0.16, 0))
		if slot == _my_slot():
			car = ArcadeCar.new()
			car.name = "PlayerCar"
			_apply_player_car(car)
			if hard_race:
				var pass_speed := float(rival_stats["speed"]) + HARD_SLIP_PASS_SPEED
				car.slipstream_top_bonus = maxf(car.SLIP_TOP, pass_speed / car.max_forward_speed - 1.0)
				car.slipstream_coast = HARD_SLIP_COAST
			car.transform = xf
			car.controls_enabled = false
			world.add_child(car)
			car.add_child(CarAudio.new())
			player_s = s
			continue
		if free or Game.mp_active():
			continue
		var info: Array = RIVALS[rival_i]
		rival_i += 1
		var rc := ArcadeCar.new()
		rc.name = "Rival_%s" % info[0]
		rc.ai = true
		rc.body_color = info[1]
		rc.car_style = info[3]
		rc.stripe_color = info[4]
		rc.race_number = info[5]
		_apply_stats(rc, rival_stats)
		rc.transform = xf
		rc.controls_enabled = false
		world.add_child(rc)
		rc.add_child(CarAudio.new())
		var d := RivalDriver.new()
		d.name = "Driver"
		d.driver_name = info[0]
		d.skill = float(info[2]) * DIFF_SKILL[Game.difficulty()]
		rc.add_child(d)
		# eerste strook = waar hij normaal rijdt. Op een gewone weg is dat altijd rechts;
		# de linkerstrook (tegenrijbaan) is alleen om in te halen.
		var own: Array = [float(lanes[0]), -float(lanes[0])] if lanes.size() == 1 else ([l] + lanes.filter(func(x): return absf(float(x) - l) > 0.5))
		d.setup(self, rc, l, own)
		rivals.append(d)

# Startplek: normaal PLAYER_SLOT; samen racen: op volgorde van spelernummer vooraan.
func _my_slot() -> int:
	if Game.mp_active():
		return maxi(0, (Game.mp["grid"] as Array).find(Game.net().my_id))
	return PLAYER_SLOT

# Slipstream: rij je 3 tot 45 m achter een auto die dezelfde kant op gaat (racer,
# politie of verkeer), dan bouw je slipstream op: dichterbij = sterker. Geldt voor jou en
# de tegenstanders. Bij uitsturen op Moeilijk valt het voordeel snel weg, terwijl
# de opgebouwde snelheid de speler nog tijd geeft om de inhaalactie af te maken.
const SLIP_RANGE := 45.0
func _slipstream(delta: float) -> void:
	var racers: Array = [car]
	for d in rivals:
		racers.append(d.car)
	if police != null and is_instance_valid(police.car):
		racers.append(police.car)
	var others: Array = obstacles()
	var hard_race := Game.difficulty() == 2 and not free
	for a in racers:
		var target := 0.0
		var va: float = absf(a.drive_speed)
		if va > 15.0:
			var fwd: Vector3 = -a.global_transform.basis.z
			var right: Vector3 = a.global_transform.basis.x
			for b in others:
				if b == a or not is_instance_valid(b):
					continue
				# alleen achter iets dat dezelfde kant op rijdt
				if (-b.global_transform.basis.z).dot(fwd) < 0.8:
					continue
				var rel: Vector3 = b.global_position - a.global_position
				var ahead: float = rel.dot(fwd)
				if ahead < 3.0 or ahead > SLIP_RANGE or absf(rel.dot(right)) > 2.0:
					continue
				target = maxf(target, 1.0 - (ahead - 3.0) / (SLIP_RANGE - 3.0) * 0.5)
		var fade := HARD_SLIP_EXIT_FADE if a == car and hard_race and target == 0.0 else 0.3
		a.slipstream = move_toward(a.slipstream, target, (1.5 if target > a.slipstream else fade) * delta)

func player_progress() -> float:
	return float(player_lap) * level.route.length + player_s

func catch_up_boost() -> float:
	var k: float = CATCH_UP[Game.difficulty()]
	if Game.difficulty() == 2:
		k = maxf(k, float(level.hard_catch_up))
	return k

func obstacles() -> Array:
	var out: Array = [car]
	for d in rivals:
		out.append(d.car)
	out.append_array(traffic)
	if police != null and is_instance_valid(police.car):
		out.append(police.car)
	return out

# Waar een tegenstander als gefinisht telt: zijn midden op dezelfde plek als het jouwe op
# het moment dat jouw auto de finishpoort raakt (poort 2,5 m diep, auto 1,9 m voor het midden).
func finish_s() -> float:
	return cp_s[cp_s.size() - 1] - 4.4 if cp_s.size() > 0 else level.route.length

func on_rival_finished(d) -> void:
	finish_order.append(d.driver_name)

func _gap_record(n: String, prog: float) -> void:
	if not gap_hist.has(n):
		var arr := PackedFloat32Array()
		arr.resize(int(level.route.length * float(laps + 1) / GAP_STEP) + 8)
		arr.fill(-1.0)
		# alles tot de startplek telt als 'gepasseerd bij de start' (startgrid)
		var i0: int = clampi(int(floor(prog / GAP_STEP)), -1, arr.size() - 1)
		for i in range(0, i0 + 1):
			arr[i] = race_clock
		gap_hist[n] = [arr, i0, prog, race_clock]
		return
	var h: Array = gap_hist[n]
	var arr: PackedFloat32Array = h[0]
	var last: int = h[1]
	var p0: float = h[2]
	var t0: float = h[3]
	var idx: int = mini(int(floor(prog / GAP_STEP)), arr.size() - 1)
	if idx > last and prog > p0:
		# precies het moment waarop hij elke grens passeerde (tussen de twee frames in)
		for i in range(maxi(last + 1, 0), idx + 1):
			var b: float = float(i) * GAP_STEP
			var f: float = clampf((b - p0) / (prog - p0), 0.0, 1.0)
			arr[i] = lerpf(t0, race_clock, f)
		h[0] = arr
		h[1] = idx
	h[2] = prog
	h[3] = race_clock

# Hoe laat was coureur n op afstand prog? (-1 = nog niet), tussen twee grenzen in geschat.
func _gap_time(n: String, prog: float) -> float:
	if not gap_hist.has(n):
		return -1.0
	var arr: PackedFloat32Array = gap_hist[n][0]
	var idx: int = int(floor(prog / GAP_STEP))
	if idx < 0 or idx + 1 >= arr.size() or arr[idx] < 0.0:
		return -1.0
	if arr[idx + 1] < 0.0:
		return arr[idx]
	var f: float = prog / GAP_STEP - float(idx)
	return lerpf(arr[idx], arr[idx + 1], f)

# Stand: gefinishte coureurs in volgorde, daarna de rest op afgelegde afstand.
func standings() -> Array:
	var rows: Array = []
	for d in rivals:
		rows.append({"name": d.driver_name, "progress": d.progress(), "finished": d.finished, "time": d.finish_time, "lap": d.lap, "start": d.start_progress})
	rows.append({"name": PLAYER_NAME, "progress": float(player_lap) * level.route.length + player_s,
		"finished": state == State.FINISHED, "time": elapsed, "lap": player_lap, "start": START_S})
	if net_ghosts != null:
		rows.append_array(net_ghosts.rows())
	rows.sort_custom(func(a, b):
		if a["finished"] and b["finished"]:
			return finish_order.find(a["name"]) < finish_order.find(b["name"])
		if a["finished"] != b["finished"]:
			return a["finished"]
		return a["progress"] > b["progress"])
	return rows

func _traffic() -> void:
	var r = level.route
	var end_s: float = level.traffic_end_s()
	var rng := RandomNumberGenerator.new()
	rng.seed = level.seed_value + 99
	# geen bijna-zwarte auto's: die vallen weg tegen het asfalt
	var colors := [Color("2f5d8a"), Color("e8e6e0"), Color("8a1c2b"), Color("8c9196"), Color("a33a2f"), Color("3f6b45"), Color("d9b44a")]
	# met 7 tegenstanders op de weg minder verkeer, anders staat alles vast
	var n: int = int(ceil(float(level.traffic_cars) * (1.0 if free else 0.5)))
	for i in range(n):
		var against: bool = i % 2 == 1
		# meerijdend verkeer pas een eind voor de start, zodat je het inhaalt
		var s: float = lerpf(120.0, end_s - 20.0, (float(i) + rng.randf() * 0.6) / float(n))
		if r.closed:
			# meerijdend verkeer niet vlak achter de startgrid: dat zou tijdens het aftellen
			# door de stilstaande auto's heen rijden. Tegenliggers mogen overal.
			var span: float = r.length - (0.0 if against else 60.0 + GRID_CLEAR)
			s = fposmod(START_S + 60.0 + span * (float(i) + rng.randf() * 0.6) / float(n), r.length)
		var t := TrafficCar.new()
		t.name = "Traffic_%d" % i
		world.add_child(t)
		traffic.append(t)
		t.lane = float(level.traffic_lanes[(i / 2) % level.traffic_lanes.size()])
		# op een gescheiden weg rijdt de linkerstrook duidelijk sneller (18-22 tegen 10-14 m/s),
		# zodat twee verkeersauto's niet lang naast elkaar blijven rijden
		var v: float = rng.randf_range(10.0, 14.0) + (8.0 if t.lane > 5.0 else 0.0)
		t.setup(r, s, end_s, v, against, colors[rng.randi_range(0, colors.size() - 1)], rng.randf() < 0.2, rng.randi_range(0, 99))

# ---------------------------------------------------------------- spel
# Ondergrond: naast de weg (gras, heide, plein) minder grip en een lagere topsnelheid.
func _physics_process(_delta: float) -> void:
	if loading or car == null or get_tree().paused:
		return
	var res: Array = level.route.nearest(car.global_position, near_i)
	near_i = res[1]
	var ns: float = res[2]
	if level.route.closed:
		if ns < player_s - level.route.length * 0.5:
			player_lap += 1
		elif ns > player_s + level.route.length * 0.5:
			player_lap -= 1
	player_s = ns
	if state == State.RACING or state == State.FINISHED:
		_gap_record(PLAYER_NAME, player_progress())
		for d in rivals:
			_gap_record(d.driver_name, d.progress())
		if net_ghosts != null:
			for row in net_ghosts.rows():
				_gap_record(String(row["name"]), float(row["progress"]))
	var off: bool = float(res[0]) > float(level.road_hw) + OFF_ROAD_MARGIN
	_slipstream(_delta)
	car.off_road = off
	# naast de weg: minder grip en topsnelheid, minder voor een terreinauto (offroad)
	car.surface_grip = lerpf(OFF_GRIP, 1.0, car.offroad) if off else 1.0
	car.surface_speed = lerpf(OFF_SPEED, 1.0, car.offroad) if off else 1.0

func _process(delta: float) -> void:
	if loading:
		return
	# prestaties voor de statistieken: gemiddelde beeldjes per seconde en haperingen
	if state == State.RACING and not get_tree().paused:
		_ev_frames += 1
		_ev_frame_time += delta
		if delta > 0.05:
			_ev_slow += 1
	if car != null:
		speed_gauge.set_speed(car.speed_kmh())
	if big_timer > 0.0:
		big_timer -= delta
		if big_timer <= 0.0:
			big_label.text = ""
	if radio_timer > 0.0:
		radio_timer -= delta
		if radio_timer <= 0.0:
			radio_label.text = ""
	police_cool = maxf(0.0, police_cool - delta)
	if get_tree().paused:
		return
	match state:
		State.COUNTDOWN:
			if Game.mp_active() and net_ghosts != null:
				var left: float = net_ghosts.countdown_left()
				if left < 0.0:
					_big("Wachten op de andere spelers...", 0.0, Color("cfd3d6"), true)
					_update_hud()
					return
				countdown = left
				if countdown <= 0.5:
					world.process_mode = Node.PROCESS_MODE_PAUSABLE
			else:
				countdown -= delta
			if countdown > 0.5:
				var n: int = ceili(countdown - 0.5)
				if n != last_beep and n <= 3:
					last_beep = n
					Sfx.play(self, "beep", -4.0)
				_big("%d" % n, 0.0, Color("f3df68"), true)
			else:
				Sfx.play(self, "go", -3.0)
				state = State.RACING
				car.controls_enabled = true
				for d in rivals:
					d.car.controls_enabled = true
				_big("GO!", 0.9, Color("7be07b"), true)
				_race_event_start()
		State.RACING:
			if free:
				_landmarks()
				_update_hud()
				return
			elapsed += delta
			race_clock += delta
			if not Game.mp_active():
				time_left -= delta
				if time_left <= 0.0:
					time_left = 0.0
					_time_up()
		State.FINISHED:
			race_clock += delta
			result_timer -= delta
			if result_timer <= 0.0:
				result_timer = 0.2
				_refresh_results()
				if flits_box != null and flits_box.visible:
					_refresh_flits()
	_update_hud()

# Vrij rijden: bij het passeren van een bezienswaardigheid de naam in beeld, en R zet
# je vanaf dan daar terug.
func _landmarks() -> void:
	for i in range(cp_s.size()):
		if i == landmark_i:
			continue
		var d: float = player_s - cp_s[i]
		if d > 0.0 and d < 12.0:
			landmark_i = i
			var r = level.route
			car.start_transform = Transform3D(r.basis_at(cp_s[i]), r.pos_at(cp_s[i]) + r.right_at(cp_s[i]) * float(level.traffic_lanes[0]) + Vector3(0, 0.3, 0))
			Sfx.play(self, "checkpoint", -6.0)
			_big(String(level.checkpoints[i]["name"]).to_upper(), 1.8, Color("f3df68"))

# Vrij rijden: de eerstvolgende bezienswaardigheid voor je en hoe ver nog.
func _next_landmark() -> Array:
	var best := -1
	var best_d := INF
	for i in range(cp_s.size()):
		var d: float = cp_s[i] - player_s
		if level.route.closed:
			d = fposmod(d, level.route.length)
		if d > 0.0 and d < best_d:
			best = i
			best_d = d
	return [best, best_d]

func _on_checkpoint(body: Node3D, idx: int) -> void:
	if body != car or state != State.RACING or idx != next_cp:
		return
	next_cp += 1
	# R zet je vanaf nu hier terug
	car.start_transform = Transform3D(cp_nodes[idx].transform.basis, cp_nodes[idx].position + cp_nodes[idx].transform.basis.x * float(level.traffic_lanes[0]) + Vector3(0, 0.3, 0))
	cp_nodes[idx].visible = false
	if next_cp >= cp_s.size():
		if lap >= laps:
			_finish()
			return
		# nieuwe ronde: alle poorten weer tonen
		lap += 1
		next_cp = 0
		for n in cp_nodes:
			n.visible = true
		time_left += lap_bonus
		Sfx.play(self, "lap", -4.0)
		_big("%s\n+%d s" % ["LAATSTE RONDE!" if lap == laps else "RONDE %d / %d" % [lap, laps], int(lap_bonus)], 1.8, Color("7be07b"))
		return
	var bonus: float = cp_bonus[next_cp]
	Sfx.play(self, "checkpoint", -5.0)
	time_left += bonus
	_big("%s\n+%d s" % [String(level.checkpoints[idx]["name"]), int(bonus)], 1.6, Color("f3df68"))

# Medaille op plaats: 1e goud, 2e zilver, 3e brons; daarbuiten geen medaille.
func _medal_for(pos: int) -> int:
	return 4 - pos if pos <= 3 else 0

func _finish() -> void:
	if Game.mp_active() and net_ghosts != null:
		_finish_mp()
		return
	state = State.FINISHED
	car.controls_enabled = false
	finish_order.append(PLAYER_NAME)
	var rows: Array = standings()
	var pos: int = 1
	for i in range(rows.size()):
		if rows[i]["name"] == PLAYER_NAME:
			pos = i + 1
	_race_event("finish", pos)
	var id: String = String(Game.current_level()["id"])
	var medal: int = _medal_for(pos)
	Sfx.play(self, "finish" if pos <= 3 else "fail", -3.0)
	var record: bool = Game.record_finish(id, elapsed, medal)
	var is_final: bool = Game.current_index == Game.LEVELS.size() - 1
	var title: String = ("PARKSTAD KAMPIOEN!" if is_final else "GEWONNEN!") if pos == 1 else "FINISH!  %de PLAATS" % pos
	var lines := [
		[title, 42, Color("f3df68") if pos <= 3 else Color.WHITE],
		["%s   %s%s" % [level.level_title, Game.format_time(elapsed), ("   " + Game.MEDAL_NAMES[medal]) if medal > 0 else ""], 26, Game.MEDAL_COLORS[medal] if medal > 0 else Color.WHITE],
		["%s   -   %s" % [Game.DIFFICULTIES[Game.difficulty()].to_upper(), "NIEUW RECORD!" if record else "record %s" % Game.format_time(Game.best_time(id))], 18, Color("7be07b") if record else Color("cfd3d6")],
	]
	if pos > 3:
		lines.append(["Eindig in de top 3 om het volgende level vrij te spelen.", 16, Color("ef5a4f")])
	lines.append_array(_payout(pos))
	var buttons := [["Opnieuw", _retry]]
	var nxt: int = Game.next_playable(Game.current_index)
	if nxt >= 0:
		buttons.insert(0, ["Volgende: %s" % Game.LEVELS[nxt]["name"], func(): Game.start_level(nxt)])
	buttons.append(["Garage", Game.garage])
	buttons.append(["Menu", Game.go_menu])
	_show_panel(lines, buttons, _results_tabs())
	_refresh_results()

# Samen racen: plaats onder de spelers, prijzengeld zoals in de single player, geen
# medailles of records; daarna terug naar de kamer.
func _finish_mp() -> void:
	state = State.FINISHED
	car.controls_enabled = false
	var pos: int = net_ghosts.finish_position()
	finish_order.append(PLAYER_NAME)
	net_ghosts.send_finish(elapsed)
	_race_event("finish", pos)
	Sfx.play(self, "finish" if pos <= 3 else "fail", -3.0)
	var n: int = (Game.mp["grid"] as Array).size()
	var lines := [
		["GEWONNEN!" if pos == 1 else "FINISH!  %de VAN %d" % [pos, n], 42, Color("f3df68") if pos <= 3 else Color.WHITE],
		["%s   %s   -   samen in kamer %s" % [level.level_title, Game.format_time(elapsed), Game.net().code], 24, Color.WHITE],
		["Samen racen: prijzengeld wel, medailles en records niet.", 16, Color("cfd3d6")],
	]
	lines.append_array(_payout(pos))
	_show_panel(lines, [["Terug naar de kamer", _back_to_room]], _results_tabs())
	_refresh_results()

func _back_to_room() -> void:
	Game.menu_tab = "together"
	Game.go_menu()

# Twee tabjes onder de titel: de uitslag en het flitsklassement.
func _results_tabs() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 8)
	v.add_child(tabs)
	results_box = _results_grid()
	flits_box = _flits_grid()
	flits_box.visible = false
	v.add_child(results_box)
	v.add_child(flits_box)
	var group := ButtonGroup.new()
	for t in [["Uitslag", false], ["Flitsklassement", true]]:
		var b := Button.new()
		b.text = String(t[0])
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = not t[1]
		b.custom_minimum_size = Vector2(170, 34)
		b.add_theme_font_size_override("font_size", 17)
		var is_flits: bool = t[1]
		b.pressed.connect(func():
			results_box.visible = not is_flits
			flits_box.visible = is_flits
			_refresh_flits())
		tabs.add_child(b)
	return v

# Knoppen onder in het paneel (Volgende, Opnieuw, Garage, Menu, Doorgaan...) die er echt
# als knop uitzien: een gevuld vlak met een gele rand en ronde hoeken; de geselecteerde
# knop (toetsenbord) krijgt een lichtere rand, indrukken maakt hem geel.
func _panel_button_style(b: Button) -> void:
	var gold := Color("f3df68")
	var states := {
		"normal": [Color(0.20, 0.25, 0.32), gold.darkened(0.3)],
		"hover": [Color(0.26, 0.32, 0.40), gold],
		"pressed": [gold, gold],
		"hover_pressed": [gold, gold],
		"focus": [Color(0, 0, 0, 0), Color.WHITE],
	}
	for k in states:
		var sb := StyleBoxFlat.new()
		sb.bg_color = states[k][0]
		sb.border_color = states[k][1]
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(7)
		sb.set_content_margin_all(6)
		sb.draw_center = k != "focus"
		b.add_theme_stylebox_override(k, sb)
	b.add_theme_color_override("font_color", Color("e6e8ea"))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color("1a1d22"))
	b.add_theme_color_override("font_hover_pressed_color", Color("1a1d22"))
	b.add_theme_color_override("font_focus_color", Color("e6e8ea"))

# Flitsklassement: hoogste geflitste snelheid (met de plek), daarna wie nooit te hard
# langs een paal reed; onderaan welke palen zijn gesloopt en door wie.
func _flits_grid() -> Control:
	flits_cells.clear()
	var v := VBoxContainer.new()
	v.add_child(_two_columns(flits_cells, [36, 110, 250], false))
	var sloop := Label.new()
	sloop.name = "Sloop"
	sloop.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sloop.add_theme_font_size_override("font_size", 16)
	sloop.add_theme_color_override("font_color", Color("7be07b"))
	v.add_child(sloop)
	return v

# In het flitsklassement je profielnaam in plaats van "Jij".
func _shown_name(n: String) -> String:
	if n == PLAYER_NAME:
		var p: String = Game.profile_name()
		return p if p != "" else n
	return n

func _refresh_flits() -> void:
	if flits_cells.is_empty():
		return
	var names: Array = [PLAYER_NAME]
	for d in rivals:
		names.append(d.driver_name)
	var fast: Array = []
	var calm: Array = []
	for n in names:
		if flits.has(n):
			fast.append(n)
		else:
			calm.append(n)
	fast.sort_custom(func(a, b): return int(flits[a][0]) > int(flits[b][0]))
	var order: Array = fast + calm
	for i in range(flits_cells.size()):
		var cells: Array = flits_cells[i]
		if i >= order.size():
			for c in cells:
				c.text = ""
			continue
		var n: String = order[i]
		var col: Color = Color("f3df68") if n == PLAYER_NAME else Color("e6e8ea")
		if flits.has(n):
			cells[0].text = "%d." % (i + 1)
			cells[2].text = "%d km/u  bij %s" % [int(flits[n][0]), String(flits[n][1])]
		else:
			cells[0].text = "-"
			cells[2].text = "keurig" if flits_measured.has(n) else "nergens gemeten"
			col = Color("8d96a0") if n != PLAYER_NAME else col
		cells[1].text = _shown_name(n)
		for c in cells:
			c.add_theme_color_override("font_color", col)
	var lines: Array = []
	for e in flits_sloop:
		lines.append("Flitspaal bij %s gesloopt door %s" % [String(e[0]), _shown_name(String(e[1]))])
	var sloop: Label = flits_box.get_node("Sloop")
	sloop.text = "\n".join(lines)
	sloop.visible = not lines.is_empty()

# Uitslag als tabel: positie, naam, tijd (winnaar) of achterstand (+1.234). Wie nog rijdt
# krijgt een geschatte achterstand (~), die wordt vervangen zodra hij finisht.
func _results_grid() -> Control:
	result_cells.clear()
	return _two_columns(result_cells, [36, 120, 120], true)

# Acht regels in twee kolommen naast elkaar (plaats 1-4 links, 5-8 rechts), zodat het
# eindscherm minder hoog is (op de telefoon). Elke regel: nummer, naam, waarde.
func _two_columns(out: Array, widths: Array, value_right: bool) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 44)
	var grids: Array = []
	for g in range(2):
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 2)
		row.add_child(grid)
		grids.append(grid)
	for i in range(8):
		var cells: Array = []
		for c in range(3):
			var l := Label.new()
			l.add_theme_font_size_override("font_size", 18)
			l.custom_minimum_size = Vector2(widths[c], 0)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if c == 0 or (c == 2 and value_right) else HORIZONTAL_ALIGNMENT_LEFT
			l.clip_text = c == 1
			l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS if c == 1 else TextServer.OVERRUN_NO_TRIMMING
			grids[0 if i < 4 else 1].add_child(l)
			cells.append(l)
		out.append(cells)
	return row

func _refresh_results() -> void:
	if result_cells.is_empty():
		return
	var rows: Array = standings()
	var L: float = level.route.length
	var target: float = float(laps) * L
	var leader_time: float = float(rows[0]["time"]) if rows[0]["finished"] else -1.0
	for i in range(mini(rows.size(), result_cells.size())):
		var row: Dictionary = rows[i]
		var me: bool = row["name"] == PLAYER_NAME
		var txt: String
		var grey := false
		if row["finished"]:
			var t: float = float(row["time"])
			txt = Game.format_time(t) if i == 0 else "+%.3f" % (t - leader_time)
		else:
			# schatting: huidige klok + resterende afstand met zijn gemiddelde snelheid tot nu toe
			var done: float = float(row["progress"]) - float(row["start"])
			var avg: float = maxf(5.0, done / maxf(1.0, race_clock))
			var est: float = race_clock + maxf(0.0, target - float(row["progress"])) / avg
			txt = ("~+%.1f" % (est - leader_time)) if leader_time > 0.0 else "ronde %d / %d" % [mini(int(row["lap"]) + 1, laps), laps]
			grey = true
		var col: Color = Color("f3df68") if me else (Color("8d96a0") if grey else Color("e6e8ea"))
		var cells: Array = result_cells[i]
		cells[0].text = "%d." % (i + 1)
		cells[1].text = _shown_name(String(row["name"]))
		cells[2].text = txt
		for c in cells:
			c.add_theme_color_override("font_color", col)

func _time_up() -> void:
	state = State.TIME_UP
	_race_event("time_up", 0)
	Sfx.play(self, "fail", -3.0)
	car.controls_enabled = false
	_show_panel([
		["TIJD OP!", 46, Color("ef5a4f")],
		["%d van %d checkpoints gehaald" % [next_cp, cp_s.size()], 24, Color.WHITE],
		["Tip: elk checkpoint geeft extra tijd, ontwijk het verkeer.", 17, Color("cfd3d6")],
	] + _payout(0), [["Opnieuw", _retry], ["Garage", Game.garage], ["Menu", Game.go_menu]])

func _retry() -> void:
	Game.start_level(Game.current_index, free)

func _unhandled_input(event: InputEvent) -> void:
	if loading:
		return
	if event.is_action_pressed("ui_cancel"):
		if state == State.FINISHED or state == State.TIME_UP:
			Game.go_menu()
		elif pause_open:
			_close_pause()
		else:
			_open_pause()
		get_viewport().set_input_as_handled()

func _open_pause() -> void:
	pause_open = true
	get_tree().paused = true
	if free:
		_show_panel([["PAUZE", 42, Color("f3df68")], ["Vrij rijden  -  %s" % Game.current_level()["name"], 22, Color.WHITE]],
			[["Doorgaan", _close_pause], ["Opnieuw beginnen", _retry],
			["Deze stad racen", func(): Game.start_level(Game.current_index, false)], [_camera_button_text(), _next_camera], ["Menu", Game.go_menu]])
		return
	_show_panel([["PAUZE", 42, Color("f3df68")], [level.level_title, 22, Color.WHITE], [Game.DIFFICULTIES[Game.difficulty()], 18, Color("9aa3ab")]],
		[["Doorgaan", _close_pause], ["Opnieuw", _retry], [_camera_button_text(), _next_camera], ["Menu", Game.go_menu]])

# Camerastandpunt wisselen vanuit het pauzemenu (de knop toont het huidige standpunt).
func _camera_button_text() -> String:
	return "Camera: " + Game.camera_view_name(Game.camera_view())

func _next_camera() -> void:
	var views: Array = Game.CAMERA_VIEWS
	var cur := 0
	for i in range(views.size()):
		if views[i][0] == Game.camera_view():
			cur = i
	var v: String = String(views[(cur + 1) % views.size()][0])
	Game.set_camera_view(v)
	if car != null:
		car.set_camera_view(v)
		car._update_camera(0.016)
	_open_pause()

func _close_pause() -> void:
	pause_open = false
	get_tree().paused = false
	panel.visible = false

# ---------------------------------------------------------------- HUD
func _hud() -> void:
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var hud := Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)
	# binnen het veilige gebied (iPhone: niet achter de Dynamic Island of in de ronde hoeken)
	var fit_safe := func():
		var sf: Vector4 = ScreenFit.safe()
		hud.offset_left = sf.x
		hud.offset_right = -sf.z
		hud.offset_bottom = -sf.w
	fit_safe.call()
	get_viewport().size_changed.connect(fit_safe)
	var title: String = ("VRIJ RIJDEN  //  " + String(Game.current_level()["name"])) if free else ("PARKSTAD RACER  //  " + String(level.level_title))
	# linksboven: titel, tijd, racetijd en ronde/checkpoint in één blokje
	info_box = PanelContainer.new()
	info_box.add_theme_stylebox_override("panel", _hud_box())
	info_box.position = Vector2(14, 12)
	info_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(info_box)
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 0)
	info_box.add_child(iv)
	iv.add_child(_label(title, Vector2.ZERO, 19, Color("f3df68")))
	time_label = _label("", Vector2.ZERO, 36, Color.WHITE)
	iv.add_child(time_label)
	elapsed_label = _label("", Vector2.ZERO, 17, Color("dfe3e6"))
	iv.add_child(elapsed_label)
	cp_label = _label("", Vector2.ZERO, 17, Color("f3df68"))
	iv.add_child(cp_label)
	# rechtsboven: mini-leaderboard (voor je, jij, achter je)
	board = PanelContainer.new()
	board.add_theme_stylebox_override("panel", _hud_box())
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	board.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	board.offset_right = -14.0
	board.offset_top = 12.0
	hud.add_child(board)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 2)
	board.add_child(bv)
	for i in range(3):
		var row := PanelContainer.new()
		var rb := StyleBoxFlat.new()
		rb.bg_color = Color(0, 0, 0, 0)
		rb.set_corner_radius_all(6)
		rb.content_margin_left = 6
		rb.content_margin_right = 8
		row.add_theme_stylebox_override("panel", rb)
		bv.add_child(row)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		row.add_child(hb)
		var lp := _label("", Vector2.ZERO, 22, Color.WHITE)
		lp.custom_minimum_size = Vector2(30, 0)
		lp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var ln := _label("", Vector2.ZERO, 20, Color.WHITE)
		ln.custom_minimum_size = Vector2(118, 0)
		ln.clip_text = true
		ln.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var lg := _label("", Vector2.ZERO, 20, Color.WHITE)
		lg.custom_minimum_size = Vector2(86, 0)
		lg.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hb.add_child(lp)
		hb.add_child(ln)
		hb.add_child(lg)
		board_rows.append([lp, ln, lg, rb])
	pos_label = null
	var controls := _label("WASD / PIJLTJES: RIJDEN    SPATIE: HANDREM    R: RESET    ESC: PAUZE", Vector2(22, 0), 17, Color.WHITE)
	controls.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	controls.position = Vector2(22, -35)
	hud.add_child(controls)
	speed_gauge = SpeedGauge.new()
	speed_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(speed_gauge)
	speed_gauge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	speed_gauge.offset_left = -290.0
	speed_gauge.offset_top = -290.0
	speed_gauge.offset_right = -15.0
	speed_gauge.offset_bottom = -15.0
	speed_gauge.set_top(car.max_forward_speed * (1.0 + car.slipstream_top_bonus) * 3.6)
	if TouchControls.enabled():
		# aanraakknoppen: geen toetsenuitleg, snelheidsmeter kleiner onderin het midden
		controls.visible = false
		speed_gauge.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		speed_gauge.offset_left = -105.0
		speed_gauge.offset_right = 105.0
		speed_gauge.offset_top = -215.0
		speed_gauge.offset_bottom = -5.0
		touch_ui = TouchControls.new()
		add_child(touch_ui)
		# de auto boven die teller in beeld houden (camera kijkt iets meer omlaag)
		car.cam_raise = true
	radio_label = _label("", Vector2(22, 168), 19, Color("9fd0ff"))
	radio_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	radio_label.add_theme_constant_override("shadow_offset_x", 2)
	radio_label.add_theme_constant_override("shadow_offset_y", 2)
	hud.add_child(radio_label)
	big_label = Label.new()
	big_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	big_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	big_label.position.y = 150
	big_label.add_theme_font_size_override("font_size", 54)
	big_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	big_label.add_theme_constant_override("shadow_offset_x", 3)
	big_label.add_theme_constant_override("shadow_offset_y", 3)
	hud.add_child(big_label)
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.1, 0.88)
	sb.border_color = Color("f3df68")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", sb)
	panel.visible = false
	hud.add_child(panel)
	panel_box = VBoxContainer.new()
	panel_box.add_theme_constant_override("separation", 10)
	panel.add_child(panel_box)
	if touch_ui != null:
		touch_ui.blocker = panel
	_update_hud()

func _update_hud() -> void:
	if free:
		time_label.visible = false
		elapsed_label.visible = false
		board.visible = false
		cp_label.add_theme_font_size_override("font_size", 22)
		var nx: Array = _next_landmark()
		if nx[0] < 0:
			cp_label.text = "EINDE VAN DE ROUTE"
		else:
			cp_label.text = "VOLGENDE:  %s   %s" % [String(level.checkpoints[nx[0]]["name"]),
				("%d m" % (int(nx[1] / 10.0) * 10)) if nx[1] < 1000.0 else ("%.1f km" % (nx[1] / 1000.0)).replace(".", ",")]
		return
	if car != null:
		var rows: Array = standings()
		for i in range(rows.size()):
			if rows[i]["name"] == PLAYER_NAME:
				race_pos = i + 1
		# na de finish (of als de tijd op is) staat de uitslag in beeld: mini-leaderboard weg
		board.visible = state == State.RACING or state == State.COUNTDOWN
		board_timer -= get_process_delta_time()
		if board.visible and board_timer <= 0.0:
			board_timer = 0.25        # vier keer per seconde: rustig te lezen
			_update_board(rows)
	time_label.text = "TIJD  %d" % ceili(time_left) if state != State.FINISHED else "TIJD  -"
	time_label.add_theme_color_override("font_color", Color("ef5a4f") if time_left < 10.0 and state == State.RACING else Color.WHITE)
	elapsed_label.text = "RACETIJD  %s" % Game.format_time(elapsed)
	var lap_text: String = ("RONDE %d / %d   " % [lap, laps]) if laps > 1 else ""
	if next_cp < cp_s.size():
		cp_label.text = lap_text + "CHECKPOINT %d / %d   >  %s" % [next_cp + 1, cp_s.size(), String(level.checkpoints[next_cp]["name"])]
	else:
		cp_label.text = "GEFINISHT"

func _hud_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.11, 0.62)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 8
	return sb

# Drie regels: de coureur voor je, jij en de coureur achter je (ben je eerste of laatste,
# dan twee achter of twee voor je). Verschil in seconden: + = hij ligt voor, - = jij.
func _update_board(rows: Array) -> void:
	var me: int = race_pos - 1
	var first: int = clampi(me - 1, 0, maxi(rows.size() - 3, 0))
	var my_prog: float = player_progress()
	for k in range(board_rows.size()):
		var cells: Array = board_rows[k]
		var i: int = first + k
		var show: bool = i < rows.size()
		for c in range(3):
			cells[c].visible = show
		if not show:
			continue
		var row: Dictionary = rows[i]
		var is_me: bool = row["name"] == PLAYER_NAME
		cells[0].text = "%d" % (i + 1)
		cells[1].text = _shown_name(String(row["name"]))
		var rb: StyleBoxFlat = cells[3]
		rb.bg_color = Color(0.95, 0.85, 0.36, 0.9) if is_me else Color(0, 0, 0, 0)
		var col: Color = Color("141820") if is_me else Color.WHITE
		cells[0].add_theme_color_override("font_color", col)
		cells[1].add_theme_color_override("font_color", col)
		cells[0].add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0) if is_me else Color.BLACK)
		cells[1].add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0) if is_me else Color.BLACK)
		if is_me:
			cells[2].text = "%d / %d" % [race_pos, rows.size()]
			cells[2].add_theme_color_override("font_color", Color("141820"))
			cells[2].add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
			continue
		cells[2].add_theme_color_override("font_shadow_color", Color.BLACK)
		var gap := -1.0
		if i < me:
			var t: float = _gap_time(String(row["name"]), my_prog)
			if t >= 0.0:
				gap = race_clock - t
			cells[2].add_theme_color_override("font_color", Color("ff9a5a"))
			cells[2].text = ("+%s" % _secs(gap)) if gap >= 0.0 else "-"
		else:
			var t2: float = _gap_time(PLAYER_NAME, float(row["progress"]))
			if t2 >= 0.0:
				gap = race_clock - t2
			cells[2].add_theme_color_override("font_color", Color("7be07b"))
			cells[2].text = ("-%s" % _secs(gap)) if gap >= 0.0 else "-"

func _secs(t: float) -> String:
	if t >= 60.0:
		return "%d:%06.3f" % [int(t / 60.0), fmod(t, 60.0)]
	return "%.3f" % t

# Beloning, bv. een omvergereden flitspaal: extra tijd en een melding.
func bonus_time(sec: float, text: String) -> void:
	if state != State.RACING:
		return
	time_left += sec
	_big("%s\n+%d s" % [text, int(sec)], 1.6, Color("7be07b"))

# Naam van een racer (jij of een tegenstander); "" voor politie en verkeer.
func racer_name(body: Node) -> String:
	if body == car:
		return PLAYER_NAME
	for d in rivals:
		if d.car == body:
			return d.driver_name
	return ""

# Plek van een flitspaal: het dichtstbijzijnde checkpoint (langs de weg gemeten).
func _camera_place(cam: Node3D) -> String:
	var L: float = level.route.length
	var s: float = level.route.closest_s(cam.global_position)
	var best := ""
	var bd := INF
	for i in range(cp_s.size()):
		var d: float = absf(float(cp_s[i]) - s)
		if level.route.closed:
			d = minf(d, L - d)
		if d < bd:
			bd = d
			best = String(level.checkpoints[i]["name"])
	return "de finish" if best == "START / FINISH" else best

func camera_measured(cam: Node3D, body: Node, kmh: int, over: bool) -> void:
	if free or not (state == State.RACING or state == State.FINISHED):
		return
	var n: String = racer_name(body)
	if n == "":
		return
	flits_measured[n] = maxi(int(flits_measured.get(n, 0)), kmh)
	if over and (not flits.has(n) or kmh > int(flits[n][0])):
		flits[n] = [kmh, _camera_place(cam)]

func camera_destroyed(cam: Node3D, body: Node) -> void:
	if free or not (state == State.RACING or state == State.FINISHED):
		return
	var n: String = racer_name(body)
	if n == "":
		n = "de politie" if police != null and body == police.car else "een verkeersdeelnemer"
	flits_sloop.append([_camera_place(cam), n])

# Melding van een flitspaal.
func flash_message(text: String) -> void:
	_big(text, 1.4, Color("f4f6ff"))

# Flitspaal omvergereden: extra tijd en geld.
func camera_knocked(sec: float) -> void:
	if free:
		Sfx.play(self, "crash", -4.0)
		_big("FLITSER OMVER!", 1.4, Color("7be07b"))
		return
	if state != State.RACING:
		return
	time_left += sec
	cash_cameras += CAMERA_BONUS
	Sfx.play(self, "crash", -4.0)
	Sfx.play(self, "coin", -5.0)
	_big("FLITSER OMVER!\n+%d s   +%s" % [int(sec), Game.format_money(CAMERA_BONUS)], 1.6, Color("7be07b"))

# Geflitst: geen boete, maar de politie komt eraan (zie spawn_police).
func speeding_fine(kmh: int, limit: int) -> void:
	if free:
		Sfx.play(self, "flash", -3.0)
		_big("GEFLITST!  %d km/u  (max %d)" % [kmh, limit], 1.4, Color("f4f6ff"))
		return
	if state != State.RACING:
		return
	Sfx.play(self, "flash", -3.0)
	_big("GEFLITST!  %d km/u  (max %d)" % [kmh, limit], 1.6, Color("ef5a4f"))
	spawn_police(kmh)

# ---------------------------------------------------------------- politie
const POLICE_FINE := 300
const POLICE_TIME := 6.0
const POLICE_ESCAPE_BONUS := 100
const POLICE_BEHIND := 120.0
# De politie groeit mee met jouw auto (inclusief upgrades): jouw rijwaarden maal deze
# factoren [snelheid, acceleratie, grip, remmen], op Normaal en op Moeilijk.
const POLICE_CAR := [[1.06, 1.15, 1.08, 1.05], [1.1, 1.22, 1.12, 1.08]]

# Na een flitser of een aangereden fietser: een politieauto start een eind achter je en komt achter je aan.
# Na een flitser niet op Makkelijk en niet vlak na een vorige achtervolging; na een fietser
# altijd. Nooit bij vrij rijden of als de politie uit staat, en maar één tegelijk.
func spawn_police(kmh: int, message := "", always := false) -> void:
	if free or state != State.RACING or not Game.police_enabled():
		return
	if not always and (Game.difficulty() == 0 or police_cool > 0.0):
		return
	if police != null:
		return
	var r = level.route
	var s: float = player_s - POLICE_BEHIND
	if r.closed:
		s = fposmod(s, r.length)
	elif s < 5.0:
		return
	var l: float = float(level.traffic_lanes[0])
	if police_spare == null or not is_instance_valid(police_spare):
		_build_police_spare()
	var pc: ArcadeCar = police_spare
	police_spare = null
	pc.visible = true
	pc.process_mode = Node.PROCESS_MODE_INHERIT
	pc.transform = Transform3D(r.basis_at(s), r.pos_at(s) + r.right_at(s) * l + Vector3(0, 0.3, 0))
	pc.add_child(CarAudio.new())
	pc.drive_speed = absf(car.drive_speed) * 0.9
	pc.controls_enabled = true
	var p = pc.get_node("PoliceDriver")
	p.setup(self, pc, l, Game.difficulty() == 2)
	police = p
	var where: String = String(Game.current_level()["name"])
	if message != "":
		police_radio(message % where)
	else:
		police_radio("Meldkamer: voertuig geflitst met %d km/u in %s. Eenheid 12, graag aanhouden." % [kmh, where])

func police_radio(text: String) -> void:
	radio_label.text = "PORTOFOON  " + text
	radio_timer = 4.5
	Sfx.play(self, "radio", -6.0)

func police_caught() -> void:
	police_cool = 25.0
	police_radio("Eenheid 12: voertuig staat stil, we schrijven een bon.")
	if state != State.RACING:
		return
	var fine: int = _scaled(POLICE_FINE)
	cash_fines += fine
	time_left = maxf(0.0, time_left - POLICE_TIME)
	Sfx.play(self, "fail", -4.0)
	_big("AANGEHOUDEN!\n-%d s   BOETE  %s" % [int(POLICE_TIME), Game.format_money(fine)], 2.0, Color("6fa8ff"))

func police_escaped(earned := true) -> void:
	police_cool = 25.0
	if not earned:
		# hij was nog vlak bij je: geen ontsnapping, de politie heeft een andere melding
		police_radio("Eenheid 12: andere melding binnen, we breken de achtervolging af.")
		return
	police_radio("Eenheid 12: we zijn hem kwijt. Achtervolging gestaakt.")
	if state != State.RACING:
		return
	cash_escape += POLICE_ESCAPE_BONUS
	Sfx.play(self, "coin", -5.0)
	_big("ONTSNAPT!\n+%s" % Game.format_money(POLICE_ESCAPE_BONUS), 1.6, Color("7be07b"))

func police_gone(p) -> void:
	if police == p:
		police = null
	# meteen de volgende klaarzetten, nu er toch niets gebeurt
	if police_spare == null:
		_build_police_spare.call_deferred()

# De politieauto wordt tijdens het laden gebouwd en weggezet (onzichtbaar, zonder
# natuurkunde), zodat het flitsen geen hapering geeft. Zijn materialen worden zo ook
# meegenomen in de voorbereiding van het laadscherm.
func _build_police_spare() -> void:
	# ook op Makkelijk: na een aangereden fietser komt de politie altijd
	if free or not Game.police_enabled():
		return
	var pc := ArcadeCar.new()
	pc.name = "Police"
	pc.ai = true
	pc.body_color = Color("f4f4f0")
	pc.car_style = "estate"
	pc.race_number = -1
	_apply_stats(pc, Game.car_stats(Game.selected_car()))
	var pf: Array = POLICE_CAR[1 if Game.difficulty() == 2 else 0]
	pc.max_forward_speed *= float(pf[0])
	pc.acceleration *= float(pf[1])
	pc.grip *= float(pf[2])
	pc.braking *= float(pf[3])
	# zijn snelheidsprofiel over de hele route alvast uitrekenen (dat is het zwaarste deel)
	pc.set_meta("profile", profile_for(pc, level.route))
	pc.process_mode = Node.PROCESS_MODE_DISABLED
	pc.visible = false
	pc.position = Vector3(0, -500, 0)
	world.add_child(pc)
	var p := Police.new()
	p.name = "PoliceDriver"
	pc.add_child(p)
	p.prepare(pc)
	police_spare = pc

# Fietser omvergereden: boete en tijdstraf.
# Geen geld, maar flink wat tijd: doe je het te vaak, dan raak je door je tijd heen. En de
# politie komt altijd (ook op Makkelijk), tenzij de politie uit staat.
const CYCLIST_TIME := 8.0
func cyclist_hit() -> void:
	if free:
		_big("PAS OP, FIETSER!", 1.4, Color("ef5a4f"))
		return
	if state != State.RACING:
		return
	time_left = maxf(0.0, time_left - CYCLIST_TIME)
	Sfx.play(self, "fail", -3.0)
	_big("FIETSER AANGEREDEN!\n-%d s" % int(CYCLIST_TIME), 1.8, Color("ef5a4f"))
	spawn_police(0, "Meldkamer: aanrijding met een fietser in %s, het voertuig rijdt door. Eenheid 12, graag aanhouden.", true)

# Door rood gereden: net als een flitser omverrijden levert dat juist iets op (een
# klein bedrag, want of het licht net rood is, is vooral geluk).
const RED_LIGHT_BONUS := 50
func red_light_fine() -> void:
	if free:
		_big("DOOR ROOD!", 1.2, Color("f4f6ff"))
		return
	if state != State.RACING:
		return
	cash_red += RED_LIGHT_BONUS
	Sfx.play(self, "coin", -5.0)
	_big("DOOR ROOD!\n+%s" % Game.format_money(RED_LIGHT_BONUS), 1.4, Color("7be07b"))

# Boetebedrag voor dit level: 50% in het eerste level, oplopend tot 100% in de finale,
# afgerond op tientallen.
func _scaled(amount: int) -> int:
	var n: int = maxi(1, Game.LEVELS.size() - 1)
	var f: float = 0.5 + 0.5 * float(Game.current_index) / float(n)
	return maxi(10, int(round(float(amount) * f / 10.0)) * 10)

# Prijzengeld voor plaats pos (1-8) in dit level.
func prize_for(pos: int) -> int:
	var base: int = PRIZE_BASE + PRIZE_PER_LEVEL * Game.current_index
	var f: float = PRIZE_DIFF[clampi(Game.difficulty(), 0, 2)]
	return int(round(float(base) * float(PRIZE_SHARE[clampi(pos - 1, 0, 7)]) * f / 10.0)) * 10

# Rekent af aan het eind van de race en geeft de regels voor het eindscherm.
func _payout(pos: int) -> Array:
	var prize: int = prize_for(pos) if pos > 0 else 0
	# boetes gaan alleen van wat je deze race verdient af (nooit van je spaargeld), en
	# hoogstens de helft daarvan: goed rijden levert altijd iets op
	var earned: int = prize + cash_cameras + cash_red + cash_escape
	var charged: int = mini(cash_fines, int(float(earned) * FINE_CAP))
	var total: int = prize + cash_cameras + cash_red + cash_escape - charged
	if not paid:
		paid = true
		Game.add_money(total)
	# kort: "+€ 1.000 prijs   +€ 250 flitsers   -€ 50 boetes   =  +€ 1.200"
	var parts: Array = []
	if prize > 0:
		parts.append("+%s prijs" % Game.format_money(prize))
	if cash_cameras > 0:
		parts.append("+%s flitsers" % Game.format_money(cash_cameras))
	if cash_red > 0:
		parts.append("+%s door rood" % Game.format_money(cash_red))
	if cash_escape > 0:
		parts.append("+%s ontsnapt" % Game.format_money(cash_escape))
	if cash_fines > 0:
		parts.append("-%s boetes%s" % [Game.format_money(charged), " (max.)" if charged < cash_fines else ""])
	var line: String = ("   ".join(parts) if parts.size() > 0 else "geen inkomsten") + "   =  %s%s" % ["+" if total >= 0 else "", Game.format_money(total)]
	return [[line, 16, Color("7be07b") if total >= 0 else Color("ef5a4f")], ["Saldo: %s" % Game.format_money(Game.money()), 18, Color("f3df68")]]

# Melding midden boven in beeld. Gewone meldingen (checkpoint, flitser, ronde) klein en hoog in
# de lucht, zodat ze de weg en het verkeer niet bedekken; het aftellen (big = true) groot, want
# dan sta je toch stil.
func _big(text: String, hold: float, color: Color, big := false) -> void:
	big_label.text = text
	big_label.add_theme_font_size_override("font_size", 54 if big else 32)
	big_label.position.y = 150.0 if big else 92.0
	big_label.add_theme_color_override("font_color", color)
	big_timer = hold if hold > 0.0 else 0.0

func _show_panel(lines: Array, buttons: Array, extra: Control = null) -> void:
	# oude inhoud meteen uit het paneel halen (queue_free alleen gebeurt pas later, en dan
	# telt die nog mee bij de grootte: het paneel werd dan soms twee keer zo lang)
	for c in panel_box.get_children():
		panel_box.remove_child(c)
		c.queue_free()
	for ln in lines:
		var l := Label.new()
		l.text = String(ln[0])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", int(ln[1]))
		l.add_theme_color_override("font_color", ln[2])
		panel_box.add_child(l)
	if extra != null:
		panel_box.add_child(extra)
	var first: Button = null
	# vier of meer knoppen: twee naast elkaar, anders wordt het paneel te hoog voor een telefoon
	var holder: Container = panel_box
	if buttons.size() >= 4:
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		panel_box.add_child(grid)
		holder = grid
	for b in buttons:
		var btn := Button.new()
		btn.text = String(b[0])
		btn.custom_minimum_size = Vector2(320 if holder == panel_box else 250, 44)
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(b[1])
		_panel_button_style(btn)
		holder.add_child(btn)
		if first == null:
			first = btn
	# alle knoppen in het rooster even breed (de breedste bepaalt), netjes in het midden
	if holder != panel_box:
		var w := 0.0
		for c in holder.get_children():
			w = maxf(w, (c as Control).get_combined_minimum_size().x)
		for c in holder.get_children():
			(c as Control).custom_minimum_size.x = w
	panel.visible = true
	panel_box.reset_size()
	panel.reset_size()
	panel.call_deferred("reset_size")
	if first != null:
		first.call_deferred("grab_focus")

func _label(value: String, at: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label
