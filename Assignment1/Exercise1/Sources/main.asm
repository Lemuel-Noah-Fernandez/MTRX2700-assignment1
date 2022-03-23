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

            ORG RAMStart
 ; Insert here your data definition.
output_string   DS.B 64 ; allocates 64 bytes at the output_string memory address
input_string    FCC "LowEr or UPPEr?" ; makes a string
null            FCB 0 ; Set a null term
output_string2  DS.B 64
input_string2   FCB "at eIOu."
null2           FCB 0 ; Set a null term
output_string3  DS.B 64 
input_string3   FCB "no capitalise nocap"
null3           FCB 0  ; Set a null term
counter         FCB $0 ; A counter for letters in task3   

; code section
            ORG   ROMStart


Entry:
_Startup:
            LDS   #RAMEnd+1       ; initialize the stack pointer

            CLI                     ; enable interrupts
mainLoop:
            LDX   #input_string ; X contains our pre-defined input_string
            LDY   #output_string ; Y contains an empty 16 byte string
            
            ;BRA task2 ; For task 2 demo
            JSR task3 ; For task 3 demo
                        
            ; For task 1 demo:
            LDAB  #0  ; Loads either 0 or 1, 1 for uppercase and 0 for lower case
            BNE Upper
            BRA Lower ; Always branches to Loop

Upper:
            LDAA 0, x ; Loads the first value of x into register A
            CMPA null
            BEQ  final1 ; If the null term is detected, branch to task2 
            LDAB #97   ; Loads 97 into register B
            SBA       ; Subtracts 97 from register A (value of ascii a)
            BHS turn_upper ; If positive or zero, turn into upper case
            ABA       ; Adds 97 to register A (gets it back to string characer)
            STAA 0, y ; Stores the value currently in register B into y which is the output string
            INX       ; Increments the x value
            INY       ; Incrememnts the y value
            BRA Upper
       
turn_upper:
            LDAB #97   ; Loads 97 
            ABA       ; Adds 97 to register A (gets it back to string character)
            LDAB #32   ; Loads 32
            SBA       ; Makes character upper case
            BRA return_from_upper

return_from_upper:
            STAA 0, y
            INX
            INY
            ;RTS
            BRA Upper
            
            
Lower: 
            LDAA 0, x ; Loads the first value of x into register A
            CMPA null
            BEQ  task2 ; If the null term is detected, branch to task2 
            LDAB #65   ; Loads 65 into register B
            SBA       ; Subtracts 65 from register A (value of ascii a)
            BGE test_for_lower ; If positive, test_for_lower (this checks for punctuation)
            ABA       ; Adds 65 to register A (gets it back to string characer)
            STAA 0, y ; Stores the value currently in register B into y which is the output string
            INX       ; Increments the x value
            INY       ; Incrememnts the y value
            BRA Lower
         
test_for_lower:
            LDAB #25 ; Loads 25 into register B
            SBA      ; Substracts 25 from register A 
            BLT turn_lower ; If less than zero, branch to turn_lower (branches if letter is already a capital)
            LDAB #90       ; If already lower case, loads 90
            ABA            ; Adds 90
            BRA return_from_lower

turn_lower:
            LDAB #90   ; Loads 97 
            ABA       ; Adds 97 to register A (gets it back to string character)
            LDAB #32   ; Loads 32
            ABA       ; Makes character upper case
            BRA return_from_lower
            
return_from_lower:
            STAA 0, y
            INX
            INY
            BRA Lower
            
final1:
            BRA final1      ; A continuous loop for once the program ends

task2:
            LDX     #input_string2
            LDY     #output_string2   
            BRA     test_vowels
                     
test_vowels:

            LDAA 0, x
            CMPA null2 ; If the null character is detected, move to task 3
            BEQ final1
            LDAB #97   ; Load ascii 'a' into b register 
            SBA        ; Subtract 97 from register A
            BEQ lower_a  ; If its 'a', turn upper and return
            LDAB #97     ; Return to normal
            ABA
            LDAB #101
            SBA
            BEQ lower_e  ; Test for 'e'
            LDAB #101
            ABA
            LDAB #105
            SBA
            BEQ lower_i   ; Test for 'i'
            LDAB #105
            ABA
            LDAB #111
            SBA
            BEQ lower_o   ; Test for 'o'
            LDAB #111
            ABA
            LDAB #117     
            SBA 
            BEQ lower_u   ; Test for 'u'
            LDAB #117
            ABA
            STAA 0, y
            INX 
            INY 
            BRA test_vowels  
            
turn_upper2:
            LDAB #97   ; Loads 97 
            ABA       ; Adds 97 to register A (gets it back to string character)
            LDAB #32   ; Loads 32
            SBA       ; Makes character upper case
            BRA return_from_upper2

return_from_upper2:
            STAA 0, y
            INX
            INY
            RTS
            ;BRA Upper
          
lower_a:
            JSR turn_upper2
            BRA test_vowels
        
lower_e:
            LDAB #4      ; 97 is added in turn_upper, so this makes sure an 'E' is made
            ABA
            JSR turn_upper2
            BRA test_vowels
lower_i:
            LDAB #8       ; Makes sure I is made
            ABA
            JSR turn_upper2
            BRA test_vowels
lower_o:
            LDAB #14      ; Make sure O is made
            ABA
            JSR turn_upper2
            BRA test_vowels
lower_u:
            LDAB #20      ; Make sure U is made
            ABA
            JSR turn_upper2
            BRA test_vowels
  
           
task3:
            LDX #input_string3
            LDY #output_string3
            LDAB counter    ; Keeps track of the letter
            BRA space_test
           
space_test:
            LDAA 0, x
            CMPA null2 ; If the null character is detected, end
            BEQ final;word_test   ; Does this have to be final instead?
            CMPA #32   ; ASCII value of a space
            BEQ word_test ; Branch to word_test if a space is detected
            INX
            INCB
            BRA space_test     
       
word_test:
            CMPB #6        ; Compare B to 6 (for 6 letters)
            PSHB           ; Remember amount of letters used
            BGE letter_counter ; If 6 or more letters in word, capitalise the first letter of the word          
            BRA finish_word

letter_counter:
            DECB
            DEX      ; Brings x position back to start of word
            CMPB #0
            BEQ capitalise
            BRA letter_counter

            
capitalise:
            ;PSHB  ; The number in B is how many letters are in the word to be capitalised. This is then stored on the stack
            ;LDX #input_string3
            LDAA 0, x
            SUBA #32
            STAA 0, y
            INX
            INY
            BRA finish_word1
            ;BRA capitalise
            
finish_word:
            DECB
            DEX      ; Brings x position back to start of word
            CMPB #0
            BEQ finish_word1
            BRA finish_word
     
finish_word1:
            LDAA 0, x
            STAA 0, y
            ;DECB            ; Decrement B to see how many letters are present
            INX
            INY
            PULB            ; Get letter amount from stack
            DECB
            CMPB x
            BEQ space_test  ; If all letters in the word have been completed, movbe to next word
            BRA finish_word1 ; If word is not yet finished, loop back to finish_word
            
          
final:
            BRA final      ; A continuous loop for once the program ends
      

