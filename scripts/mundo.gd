extends Control

const EXAMEN = preload("res://scenes/examen.tscn")

# las fichas: rojo (atacante), verde (victima), azul (proteccion)

var matrix = []

func _ready() -> void:
	randomize()
	$Anima.play("luz")
	# conectar todos los botones a un unico metodo
	for btn in $Ventanas.get_children():
		btn.connect("toggled", Callable(self, "pulsa_ventana").bind(btn))
	# mostrar el menu principal
	$Menu.visible = true
	# inicializacion de matrix
	for y in range(8):
		matrix.append([])
		for x in range(16):
			matrix[-1].append(false)
	# debug
	#putNumVentana()

func pulsa_ventana(is_toggled: bool, boton: Button) -> void:
	if is_toggled:
		# evitar que haya mas ventanas seleccionadas
		for btn in $Ventanas.get_children():
			if btn != boton and btn.button_pressed:
				btn.button_pressed = false
		# mostrar lo que hay en la ventana seleccionada
		$Menu.visible = false
		var ind = boton.name.replace("Btn", "")
		for pag in $Info.get_children():
			pag.visible = pag.name == "Pag" + ind
	else:
		# mostrar el menu principal porque no hay ventana seleccionada
		$Menu.visible = true

func _on_btn_back_pressed() -> void:
	for btn in $Ventanas.get_children():
		btn.button_pressed = false
	$Menu.visible = true

func putNumVentana() -> void:
	# coloca los numeros ind en cada ventana
	for btn in $Ventanas.get_children():
		var ind = btn.name.replace("Btn", "")
		btn.text = ind
		if get_node("Info/Pag" + ind + "/Texto").text != "":
			btn.self_modulate = Color(1, 1, 1, 0.25)

func _on_timer_matrix_timeout() -> void:
	# mover viejos valores
	for y in range(7, 0, -1):
		for x in range(16):
			matrix[y][x] = matrix[y - 1][x]
	# colocar nuevos valores
	for x in range(16):
		matrix[0][x] = randf() < 0.333
	# dibujar la matrix
	var m = ""
	for y in range(8):
		for x in range(16):
			if matrix[y][x]:
				m += "1"
			else:
				m += "0"
			if x == 15:
				break
			m += " "
		if y == 7:
			break
		m += "\n"
	$Info/Pag48/Matrix.text = m

func _on_button_pressed() -> void:
	var examen = EXAMEN.instantiate()
	add_child(examen)
