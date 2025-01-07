extends MeshInstance3D


@export_range(3, 720) var segments := 6:
	set(value):
		segments = value
		recreate_mesh()
	get():
		return segments

@export_range(0.0001, 2048) var height := 4.0:
	set(value):
		height = value
		recreate_mesh()
	get():
		return height

@export_range(0.0001, 2048) var radius := 1.0:
	set(value):
		radius = value
		recreate_mesh()
	get():
		return radius

@export_range(0.0001, 2048) var thickness := 2.0:
	set(value):
		thickness = value
		recreate_mesh()
	get():
		return thickness

@export_range(0, 2048) var bevel_count := 2:
	set(value):
		bevel_count = value
		recreate_mesh()
	get():
		return bevel_count




func _enter_tree() -> void:
	recreate_mesh()

func recreate_mesh():


	"""top"""

	mesh = ArrayMesh.new()
	var surface_array_cap = []
	surface_array_cap.resize(Mesh.ARRAY_MAX)
	var verts_cap = PackedVector3Array()
	var norms_cap = PackedVector3Array()
	var index_cap = PackedInt32Array()
	var alpha = 2 * PI / segments

	for i in range(segments):
		verts_cap.push_back(Vector3(radius * cos(alpha * i), radius * sin(alpha * i), height/2))
		norms_cap.push_back(Vector3(0,0,1))
		index_cap.push_back(i+1)
		index_cap.push_back(i)
		index_cap.push_back(segments)

	verts_cap.push_back(Vector3(0,0,height/2))
	norms_cap.push_back(Vector3(0,0,1))
	index_cap.push_back(0)
	index_cap.push_back(segments-1)
	index_cap.push_back(segments)

	surface_array_cap[Mesh.ARRAY_VERTEX] = verts_cap
	surface_array_cap[Mesh.ARRAY_INDEX] = index_cap

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array_cap)


	"""bottom"""

	var surface_array_bot = []
	surface_array_bot.resize(Mesh.ARRAY_MAX)
	var verts_bot = PackedVector3Array()
	var norms_bot = PackedVector3Array()
	var index_bot = PackedInt32Array()

	for i in range(segments):
		verts_bot.push_back(Vector3(radius * cos(alpha * i), radius * sin(alpha * i), -height/2))
		norms_bot.push_back(Vector3(0,0,-1))
		index_bot.push_back(i)
		index_bot.push_back(i+1)
		index_bot.push_back(segments)

	verts_bot.push_back(Vector3(0,0,-height/2))
	norms_bot.push_back(Vector3(0,0,-1))
	index_bot.push_back(0)
	index_bot.push_back(segments)
	index_bot.push_back(segments-1)

	surface_array_bot[Mesh.ARRAY_VERTEX] = verts_bot
	surface_array_bot[Mesh.ARRAY_INDEX] = index_bot

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array_bot)


	"""lateral_surface"""
	
	var streckfaktor := 0.0
	var d = float(thickness - radius)
	
	streckfaktor = float(-d / float(height/2)**2)

	var surface_array_lats = []
	surface_array_lats.resize(Mesh.ARRAY_MAX)
	var verts_lats = PackedVector3Array()
	var norms_lats = PackedVector3Array()
	var index_lats = PackedInt32Array()

	var segment_height = float(height / (bevel_count+1))

	for n in range (bevel_count + 1):
		var add_previus = 0
		var current_height = float((segment_height*n) - (height/2))
		var add_current = streckfaktor * (current_height + segment_height) ** 2.0 + d

		for i in range(segments):
			var angle = alpha * i
			var next_angle = alpha * ((i + 1) % segments)

			var bottom_current = Vector3((radius+add_previus) * cos(angle), (radius+add_previus) * sin(angle), current_height)
			var bottom_next = Vector3((radius+add_previus) * cos(next_angle), (radius+add_previus) * sin(next_angle), current_height)
			var top_current = Vector3((radius+add_current) * cos(angle), (radius+add_current) * sin(angle), current_height + segment_height)
			var top_next = Vector3((radius+add_current) * cos(next_angle), (radius+add_current) * sin(next_angle), current_height + segment_height)

			verts_lats.append(bottom_current)
			verts_lats.append(top_current)
			verts_lats.append(bottom_next)
			verts_lats.append(top_next)

			var normal_current = Vector3(cos(angle), sin(angle), 0).normalized()
			var normal_next = Vector3(cos(next_angle), sin(next_angle), 0).normalized()

			norms_lats.append(normal_current)
			norms_lats.append(normal_current)
			norms_lats.append(normal_next)
			norms_lats.append(normal_next)

			var base_index = (n * segments + i) * 4
			index_lats.append(base_index)
			index_lats.append(base_index + 1)
			index_lats.append(base_index + 2)

			index_lats.append(base_index + 2)
			index_lats.append(base_index + 1)
			index_lats.append(base_index + 3)
		add_previus = add_current       #Hier ist das Problem aber ich hab kein Plan wieso es nicht Funktioniert!



	surface_array_lats[Mesh.ARRAY_VERTEX] = verts_lats
	surface_array_lats[Mesh.ARRAY_NORMAL] = norms_lats
	surface_array_lats[Mesh.ARRAY_INDEX] = index_lats
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array_lats)
