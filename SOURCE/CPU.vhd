library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use work.comMCU.ALL;
use work.HEXfile.ALL;

entity CPU is
    Port (
		clk 	: in STD_LOGIC;
		reset	: in STD_LOGIC;
		keyboard: in STD_LOGIC_VECTOR (7 downto 0);
		sw		: in STD_LOGIC_VECTOR (15 downto 0);
		CS		: out STD_LOGIC;
		Data	: out STD_LOGIC_VECTOR (7 downto 0);
		Addr	: out STD_LOGIC_VECTOR (7 downto 0);
		led 	: out STD_LOGIC_VECTOR (15 downto 0));
end CPU;

architecture Behavioral of CPU is
-----------------------------------------------------
----the real clock
	signal ClkSec:std_logic;		--1Hz
	signal second:integer range 0 to 59;
	signal minute:integer range 0 to 59;
	signal hour	 :integer range 0 to 23;
	signal second_i	:integer;
	signal minute_i	:integer;
	signal hour_i	:integer;
	signal clock_START:std_logic:='0';
	signal SS_L	 :STD_LOGIC_VECTOR (7 downto 0);
	signal SS_H	 :STD_LOGIC_VECTOR (7 downto 0);
	signal MM_L	 :STD_LOGIC_VECTOR (7 downto 0);
	signal MM_H	 :STD_LOGIC_VECTOR (7 downto 0);
	signal HH_L	 :STD_LOGIC_VECTOR (7 downto 0);
	signal HH_H	 :STD_LOGIC_VECTOR (7 downto 0);
-----------------------------------------------------
	signal RAMINPUT :MEMORY( 16#0# to 16#F# );
-----------------------------------------------------
	constant clockHZ:integer:=1_000_000;
	signal PC	:integer range 0 to ROM'LENGTH;--16#FFFF#;--指令地址寄存器
	signal clock:std_logic;			--CPU时钟
	signal next_state :states:=PRE0;	--CPU状态寄存器
--	signal current_state:states:=PRE0;	--CPU状态寄存器 --simu
----内部数据存储器&特殊功能寄存器 RAMSFR 及初值
	signal RAMSFR :MEMORY( 16#00# to 16#FF# ):=(
		aSP=>X"07",aP0=>X"FF",aP1=>X"FF",aP2=>X"FF",aP3=>X"FF",others=>X"00");
----RAMSFR寄存器地址
	signal aR0 :integer:= 16#00#;
--	signal aR1 :integer:= 16#01#;
--	signal aR2 :integer:= 16#02#;
--	signal aR3 :integer:= 16#03#;
--	signal aR4 :integer:= 16#04#;
--	signal aR5 :integer:= 16#05#;
--	signal aR6 :integer:= 16#06#;
--	signal aR7 :integer:= 16#07#;
begin
----------------------------------------------------------------------------
----Output
	CS   <= RAMSFR(16#20#)(0);
	Addr <= RAMSFR(aP2);
	Data <= RAMSFR(aP3);
	led( 7 downto 0) <= RAMSFR(aP0);
	led(15 downto 8) <= RAMSFR(aP1);
	clock_START <= RAMSFR(16#C6#)(0);
	second_i<=CONV_INTEGER(RAMSFR(16#C7#)(7 downto 4))*10+CONV_INTEGER(RAMSFR(16#C7#)(3 downto 0));
	minute_i<=CONV_INTEGER(RAMSFR(16#C8#)(7 downto 4))*10+CONV_INTEGER(RAMSFR(16#C8#)(3 downto 0));
	hour_i  <=CONV_INTEGER(RAMSFR(16#C9#)(7 downto 4))*10+CONV_INTEGER(RAMSFR(16#C9#)(3 downto 0));
----------------------------------------------------------------------------
----Input	
	process(keyboard,sw,SS_H,SS_L,MM_H,MM_L,HH_H,HH_L)
	begin
		RAMINPUT(16#0#)	<= keyboard;
		RAMINPUT(16#1#)	<= KEY2ASCII(keyboard);
		RAMINPUT(16#2#)	<= sw( 7 downto 0);
		RAMINPUT(16#3#)	<= sw(15 downto 8);
	
		RAMINPUT(16#A#)	<= SS_L;
		RAMINPUT(16#B#)	<= SS_H;
		RAMINPUT(16#C#)	<= MM_L;
		RAMINPUT(16#D#)	<= MM_H;
		RAMINPUT(16#E#)	<= HH_L;
		RAMINPUT(16#F#)	<= HH_H;
	end process;
----------------------------------------------------------------------------
----CPU
	process(clock,reset)
		variable IR	:MEMORY(0 to 2);		--指令寄存器(0,1,2)
		variable ilen:integer range 1 to 3;	--指令长度寄存
	--ALU中临时寄存器
--		variable vbit	:STD_LOGIC;
--		variable swap1,swap2:STD_LOGIC_VECTOR(3 downto 0);
		variable temp1,temp2:STD_LOGIC_VECTOR(7 downto 0);
--		variable tempbit9 	:STD_LOGIC_VECTOR(8 downto 0);
		variable vPC:STD_LOGIC_VECTOR(15 downto 0);
		variable dir:INTEGER;
		variable odir:INTEGER;
		variable rel:INTEGER;
		variable tm1:INTEGER;
		variable tm2:INTEGER;
--	--寄存器
		variable DPTR:STD_LOGIC_VECTOR(15 downto 0);
	begin
	if reset='1'then
		next_state <= RST0;
	elsif rising_edge(clock) then
		RAMSFR( 16#C0# to 16#CF# ) <= RAMINPUT;
		case next_state is
			when PRE0	=> next_state<=RST0; PC<=0;		--复位前准备状态
			when RST0	=> next_state<=GETI; PC<=0; 	--复位状态
							RAMSFR(aSP)<=X"07";
							RAMSFR(aP0)<=X"FF";
							RAMSFR(aP1)<=X"FF";
							RAMSFR(aP2)<=X"FF";
							RAMSFR(aP3)<=X"FF";
			when GETI	=> next_state<=PCPP; ilen:=lengthof(ROM(PC));
 							IR:=(0=>ROM(PC),1=>ROM(PC+1),2=>ROM(PC+2));	--取指令
							dir:=CONV_INTEGER(IR(1));
							DPTR:= RAMSFR(aDPH) & RAMSFR(aDPL);
			when PCPP	=> next_state<=ALU0; PC<=PC+ilen;
			when ALU0	=>
				case CONV_INTEGER(IR(0))is
-------------------------------------------------------------------------------------------------------
--ADD A,Rn
			when 16#28#|16#29#|16#2A#|16#2B#|16#2C#|16#2D#|16#2E#|16#2F# =>	next_state<=ENDI;
				RAMSFR(aA)<=RAMSFR(aA)+RAMSFR(aR0+CONV_INTEGER(IR(0)(2 downto 0)));
--ADD A,(dir)
			when 16#25# => next_state<=ENDI; RAMSFR(aA)<=RAMSFR(aA)+RAMSFR(dir);	--A=A+(dir)
--ADD A,#data
			when 16#24# => next_state<=ENDI; RAMSFR(aA)<=RAMSFR(aA)+IR(1);
--INC A
			when 16#04# => next_state<=ENDI; RAMSFR(aA)<=RAMSFR(aA)+1;
--INC dir
			when 16#05# => next_state<=ENDI; RAMSFR(dir)<=RAMSFR(dir)+1;
--INC Rn
			when 16#08#|16#09#|16#0A#|16#0B#|16#0C#|16#0D#|16#0E#|16#0F# => next_state<=ENDI;
				RAMSFR(aR0+CONV_INTEGER(IR(0)(2 downto 0)))<=RAMSFR(aR0+CONV_INTEGER(IR(0)(2 downto 0)))+1;
--INC DPTR
			when 16#A3# => next_state<=ENDI; DPTR:=DPTR+1;
--DEC A
			when 16#14# => next_state<=ENDI; RAMSFR(aA)<=RAMSFR(aA)-1;
--DEC (dir)
			when 16#15# => next_state<=ENDI; RAMSFR(dir)<=RAMSFR(dir)-1;
--DEC Rn
			when 16#18#|16#19#|16#1A#|16#1B#|16#1C#|16#1D#|16#1E#|16#1F# => next_state<=ENDI;
				RAMSFR(aR0+CONV_INTEGER(IR(0)(2 downto 0)))<=RAMSFR(aR0+CONV_INTEGER(IR(0)(2 downto 0)))-1;
--CLR A
			when 16#E4# => next_state<=ENDI; RAMSFR(aA)<=(others=>'0');
--CPL A
			when 16#F4# => next_state<=ENDI; RAMSFR(aA)<=NOT RAMSFR(aA);
-------------------------------------------------------------------------------------------------------
--MOV A,Rn
			when 16#E8#|16#E9#|16#EA#|16#EB#|16#EC#|16#ED#|16#EE#|16#EF#=> next_state<=ENDI;
					RAMSFR(aA)<=RAMSFR(aR0+CONV_INTEGER(IR(0)(2 downto 0)));
--MOV A,(dir)
			when 16#E5# => next_state<=ENDI; RAMSFR(aA)<=RAMSFR(dir);	--A=(dir)
--MOV A,#data
			when 16#74# => next_state<=ENDI; RAMSFR(aA)<=IR(1);
--MOV Rn,A
			when 16#F8#|16#F9#|16#FA#|16#FB#|16#FC#|16#FD#|16#FE#|16#FF# => next_state<=ENDI;
				RAMSFR(aR0+CONV_INTEGER(IR(0)(2 downto 0)))<=RAMSFR(aA);
--MOV Rn,(dir)
			when 16#A8#|16#A9#|16#AA#|16#AB#|16#AC#|16#AD#|16#AE#|16#AF# => next_state<=ENDI;
				RAMSFR(aR0+CONV_INTEGER(IR(0)(2 downto 0)))<=RAMSFR(dir);
--MOV Rn,#data
			when 16#78#|16#79#|16#7A#|16#7B#|16#7C#|16#7D#|16#7E#|16#7F# => next_state<=ENDI;
				RAMSFR(aR0+CONV_INTEGER(IR(0)(2 downto 0)))<=IR(1);
--MOV (dir),A
			when 16#F5# => next_state<=ENDI; RAMSFR(dir)<=RAMSFR(aA);
--MOV (dir),Rn
			when 16#88#|16#89#|16#8A#|16#8B#|16#8C#|16#8D#|16#8E#|16#8F#=> next_state<=ENDI;
				RAMSFR(dir)<=RAMSFR(aR0+CONV_INTEGER(IR(0)(2 downto 0)));
--MOV (dir),(dir)
			when 16#85# => next_state<=ENDI; RAMSFR(CONV_INTEGER(IR(2)))<=RAMSFR(dir);
--MOV (dir),#data
			when 16#75# => next_state<=ENDI; RAMSFR(dir)<=IR(2);
-------------------------------------------------------------------------------------------------------
--MOV DPTR,#data16
			when 16#90# => next_state<=ENDI; RAMSFR(aDPH)<=IR(1);RAMSFR(aDPL)<=IR(2);
--MOVC A,@A+DPTR
			when 16#93# => next_state<=MOVC; tm1:=CONV_INTEGER(RAMSFR(aA));tm2:=CONV_INTEGER(DPTR);
-------------------------------------------------------------------------------------------------------
--------->>>>>>>>>>>>>
--					when 16#11#|16#31#|16#51#|16#71#|16#91#|16#B1#|16#D1#|16#F1#
--								=> next_state<=ACALL0; vPC:=CONV_STD_LOGIC_VECTOR(PC,16);	--ACALL

--					when 16#12# => next_state<=LCALL0; vPC:=CONV_STD_LOGIC_VECTOR(PC,16);	--LCALL

--					when 16#22# => next_state<=RET0; vPC:=CONV_STD_LOGIC_VECTOR(PC,16);	--RET
--					when 16#32# => next_state<=RET0; vPC:=CONV_STD_LOGIC_VECTOR(PC,16);	--RETI	--中断返回
-------------------------------------------------------------------------------------------------
--AJMP ad11
			when 16#01#|16#21#|16#41#|16#61#|16#81#|16#A1#|16#C1#|16#E1# =>
				next_state<=AJMP; vPC:=CONV_STD_LOGIC_VECTOR(PC,16);
--LJMP ad16
			when 16#02# => next_state<=LJMP; vPC:=CONV_STD_LOGIC_VECTOR(PC,16);
--SJMP rel
			when 16#80# => next_state<=PCrel; rel:=CONV_INTEGER(IR(1));
-------------------------------------------------------------------------------------------------
--JZ rel
			when 16#60# => if RAMSFR(aA)=X"00" then next_state<=PCrel;rel:=CONV_INTEGER(IR(1));
										  else next_state<=ENDI; end if;
--JNZ rel
			when 16#70# => if RAMSFR(aA)/=X"00" then next_state<=PCrel;rel:=CONV_INTEGER(IR(1));
										  else next_state<=ENDI; end if;
---------------------------------------------------------------------------------------------------------
--CJNE A,dir,rel
			when 16#B5# => next_state<=CJNE; temp1:=RAMSFR(aA);temp2:=RAMSFR(dir);rel:=CONV_INTEGER(IR(2));
--CJNE A,#data,rel
			when 16#B4# => next_state<=CJNE; temp1:=RAMSFR(aA);temp2:=IR(1);rel:=CONV_INTEGER(IR(2));
--CJNE Rn,#data,rel
			when 16#B8#|16#B9#|16#BA#|16#BB#|16#BC#|16#BD#|16#BE#|16#BF# => next_state<=CJNE;
				temp1:=RAMSFR(aR0+CONV_INTEGER(IR(0)(2 downto 0))); temp2:=IR(1); rel:=CONV_INTEGER(IR(2));
-----------------------------------------------------------------------------------------------------
--DJNZ Rn,rel
			when 16#D8#|16#D9#|16#DA#|16#DB#|16#DC#|16#DD#|16#DE#|16#DF# => next_state<=DJNZ0;
				RAMSFR(aR0+CONV_INTEGER(IR(0)(2 downto 0)))<=RAMSFR(aR0+CONV_INTEGER(IR(0)(2 downto 0)))-1;
				rel:=CONV_INTEGER(IR(1));
--DJNZ (dir),rel
			when 16#D5# => next_state<=DJNZd; RAMSFR(dir)<=RAMSFR(dir)-1; rel:=CONV_INTEGER(IR(2));
-----------------------------------------------------------------------------------------------------
--					when 16#00# => next_state<=ENDI; 	--NOP
--					when 16#A5# => next_state<=ENDI;
-----------------------------------------------------------------------------------------------------
					when others => next_state<=ENDI;
				end case;
			when MOVC	=> next_state<=ENDI; RAMSFR(aA)<=ROM(tm1+tm2);

			when AJMP	=> next_state<=vP2PC; vPC(7 downto 0):=IR(1);vPC(10 downto 8):=IR(0)(7 downto 5);
			when LJMP	=> next_state<=vP2PC; vPC(7 downto 0):=IR(2);vPC(15 downto 8):=IR(1);
			when vP2PC	=> next_state<=ENDI;  PC<=CONV_INTEGER(vPC);

			when CJNE	=> 	if temp1/=temp2 then
								next_state<=PCrel;
								-- if temp1<temp2 then	CY:='1';
								-- else CY:='0';
								-- end if;
							else next_state<=ENDI;
							end if;
			when DJNZd => next_state<=DJNZ; temp1:=RAMSFR(dir);
			when DJNZ0 => next_state<=DJNZ; temp1:=RAMSFR(aR0+CONV_INTEGER(IR(0)(2 downto 0)));
			when DJNZ	=> 	if temp1/=X"00" then
								next_state<=PCrel;
							else
								next_state<=ENDI;
							end if;
			when PCrel	=> next_state<=ENDI;	if rel<128 then PC<=PC+rel;	--PC=PC+rel(补码)
													else PC<=PC+rel-256;
												end if;
	----P奇偶标志位
	--				RAMSFR(aPSW)(aP)<= RAMSFR(aA)(0) XOR RAMSFR(aA)(1) XOR RAMSFR(aA)(2) XOR RAMSFR(aA)(3) XOR RAMSFR(aA)(4) XOR RAMSFR(aA)(5) XOR RAMSFR(aA)(6) XOR RAMSFR(aA)(7);
			when ENDI	=> next_state<=GETI; 
							RAMSFR(aDPH)<=DPTR(15 downto 8); RAMSFR(aDPL)<=DPTR(7 downto 0);
			when others	=> next_state<=GETI;
		end case;
	end if;
	end process;
--------------------------------------------------------------------------------
----Real clock counting
	process(reset,ClkSec,second,minute,hour)
		variable m:integer:=0;
	begin
		if reset='1' then
			second	<= 00;		--second_i;
		    minute	<= 58;		--inute_i;
		    hour	<= 23;		--hour_i;
		elsif(rising_edge(ClkSec)) then
			second <= second + 1;
			if second >= 59 then
				second <= 0;
				minute <= minute + 1;
				if minute >= 59 then
					minute <= 0;
					hour <= hour + 1;
					if hour >= 23 then
						hour <= 0;
					end if;
				end if;
			end if;
		SS_L <= CONV_STD_LOGIC_VECTOR((second REM 10)+16#30#,8);
		SS_H <= CONV_STD_LOGIC_VECTOR((second  /  10)+16#30#,8);
		MM_L <= CONV_STD_LOGIC_VECTOR((minute REM 10)+16#30#,8);
		MM_H <= CONV_STD_LOGIC_VECTOR((minute  /  10)+16#30#,8);
		HH_L <= CONV_STD_LOGIC_VECTOR((hour REM 10)+16#30#,8);
		HH_H <= CONV_STD_LOGIC_VECTOR((hour  /  10)+16#30#,8);
		end if;
	end process;
--------------------------------------------------------------------------------
--	clock<=clk;
Uclksec:clkDiv generic map(n=>1)
	port map(clk=>clk,reset=>reset,clkOut=>ClkSec);
Uclk:clkDiv generic map(n=> clockHZ)
	port map(clk=>clk,reset=>reset,clkOut=>clock);
end Behavioral;
