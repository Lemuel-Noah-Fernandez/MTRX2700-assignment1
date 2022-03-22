;*****************************************************************
;* This stationery serves as the framework for a                 *
;* user application (single file, absolute assembly application) *
;* For a more comprehensive program that                         *
;* demonstrates the more advanced functionality of this          *
;* processor, please see the demonstration applications          *
;* located in the examples subdirectory of the                   *
;* Freescale CodeWarrior for the HC12 Program directory          *
;*****************************************************************

; Serial receive and reply code

; export symbols
            XDEF Entry, _Startup            ; export 'Entry' symbol
            ABSENTRY Entry        ; for absolute assembly: mark this as application entry point



; Include derivative-specific definitions 
		INCLUDE 'derivative.inc' 

ROMStart    EQU  $4000  ; absolute address to place my code/constant data

; variable/data section

            ORG RAMStart
; Insert here your data definition.
baud_rate   equ   9600    ; define the baud rate
inputs      FCC   "Hello World!"    ; string from memory  
carriage    equ   $0D   ;carriage return byte
counter     DS.B    1    ;one byte to store the counter
string      DS.B  64    ;allocate 64 bytes 
back_counter    DS.B 1    ;one byte for counter 


; code section
            ORG   ROMStart


Entry:
_Startup:
            lds   #RAMEnd+1       ; initialize the stack pointer
            cli                     ; enable interrupts

mainLoop:

            ; initialise the serial port (SCI1)
            movw    #baud_rate, 2, -SP ; two bytes on the stack for baud rate
            jsr     SCI1_init
            
            ; clear the parameter sent to the init function
            ;  note: this doesn't clear the memory, just moves the SP
            leas 2, SP
            
                  ;starting the counter at 0
            ;leas -30, SP ;allocate memory

            ldx #0
            stx counter
            stx back_counter
     
            ldy #string
            ldx   #inputs
            
            
            
            ;bra send_to_serial

read_serial_char:
            ; load the status register from SCI1 and mask the bit $20 which is RDRF
            ; receive data is available
            ldaa  SCI1SR1
            anda  #mSCI1SR1_RDRF
            
            ; test if there has been a new character received (else loop)
            beq   read_serial_char
            
            ; read the new character into register B
            ldab  SCI1DRL
            ; push the character onto the stack for storing
            
            stab 0,y
            iny
            inc counter
            ;movb $3FFF, 1,-SP
             
            
            ;pshb
            
            
            ;branch back to read_serial_char if the carriage return byte is not hit $0D
            cmpb #carriage
            ;ins
            bne read_serial_char
            
            ldaa #0
            
reset_loop:
            
            
            dec counter
            inc back_counter
            cmpa counter
            dey
            
            bne reset_loop
            
            
write_serial_char:
            ; TDRE is the most significant bit of SCI1SR1 (1 indicates empty and ready)
            ; The following lines
            ; test the memory address SCI1SR1 and sets the condition control registers
            ; accordingly. If the most significant bit is 1, the negative flag is 1 and
            ; visa versa. BPL branches on positive, so will loop until TDRE is ready to send
            tst   SCI1SR1
            bpl   write_serial_char
            
            
            
            ; store the char from register B in the SCI output data register
            
            
            ldab 1,y+
            
            
            stab  SCI1DRL
            
            ; check if the carriage return byte is sent and if not keep writing out the string.
            ;cmpb #carriage
            
            dec back_counter
            cmpa back_counter
            bne write_serial_char

            bra read_serial_char
            ; loop back to itself to keep writing it out
            
delay: 
            ; delay function between the characters
            
            
            
send_to_serial:

            tst   SCI1SR1
            bpl   write_serial_char

            
            ldab 1,x+
            
            
            stab  SCI1DRL
            
            bra send_to_serial
            





; subroutine to initialise the serial port and baud rate
baud_rate_parameter  equ 2
SCI1_init: 	
           	; Enable the TE and RE (tx and rx) for port SCI1
           	; use the masks from the definition file. The first mask needs a hash
           	; otherwise it will try read it as an address
            clr SCI1CR1
            movb #mSCI1CR2_RE | mSCI1CR2_TE, SCI1CR2
            
            ; follow the equation for baud rate setting in SCI1BDH (see documentation)
            ; EDIV divides a 32 bit number (top 16 bits in Y, lower 16 bits in D)
            ;  and divides it by the value in register X

            ; from the datasheet, baud parameter is clock (24MHz) / 16 / baud rate
            ;  24M = 016E 3600
            ;  24M/16 = 0016 E360 (shift hex right)
            ;  baud rate is passed as a parameter
            ldy #$0016    ; 24 mhz
            ldd #$E360
            ldx baud_rate_parameter, SP
            ediv
            
            ; result of EDIV is stored in register Y, transfer these 16 bits to
            ;  the baud data register
            sty SCI1BDH
            
            rts
            

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
