//*****************************************************************************
//Universidad del Valle de Guatemala 
//Programación de Microprocesadores 
//Archivo:PreLaboratorio_02
//Hardware:ATMEGA328P
//Autor:Adriana Marcela Gonzalez 
//Carnet:22438
//*****************************************************************************
//Encabezado 
//*****************************************************************************
.include "M328PDEF.INC" 
.cseg 
.org 0x00

//*****************************************************************************
//Stack pointer
//*****************************************************************************
LDI R16, LOW(RAMEND)
OUT SPL, R16
LDI R17, HIGH(RAMEND)
OUT SPH, R17 

//*****************************************************************************
//Tabla 7 segmentos
//*****************************************************************************
//Catodo
Tabla7seg: .DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71

//*****************************************************************************
//Configuración 
//*****************************************************************************

//R16 temporizador, R17 contador de 4 bits, R22 contador 7seg.

Setup:
//Cargar las direcciones de la tabla 
	LDI ZH, HIGH(Tabla7seg << 1)
	LDI ZL, LOW(Tabla7seg << 1)

//Configuración 1 MHz
	LDI R19, (1 << CLKPCE) //Habilitar el prescaler
	STS CLKPR, R19
	LDI R19, 0b0000_0100
	STS CLKPR, R19

//Temporizador de 100ms
    CALL Timer_100ms

	LDI R30, 0b1111_1111
	OUT DDRB, R30 //Habilita el puerto B como salida

	LDI R30, 0b1111_1111
	OUT DDRD, R30 //Habilita el puerto D como salida 
	LDI R30, 0x00
	OUT PORTD, R30 
	STS UCSR0B, R30 //Habilita D0 y D1 como puertos normales 

	LDI R30, 0b0000_0000
	OUT DDRC, R30 //Habilita el puerto C como entrada 
	LDI R30, 0b0011_1111
	OUT PORTC,	R30
	
//Registros utilizados para los botones.
	LDI R20, 0xFF
	MOV R21, R20

//Inicialización del contador del TIMER0
    LDI R17, 0
//Inicialización del contador hexadecimal 
	LDI R23, 0 //Registro para controlar Z 
	LDI R22, 0 //Registro para contar
	

//Establece el contador de 1 segundo
	LDI R26, 10
	LDI R27, 0
Loop:

	CBI PORTB, PB4 //Limpiar el led del comparacion de los contadores


//Se llama la lectura de los botones.
	CALL LECTURA 
	
	//Llama a la subrutina comparadora del postlab.
	CALL Comparador

	IN R16, TIFR0
    CPI R16, (1<<TOV0) 
	BRNE Loop

	LDI R16, 60
	OUT TCNT0, R16

	SBI TIFR0, TOV0

//Incremento del contador binario de 4 bits
	INC R27
	CPI R27, 5
	BRNE Loop
	LDI R27, 0
	INC R17
	CALL LUCESITAS
    CPI R17, 16
	BRNE Loop 
	
    
//Reinicio del contador 
    CLR R17
	CALL LUCESITAS

	RJMP Loop 

//*****************************************************************************
//Subrutinas
//*****************************************************************************

Timer_100ms:
//Configuración del Timer0
    LDI R16, (1 << CS02) | (1 << CS00) //Configura el prescaler a 1024
    OUT TCCR0B, R16
    LDI R16, 60
	OUT TCNT0, R16

	RET


LECTURA: 
	MOV R21, R20
	IN R20, PINC //El registro 20 pasa a tomar el valor del puerto C
	CPSE R21, R20 /*Compara el valor del registro 20 que es el del PINC 
	con 0xFF para verificar los botones*/
	RJMP BOTONCITOS
	RET

BOTONCITOS:
	IN R20, PINC
	MOV R21, R20
	IN R20, PINC
	SBRS R20, PC0
	RJMP SEGMENTITOS_INC //Lama al incremento
	SBRS R20, PC1
	RJMP SEGMENTITOS_DEC//Llama al decremento 
	RET

SEGMENTITOS_INC:
	CPI ZL, 23 //Compara ZL con 23 que es el maximo del contador 
	BRNE Incremento 
	LDI R22, 0x00 //Reinicio del registro que cuenta
	LDI ZL, 8//Inicia el contador en 8
	LPM R23, Z //Carga a la memoria el valor de z
	OUT PORTD, R23 //El valor de Z sale por el puerto D
	JMP Delaybounce
	RET 
		Incremento:
			INC R22 //Incremento del contador 
			LDI R23, 1
			ADD ZL, R23 //Suma uno en Z
			LPM R23, Z //Carga a la memoria el valor de z igual a R23
			OUT PORTD,R23 //El valor de Z sale por el puerto D
			JMP Delaybounce
			RET 

SEGMENTITOS_DEC:
	CPI ZL, 8  //Inicia el contador en 8
	BRNE Decremento
	LDI R22, 0xFF //Reinicio del registro que cuenta pero dando la vuelta en su valor maximo
	LDI ZL, 23
	LPM R23, Z
	OUT PORTD, R23
	JMP Delaybounce
	RET 
		Decremento:
			DEC R22 //Decremento del contador 
			LDI R23, 1
			SUB ZL, R23
			LPM R23, Z
			OUT PORTD,R23
			JMP Delaybounce
			RET 

Comparador: 
	CPSE R17, R22 //Compara los contadores 
	RET
	SBI PINB, PB4 //Si son iguales enciende un led
	RET

//LEDS del contador de 4 bits con el TIMER0
LUCESITAS:
	SBRC R17, 0
	SBI PORTB, 3
	SBRS R17, 0
	CBI PORTB, 3
	SBRC R17, 1
	SBI PORTB, 2
	SBRS R17, 1
	CBI PORTB, 2
	SBRC R17, 2
	SBI PORTB, 1
	SBRS R17, 2
	CBI PORTB, 1
	SBRC R17, 3
	SBI PORTB, 0
	SBRS R17, 3
	CBI PORTB, 0
	
	RET 

//Antirrebote 
	Delaybounce:
    LDI R28, 100
    delay:
        DEC R28
        BRNE delay
    RET