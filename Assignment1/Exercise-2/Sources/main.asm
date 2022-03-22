
; export symbols
            XDEF Entry, _Startup            ; export 'Entry' symbol
            ABSENTRY Entry        ; for absolute assembly: mark this as application entry point



; Include derivative-specific definitions 
		INCLUDE 'derivative.inc' 

ROMStart    EQU  $4000  ; absolute address to place my code/constant data
PORT_H_MASK EQU %00000011



; variable/data section

            ORG RAMStart
 ; Insert here your data definition.

 
inputs      FCC "0123456789AbCdEF"         ;inputs
outputs     DC.B $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F,$77,$7C,$39,$5E,$79,$71
dig1_index  DS.B 1
dig2_index  DS.B 1
toDisplay:  FDB "F0"
output_code:FDB $0000

; code section
            ORG   ROMStart


Entry:
_Startup:
            LDS   #RAMEnd+1       ; initialize the stack pointer

            CLI                   ; enable interrupts
            BSR initialise_io     ;configure output ports and input interupts
            BRA main
 
            
;******* This runs at startup and configures the relevant output ports *******            
;******* it also enables interupts from the buttons connected to port H*******
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
            RTS

;******          This is the entry point for the main function          ******

main:           
convert_setup:    
            LDY #toDisplay        ;load the memory address of the first character
convert_start:
            LDX #inputs           ;load the lookup array into X register
            LDAA #0               ;initiliase counter to iterate array
convert_loop:
            LDAB a, x             ;loadnext char from lookup aray
            CMPB y                ;compare to char that we want to display
            BEQ equivalent_found  ;if equal, branch
            INCA                  ;if not, increment counter
            BRA convert_loop

equivalent_found:
            LDX #output_code      ;next four lines check if the first digit has been filled
            LDAB x
            CMPB #0
            BNE second_digit
            
            STAA dig1_index
            JSR get_output_code1
            INY                   ;increment Y so we are looking at 2nd input digit 
            BRA convert_start     ;
second_digit:
            STAA dig2_index
            JSR get_output_code2
            BRA output7seg


;*********These require the index variables are filled in, they fill*********
;*********            in "output_code" with the correct val.        *********
          
get_output_code1:
            LDAA dig1_index       ;load the index of the digit into A
            LDX #outputs          ;load the array of output codes into X 
            LDAB a, x             ;load the correct output code into B
            LDX #output_code      ;load the output variable
            STAB x                ;put the correct output code into the variable
            RTS 
            
get_output_code2:                 
            LDAA dig2_index       ;load the index of the digit into A
            LDX #outputs          ;load the array of output codes into X
            LDAB a, x             ;load the correct output code into B
            LDX #output_code      ;load the output variable
            STAB 1, x             ;put the correct output code into the variables 2nd pos
            RTS    



;*********   This takes in 2 bytes from the variable "output_code" and *********
;*********will output the corresponding 7seg values to the dragon board*********

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
            


;******** A short delay routine of approx. 1ms ********
            
delay:
                              ;delay by 1ms
            ldy #$6000        ;load $6000
            delay_loop:
              dey
              bne delay_loop
              rts
              
              
              
              
;******** The following sections are for the interupts when a button is pressed ********
              
port_h_isr:                       
            LDAA PTH              ;store porth in reg A and invert to determine
            coma                  ;which button has been pressed
            DECA                  ;if first button (PH0) is pressed, this will set Z
            BEQ clear             ;if PH0 pressed, branch to subroutine to clear 7seg
            
            LDAA dig2_index       ;if instead PH1 is pressed, increment
            CMPA #15              ;check if +1 causes overflow into 1st digit
            BEQ digit_overflow    ;if so branch
            INCA                  ;otherwise increment index to +1
            STAA dig2_index       ;store incremented index in variable
            JSR get_output_code2  ;update output code
            
isr_continue:
            BSET PIFH, #PORT_H_MASK ;reset flag
            RTI                     ;exit interupt
            
clear:
            LDD #0                ;store value of 0 in registerD
            STD output_code       ;store this in output code variable -> no segments on
            BRA isr_continue      ;branch back for reset and to finish interupt

digit_overflow:
            LDAA dig1_index       ;load and increment +1 index variable
            CMPA #15
            INCA
            STAA dig1_index       ;store updated variable
            LDAA #0               ;set 2nd digit to 0
            STAA dig2_index
            JSR get_output_code1  ;update output codes for both digits
            JSR get_output_code2
            BRA isr_continue      ;branch back to finish interupt
                     

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG $FFCC
            DC.W port_h_isr
            
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
