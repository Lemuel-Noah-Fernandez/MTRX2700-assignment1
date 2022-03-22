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
baud_rate      equ 9600 ; Defining the baud rate
carriage       equ $0D  ; Carriage return byte
counter        DS.B 1   ; Byte to store counter
output_string  DS.B 64  ; 64 bytes to store string
input_string   FCC "Test"
null           FCB 0    ; A null term
back_counter   DS.B 1   ; Byte to store counter
t_0            DS.B 2   ; Timer variable
time_taken     DS.B 2   ; Another time variable
PORT_H_MASK    EQU %00000011
output_code    FDB $9874


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
            movb #mTSCR1_TEN, TSCR1   ; Initialisign the timer
            ldx #0
            stx counter
            stx back_counter
            ldx #input_string
            ldy #output_string
            jsr   SCI1_setup
            
            bra initialise_io
            
; Start timer now
subroutine_timer:      
           MOVB #$80, TSCR1      ;enable timer
           MOVB #$00, TSCR2      ;set prescaler to 1 -> highly accurate for shorter subroutines
           SEI
           LDD TCNT              ;load current timer count in D
           STD t_0               ;store in t_0 variable
           JSR string_to_serial  ;jump to subroutine to be tested
           LDD TCNT              ;once subroutine returns load timer count
           CLI
           SUBD t_0              ;subtract t_0 to get difference in count
           STD time_taken        ;store in time_taken variable
           end: bra *            ;demo over    

string_to_serial:
            ; Not sure if the tst and bpl are necessary
            tst SCI1SR1
            bpl string_to_serial
            
            ldab 0, x
            cmpb null
            beq  return        ; End program if string is finished
            stab SCI1DRL       ; Store in serial port
            inx                
            bra string_to_serial
  
return:
            rts
            


read_serial:
            ldaa SCI1SR1
            anda #mSCI1SR1_RDRF
            
            beq read_serial ; Checks for a new character
            ldab  SCI1DRL   ; Reads new character into B
            
            stab 0, y       ; 
            iny
            inc counter
            bra final
            
initialise_io:
            SEI
            LDAA #PORT_H_MASK
            STAA PIEH
            COMA
            STAA PPSH
            CLI
            
            LDAA #$FF
            STAA DDRP         ;set port P (7seg enable) to output
            STAA DDRB         ;set port B (7seg data)  to output
            ;RTS  
                      
output7seg:                                  
            ldaa #$0E         ;loads 00001110 to enable first 7seg
            staa PTP          ;stores enable in portP
            ldd output_code     ;load chars into index   ; 
            staa PORTB        ;output first char to the first 7seg
            bsr delay         ;1ms delay
            clr PORTB
            ldaa #$0D         ;loads 00001101 to enable second 7seg
            staa PTP
            ldd output_code     ;load second digit into register A
            stab PORTB        ;Change to $02 for simulation
            bsr delay         ;1ms delay
            clr PORTB         ;clear PORTB
            bra output7seg
            
            
delay:
                              ;delay by 1ms
            ldy #$6000        ;load $6000
            delay_loop:
              dey
              bne delay_loop
              rts
           
SCI1_setup:
            ; See exercise 3 for detailed comments
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
