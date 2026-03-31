extends Control

const FICHA: PackedScene = preload("res://scenes/ficha.tscn")
const RUTA: String = "user://save.txt"
const MINUTOS: int = 3
const PREGUNTAS: int = 20

@onready var la_info: String = $Oscuro/Evaluacion/Informacion.text
var segundos: float = MINUTOS * 60.0

# almacena las preguntas como { pregunta, bool_usr, int_res, bool_res, opc1, opc2, opc3, opc4 }
var preguntas: Array = []
var preg_actual: int = 0
var mi_nombre: String = ""

func _ready() -> void:
	$Preguntas.visible = false
	$Oscuro/Evaluacion/Introduccion.visible = true
	$Oscuro/Evaluacion/Resultados.visible = false
	var txt = $Oscuro/Evaluacion/Introduccion/InfoIni.text
	$Oscuro/Evaluacion/Introduccion/InfoIni.text = txt.\
		replace("$$", str(MINUTOS)).replace("$", str(PREGUNTAS))
	demo_basura()
	barajar_preguntas()

func demo_basura() -> void:
	# para llenar preguntas de basura en caso de no haber sido escritas aun
	var i = 0
	for ndo in $Preguntas.get_children():
		if ndo.text == "":
			if ndo.name.contains("Usr"):
				ndo.text = "Pregunta Usr " + str(i)
			else:
				ndo.text = "Pregunta Tec " + str(i)
			ndo.get_node("Answers").text = "Respuesta A\nRespuesta B\nRespuesta C\nRespuesta D"
		i += 1

func barajar_preguntas() -> void:
	var tot_usr = []
	var tot_tec = []
	for ndo in $Preguntas.get_children():
		if ndo.name.contains("Usr"):
			tot_usr.append(ndo)
		else:
			tot_tec.append(ndo)
	tot_usr.shuffle()
	tot_tec.shuffle()
	var oscila: bool = randf() < 0.5
	for i in range(PREGUNTAS):
		if oscila:
			preguntas.append(obtener_qst(tot_usr[i]))
		else:
			preguntas.append(obtener_qst(tot_tec[i]))
		oscila = not oscila
	preguntas.shuffle()
	pinta_info()

func obtener_qst(nodo: Node) -> Dictionary:
	# { pregunta, bool_usr, int_res, bool_res, opc1, opc2, opc3, opc4 }
	var baraja = [0, 1, 2, 3]
	baraja.shuffle()
	var qst = {
		"pregunta": nodo.text,
		"bool_usr": nodo.name.contains("Usr"),
		"int_res": baraja.find(0),
		"bool_res": false
	}
	var ans = nodo.get_node("Answers").text.split("\n")
	if len(ans) == 4:
		var i = 1
		for b in baraja:
			qst["opc" + str(i)] = ans[b]
			i += 1
	else:
		for i in range(4):
			qst["opc" + str(i + 1)] = ""
	return qst

func seleccionar_una(opcion: int) -> void:
	preguntas[preg_actual]["bool_res"] = preguntas[preg_actual]["int_res"] == opcion - 1
	preg_actual += 1
	if preg_actual == PREGUNTAS:
		finalizo_examen()
	else:
		pinta_info()
	$Anima.play("opacar")

func finalizo_examen() -> void:
	$TimExamen.stop()
	# guardado de los resultados
	var tot_usr = [0, 0]
	var tot_tec = [0, 0]
	for prg in preguntas:
		if prg["bool_usr"]:
			tot_usr[1] += 1
			if prg["bool_res"]:
				tot_usr[0] += 1
		else:
			tot_tec[1] += 1
			if prg["bool_res"]:
				tot_tec[0] += 1
	var data = mi_nombre
	for tot in [tot_usr, tot_tec]:
		data += "|" + str(int((float(tot[0]) / tot[1]) * 50) / 10.0)
	data += "|" + str(int((float(tot_usr[0] + tot_tec[0]) / (tot_usr[1] + tot_tec[1])) * 50) / 10.0)
	data += "|" + obtener_fecha_formateada()
	escribir_en_archivo(RUTA, data)
	ver_resultados()

func ver_resultados() -> void:
	$Oscuro/Result.visible = false
	$Oscuro/Evaluacion/Resultados.visible = true
	$Anima.play("opacar")
	# abrir los resultados
	var data: Array = leer_archivo(RUTA)
	for d in data:
		var prg: Array = d.split("|")
		if len(prg) == 5:
			var ficha = FICHA.instantiate()
			ficha.set_all(prg[0], prg[1], prg[2], prg[3], prg[4])
			$Oscuro/Evaluacion/Resultados/Results/Scroll/Vbox.add_child(ficha)
			$Oscuro/Evaluacion/Resultados/Results/Scroll/Vbox.move_child(ficha, 0)

# file acces

func escribir_en_archivo(ruta: String, contenido: String):
	var archivo = null
	if FileAccess.file_exists(ruta):
		archivo = FileAccess.open(ruta, FileAccess.READ_WRITE)
		archivo.seek_end() 
	else:
		archivo = FileAccess.open(ruta, FileAccess.WRITE)
	if archivo:
		var bytes = contenido.to_utf8_buffer()
		archivo.store_line(Marshalls.raw_to_base64(bytes))
		archivo.close()

func leer_archivo(ruta: String) -> Array:
	if FileAccess.file_exists(ruta):
		var archivo = FileAccess.open(ruta, FileAccess.READ)
		var contenido: Array = []
		if archivo:
			var txt = archivo.get_as_text()
			archivo.close()
			contenido = txt.split("\n", false)
			for i in range(len(contenido)):
				var bytes = Marshalls.base64_to_raw(contenido[i])
				contenido[i] = bytes.get_string_from_utf8()
		return contenido
	return []

func obtener_fecha_formateada() -> String:
	var d = Time.get_datetime_dict_from_system()
	var formato = "%02d/%02d/%04d - %02d:%02d:%02d"
	return formato % [d.day, d.month, d.year, d.hour, d.minute, d.second]

# temporizador y estados

func _on_tim_examen_timeout() -> void:
	segundos -= 1.0
	if segundos <= 0:
		finalizo_examen()
	else:
		$TimExamen.start()
		pinta_info()

func pinta_info() -> void:
	# poner textos de pregunta
	$Oscuro/Evaluacion/Pregunta.text = preguntas[preg_actual]["pregunta"]
	for i in range(4):
		get_node("Oscuro/Evaluacion/Opt" + str(i + 1)).text =\
			preguntas[preg_actual]["opc" + str(i + 1)]
	# poner informacion
	var tot = (float(preg_actual) / PREGUNTAS) * 100
	$Oscuro/Evaluacion/Informacion.text = la_info.\
		replace("$$", str(int(segundos))).replace("$", str(int(tot)))

# pulsacion de botones

func _on_iniciar_pressed() -> void:
	mi_nombre = $Oscuro/Evaluacion/Introduccion/LinNombre.text
	mi_nombre = mi_nombre.replace("\n", "").replace("|", "").strip_edges()
	if mi_nombre == "":
		$Anima.play("error_name")
	else:
		$Oscuro/Evaluacion/Introduccion.visible = false
		$Oscuro/Result.visible = false
		$TimExamen.start()
		$Anima.play("opacar")
		pinta_info()

func _on_result_pressed() -> void:
	ver_resultados()

func _on_salir_pressed() -> void:
	queue_free()

func _on_opt_1_pressed() -> void:
	seleccionar_una(1)

func _on_opt_2_pressed() -> void:
	seleccionar_una(2)

func _on_opt_3_pressed() -> void:
	seleccionar_una(3)

func _on_opt_4_pressed() -> void:
	seleccionar_una(4)
