;*****************************************************************
;* This stationery serves as the framework for a                 *
;* user application (single file, absolute assembly application) *
;* For a more comprehensive program that                         *
;* demonstrates the more advanced functionality of this          *
;* processor, please see the demonstration applications          *
;* located in the examples subdirectory of the                   *
;* Freescale CodeWarrior for the HC12 Program directory          *
;*****************************************************************

; export symbols
            XDEF Entry, _Startup            ; export 'Entry' symbol
            ABSENTRY Entry        ; for absolute assembly: mark this as application entry point



; Include derivative-specific definitions 
		INCLUDE 'derivative.inc' 

ROMStart    EQU  $4000  ; absolute address to place my code/constant data

; variable/data section

 ifdef _HCS12_SERIALMON
            ORG $3FFF - (RAMEnd - RAMStart)
 else
            ORG RAMStart
 endif
 ; Insert here your data definition.
Counter     DS.W 1
FiboRes     DS.W 1
baud_rate  equ 9600 ; Defining the baud rate


; code section
            ORG   ROMStart


Entry:
_Startup:
            ; remap the RAM &amp; EEPROM here. See EB386.pdf
 ifdef _HCS12_SERIALMON
            ; set registers at $0000
            CLR   $11                  ; INITRG= $0
            ; set ram to end at $3FFF
            LDAB  #$39
            STAB  $10                  ; INITRM= $39

            ; set eeprom to end at $0FFF
            LDAA  #$9
            STAA  $12                  ; INITEE= $9


            LDS   #$3FFF+1        ; See EB386.pdf, initialize the stack pointer
 else
            LDS   #RAMEnd+1       ; initialize the stack pointer
 endif

            CLI                     ; enable interrupts
mainLoop:
            movw  #baud_rate, 2, -SP  ; Set two bytes for baud rate onto the stack
            jsr   SCI1_setup
            
read_serial:
            ldaa SCI1SR1
            anda #mSCI1SR1_RDRF
            
            beq read_serial ; Checks for a new character
            ldab  SCI1DRL    ; Reads new character into B
            bra final
           
SCI1_setup:
            clr SCI1CR1
            movb #mSCI1CR2_RE | mSCI1CR2_TE, SCI1CR2 ; Enables TX and RX signals for the serial port
            ldy #$0016
            ldd #$E360
            ldx 2, SP
            ediv
            
            sty SCI1BDH
            
            rts
           
final:
            bra final
