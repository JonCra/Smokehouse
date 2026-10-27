/*
    Jonas Cram
     Robotics and Communication Systems Engineering Technology (RCET)
     College of Technology - Idaho State University
     
    Project Smokehouse
     
 */
    
; PIC16F1788 Configuration Bit Settings
; Assembly source line config statements
; CONFIG1
  CONFIG  FOSC = XT             ; Oscillator Selection (XT Oscillator, Crystal/resonator connected between OSC1 and OSC2 pins)
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
  CONFIG  DEBUG = ON            ; In-Circuit Debugger Mode (In-Circuit Debugger enabled, ICSPCLK and ICSPDAT are dedicated to the debugger)
  CONFIG  LVP = ON              ; Low-Voltage Programming Enable (Low-voltage programming enabled)

// config statements should precede project file includes.
#include <xc.inc>
  
PSECT resetVect,class=CODE,delta=2
    GOTO SETUP
PSECT isrVect,class=CODE,delta=2
    GOTO IE_HANDLER
  
SETUP:
    BANKSEL	INTCON
	BCF	INTCON,7	; DSBL GLBL IEs
    ; -------------------
    ; Register Setup
    ; -------------------
    STATUS_TEMP EQU 0x70h	; INIT TEMP STATUS REG
	CLRF	STATUS_TEMP	; CLR REG
	
    W_TEMP	EQU 0x71h	; INIT TEMP W REG
	CLRF	W_TEMP		; CLR REG
	
    RX_TEMP	EQU 0x72h	; INIT TEMP Rx PORT REG
	CLRF	RX_TEMP		; CLR REG

    ; -------------------
    ; UART SETUP
    ; -------------------
     BANKSEL	TX1STA
	; LOAD Tx'r REG SETUP
	MOVLW	00000010B
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
     BANKSEL	RC1STA
	; LOAD Rx'r REG SETUP
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
	 0 - 9th BIT OF Tx DAT
	*/
	MOVWF	RC1STA
     BANKSEL	BAUD1CON
	; LOAD BAUD CONTROL REG SETUP
	MOVLW	00000010B
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
    
    ; -------------------
    ; PORTC SETUP
    ; -------------------
    BANKSEL	PORTC
	CLRF	PORTC	; CLR PORTC
    BANKSEL	TRISC
	MOVLW	00000000B
	/*
	 7 - 
	 6 - 
	 5 - 
	 4 - 
	 3 - 
	 2 - 
	 1 - 
	 0 - 
	*/
	MOVWF	TRISC
;    BANKSEL	
    
    ; -------------------
    ; INTCON SETUP
    ; -------------------
    BANKSEL	INTCON
	; ENABLE FUNCTION IS HI STATE
	BCF	INTCON,0    ; CLR IOC IE FLG
	BCF	INTCON,1    ; CLR INT EXT IE FLG
	BCF	INTCON,2    ; CLR TMR0 IE FLG
	BCF	INTCON,3    ; DSBL IOC IE
	BCF	INTCON,4    ; DSBL EXT IE
	BCF	INTCON,5    ; DSBL TMR0 OVERFLOW IE
	BSF	INTCON,6    ; ENBL PERIPH IEs
	BSF	INTCON,7    ; ENBL GLBL IEs
    GOTO    MAIN
    
MAIN:
    
    GOTO    MAIN    ; LOOP INDEF
    
SUBROUTINES:
    
    RETURN
    
IE_HANDLER:
    
    RETFIE