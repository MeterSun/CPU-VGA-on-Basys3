library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use work.comMCU.ALL;
use work.ImageQQ.ALL;

entity PPU is
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
end PPU;

architecture Behavioral of PPU is
--signal coordinate X,Y
	signal X,Y : integer;	--for frame A (QQ)
	signal BX,BY : integer;	-- for frame B
----------------------------------------------------------------------
---- memorys
----FrameA in package ImageQQ	
--	subtype MemVideoPix is std_logic_vector(3 downto 0);
--	type MemVideoLine is array(0 to DIS_MAX_X - 1) of MemVideoPix;
--	type MemVideoFrame is array(0 to DIS_MAX_Y - 1) of MemVideoLine;
--	constant VideoFrameA_R : MemVideoFrame;
--	constant VideoFrameA_G : MemVideoFrame;
--	constant VideoFrameA_B : MemVideoFrame;
----------------------------------------------------------------------
----FrameB
	constant DIS_MAX_B_X :integer:= 40;		--横坐标
	constant DIS_MAX_B_Y :integer:= 32;		--纵坐标

	type MemVideoColB is array(0 to 15) of memByte;	--一列32行（每行8位）
	type MemVideoFrameB is array(0 to 9) of MemVideoColB;		--一共5列，一行40pixs
	signal VideoFrameB : MemVideoFrameB;	--显存B
----------------------------------------------------------------------
----|address of VideoFrameB
----|0|1|2|3|4|
----|5|6|7|8|9|
----------------------------------------------------------------------
---	type MemChar is array(0 to 16) of memByte;
	type MemCharLib is array(0 to 16#5A#) of MemVideoColB;
	constant CharPixLib :MemCharLib:=(
	16#30#=>(X"00",X"00",X"1C",X"36",X"63",X"63",X"63",X"63",X"63",X"63",X"63",X"63",X"36",X"1C",X"00",X"00"),
	16#31#=>(X"00",X"00",X"3C",X"0C",X"0C",X"0C",X"0C",X"0C",X"0C",X"0C",X"0C",X"0C",X"0C",X"3F",X"00",X"00"),
	16#32#=>(X"00",X"00",X"3E",X"63",X"63",X"63",X"06",X"0C",X"18",X"30",X"20",X"73",X"6B",X"66",X"00",X"00"),
	16#33#=>(X"00",X"00",X"7F",X"63",X"66",X"66",X"0C",X"1C",X"06",X"03",X"03",X"63",X"66",X"3C",X"00",X"00"),
	16#34#=>(X"00",X"00",X"06",X"0E",X"0E",X"1E",X"16",X"36",X"26",X"66",X"7F",X"06",X"06",X"1F",X"00",X"00"),
	16#35#=>(X"00",X"00",X"7F",X"63",X"63",X"60",X"7C",X"66",X"63",X"03",X"03",X"63",X"66",X"3C",X"00",X"00"),
	16#36#=>(X"00",X"00",X"1E",X"33",X"63",X"60",X"7C",X"76",X"63",X"63",X"63",X"63",X"36",X"1C",X"00",X"00"),
	16#37#=>(X"00",X"00",X"7B",X"67",X"63",X"62",X"06",X"06",X"06",X"0C",X"0C",X"0C",X"0C",X"0C",X"00",X"00"),
	16#38#=>(X"00",X"00",X"1C",X"36",X"63",X"63",X"36",X"1C",X"36",X"63",X"63",X"63",X"36",X"1C",X"00",X"00"),
	16#39#=>(X"00",X"00",X"1C",X"36",X"63",X"63",X"63",X"63",X"37",X"1B",X"03",X"63",X"66",X"3C",X"00",X"00"),
	16#41#=>(X"00",X"00",X"38",X"08",X"1C",X"1C",X"14",X"14",X"36",X"3E",X"36",X"36",X"36",X"77",X"00",X"00"),
	16#42#=>(X"00",X"00",X"7E",X"33",X"33",X"33",X"33",X"3E",X"33",X"33",X"33",X"33",X"33",X"7E",X"00",X"00"),
	16#43#=>(X"00",X"00",X"1D",X"37",X"63",X"61",X"61",X"60",X"60",X"60",X"60",X"61",X"33",X"1E",X"00",X"00"),
	16#44#=>(X"00",X"00",X"7C",X"36",X"33",X"33",X"33",X"33",X"33",X"33",X"33",X"33",X"36",X"7C",X"00",X"00"),
	16#45#=>(X"00",X"00",X"7F",X"33",X"33",X"30",X"32",X"3E",X"32",X"32",X"30",X"33",X"33",X"7F",X"00",X"00"),
	16#46#=>(X"00",X"00",X"7F",X"33",X"33",X"30",X"32",X"3E",X"32",X"32",X"30",X"30",X"30",X"7C",X"00",X"00"),
	16#47#=>(X"00",X"00",X"1B",X"37",X"63",X"63",X"60",X"60",X"6F",X"63",X"63",X"63",X"37",X"1B",X"00",X"00"),
	16#48#=>(X"00",X"00",X"63",X"63",X"63",X"63",X"63",X"7F",X"63",X"63",X"63",X"63",X"63",X"63",X"00",X"00"),
	16#49#=>(X"00",X"00",X"7E",X"18",X"18",X"18",X"18",X"18",X"18",X"18",X"18",X"18",X"18",X"7E",X"00",X"00"),
	16#4A#=>(X"00",X"00",X"3F",X"0C",X"0C",X"0C",X"0C",X"0C",X"0C",X"0C",X"6C",X"6C",X"6C",X"78",X"00",X"00"),
	16#4B#=>(X"00",X"00",X"77",X"33",X"36",X"36",X"3C",X"38",X"3C",X"36",X"36",X"33",X"33",X"77",X"00",X"00"),
	16#4C#=>(X"00",X"00",X"78",X"30",X"30",X"30",X"30",X"30",X"30",X"30",X"33",X"33",X"33",X"7F",X"00",X"00"),
	16#4D#=>(X"00",X"00",X"63",X"63",X"77",X"77",X"77",X"7F",X"6B",X"6B",X"6B",X"63",X"63",X"63",X"00",X"00"),
	16#4E#=>(X"00",X"00",X"77",X"33",X"33",X"3B",X"3B",X"3B",X"37",X"37",X"37",X"33",X"33",X"7B",X"00",X"00"),
	16#4F#=>(X"00",X"00",X"1C",X"36",X"63",X"63",X"63",X"63",X"63",X"63",X"63",X"63",X"36",X"1C",X"00",X"00"),
	16#50#=>(X"00",X"00",X"7C",X"36",X"33",X"33",X"33",X"33",X"36",X"3C",X"30",X"30",X"30",X"7C",X"00",X"00"),
	16#51#=>(X"00",X"00",X"1C",X"36",X"63",X"63",X"63",X"63",X"63",X"63",X"6B",X"77",X"36",X"1E",X"03",X"00"),
	16#52#=>(X"00",X"00",X"7E",X"33",X"33",X"33",X"33",X"36",X"3C",X"36",X"33",X"33",X"33",X"7B",X"00",X"00"),
	16#53#=>(X"00",X"00",X"1D",X"37",X"63",X"61",X"61",X"38",X"0E",X"43",X"43",X"63",X"76",X"5C",X"00",X"00"),
	16#54#=>(X"00",X"00",X"3F",X"2D",X"2D",X"2D",X"0C",X"0C",X"0C",X"0C",X"0C",X"0C",X"0C",X"1E",X"00",X"00"),
	16#55#=>(X"00",X"00",X"77",X"33",X"33",X"33",X"33",X"33",X"33",X"33",X"33",X"33",X"33",X"1E",X"00",X"00"),
	16#56#=>(X"00",X"00",X"77",X"36",X"36",X"36",X"36",X"36",X"36",X"1C",X"1C",X"1C",X"08",X"08",X"00",X"00"),
	16#57#=>(X"00",X"00",X"63",X"63",X"63",X"63",X"6B",X"6B",X"6B",X"7F",X"3E",X"36",X"36",X"36",X"00",X"00"),
	16#58#=>(X"00",X"00",X"77",X"77",X"22",X"36",X"36",X"1C",X"1C",X"36",X"36",X"22",X"77",X"77",X"00",X"00"),
	16#59#=>(X"00",X"00",X"77",X"33",X"33",X"33",X"33",X"1E",X"0C",X"0C",X"0C",X"0C",X"0C",X"1E",X"00",X"00"),
	16#5A#=>(X"00",X"00",X"7E",X"66",X"66",X"6C",X"0C",X"18",X"18",X"30",X"36",X"66",X"66",X"7E",X"00",X"00"),
	others=>(others=>(others=>'0')));
----------------------------------------------------------------------
---- The control memory.
	signal PPUCtrl :MEMORY(0 to 19);
	------------------------------------------------------------------
----|0F0H|PPUCtrl(0)| Display On/Off|XXXX|XX|BA|
----|0F1H|PPUCtrl(1)| 
----|0F2H|PPUCtrl(2)|
----|0F3H|PPUCtrl(3)|
----|0F4H|PPUCtrl(4)|
----|0F5H|PPUCtrl(5)| Red   Background Color/Foreground Color
----|0F6H|PPUCtrl(6)| Green Background Color/Foreground Color
----|0F7H|PPUCtrl(7)| Blue  Background Color/Foreground Color

----|0E0H|PPUCtrl(10)|	BLOCK0
----|0E1H|PPUCtrl(11)|  BLOCK1
----|0E2H|PPUCtrl(12)|  BLOCK2
----|0E3H|PPUCtrl(13)|  BLOCK3
----|0E4H|PPUCtrl(14)|  BLOCK4
----|0E5H|PPUCtrl(15)|  BLOCK5
----|0E6H|PPUCtrl(16)|  BLOCK6
----|0E7H|PPUCtrl(17)|  BLOCK7
----|0E8H|PPUCtrl(18)|  BLOCK8
----|0E9H|PPUCtrl(19)|  BLOCK9
----------------------------------------------------------------------
	signal R_A_reg:STD_LOGIC_VECTOR(3 downto 0);
	signal G_A_reg:STD_LOGIC_VECTOR(3 downto 0);
	signal B_A_reg:STD_LOGIC_VECTOR(3 downto 0);
    ------------------------------------------------------------------
	signal R_B_reg:STD_LOGIC_VECTOR(3 downto 0);
	signal G_B_reg:STD_LOGIC_VECTOR(3 downto 0);
	signal B_B_reg:STD_LOGIC_VECTOR(3 downto 0);
----------------------------------------------------------------------
begin
----------------------------------------------------------------------
----coordinate X,Y
	X <= PIX_X/(640/DIS_MAX_X) when PIX_X>=0 and PIX_X<640;
	Y <= PIX_Y/(480/DIS_MAX_Y) when PIX_Y>=0 and PIX_Y<480;
----coordinate X,Y
	BX <= PIX_X/(640/DIS_MAX_B_X) when PIX_X>=0 and PIX_X<640;
	BY <= PIX_Y/(480/DIS_MAX_B_Y) when PIX_Y>=0 and PIX_Y<480;
----------------------------------------------------------------------
	RGBmR 	<= 	R_A_reg when PPUCtrl(0)(0)='1' else
				R_B_reg when PPUCtrl(0)(1)='1' else
				"0000";
	RGBmG 	<= 	G_A_reg when PPUCtrl(0)(0)='1' else
	            G_B_reg when PPUCtrl(0)(1)='1' else
	            "0000";
	RGBmB 	<= 	B_A_reg when PPUCtrl(0)(0)='1' else
	            B_B_reg when PPUCtrl(0)(1)='1' else
	            "0000";
----------------------------------------------------------------------
	R_A_reg <=	VideoFrameA_R(Y)(X);
	G_A_reg <=	VideoFrameA_G(Y)(X);
	B_A_reg <=	VideoFrameA_B(Y)(X);
    ------------------------------------------------------------------
	R_B_reg <=	PPUCtrl(5)(3 downto 0) when VideoFrameB(BX/8 + 5*(BY/16))(BY REM 16)(7-(BX REM 8)) = '1' else 
				PPUCtrl(5)(7 downto 4);
	G_B_reg <=	PPUCtrl(6)(3 downto 0) when VideoFrameB(BX/8 + 5*(BY/16))(BY REM 16)(7-(BX REM 8)) = '1' else
	            PPUCtrl(6)(7 downto 4);
	B_B_reg <=	PPUCtrl(7)(3 downto 0) when VideoFrameB(BX/8 + 5*(BY/16))(BY REM 16)(7-(BX REM 8)) = '1' else
	            PPUCtrl(7)(7 downto 4);
----------------------------------------------------------------------
	process(CS,Data,Addr)
	begin
		if CS='1' then
			if Addr(7 downto 4)="1111" then
				PPUCtrl(CONV_INTEGER(Addr(3 downto 0))) <= Data;
			elsif Addr(7 downto 4)="1110" then
				PPUCtrl(10 + CONV_INTEGER(Addr(3 downto 0))) <= Data;
			end if;
		end if;
	end process;
----------------------------------------------------------------------
	process(PPUCtrl)
	begin
		VideoFrameB(0)( 0 to 15) <= CharPixLib(CONV_INTEGER(PPUCtrl(10)))(0 to 15);
		VideoFrameB(1)( 0 to 15) <= CharPixLib(CONV_INTEGER(PPUCtrl(11)))(0 to 15);
		VideoFrameB(2)( 0 to 15) <= CharPixLib(CONV_INTEGER(PPUCtrl(12)))(0 to 15);
		VideoFrameB(3)( 0 to 15) <= CharPixLib(CONV_INTEGER(PPUCtrl(13)))(0 to 15);
		VideoFrameB(4)( 0 to 15) <= CharPixLib(CONV_INTEGER(PPUCtrl(14)))(0 to 15);
		VideoFrameB(5)( 0 to 15) <= CharPixLib(CONV_INTEGER(PPUCtrl(15)))(0 to 15);
		VideoFrameB(6)( 0 to 15) <= CharPixLib(CONV_INTEGER(PPUCtrl(16)))(0 to 15);
		VideoFrameB(7)( 0 to 15) <= CharPixLib(CONV_INTEGER(PPUCtrl(17)))(0 to 15);
		VideoFrameB(8)( 0 to 15) <= CharPixLib(CONV_INTEGER(PPUCtrl(18)))(0 to 15);
		VideoFrameB(9)( 0 to 15) <= CharPixLib(CONV_INTEGER(PPUCtrl(19)))(0 to 15);
	end process;
----------------------------------------------------------------------	
end Behavioral;
