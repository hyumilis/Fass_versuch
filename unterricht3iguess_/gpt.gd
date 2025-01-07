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
	mesh = ArrayMesh.new()
	var alpha = 2 * PI / segments
	var stretch_factor = -(thickness - radius) / pow(height / 2, 2)

	""" TOP CAP """
	var top_surface = []
	top_surface.resize(Mesh.ARRAY_MAX)
	var top_verts = PackedVector3Array()
	var top_normals = PackedVector3Array()
	var top_indices = PackedInt32Array()

	for i in range(segments):
		top_verts.push_back(Vector3(radius * cos(alpha * i), radius * sin(alpha * i), height))
		top_normals.push_back(Vector3(0, 0, 1))
		top_indices.push_back(segments)
		top_indices.push_back((i + 1) % segments)
		top_indices.push_back(i)

	top_verts.push_back(Vector3(0, 0, height))  # Center vertex
	top_normals.push_back(Vector3(0, 0, 1))

	top_surface[Mesh.ARRAY_VERTEX] = top_verts
	top_surface[Mesh.ARRAY_NORMAL] = top_normals
	top_surface[Mesh.ARRAY_INDEX] = top_indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, top_surface)

	""" BOTTOM CAP """
	var bottom_surface = []
	bottom_surface.resize(Mesh.ARRAY_MAX)
	var bottom_verts = PackedVector3Array()
	var bottom_normals = PackedVector3Array()
	var bottom_indices = PackedInt32Array()

	for i in range(segments):
		bottom_verts.push_back(Vector3(radius * cos(alpha * i), radius * sin(alpha * i), 0))
		bottom_normals.push_back(Vector3(0, 0, -1))
		bottom_indices.push_back(i)
		bottom_indices.push_back((i + 1) % segments)
		bottom_indices.push_back(segments)

	bottom_verts.push_back(Vector3(0, 0, 0))  # Center vertex
	bottom_normals.push_back(Vector3(0, 0, -1))

	bottom_surface[Mesh.ARRAY_VERTEX] = bottom_verts
	bottom_surface[Mesh.ARRAY_NORMAL] = bottom_normals
	bottom_surface[Mesh.ARRAY_INDEX] = bottom_indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, bottom_surface)

	""" LATERAL SURFACE WITH BEVEL """
	var lateral_surface = []
	lateral_surface.resize(Mesh.ARRAY_MAX)
	var lateral_verts = PackedVector3Array()
	var lateral_normals = PackedVector3Array()
	var lateral_indices = PackedInt32Array()

	for n in range(bevel_count):
		var segment_height = height / bevel_count
		var current_height = segment_height * n
		var next_height = segment_height * (n + 1)

		# Am oberen und unteren Rand bleibt der Radius konstant.
		var current_radius = radius if n == 0 else radius + stretch_factor * pow(current_height - height / 2, 2)
		var next_radius = radius if n == (bevel_count - 1) else radius + stretch_factor * pow(next_height - height / 2, 2)

		for i in range(segments):
			var angle = alpha * i
			var next_angle = alpha * ((i + 1) % segments)

			# Define vertices
			var bottom_current = Vector3(current_radius * cos(angle), current_radius * sin(angle), current_height)
			var bottom_next = Vector3(current_radius * cos(next_angle), current_radius * sin(next_angle), current_height)
			var top_current = Vector3(next_radius * cos(angle), next_radius * sin(angle), next_height)
			var top_next = Vector3(next_radius * cos(next_angle), next_radius * sin(next_angle), next_height)

			# Append vertices
			lateral_verts.append(bottom_current)
			lateral_verts.append(top_current)
			lateral_verts.append(bottom_next)
			lateral_verts.append(top_next)

			# Append normals
			var normal_current = Vector3(cos(angle), sin(angle), 0).normalized()
			var normal_next = Vector3(cos(next_angle), sin(next_angle), 0).normalized()
			lateral_normals.append(normal_current)
			lateral_normals.append(normal_current)
			lateral_normals.append(normal_next)
			lateral_normals.append(normal_next)

			# Append indices
			var base_index = (n * segments + i) * 4
			lateral_indices.append(base_index)
			lateral_indices.append(base_index + 1)
			lateral_indices.append(base_index + 2)
			lateral_indices.append(base_index + 2)
			lateral_indices.append(base_index + 1)
			lateral_indices.append(base_index + 3)

	lateral_surface[Mesh.ARRAY_VERTEX] = lateral_verts
	lateral_surface[Mesh.ARRAY_NORMAL] = lateral_normals
	lateral_surface[Mesh.ARRAY_INDEX] = lateral_indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, lateral_surface)
