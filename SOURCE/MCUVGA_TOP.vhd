----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2016/05/30 11:21:31
-- Design Name: 
-- Module Name: MCUVGA - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.comMCU.ALL;

entity MCUVGA_TOP is
	Port ( 	
		clk	: in STD_LOGIC;
		reset	: in STD_LOGIC;
		PS2Clk	: in STD_LOGIC;
		PS2Data	: in STD_LOGIC;
		sw		: in STD_LOGIC_VECTOR (15 downto 0);
		Hsync	: out STD_LOGIC;
		Vsync	: out STD_LOGIC;
		vgaRed	: out STD_LOGIC_VECTOR (3 downto 0);
		vgaBlue	: out STD_LOGIC_VECTOR (3 downto 0);
		vgaGreen: out STD_LOGIC_VECTOR (3 downto 0);
		led 	: out STD_LOGIC_VECTOR (15 downto 0)
		);
end MCUVGA_TOP;

architecture Behavioral of MCUVGA_TOP is
	
	signal Keyflag:KEYSTATE:=NONE;
	signal Keycode:STD_LOGIC_VECTOR (7 downto 0);
	signal Keycode_IN:STD_LOGIC_VECTOR (7 downto 0);
	
	signal PIX_X,PIX_Y:integer;
	signal CS	:STD_LOGIC;
	signal RGBmR:STD_LOGIC_VECTOR (3 downto 0);
	signal RGBmG:STD_LOGIC_VECTOR (3 downto 0);
	signal RGBmB:STD_LOGIC_VECTOR (3 downto 0);
	signal Data	:STD_LOGIC_VECTOR (7 downto 0);
	signal Addr	:STD_LOGIC_VECTOR (7 downto 0);
begin
	
	Keycode_IN <= 	Keycode when Keyflag=MAKE else
					(others=>'0');
	
Ucpu:CPU port map(
		clk 	=> clk,
		reset	=> reset,
		keyboard=> Keycode_IN,
		sw		=> sw,
		CS		=> CS,
		Data	=> Data,
		Addr	=> Addr,
		led 	=> led);

Uppu:PPU Port map(
		clk  	=> clk,  	
		reset	=> reset,	
		CS		=> cs,
		Data	=> Data,	
		Addr	=> Addr,	
		PIX_X	=> PIX_X,	
		PIX_Y	=> PIX_Y,	
		RGBmR	=> RGBmR,	
		RGBmG	=> RGBmG,	
		RGBmB	=> RGBmB );

Uvgau:VGA Port map (
		CLK			=> clk,
		VGA_HS	    => Hsync,
		VGA_VS	    => Vsync,
		VGA_RED	    => vgaRed, 
		VGA_BLUE    => vgaBlue,
		VGA_GREEN   => vgaGreen,
		RGBmR		=> RGBmR,
		RGBmG		=> RGBmG,
		RGBmB		=> RGBmB,
		PIX_X		=> PIX_X,
		PIX_Y		=> PIX_Y);
		
Keyboard:PS2Keyboard port map(
		reset	=> reset,
		PS2Clk	=> PS2Clk,
		PS2Data	=> PS2Data,
		Keyflag	=> Keyflag,
		Keycode	=> Keycode);

end Behavioral;
