/*
    Jonas Cram
    Robotics and Communication Systems Engineering Technology (RCET)
    College of Technology - Idaho State University
     
    - - - - - UART Tx/Rx TEST CODE - - - - -
    Project Smokehouse Transmitter Board
    Revised 20261102 (yyyymmdd)
     
    MPLAB X IDE v6.20
     
    PROGRAM FUNCTION:
     RECEIVE AND ECHO A SINGLE-BYTE PACKET
	BYTE 1: HANDSHAKE - 0x24h (ASCII "$")
 */
    
; PIC16F1788 Configuration Bit Settings
; Assembly source line config statements
; CONFIG1
  CONFIG  FOSC = HS             ; Oscillator Selection (HS Oscillator, High-speed crystal/resonator connected between OSC1 and OSC2 pins)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable (WDT disabled)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable (PWRT disabled)
  CONFIG  MCLRE = ON            ; MCLR Pin Function Select (MCLR/VPP pin function is MCLR)
  CONFIG  CP = OFF              ; Flash Program Memory Code Protection (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Memory Code Protection (Data memory code protection is disabled)
  CONFIG  BOREN = ON            ; Brown-out Reset Enable (Brown-out Reset enabled)
  CONFIG  CLKOUTEN = OFF        ; Clock Out Enable (CLKOUT function is disabled. I/O or oscillator function on the CLKOUT pin)
  CONFIG  IESO = ON             ; Internal/External Switchover (Internal/External Switchover mode is enabled)
  CONFIG  FCMEN = ON            ; Fail-Safe Clock Monitor Enable (Fail-Safe Clock Monitor is enabled)

; CONFIG2
  CONFIG  WRT = BOOT            ; Flash Memory Self-Write Protection (000h to 1FFh write protected, 200h to 1FFFh may be modified by EECON control)
  CONFIG  VCAPEN = OFF          ; Voltage Regulator Capacitor Enable bit (Vcap functionality is disabled on RA6.)
  CONFIG  PLLEN = OFF           ; PLL Enable (4x PLL disabled)
  CONFIG  STVREN = ON           ; Stack Overflow/Underflow Reset Enable (Stack Overflow or Underflow will cause a Reset)
  CONFIG  BORV = LO             ; Brown-out Reset Voltage Selection (Brown-out Reset Voltage (Vbor), low trip point selected.)
  CONFIG  LPBOR = ON            ; Low Power Brown-Out Reset Enable Bit (Low power brown-out is enabled)
  CONFIG  DEBUG = OFF           ; In-Circuit Debugger Mode (In-Circuit Debugger disabled, ICSPCLK and ICSPDAT are general purpose I/O pins)
  CONFIG  LVP = ON              ; Low-Voltage Programming Enable (Low-voltage programming enabled)

// config statements should precede project file includes.
#include <xc.inc>
  
PSECT resetVect,class=CODE,delta=2
    GOTO SETUP
PSECT isrVect,class=CODE,delta=2
    GOTO IE_HANDLER
  
SETUP:
    ; -------------------
    ; Register Setup
    ; -------------------
    STATUS_TEMP EQU 0x70h	; INIT TEMP STATUS REG
	CLRF	STATUS_TEMP
    W_TEMP	EQU 0x71h	; INIT TEMP W REG
	CLRF	W_TEMP
    RX_TEMP	EQU 0x72h	; INIT TEMP REG FOR Rx'd DATA
	CLRF	RX_TEMP
    HANDSHAKE	EQU 0x73h	; INIT REG TO REFERENCE HANDSHAKE "GLOBALLY"
	MOVLW	0x24h		; ASCII "$"
	MOVWF	HANDSHAKE
	CLRW
    TMR2_SETUP	EQU 0x74h	; STORE TIMER 2 SETUP FOR POSSIBLE RESET/RELOAD
	CLRF	TMR2_SETUP
    DEBUG	EQU 0x75h	; INIT REG FOR DUBUGGING
	CLRF	DEBUG
	
    ; -------------------
    ; UART SETUP
    ; -------------------
     BANKSEL	APFCON1
	MOVLW	01000001B
	/*
	 7 - 1(C2OUT ON RA6) / 0(C2OUT ON RA5)
	 6 - 1(CCP1 ON RB0) / 0(CCP1 ON RC2)
	 5 - 1(MSSP SDO ON RB5) / 0(MSSP SDO ON PIN RC5)
	 4 - 1(MSSP SCL/SCK ON RB7) / 0(MSSP SCL/SCK ON RC3)
	 3 - 1(MSSP SDA/SDI ON RB6) / 0(MSSP SDA/SDI ON RC4)
	 2 - 1(USART Tx PIN ON RB6) / 0(USART Tx PIN ON RC6)
	 1 - 1(USART Rx PIN ON RB7) / 0(USART Rx PIN ON RC7)
	 0 - 1(CCP2 ON PIN RB3) / 0(CCP2 ON PIN RC1)
	*/
	MOVWF	APFCON1
	CLRW
     BANKSEL	TX1STA
	; - - - - - LOAD Tx'r REG SETUP - - - - -
	MOVLW	00100010B
	/*
	 BITS FOR ASYNC MODE
	 7 - NA
	 6 - 1(9b Tx) / 0(8b Tx)
	 5 - 1(Tx ENBL) / 0(Tx DSBL)
	 4 - 1(SYNC MODE) / 0(ASYNC MODE)
	 3 - 1(SEND SYNC BREAK) / 0(SYNC BREAK Tx CMPLT)
	 2 - 1(HI SPD) / 0(LO SPD)
	 1 - 1(Tx SHFT REG EMPT) / 0(Tx SHFT REG FULL)
	 0 - (9th BIT OF Tx DAT; CAN BE ADDRESS/DAT OR PARITY BIT)
	*/
	MOVWF	TX1STA
	CLRW
     BANKSEL	RC1STA
	; - - - - - LOAD Rx'r REG SETUP - - - - -
	MOVLW	10010000B
	/*
	 UART MODE; Rx STAT AND CTRL REG
	 7 - 1(SRL PRT ENBL) / 0(SRL PRT DSBL)
	 6 - 1(9b Rx) / 0(8b Rx)
	 5 - NA
	 4 - 1(ENBL Rx'r) / 0(DSBL Rx'r)
	 3 - BIT 6 MUST BE HI
	    1(ENBLs ADDR DETECTION, ENBL IE AND LD Rx BFFR WHEN RSR<8> IS SET)
	    0(DSBLs ADDR DETECTION, ALL BYTES Rx'd AND 9th CAN BE PARITY)
	 2 - FRAMING ERROR: 1(Y) / 0(N)
	 1 - OVERRUN ERROR: 1(Y) / 0(N)
	 0 - 9th BIT OF Rx DAT
	*/
	MOVWF	RC1STA
	CLRW
     BANKSEL	BAUD1CON
	; - - - - - LOAD BAUD CONTROL REG SETUP - - - - -
	MOVLW	00001000B
	/*
	 ASYNC MODE BIT CONFIGs
	 7 - 1(AUTO-BAUD TMR OVRFLW) / 0(AUTO-BAUD TMR NO OVRFLW)
	 6 - 1(Rx'r IS IDLE) / 0(Rx'r IS Rx'ing)
	 5 - NA
	 4 - 1(INVERT Tx'd DATA) / 0(DO NOT INVERT Tx'd DATA)
	 3 - 1(16b BRG USED) / 0(8b BRG USED)
	 2 - NA
	 1 - 1(WAKE-UP ENBL'D; FALLING EDGE TRIG) / 0(Rx'r OPERATING NORMALLY)
	 0 - 1(AUTO-BAUD DETECT ENBL'd) / 0(AUTO-BAUD DETECT DSBL'd)
	*/
	MOVWF	BAUD1CON
	CLRW
	
     ; - - - - - BAUD RATE GENERATOR - - - - -
	; DESIRED BAUD = Fosc/(X(SPBRGH:SPBRGL + 1)
	; X = VALUE DEPENDENT ON BAUD RATE, SEE DATASHEET
	; SPBRGH:SPBRGL = (((11.0592MHz/9600 BAUD)/16) - 1
	; SPBRGH:SPBRGL = 71d = 47h
	; SPBRGH = 0x00h, SPBRGL = 0x47h
     BANKSEL	SP1BRGH
	CLRF	SP1BRGH	    ; CLR HI-BYTE OF BAUD RATE GEN (BRG16)
     BANKSEL	SP1BRGL
	MOVLW	0x47h
	MOVWF	SP1BRGL
	CLRW
    ; -------------------
    ; PORTB SETUP
    ; -------------------
    BANKSEL	PORTB
	CLRF	PORTB	    ; SET PORTB VALUE TO ZERO
    BANKSEL	ANSELB
	CLRF	ANSELB	    ; SET PORTB PINS AS DIG IO
    BANKSEL	WPUB
	CLRF	WPUB	    ; DSBL PORTB WEAK PULL-UP
    BANKSEL	TRISB
	MOVLW	11000000B
	MOVWF	TRISB	    ; SET PORTB PINS AS OUTPUTS
    
    ; -------------------
    ; PORTC SETUP
    ; -------------------
    BANKSEL	ANSELC
	CLRF	ANSELC	; CONFIG PORTC AS DIG IO
    BANKSEL	WPUC
	CLRF	WPUC	; DSBL PORTC WEAK PULL-UP
    BANKSEL	PORTC
	CLRF	PORTC	; CLR PORTC
    BANKSEL	TRISC
	; 1(TRI-STATE INPUT) / 0(OUTPUT)
	MOVLW	10011001B
	MOVWF	TRISC
	CLRW
    
    ; -------------------
    ; TIMER 2 SETUP
    ; -------------------
     /*
	- - - - - TIMER 2 INTERRUPT OCCURANCE INTERVAL - - - - -
	T_INSTR (instruction time) = (Fosc/4)^-1 = (11.0952MHz/4)^-1
	    T_INSTR = 361.690ns
	TMR2 IE = T_INSTR * PREscale * POSTscale * PR2reg
	TMR2 IE = 361.690ns * 64 * 16 * 255 = 94.444ms
	AN LED CAN BE USED AS A VISUAL INDICATOR:
	    PORTB,0: 94.444ms * 2 = 188.276ms roughly
	    PORTB,1: 94.444ms * 4 = 376.552ms roughly
	    PORTB,2: 94.444ms * 8 = 755.556ms roughly
	    PORTB,3: 94.444ms * 16 = 1.506s roughly
	    PORTB,4: 94.444ms * 32 = 3.012s roughly
	    PORTB,5: 94.444ms * 64 = 6.025s roughly
     */
     BANKSEL	T2CON
	MOVLW	01111111B	; 1:16 PoSCLR, TMR2 ON, 1:64 PreSCLR
	/*
	 7 - NA
	 6-3 - POSTSCALER BITS
	 2 - 1(TMR2 ON)/0(TMR2 OFF)
	 1-0 - PRESCALER BITS 
	*/
	MOVWF	T2CON		; CONFIG TMR2
	MOVWF	TMR2_SETUP	; STORE TMR2 SETUP
	CLRW
     BANKSEL	TMR2
	CLRF	TMR2
     BANKSEL	PR2
	MOVLW	0xFFh
	MOVWF	PR2
	CLRW

    ; -------------------
    ; INTERRUPT SETUP
    ; -------------------
     ; - - - - - CLR PERIPH IE FLGs - - - - -
     BANKSEL	PIR1
	CLRF	PIR1
	/*
	 PIR1,7	    ; TMR1 GATE IE FLG
	 PIR1,6	    ; ADC IE FLG
	 PIR1,5	    ; EUSART Rx IE FLG
	 PIR1,4	    ; EUSART Tx IE FLG
	 PIR1,3	    ; MSSP IE FLG
	 PIR1,2	    ; CCP1 IE FLG
	 PIR1,1	    ; TMR2 IE FLG
	 PIR1,0	    ; TMR1 OVERFLOW IE FLG
	*/
     BANKSEL	PIR2
	CLRF	PIR2
	/*
	 PIR2,7	    ; OSC FAIL IE FLG
	 PIR2,6	    ; COMP2 IE FLG
	 PIR2,5	    ; COMP1 IE FLG
	 PIR2,4	    ; EEPROM WR COMPLETE IE FLG
	 PIR2,3	    ; MSSP COLLISION IE FLG
	 PIR2,2	    ; COMP4 IE FLG
	 PIR2,1	    ; COMP3 IE FLG
	 PIR2,0	    ; CCP2 IE FLG
	*/
     BANKSEL	PIR3
	CLRF	PIR3
	; PIR3,4    ; CCP3 IE FLG
     BANKSEL	PIR4
	CLRF	PIR4	    ; xX UNUSED Xx
     BANKSEL	PIE1
	BCF	PIE1,7	    ; DSBL TMR1 GATE IE
	BCF	PIE1,6	    ; DSBL ADC IE
	BSF	PIE1,5	    ; ENBL EUSART Rx IE
	BCF	PIE1,4	    ; DSBL EUSART Tx IE
	BCF	PIE1,3	    ; DSBL MSSP IE
	BCF	PIE1,2	    ; DSBL CCP1 IE
	BSF	PIE1,1	    ; ENBL TMR2 IE
	BCF	PIE1,0	    ; DSBL TMR1 OVRFLW IE
     BANKSEL	PIE2
	BCF	PIE2,7	    ; DSBL OSC FAIL IE
	BCF	PIE2,6	    ; DSBL COMP2 IE
	BCF	PIE2,5	    ; DSBL COMP1 IE
	BCF	PIE2,4	    ; DSBL EEPROM WR COMPLETE IE
	BCF	PIE2,3	    ; DSBL MSSP BUS COLLISION IE
	BCF	PIE2,2	    ; DSBL COMP4 IE
	BCF	PIE2,1	    ; DSBL COMP3 IE
	BCF	PIE2,0	    ; DSBL CCP2 IE
     BANKSEL	PIE3
	CLRF	PIE3	    ; xX UNUSED Xx
     BANKSEL	PIE4
	CLRF	PIE4	    ; xX UNUSED Xx
     BANKSEL	INTCON
	BCF	INTCON,0    ; CLR IOC IE FLG
	BCF	INTCON,1    ; CLR INT EXT IE FLG
	BCF	INTCON,2    ; CLR TMR0 IE FLG
	BCF	INTCON,3    ; DSBL IOC IE
	BCF	INTCON,4    ; DSBL EXT IE
	BCF	INTCON,5    ; DSBL TMR0 OVERFLOW IE
	BSF	INTCON,6    ; ENBL PERIPH IEs
	BSF	INTCON,7    ; ENBL GLBL IEs
CLRW
GOTO    MAIN
    
MAIN:
    BTFSS	DEBUG,0	    ; PIC CONFIG'd?
    CALL	PIC_CONFIG  ; NO, CONFIG PIC
    GOTO	MAIN	    ; LOOP INDEF
    
IE_HANDLER:
    ; - - - - - SAVE W AND STATUS REGS - - - - -
    BANKSEL	INTCON
    BCF		INTCON,7    ; DSBL GLBL IEs
    MOVWF	W_TEMP	    ; STORE W REG
    MOVF	STATUS,W    ; STORE STATUS REG
    MOVWF	STATUS_TEMP ; ^
    
    ; - - - - - TEST INTERRUPT FLAG(S) - - - - -
    BANKSEL	PIR1
    BTFSC	PIR1,1	    ; TMR2 IE?
    GOTO	SEND_HS	    ; Y: TMR2 IE, SEND HANDSHAKE
    BTFSC	PIR1,5	    ; EUSART Rx IE?
    GOTO	ERROR_TEST  ; Y:
    GOTO	LEAVEISR    ; N: LEAVE ISR
    
    ; - - - - - TEST ERROR FLAGS - - - - -
    ERROR_TEST:
    BANKSEL	RC1STA
    BTFSC	RC1STA,1    ; OVERRUN ERROR?
    GOTO	CLR_OVRRN   ; Y: CLEAR OVERRUN
    BTFSC	RC1STA,2    ; FRAMING ERROR?
    GOTO	DISCARD	    ; Y: CLR DATA
    GOTO	HS_TEST	    ; TEST HANDSHAKE
    
 ; - - - - - OVERRUN ERROR - - - - -
 CLR_OVRRN:
    BANKSEL	RC1STA
    BCF		RC1STA,4    ; Toggle / Restart CONST. Rx ENBL
    BSF		RC1STA,4    ; ^
    MOVF	RC1REG,0    ; READ REG TO CLR (REDUNDANT)
    CLRW
    GOTO	LEAVEISR
    
 ; - - - - - FRAMING ERROR - - - - -
 DISCARD:
    BANKSEL	RC1REG
    MOVF	RC1REG,0    ; READ REG TO CLR
    CLRW
    GOTO	LEAVEISR
     
 ; - - - - - TEST HANDSHAKE - - - - -
 HS_TEST:
    BANKSEL	RC1REG
    MOVF	RC1REG,W    ; MOVE Rx'd DATA TO W REG
    MOVWF	RX_TEMP	    ; STORE Rx'd DATA IN TEMP REG
    
    MOVF	RX_TEMP,W   ; MOVE STORED Rx'd DATA TO W REG
    XORWF	HANDSHAKE,W ; XOR W REG W/ HANDSHAKE VALUE
    
    BANKSEL	STATUS
    BTFSS	STATUS,2    ; ZERO BIT SET?
    GOTO	DISCARD	    ; N: BAD HANDSHAKE
    
    ; - - - - - GOOD HANDSHAKE - - - - -
    BCF		STATUS,2    ; CLR ZERO-BIT FLG
    MOVF	RX_TEMP,W   ; MOVE GOOD HANDSHAKE TO W REG
    BANKSEL	PORTB
    INCF	PORTB	    ; INCREMENT PORTB OUTPUT PINS
    
    ; - - - - - ECHO HANDSHAKE BACK - - - - -
     
 SEND_HS:
    BANKSEL	INTCON
    BCF		INTCON,7    ; DSBL GLBL IEs
    
    BANKSEL	PIR1
    BCF		PIR1,1	    ; CLR TMR2 FLG
    BTFSS	PIR1,4	    ; Tx BUFFER EMPTY?
    GOTO	$-1	    ; N: CHECK AGAIN
    
    ; - - - - - SEND HANDSHAKE DATA - - - - -
    BANKSEL	TX1REG
    MOVF	HANDSHAKE,W ; LOAD HS BYTE
    MOVWF	TX1REG	    ; Tx HS BYTE
    
    BANKSEL	TX1STA
    BTFSS	TX1STA,1    ; Tx'r EMPTY?
    GOTO	$-1	    ; N: TEST AGAIN
    
    BANKSEL	INTCON
    BSF		INTCON,7    ; ENBL GLBL IEs
    
LEAVEISR:
    ; - - - - - RESTORE W AND STATUS REGS - - - - -
    MOVF	STATUS_TEMP,W
    MOVWF	STATUS	    ; RESTORE STATUS REG
    MOVF	W_TEMP,W    ; RESTORE W REG
    
    BANKSEL	INTCON
    BSF		INTCON,7    ; ENBL GLBL IEs
    RETFIE		    ; RETURN FROM IE
    
; - - - - -
; SUBROUTINES
; - - - - -
PIC_CONFIG:
    BANKSEL	PORTC
    BTFSC	PORTC,0	    ; RC0 HI?
    GOTO	CONFIGd	    ; Y: PIC IS Tx'r, NO CHANGES
    
    BANKSEL	T2CON
    BCF		T2CON,2	    ; PIC IS Rx'r, DSBL TMR2
    
    CONFIGd:
    BSF		DEBUG,0	    ; SET CONFIG'd BIT
    RETURN