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
This module focuses on manipulating information within memory. For each task, both an `input_string` and `output_string` variable are initialised and stored into index registers x and y. The tasks require individual characters wihtin the strings to either turn upper or lower case. In the functions `Lower` and `Upper`, this is done by first testing if a character is already lower or upper case by subtracting ascii values from them and branching based on the result. To turn a lower case character to upper case, the ascii value must have 32 subtracted from it whereas it must have 32 added to it to turn lower case from upper.

After an individual character is changed, the result is stored in the `output_string` variable and both this variable and `input_string` are incremented to receive and manipulate the next character. Eventually, the end of a string will be reached. This is recognised as the `null` term character with ascii value 0 will be loaded into the index register. Once this is character is detected, the program wil finish.

### Testing
Testing for this module mainly had to do with the data section of the debugger. In this section, all variables that have been initialised are present and change in realtime as the code is stepped through. After every function was finalised, the debugger would step through to ensure everything was working as intended.

### Digital Input and Output (Ex. 2)
This module predominantly deals with outputting values to the 7 segment display, and using the push buttons inputs to generate interrupts. In the Exercise-2 CodeWarrior project, the variable `to_display` should be set to the desired two-digit hexadecimal output for the 7 segment display. Each digit is indexed to an array in the `convert` function, which is used to find the corresponding 7-segment output code using the `get_output_code` function. The two output codes are stored in `output_code`, which is output the the display using the `output7seg` function.

When either of the PH0 or PH1 pushbuttons are pressed, an interrupt is triggered directing to the `port_h_isr` function. The interrupt service routine first determines which button has been pressed. If PH0, the display is cleared using `clear` function, if PH1, the hexadecimal value on the 7-segment increments. This is acheived by incrementing the stored index and updating the output code.

#### Testing
Testing and debugging for this module mainly took place in the simulator, using the `spc` command to view relevant memory addresses, as well as looking at the CPU registers and condition flags. A range of test cases were implemented to ensure the functions were adequately flexible. The functions assume valid inputs (0-F), another flaw is the overflow when the 7 segment display is incremented past FF, however with some additional checks this could be fixed to "wrap-around" to 00.

### Serial Input and Output (Ex. 3)

This module focuses on serial interface to send and receive data. The SCI1 port is first initiallised to be able to send and read data from our Terminal Emulator, achieved through `SCI1_init`, which initialises the registers and allocates the appropriate settings such as baud rate. The first useful function, `send_to_serial`, checks control condition registers to detect if the serial interface is ready to send. Beforehand, a string from memory allocated in `inputs` is loaded into register x which is then character by character, sent to the serial interface. Right after sending a character, the function jumps to `variable_delay` which is replicated from Exercise 4. The variable delay length can be set using `delay_length`. As such, the string is sent character by character after a delay, and is ended when a null character is detected, in which it then sends a carriage return byte.

The `serial_port_storer` function similarly has a 64 bit space allocated in the RAM and loaded into register Y for storing user input, and a testing loop to detect serial control conditions to detect if serial is ready to receive data. When ready, the serial register is sent the first byte of the Y register and continously loops through the user input while incrementing y to move to the next character. A compare is used to detect when a carriage return byte is sent which ends the function.

The `combined` function integrates both previous functions to be able to successfully receive a string from user input, and display the same string back on the serial monitor with a variable delay after each character. Register X is set to the address of the incoming string to be stored in RAM memory. The interface is achieved through setting CodeWarrior on COM3 and a Terminal Emulator such as puTTY on COM4, which allows for input to be placed into the terminal and then to be verified by the board and resent to the serial interface character by character with delay.

### Hardware Timer (Ex. 4)
This module develops functions which utilise the built in hardware timer of the HCS12. The first useful function is `variable_delay`, which can cause a delay of which the length is determined by both the `delay_length` variable and the prescaler. This gives a range of 2.5ms to over 5.8 hours of delay. A default prescaler of 4 is chosen, which sets each increment of `delay_length` to take 10ms. For example, a 1 second delay could be achieved by setting the `delay_length EQU 100`. Note that this variable's value must fit into register D (16-bits).

The `subroutine_timer` function can be used to time how long a subroutine takes to execute. This could be useful for comparing time complexities of different algorithms. To time a subroutine, change the line `JSR dummy-subroutine` with the target subroutine. The time taken in CPU clock ticks will be stored in the variable `time_taken` as well as in register D. For higher accuracy, the prescaler is set to 1 for this function, so obtain the actual time by multiplying the stored value by 41.67 nanoseconds. Additionally the function `STD` involves some overhead (2 clock cycles) which slightly inflates the time taken, however, since the intent is to *compare* subroutine times and this is a fixed error, it does not pose a serious issue.

This module also includes a blueprint for a timer overflow interrupt, which can make a function run at set intervals independently of the rest of the software. Each time the timer overflows a counter is incremented, when this occurs a user written function can be run (`counter_overflow` is used as a default). The frequency at which the interrupt occurs can be determined by the size of the `counter` variable and the prescaler value. The default function used is trivial, but the program is capable of running time critical functions at highly accurate intervals.

#### Testing
Testing for this module made heavy use of visual feedback from the Dragonboard. Specifically an LED was blinked with frequency of the `variable_delay`, so changes in the `delay_length` variable and prescaler had noticable impacted how quickly the LED blinked. In order to check the timer count was being stored in memory, the CodeWarrior simulation was used along with `spc`. Similarly to with the variable delay, the timer interrupts were tested by associating an interrupt with a pattern of LED blinks. Visual inspection could confirm that the interrupt was triggering at regular intervals.


## Integration (Ex. 5)
The task 5 module integrates functions developed in various other modules to complete specific tasks. As such, each of the tasks are very different.

Task 1: Firstly, the `baud_rate` is set to 9600, the timers `TSCR1/TSCR2` are initialised and the serial port is set up through function `SCI1_setup`. The `subroutine_timer` function calculates time by recording the time that has passed at a reference `t_0`, and then subtracting this number from the updated timer once the subroutine is finished. The subroutine pastes whatever is inside the `input_string` onto the serial.

Task 2: Baud rate and serial are set-up similarly to task 1. First the serial is read to obtain an ascii value which is to later be displayed onto the 7-segment display. A variety of different functions starting from `intialise_io` are called to initialise the seven segment display, and then to convert the value obtained from serial into numbers that can be recognisable on the 7-seg display. Finally, `output7seg` is called and looped to display the desired numbers.


