# CPU-VGA-on-Basys3
a simple CPU write by VHDL which control a VGA,keyboard on Xilinx Basys3.
## how to start
It needs a keil2 project to write assembly language,then use `Hexfile2data_可用.m` transform the `.hex` file to `HEXfile.vhd`.
## the result
First,it shows a image of the QQ's logo on VGA;then it displays 0 to 9 on VGA;after the numbers it shows a clock meanwhile the monitor can display a letter or a number pressed on the keyboard.
