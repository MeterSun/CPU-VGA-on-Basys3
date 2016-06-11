library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package comMCU is
	
--CPU states
	type states is ( 
				PRE0,RST0,GETI,PCPP,ALU0,
				MUL,DIV,RLC,RRC,RXC2,SWAP,PUSH,POP,
				MOVC,
				ACALL0,ACALL1,ACALL2,ACALL3,ACALL4,LCALL0,LCALL1,LCALL2,LCALL3,LCALL4,
				RET0,RET1,RET2,RET3,
				AJMP,LJMP,CJNE,DJNZ,DJNZ0,DJNZ1,DJNZ2,DJNZ3,DJNZ4,DJNZ5,DJNZ6,DJNZ7,DJNZd,
				vP2PC,PCrel,
				PUTI,ENDI);

	subtype memByte is std_logic_vector(7 downto 0);	--MEMORY Byte
	type MEMORY is array (NATURAL range <>) of memByte;	--MEMORY
----各个SFR寄存器地址
	constant aP0	:integer:=16#80#;
	constant aSP 	:integer:=16#81#;
	constant aDPL	:integer:=16#82#;
	constant aDPH	:integer:=16#83#;
--	constant aPCON	:integer:=16#87#;
--	constant aTCON	:integer:=16#88#;
--	constant aTMOD	:integer:=16#89#;
--	constant aTL0	:integer:=16#8A#;
--	constant aTL1	:integer:=16#8B#;
--	constant aTH0	:integer:=16#8C#;
--	constant aTH1	:integer:=16#8D#;
	constant aP1	:integer:=16#90#;
--	constant aSCON	:integer:=16#98#;
--	constant aSBUF	:integer:=16#99#;
	constant aP2	:integer:=16#A0#;
--	constant aIE	:integer:=16#A8#;
	constant aP3	:integer:=16#B0#;
--	constant aIP	:integer:=16#B8#;
--	constant aPSW	:integer:=16#D0#;
	constant aA		:integer:=16#E0#;
	constant aB		:integer:=16#F0#;
	--PSW程序状态字--e.g.SFR(PSW)(CY)
--	constant aCY	:integer:=7;
--	constant aAC	:integer:=6;
--	constant aRS0	:integer:=4;
--	constant aRS1	:integer:=3;
--	constant aOV	:integer:=2;
--	constant aP		:integer:=0;

-----------------------------------------------
	function KEY2ASCII(key : in STD_LOGIC_VECTOR(7 downto 0))
		return STD_LOGIC_VECTOR ;
-----------------------------------------------
----CPU's the length of instructions
	function lengthof(i :in std_logic_vector)
		return integer ;
-----------------------------------------------
	component CPU is
		Port ( 	clk		: in STD_LOGIC;
				reset	: in STD_LOGIC;
				keyboard: in STD_LOGIC_VECTOR (7 downto 0);
				sw		: in STD_LOGIC_VECTOR (15 downto 0);
				CS		: out STD_LOGIC;
				Data	: out STD_LOGIC_VECTOR (7 downto 0);
				Addr	: out STD_LOGIC_VECTOR (7 downto 0);			
				led 	: out STD_LOGIC_VECTOR (15 downto 0));
	end component CPU;
-----------------------------------------------
	component PPU is
		Port ( 	clk  	: in STD_LOGIC;
				reset	: in STD_LOGIC;
				CS		: in STD_LOGIC;
				Data	: in STD_LOGIC_VECTOR (7 downto 0);
				Addr	: in STD_LOGIC_VECTOR (7 downto 0);
				PIX_X	: in INTEGER;
				PIX_Y	: in INTEGER;
				RGBmR	: out STD_LOGIC_VECTOR (3 downto 0);
				RGBmG	: out STD_LOGIC_VECTOR (3 downto 0);
				RGBmB	: out STD_LOGIC_VECTOR (3 downto 0)
			);
	end component PPU;
-----------------------------------------------
	component VGA is
		Port ( 	CLK		: in STD_LOGIC;
				VGA_HS	: out STD_LOGIC;
				VGA_VS	: out STD_LOGIC;
				VGA_RED	: out STD_LOGIC_VECTOR (3 downto 0);
				VGA_BLUE: out STD_LOGIC_VECTOR (3 downto 0);
				VGA_GREEN: out STD_LOGIC_VECTOR (3 downto 0);
				RGBmR	: in STD_LOGIC_VECTOR (3 downto 0);
				RGBmG	: in STD_LOGIC_VECTOR (3 downto 0);
				RGBmB	: in STD_LOGIC_VECTOR (3 downto 0);
				PIX_X	: out integer;
				PIX_Y	: out integer
           );
	end component;
-----------------------------------------------
----定义键盘按键状态类型（无/通码/断码）	
	type KEYSTATE is ( NONE,MAKE,BREAK );
-----------------------------------------------
	component PS2Keyboard
	Port (	reset 	: in STD_LOGIC;
			PS2Clk 	: in STD_LOGIC;
			PS2Data : in STD_LOGIC;
			Keyflag : out KEYSTATE;
			Keycode	: out STD_LOGIC_VECTOR (7 downto 0) );
	end component;
-----------------------------------------------
--	component uart_module 
--		Port (	clk	: in STD_LOGIC;
--			reset 	: in STD_LOGIC;
--			flagRX	: out STD_LOGIC;
--			flagTX	: in STD_LOGIC;
--			RsRx 	: in STD_LOGIC;
--			RsTx 	: out STD_LOGIC;
--			dataRx	: out STD_LOGIC_VECTOR(7 downto 0);
--			dataTx	: in STD_LOGIC_VECTOR(7 downto 0));
--	end component;
-----------------------------------------------
---clock
	component clkDiv is
		Generic( n : INTEGER);		--n?
		Port ( 
			clk 	: in STD_LOGIC;
			reset	: in STD_LOGIC;
			clkOut	: out STD_LOGIC);
	end component;
-----------------------------------------------
end;
package body comMCU is

	function lengthof(i :in std_logic_vector)
		return integer is
	begin
	if i(3 downto 0)="0001"then
		return 2;
	else
		case CONV_INTEGER(i) is
			when 16#02#=> return 3;
			when 16#10#=> return 3;
			when 16#12#=> return 3;
			when 16#20#=> return 3;
			when 16#30#=> return 3;
			when 16#43#=> return 3;
			when 16#53#=> return 3;
			when 16#63#=> return 3;
			when 16#75#=> return 3;
			when 16#85#=> return 3;
			when 16#90#=> return 3;
			when 16#B4# to 16#BF#=>return 3;
			when 16#D5#=>return 3;
	
			when 16#05#=>return 2;
			when 16#15#=>return 2;
			when 16#24#=>return 2;
			when 16#25#=>return 2;
			when 16#34#=>return 2;
			when 16#35#=>return 2;
			when 16#40#=>return 2;
			when 16#42#=>return 2;
			when 16#44#=>return 2;
			when 16#45#=>return 2;
			when 16#50#=>return 2;
			when 16#52#=>return 2;	
			when 16#54#=>return 2;
			when 16#55#=>return 2;
			when 16#60#=>return 2;
			when 16#62#=>return 2;
			when 16#64#=>return 2;
			when 16#65#=>return 2;
			when 16#70#=>return 2;
			when 16#72#=>return 2;
			when 16#74#=>return 2;
			when 16#76# to 16#7F#=>return 2;
			when 16#80#=>return 2;
			when 16#82#=>return 2;
			when 16#86# to 16#8F#=>return 2;
			when 16#92#=>return 2;
			when 16#94#=>return 2;
			when 16#95#=>return 2;
			when 16#A0#=>return 2;
			when 16#A2#=>return 2;
			when 16#A6# to 16#AF#=>return 2;
			when 16#B0#=> return 2;
			when 16#B2#=> return 2;
			when 16#C0#=> return 2;
			when 16#C2#=> return 2;
			when 16#C5#=> return 2;
			when 16#D0#=> return 2;
			when 16#D2#=> return 2;
			when 16#D8# to 16#DF#=>return 2;
			when 16#E5#=> return 2;
			when 16#F5#=> return 2;
	
			when others =>return 1;
		end case;
	end if;
	end function;
	function KEY2ASCII(key : in STD_LOGIC_VECTOR(7 downto 0))
		return STD_LOGIC_VECTOR is
	begin
		case key is
			when X"1C" => return X"41";	--'A';
			when X"32" => return X"42";	--'B';
			when X"21" => return X"43";	--'C';
			when X"23" => return X"44";	--'D';
			when X"24" => return X"45";	--'E';
			when X"2B" => return X"46";	--'F';
			when X"34" => return X"47";	--'G';
			when X"33" => return X"48";	--'H';
			when X"43" => return X"49";	--'I';
			when X"3B" => return X"4A";	--'J';
			when X"42" => return X"4B";	--'K';
			when X"4B" => return X"4C";	--'L';
			when X"3A" => return X"4D";	--'M';
			when X"31" => return X"4E";	--'N';
			when X"44" => return X"4F";	--'O';
			when X"4D" => return X"50";	--'P';
			when X"15" => return X"51";	--'Q';
			when X"2D" => return X"52";	--'R';
			when X"1B" => return X"53";	--'S';
			when X"2C" => return X"54";	--'T';
			when X"3C" => return X"55";	--'U';
			when X"2A" => return X"56";	--'V';
			when X"1D" => return X"57";	--'W';
			when X"22" => return X"58";	--'X';
			when X"35" => return X"59";	--'Y';
			when X"1A" => return X"5A";	--'Z';
			when X"29" => return X"20";	--' ';
			when X"16" => return X"31";	--'1';
			when X"1E" => return X"32";	--'2';
			when X"26" => return X"33";	--'3';
			when X"25" => return X"34";	--'4';
			when X"2E" => return X"35";	--'5';
			when X"36" => return X"36";	--'6';
			when X"3D" => return X"37";	--'7';
			when X"3E" => return X"38";	--'8';
			when X"46" => return X"39";	--'9';
			when X"45" => return X"30";	--'0';
			when others=> return X"00";
		end case;
	end function;

end;
