extends Control

const MINUTOS: int = 3
const PREGUNTAS: int = 20

@onready var la_info: String = $Oscuro/Evaluacion/Informacion.text
var segundos: float = MINUTOS * 60.0

# almacena las preguntas como [pregunta, bool_usr, int_res, opc1, opc2, opc3, opc4] opc ya barajadas
var preguntas: Array = []
var preg_actual: int = 0

# lista de bool segun respuesta buena o mala
var res_usr: Array = []
var res_tec: Array = []

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
			ndo.text = "Pregunta " + str(i)
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
	for i in range(PREGUNTAS):
		preguntas.append(obtener_qst(tot_usr[i]))
	pinta_info()

func obtener_qst(nodo: Node) -> Array:
	# [pregunta, bool_usr, int_res, opc1, opc2, opc3, opc4]
	var baraja = [0, 1, 2, 3]
	baraja.shuffle()
	var qst = [nodo.text, nodo.name.contains("Usr"), baraja.find(0)]
	var ans = nodo.get_node("Answers").text.split("\n")
	if len(ans) == 4:
		for b in baraja:
			qst.append(ans[b])
	else:
		qst.append_array(["", "", "", ""])
	return qst

func seleccionar_una(opcion: int) -> void:
	if preguntas[preg_actual][1]:
		res_usr.append(preguntas[preg_actual][2] == opcion - 1)
	else:
		res_tec.append(preguntas[preg_actual][2] == opcion - 1)
	preg_actual += 1
	if preg_actual == PREGUNTAS:
		finalizo_examen()
	else:
		pinta_info()
	$Anima.play("opacar")

func finalizo_examen() -> void:
	$TimExamen.stop()
	# guardado de los resultados
	# Tarea
	ver_resultados()

func ver_resultados() -> void:
	$Oscuro/Result.visible = false
	$Oscuro/Evaluacion/Resultados.visible = true
	$Anima.play("opacar")
	# abrir los resultados
	# Tarea

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
	$Oscuro/Evaluacion/Pregunta.text = preguntas[preg_actual][0]
	for i in range(4):
		get_node("Oscuro/Evaluacion/Opt" + str(i + 1)).text = preguntas[preg_actual][3 + i]
	# poner informacion
	var tot = (float(preg_actual) / PREGUNTAS) * 100
	$Oscuro/Evaluacion/Informacion.text = la_info.\
		replace("$$", str(int(segundos))).replace("$", str(int(tot)))

# pulsacion de botones

func _on_iniciar_pressed() -> void:
	if $Oscuro/Evaluacion/Introduccion/LinNombre.text == "":
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
