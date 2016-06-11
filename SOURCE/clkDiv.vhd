----------------------------------------
--	component clkDiv is
--		Generic( n : INTEGER);		--nƵ
--		Port (  clk : in STD_LOGIC;
--			reset : in STD_LOGIC;
--			clkOut : out STD_LOGIC);
--	end component;
--	Uclk:clkDiv generic map(n=>100)
--				port map(clk   => clk,
--						 reset => reset,
--						 clkOut=> );
----------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity clkDiv is
	Generic( n : INTEGER);
    Port (  clk : in STD_LOGIC;
          reset : in STD_LOGIC;
          clkOut : out STD_LOGIC);
end ;

architecture Behavioral of clkDiv is
	signal clkS :STD_LOGIC:='0';
begin
	clkOut <= clkS;
    process(clk,reset)
        variable m : integer ;
    begin
        if reset = '1'then
        	m:=0;clkS<='0';
        elsif rising_edge(clk) then
            m := m + 1;
			if m>=(50_000_000/n) then
				clkS <= not clkS;m:=0;
        	end if;
        end if;
    end process;
end;
