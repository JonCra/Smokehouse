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
    BANKSEL	TXSTA
	MOVLW	0_000110B
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
	MOVWF	TXSTA
    BANKSEL	RCSTA
	MOVLW	1_01_000B
	/*
	 UART MODE; Rx STAT AND CTRL REG
	 7 - 1(SRL PRT ENBL) / 0(SRL PRT DSBL)
	 6 - 1(9b Rx) / 0(8b Rx)
	 5 - NA
	 4 - 1(ENBL Rx'r) / 0(DSBL Rx'r)
	 3 - 
	 2 - FRAMING ERROR: 1(Y) / 0(N)
	 1 - OVERRUN ERROR: 1(Y) / 0(N)
	 0 - 9th BIT OF Tx DAT
	*/
	MOVWF	RCSTA
    BANKSEL	
	MOVLW	
	/*
	 
	*/
    
    ; -------------------
    ; PORTC SETUP
    ; -------------------
    BANKSEL	PORTC
	CLRF	PORTC		; CLR PORTC
    BANKSEL	TRISC
	MOVLW	
	/*
	 0 - 
	 1 - 
	 2 - 
	 3 - 
	 4 - 
	 5 - 
	 6 - 
	 7 - 
	*/
	MOVWF	TRISC
    
    GOTO MAIN
    
MAIN:
    
    END
    
SUBROUTINES:
    
    RETURN
    
IE_HANDLER:
    
    RETFIE