----------------------------------------------------------------------------------
--	component PS2Keyboard
--	Port (	reset 	: in STD_LOGIC;
--			PS2Clk 	: in STD_LOGIC;
--			PS2Data : in STD_LOGIC;
--			Keyflag : out KEYSTATE;
--			Keycode	: out STD_LOGIC_VECTOR (7 downto 0) );
--	end component;
--	Keyboard:PS2Keyboard port map(
--			reset	=> ,
--			PS2Clk	=> ,
--			PS2Data	=> ,
--			Keyflag	=> ,
--			Keycode	=> );
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.comMCU.ALL;


entity PS2Keyboard is
	Port (	reset 	: in STD_LOGIC;
			PS2Clk 	: in STD_LOGIC;
			PS2Data : in STD_LOGIC;
			Keyflag : out KEYSTATE;
			Keycode	: out STD_LOGIC_VECTOR (7 downto 0) );
end PS2Keyboard;

architecture Behavioral of PS2Keyboard is
    signal flag : KEYSTATE:=NONE;
    signal out_S : std_logic_vector(15 downto 0);
begin
	
ps2:process(reset,PS2Clk)
		variable vData :STD_LOGIC_VECTOR(21 downto 0):=(0=>'1',others=>'0');
		variable vCount :integer range 0 to 21;
	begin
		if reset='1' then
			vCount:=0;
			flag<=NONE;
			out_S<=(others=>'1');
		elsif falling_edge(PS2Clk) then
		--检测低电平，若有则进行下一位检测，接收标识置零
		--检测下一位保存，置位输出，结果自输出后保存至下一位检测开始，时间最短为两个码元周期
		--检测是否停止位，有则输出，接收标识置位（接收标识持续一个码元周期），无则重新开始检测
			case vCount is
				when 0 => vData(0):=PS2Data; if vData(0)='0' then vCount:=1; end if;
												flag<=NONE;
				when 1 to 9 => vData(vCount):=PS2Data; vCount:=vCount+1;
				when 10 => vData(vCount):=PS2Data;	if vData(8 downto 1)=X"F0" then 
														vCount:=vCount+1;		--判断是断码，继续向下扫描
													else flag<=MAKE;vCount:=0;	--确定是通码，置标识、返回
														out_S(7 downto 0)<=vData(8 downto 1);
													end if;
				when 11 => vData(vCount):=PS2Data; if vData(0)='0' then vCount:=12;
													else vCount:=0;flag<=NONE;
													end if;
				when 12 to 20 => vData(vCount):=PS2Data; vCount:=vCount+1;
				when 21 => vData(vCount):=PS2Data;	if vData(21)='1' then 
														vCount:=0;flag<=BREAK;	--确定是断码，置标识、返回
														out_S(7 downto 0)<=vData(8 downto 1);
														out_S(15 downto 8)<=vData(19 downto 12);
													else vCount:=0;flag<=NONE;
													end if;
													
				when others => vCount:=0;flag<=NONE;--out_S<=(others=>'1');
			end case;
		end if;
	end process; 
	Keyflag <= flag;
	Keycode <=	out_S(7 downto 0) when flag=MAKE else
--				out_S(15 downto 8)when flag=BREAK else
				(others=>'1');
	
end Behavioral;

--Data(0) --Start
--Data(1) --D0
--Data(2) --D1
--Data(3) --D2
--Data(4) --D3
--Data(5) --D4
--Data(6) --D5
--Data(7) --D6
--Data(8) --D7
--Data(9) --P
--Data(10) --Stop 

--Data(11) --Start
--Data(12) --D0
--Data(13) --D1
--Data(14) --D2
--Data(15) --D3
--Data(16) --D4
--Data(17) --D5
--Data(18) --D6
--Data(19) --D7
--Data(20) --P
--Data(21) --Stop 
