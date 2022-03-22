# MTRX2700 Assignment 1
### Group 2 Members

**Duncan Chen**
- Head of Minutes
- Serial Input and Output (Exercise 3)
- Integration (Exercise 5)


**Lemuel Fernandez**
- Head of Git
- Memory and Pointers (Exercise 1)
- Integration (Exercise 5)

**Ethan Foster**
- Head of Hardware
- Digital Input and Output (Exercise 2)
- Hardware Timer (Exercise 4)
- Integration (Execise 5)

## Modules
The project is split into four main modules, each of which deal with different aspects/functionality of the HCS12 Microcontroller. These modules are demonstrated working together in the integration section (Ex. 5).

### Memory and Pointers (Ex. 1)

### Digital Input and Output (Ex. 2)
This module predominantly deals with outputting values to the 7 segment display, and using the push buttons inputs to generate interrupts. In the Exercise-2 CodeWarrior project, the variable `to_display` should be set to the desired two-digit hexadecimal output for the 7 segment display. Each digit is indexed to an array in the `convert` function, which is used to find the corresponding 7-segment output code using the `get_output_code` function. The two output codes are stored in `output_code`, which is output the the display using the `output7seg` function.

When either of the PH0 or PH1 pushbuttons are pressed, an interrupt is triggered directing to the `port_h_isr` function. The interrupt service routine first determines which button has been pressed. If PH0, the display is cleared using `clear` function, if PH1, the hexadecimal value on the 7-segment increments. This is acheived by incrementing the stored index and updating the output code.

### Serial Input and Output (Ex. 3)
### Hardware Timer (Ex. 4)
## Integration (Ex. 5)
