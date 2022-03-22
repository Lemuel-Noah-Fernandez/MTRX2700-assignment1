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
delay_length EQU 100 ;multiples of 10ms if prescaler=4

; variable/data section

            ORG RAMStart
 ; Insert here your data definition.
t_0 DS.B 2
time_taken DS.B 2
counter DS.B 1



; code section
            ORG   ROMStart


Entry:
_Startup:
            LDS   #RAMEnd+1       ;initialize the stack pointer
            SEI                   ;disable interrupts for setup
            
            MOVB #0, counter      ;set counter as 0
            MOVB #$FF, DDRB       ;configure LEDs to output for delay demo
            
            CLI                   ;enable interrupts
            
            BRA interupt_demo
            
            

interupt_demo:
            MOVB #mTSCR1_TEN, TSCR1
            MOVB #mTSCR2_TOI, TSCR2
            BSET TFLG2, #mTFLG2_TOF
            MOVB #$FF, PORTB
empty_loop:
           BRA *


            
            
            


            
subroutine_timer:      
           MOVB #$80, TSCR1      ;enable timer
           MOVB #$00, TSCR2      ;set prescaler to 1 -> highly accurate for shorter subroutines
           SEI
           LDD TCNT              ;load current timer count in D
           STD t_0               ;store in t_0 variable
           JSR dummy_subroutine  ;jump to subroutine to be tested
           LDD TCNT              ;once subroutine returns load timer count
           CLI
           SUBD t_0              ;subtract t_0 to get difference in count
           STD time_taken        ;store in time_taken variable
           end: bra *            ;demo over
   
                       
            



dummy_subroutine:
            LDAA #$10
            SUBA #$01
            LDAB #41
            LDAA #62
            LDAB #73
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
            rts                    ;return
                        
;**************************************************************
;*                 Interrupt Functions                        *
;**************************************************************
            
timer_overflow:
            INC counter
            BVS counter_overflow
end_isr:
            LDX TCNT
            BSET TFLG2, #mTFLG2_TOF
            RTI




counter_overflow:         
            MOVB #$80, PORTB
            JSR fixed_delay
            MOVB #$40, PORTB
            JSR fixed_delay
            MOVB #$20, PORTB
            JSR fixed_delay
            MOVB #$10, PORTB
            JSR fixed_delay
            MOVB #$08, PORTB
            JSR fixed_delay
            MOVB #$04, PORTB
            JSR fixed_delay
            MOVB #$02, PORTB
            JSR fixed_delay
            MOVB #$01, PORTB
            JSR fixed_delay
            
            BRA end_isr
            
            
fixed_delay:
            LDY #$FFFF
            fixed_delay_loop:
              DEY
              BNE fixed_delay_loop
              LDX #$FFFF
              fixed_delay_inner_loop:
                DEX
                BNE fixed_delay_inner_loop
              RTS            
            
;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
            
            ORG   $FFDE
            DC.W timer_overflow
