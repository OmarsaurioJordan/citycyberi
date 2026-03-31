extends VBoxContainer

func set_all(nombre: String, nota1: String, nota2: String, nota3: String, fecha: String) -> void:
	$Data/Header/Nombre.text = nombre
	$Data/Header/Fecha.text = fecha
	$Data/NotaUsr.text = nota1
	$Data/NotaTec.text = nota2
	$Data/NotaFin.text = nota3
