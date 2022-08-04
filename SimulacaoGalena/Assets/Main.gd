extends Node2D


onready var linha:Line2D = get_node("Line2D")
onready var retangulo:ColorRect = get_node("ColorRect")
onready var transConfigButton:Button = get_node("TransConfigButton")
onready var TransConfigBG:ColorRect = get_node("TransConfigButton/TransConfigBG")


onready var ponto0 = get_node("Ponto0") #Offset da posição
onready var ponto1 = get_node("Ponto1") 
onready var ponto2 = get_node("Ponto2")
onready var ponto3 = get_node("Ponto3")
onready var ponto4 = get_node("Ponto4")
onready var pontoSaida = ponto2
onready var pontoSintonizador = ponto2
#onready var pontoRetificado

onready var retificadorInfo = get_node("Control/RetificadorInfo")
onready var sintonizadorInfo = get_node("Control/SintonizadorInfo")
onready var saidaInfo = get_node("Control/SaidaInfo")
onready var filtroInfo = get_node("Control/FiltroInfo")

onready var periodoSintVal:Label = get_node("Circuito/SliderPeriodoSintonizador/SliderPeriodoSintonizadorVal")
onready var periodoCarrierVal:Label = get_node("TransmitionSettings/SliderPeriodoCarrier/SliderPeriodoCarrierVal")

onready var periodoDeTrans = .1
onready var periodoCarrierTrans = .5

onready var amplitude = 50 #Amplitude da onda
onready var periodo = .05 #Periodo da onda
onready var periodoCarrier = .5

onready var periodoSint = .5

var espacoAmostral = 420

var comprimentoDeOndaCarrier:float
var comprimentoDeOndaSeno:float

onready var pontoInicialCarrier:Vector2
onready var pontoFinalCarrier:Vector2

onready var poolCarrier:PoolVector2Array #Ponto0
onready var poolSenoidal:PoolVector2Array #Ponto1
onready var poolModulada:PoolVector2Array #ponto4
onready var poolRetificada:PoolVector2Array #Ponto2
onready var poolSaida:PoolVector2Array #PontoSaida
onready var poolSintonizador:PoolVector2Array #PontoSintonizador


var retificadorInfoIsOn = false
var saidaInfoIsOn = false
var sintonizadorInfoIsOn = false
var filtroInfoIsOn = false



func ondaSenoidal():
	var step = 1
	poolSenoidal = PoolVector2Array()
	var indx:int = 0
	
	var i = 0
	var doOnce:bool = true
	while i < espacoAmostral:
		poolSenoidal.append(Vector2(i, amplitude*sin(periodo*i)) + ponto1.position)
		i += step
		
		
		var folgaY = 0.1 + ponto1.position.y
		var folgaX = 2.1 + ponto1.position.x
		if(poolSenoidal[indx].y < folgaY && poolSenoidal[indx].y > -folgaY && poolSenoidal[indx].x > folgaX && doOnce):
			comprimentoDeOndaSeno = poolSenoidal[indx].x - ponto1.position.x
			#retangulo.set_position(Vector2(poolSenoidal[indx].x, retangulo.rect_position.y))
			doOnce = false
		indx += 1
	
	draw_polyline(poolSenoidal, Color(1, 0.5, 0.31, 1), 1, true)

func ondaCarrier():
	var step = .15
	poolCarrier = PoolVector2Array()
	var indx:int = 0
	
	
	var i = 0	
	var doOnce:bool = true
	while i < espacoAmostral:
		poolCarrier.append(Vector2(i,(amplitude*sin(periodoCarrier*i))) + ponto0.position)
		i += step
		
		
		### Calculando o comprimento de onda
		var folgaY = 0.1 + ponto0.position.y
		var folgaX = 2.1 + ponto0.position.x

		if(poolCarrier[indx].y < folgaY && poolCarrier[indx].y > -folgaY && poolCarrier[indx].x > folgaX && doOnce):
			comprimentoDeOndaCarrier = poolCarrier[indx].x - ponto0.position.x
			doOnce = false
		indx += 1
	
	draw_polyline(poolCarrier, Color(1, 0.5, 0.31, 1), 1, true)


func ondaModulada():
	var step = 0.1
	poolModulada = PoolVector2Array()
	var i = 0
	
	
	while i < espacoAmostral:
		poolModulada.append(ponto4.position+Vector2(i, 2 * sin(periodo*i)*(1+(amplitude/2*cos(periodoCarrier*i)))))
		i += step
	draw_polyline(poolModulada, Color( 0, 1, 1, 1 ), 1, true)

func _ondaModulada():
	var step = 0.1
	poolModulada = PoolVector2Array()
	
	
	var i = -comprimentoDeOndaSeno/2
	
	while i < espacoAmostral - (comprimentoDeOndaSeno/2):
		var peqAmplitude = (amplitude*sin((periodo/2)*i))*2
		poolModulada.append(Vector2(i + (comprimentoDeOndaSeno/2), peqAmplitude*sin(periodoCarrier * i)) + ponto4.position)
		
		
		i += step
	
	draw_polyline(poolModulada, Color( 0, 1, 1, 1 ), 1, true)


func ondaRetificada():
	poolRetificada = PoolVector2Array()
	var step = 0.2
	var i = 0	
	while i < espacoAmostral:
		var calculo = 2 * sin(periodo*i)*(1+(amplitude/2*cos(periodoSint*i)))
		
		if(calculo > 0):
			calculo = 0
		
		poolRetificada.append(ponto2.position+Vector2(i, calculo))
		i += step
	draw_polyline(poolRetificada, Color(1, 0.5, 0.31, 1), 1, true)



func ondaSaida():
	var step = 1
	poolSaida = PoolVector2Array()
	
	var i = 0
	var doOnce:bool = true
	while i < espacoAmostral:
		var calculo = (sin(periodo*i)*(1+(amplitude/1*cos(periodoCarrier*i))))/(1+(amplitude*(cos(periodoSint*i)/1)))
		
		var amplitudeDeSaida = 40
		
		calculo *= amplitudeDeSaida #Acrecimo à amplitude
		
		var maxOffset = amplitudeDeSaida + 10
		
		if(calculo > maxOffset):
			calculo = maxOffset
		if(calculo < -maxOffset):
			calculo = -maxOffset
		
		poolSaida.append(pontoSaida.position + Vector2(i, calculo))
		i += step
	
#	var indx = 0
#	for p in poolSaida:
#		if(indx < poolSaida.size()-1):
#			poolSaida[indx].y = (poolSaida[indx].y + poolSaida[indx+1].y)/2
#			print(indx)
#		indx += 1
	draw_polyline(poolSaida, Color(1, 0.5, 0.31, 1), 1, true)

func ondaSintonizador():
	var step = .15
	poolSintonizador = PoolVector2Array()
	var i = 0	

	while i < espacoAmostral:
		poolSintonizador.append(Vector2(i,(amplitude*sin(periodoSint*i))) + pontoSintonizador.position)
		i += step
	
	draw_polyline(poolSintonizador, Color(1, 0.5, 0.31, 1), 1, true)


func _draw():
	ondaSenoidal()
	ondaCarrier()
	ondaModulada()
	ondaRetificada()
	if(saidaInfoIsOn):
		ondaSaida()
	if(sintonizadorInfoIsOn):
		ondaSintonizador()



func _process(delta):
	update()
	
	

func _ready():
	retificadorInfo.visible = false
	sintonizadorInfo.visible = false
	saidaInfo.visible = false
	filtroInfo.visible = false 



func _on_SliderPeriodoModulado_value_changed(value):
	periodo = value


func _on_SliderPeriodoCarrier_value_changed(value):
	periodoCarrierVal.text = str(value)
	periodoCarrier = value


func hideAllInfo():
	retificadorInfoIsOn = false
	saidaInfoIsOn = false
	sintonizadorInfoIsOn = false
	filtroInfoIsOn = false
	
	retificadorInfo.visible = false
	ponto2 = get_node("Ponto2")
	saidaInfo.visible = false
	pontoSaida = ponto2
	sintonizadorInfo.visible = false
	pontoSintonizador = ponto2
	filtroInfo.visible = false


func _on_BotaoRetificador_pressed():
	if(!retificadorInfoIsOn):
		hideAllInfo()
		retificadorInfoIsOn = true
		retificadorInfo.visible = true
		ponto2 = get_node("PontoRetificador")
	else:
		hideAllInfo()



func _on_BotalSinalSaida_pressed():
	if(!saidaInfoIsOn):
		hideAllInfo()
		saidaInfoIsOn = true
		saidaInfo.visible = true
		pontoSaida = get_node("PontoSaida")
	else:
		hideAllInfo()


func _on_BotaoSintonizador_pressed():
	if(!sintonizadorInfoIsOn):
		hideAllInfo()
		sintonizadorInfoIsOn = true
		sintonizadorInfo.visible = true
		pontoSintonizador = get_node("PontoSintonizador")
	else:
		hideAllInfo()


func _on_BotaoFiltro_pressed():
	if(!filtroInfoIsOn):
		hideAllInfo()
		filtroInfoIsOn = true
		filtroInfo.visible = true
	else:
		hideAllInfo()


func _on_SliderPeriodoSintonizador_value_changed(value):
	periodoSintVal.text = str(value)
	periodoSint = value
