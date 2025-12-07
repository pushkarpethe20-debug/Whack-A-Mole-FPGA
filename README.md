# Whack-A-Mole-FPGA Game
A Verilog-based real-time game implemented on a Spartan-6 FPGA
This project implements a simple Whack-a-Mole-style game on FPGA hardware using Verilog. The system flashes an LED randomly, and the player responds through corresponding switches to score points.

# Game Description:
1. One LED turns ON randomly.
2. Each LED has an individual switch assigned to it.
3. If the correct switch is toggled while the LED is still ON → score increments.
4. After 30 seconds, the game stops, and the score is displayed on a 7-segment output.

# Tools and Hardware Used
1. Xilinx ISE
2. Spartan-6 FPGA board

# Steps to Implement
1. Open Xilinx ISE and create a new project.
2. Add .v source file.
3. Add .ucf file to assign pins.
4. Generate .bit file (already provided in repo).
5. Program FPGA board.
6. Play the game.

# Game Logic Used
1. Timer-based LED turn duration
2. Random selection logic
3. Switch monitoring
4. Score increment
5. Output display

# Video
https://github.com/user-attachments/assets/597e9df4-8867-4a6e-bcd5-d9b2788b13a3

