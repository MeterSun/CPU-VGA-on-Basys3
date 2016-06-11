----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 2016/05/31 13:42:15
-- Design Name:
-- Module Name: VGA - Behavioral
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
-- this part is from the demo

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;


entity VGA is
    Port ( CLK	: in STD_LOGIC;
           VGA_HS	: out STD_LOGIC;
           VGA_VS	: out STD_LOGIC;
           VGA_RED	: out STD_LOGIC_VECTOR (3 downto 0);
           VGA_BLUE	: out STD_LOGIC_VECTOR (3 downto 0);
           VGA_GREEN: out STD_LOGIC_VECTOR (3 downto 0);
			RGBmR	: in STD_LOGIC_VECTOR (3 downto 0);
			RGBmG	: in STD_LOGIC_VECTOR (3 downto 0);
			RGBmB	: in STD_LOGIC_VECTOR (3 downto 0);
			PIX_X	: out integer;
			PIX_Y	: out integer
           );
end VGA;

architecture Behavioral of VGA is

	---------------------------------------------------------------
	------------------------ 640x480@60Hz -------------------------
	---------------------------------------------------------------
	---|____________________________               ____________|---
	---|    						|_____________|            |---	
	---| Display time | Front porch | Pulse width | Back porch |---
	---------------------------------------------------------------
	constant FRAME_WIDTH : natural := 640;
	constant FRAME_HEIGHT : natural := 480;

	constant H_FP : natural := 16; --H front porch width (pixels)
	constant H_PW : natural := 96; --H sync pulse width (pixels)
	constant H_MAX : natural := 800; --H total period (pixels)

	constant V_FP : natural := 10; --V front porch width (lines)
	constant V_PW : natural := 2; --V sync pulse width (lines)
	constant V_MAX : natural := 521; --V total period (lines)

	constant H_POL : std_logic := '1';
	constant V_POL : std_logic := '1';

	-------------------------------------------------------------------------
	-- VGA Controller specific signals: Counters, Sync, R, G, B
	-------------------------------------------------------------------------
	-- Pixel clock, in this case 25 MHz
	signal pxl_clk : std_logic;
	-- The active signal is used to signal the active region of the screen (when not blank)
	signal active  : std_logic;

	-- Horizontal and Vertical counters
	signal h_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
	signal v_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');

	-- Pipe Horizontal and Vertical Counters
	signal h_cntr_reg_dly   : std_logic_vector(11 downto 0) := (others => '0');
	signal v_cntr_reg_dly   : std_logic_vector(11 downto 0) := (others => '0');

	-- Horizontal and Vertical Sync
	signal h_sync_reg : std_logic := not(H_POL);
	signal v_sync_reg : std_logic := not(V_POL);
	-- Pipe Horizontal and Vertical Sync
	signal h_sync_reg_dly : std_logic := not(H_POL);
	signal v_sync_reg_dly : std_logic :=  not(V_POL);

--	signal PIX_X :integer;-- range 0 to 639;
--	signal PIX_Y :integer;-- range 0 to 479;

	-- VGA R, G and B signals coming from the main multiplexers
	signal vga_red_cmb   : std_logic_vector(3 downto 0);
	signal vga_green_cmb : std_logic_vector(3 downto 0);
	signal vga_blue_cmb  : std_logic_vector(3 downto 0);
	--The main VGA R, G and B signals, validated by active
	signal vga_red_m    : std_logic_vector(3 downto 0);
	signal vga_green_m  : std_logic_vector(3 downto 0);
	signal vga_blue_m   : std_logic_vector(3 downto 0);
	-- Register VGA R, G and B signals
	signal vga_red_reg   : std_logic_vector(3 downto 0) := (others =>'0');
	signal vga_green_reg : std_logic_vector(3 downto 0) := (others =>'0');
	signal vga_blue_reg  : std_logic_vector(3 downto 0) := (others =>'0');

begin
	process(CLK)
		variable m:integer;
	begin
		if rising_edge(CLK) then
			m := m + 1;
			if ( m >= 2 ) then
				m := 0;
				pxl_clk <= NOT pxl_clk;
			end if;
		end if;
	end process;
       ---------------------------------------------------------------
       -- Generate Horizontal, Vertical counters and the Sync signals
       ---------------------------------------------------------------
	-- Horizontal counter
         process (pxl_clk)
         begin
           if (rising_edge(pxl_clk)) then
             if (h_cntr_reg = (H_MAX - 1)) then
               h_cntr_reg <= (others =>'0');
             else
               h_cntr_reg <= h_cntr_reg + 1;
             end if;
           end if;
         end process;
	-- Vertical counter
         process (pxl_clk)
         begin
           if (rising_edge(pxl_clk)) then
             if ((h_cntr_reg = (H_MAX - 1)) and (v_cntr_reg = (V_MAX - 1))) then
               v_cntr_reg <= (others =>'0');
             elsif (h_cntr_reg = (H_MAX - 1)) then
               v_cntr_reg <= v_cntr_reg + 1;
             end if;
           end if;
         end process;
	-- Horizontal sync
         process (pxl_clk)
         begin
           if (rising_edge(pxl_clk)) then
             if (h_cntr_reg >= (H_FP + FRAME_WIDTH - 1)) and (h_cntr_reg < (H_FP + FRAME_WIDTH + H_PW - 1)) then
               h_sync_reg <= H_POL;
             else
               h_sync_reg <= not(H_POL);
             end if;
           end if;
         end process;
	-- Vertical sync
         process (pxl_clk)
         begin
           if (rising_edge(pxl_clk)) then
             if (v_cntr_reg >= (V_FP + FRAME_HEIGHT - 1)) and (v_cntr_reg < (V_FP + FRAME_HEIGHT + V_PW - 1)) then
               v_sync_reg <= V_POL;
             else
               v_sync_reg <= not(V_POL);
             end if;
           end if;
         end process;


		process (pxl_clk)
		begin
		if (rising_edge(pxl_clk)) then
            h_cntr_reg_dly <= h_cntr_reg;
            v_cntr_reg_dly <= v_cntr_reg;
        end if;
		end process;

	PIX_X <= CONV_INTEGER(h_cntr_reg_dly) when (h_cntr_reg_dly >= 0) and (h_cntr_reg_dly < FRAME_WIDTH);
	PIX_Y <= CONV_INTEGER(v_cntr_reg_dly) when (v_cntr_reg_dly >= 0) and (v_cntr_reg_dly < FRAME_HEIGHT);

	vga_red_m	<= RGBmR;
	vga_green_m	<= RGBmG;
	vga_blue_m	<= RGBmB;

       --------------------
       -- The active signal
         active <= '1' when h_cntr_reg_dly < FRAME_WIDTH and v_cntr_reg_dly < FRAME_HEIGHT  else '0';
       --------------------

    ------------------------------------------------------------
    -- Turn Off VGA RBG Signals if outside of the active screen
    -- Make a 4-bit AND logic with the R, G and B signals
    ------------------------------------------------------------
    vga_red_cmb	<= (active & active & active & active) and vga_red_m;
    vga_green_cmb <= (active & active & active & active) and vga_green_m;
    vga_blue_cmb <= (active & active & active & active) and vga_blue_m;


    -- Register Outputs
     process (pxl_clk)
     begin
       if (rising_edge(pxl_clk)) then

         v_sync_reg_dly <= v_sync_reg;
         h_sync_reg_dly <= h_sync_reg;
         vga_red_reg    <= vga_red_cmb;
         vga_green_reg  <= vga_green_cmb;
         vga_blue_reg   <= vga_blue_cmb;
       end if;
     end process;

     -- Assign outputs
     VGA_HS		<= h_sync_reg_dly;
     VGA_VS		<= v_sync_reg_dly;
     VGA_RED	<= vga_red_reg;
     VGA_GREEN	<= vga_green_reg;
     VGA_BLUE	<= vga_blue_reg;

end Behavioral;
