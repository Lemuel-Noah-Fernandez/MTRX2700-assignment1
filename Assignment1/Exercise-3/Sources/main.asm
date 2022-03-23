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
string      DS.B  64    ;allocate 64 bytes 
null        equ   $00     ;null for end of string
delay_length EQU 100 ;multiples of 10ms if prescaler=4

; code section
            ORG   ROMStart


Entry:
_Startup:
            lds   #RAMEnd+1       ; initialize the stack pointer
            cli                     ; enable interrupts

mainLoop:     
            ; initialise the serial port (SCI1)
            movw    #baud_rate, 2, -SP ; two bytes on the stack for baud rate
            jsr   SCI1_init
            
            ; clear the parameter sent to the init function
            ;  note: this doesn't clear the memory, just moves the SP
            leas 2, SP
            

     
            ldy #string       ;loading register y with the string to input to
            ldx #inputs       ;loading the input into register x to read from 
            
            
            ;These are the options to switch between task 1,2 and 3 respectively
            
            ;bra send_to_serial
            ;bra serial_port_storer
            bra combined
             

             
             
             
 ;**************************************************************
;*                    Task 3 Read and Send                     *
;**************************************************************            
            
            
            
combined:     
            ldx #$100C      ; Loading x with the address of where the read string was stored
            
            

combined_reader:  
          ; load the status register from SCI1 and mask the bit $20 which is RDRF
            ; receive data is available
            ldaa  SCI1SR1
            anda  #mSCI1SR1_RDRF
            
            ; test if there has been a new character received (else loop)
            beq   combined_reader
            
            ; read the new character into register B
            ldab  SCI1DRL
            
            ; store the character in y array
            stab 0,y
            iny                   ;increment y so the next storage is the next index in y

            
            ; loops again if the character is not carriage return byte. Continues to sender if return byte is triggered
            cmpb #carriage
            
            bne combined_reader
            
            
            
combined_sender: 
            ; TDRE is the most significant bit of SCI1SR1 (1 indicates empty and ready)
            ; The following lines
            ; test the memory address SCI1SR1 and sets the condition control registers
            ; accordingly. If the most significant bit is 1, the negative flag is 1 and
            ; visa versa. BPL branches on positive, so will loop until TDRE is ready to send
            tst   SCI1SR1
            bpl   combined_sender
            
            ; store the char from register B in the SCI output data register
            ldab x            
            stab  SCI1DRL
            
            ; jumping to variable delay to create delay between omission of characters
            jsr variable_delay
            
            ; incrementing x to move forward to the next character to send out            
            inx
                       
            ; checking if this is the end of the string and continues to loop if not
            cmpb #null
            bne combined_sender
            
            ;cmpb #carriage
            
            
            ; returns back
            rts 
            
            
            
 ;**************************************************************
;*                    Task 1 Send to serial port               *
;**************************************************************   
 

send_to_serial: 
            ; TDRE is the most significant bit of SCI1SR1 (1 indicates empty and ready)
            ; The following lines
            ; test the memory address SCI1SR1 and sets the condition control registers
            ; accordingly. If the most significant bit is 1, the negative flag is 1 and
            ; visa versa. BPL branches on positive, so will loop until TDRE is ready to send
            tst   SCI1SR1
            bpl   send_to_serial
             
            ; store the char from register B in the SCI output data register
            ldab x            
            stab  SCI1DRL
            
            ; jumping to variable delay to create delay between omission of characters
            jsr variable_delay

            ; incrementing x to move forward to the next character to send out            
            inx
            
            ; checking if this is the end of the string and continues to loop if not
            cmpb #null
            bne send_to_serial
            
            ; sends a carriage return byte since it is the end of the string
            ldab #carriage
            stab SCI1DRL
            
            ; returns back                              
            rts 
            
 ;**************************************************************
;*                    Task 2 Read from serial port             *
;**************************************************************        
                   
serial_port_storer: 
            ; load the status register from SCI1 and mask the bit $20 which is RDRF
            ; receive data is available
            ldaa  SCI1SR1
            anda  #mSCI1SR1_RDRF
            
            ; test if there has been a new character received (else loop)
            beq   serial_port_storer
            
            ; read the new character into register B
            ldab  SCI1DRL
            
            ; store the character in y array
            stab 0,y
            iny                   ;increment y so the next storage is the next index in y

            
            ; loops again if the character is not carriage return byte. Ends if is carriage return byte
            cmpb #carriage
            bne serial_port_storer
            
            ; returns back
            rts  
                      
;**************************************************************
;*                    Variable Delay                          *
;**************************************************************

variable_delay_demo:       
            MOVB #$FF, PORTB
            JSR variable_delay
            CLR PORTB
            JSR variable_delay
            BRA variable_delay_demo

variable_delay:
            MOVB #$90, TSCR1       ;enable the time and fast flag clear
            MOVB #%00000010, TSCR2 ;disable interupts, output compare resets and sets prescaler to /4
            MOVB #$01, TIOS        ;set channel 0 to output compare
            
            LDY #delay_length  ;delay will be (10ms * Y)
            
delay_loop:
            ldd TCNT               ;load timer count into D
            ADDD #60000            ;add delay/offset to count
            std TC0                ;store offset count in compare register
            
delay_loop_inner:
            brclr TFLG1, #01,delay_loop_inner ;loop until timer reaches offset (TCNT == TC0)
            dbne y, delay_loop     ;decrement Y and loop back to another 10ms delay
            rts            
            
            





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
            
