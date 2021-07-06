library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
---------THIS FILE CODED IN GB 2312--------
entity CPU_INT is
    port (
        -------- INPUT SIGNAL--------
        --复位信号，低电平有效
        CLR : in STD_LOGIC;
        --运行模式:读写寄存器/RAM，执行程序
        SWA, SWB, SWC : in STD_LOGIC;
        --指令
        IR7, IR6, IR5, IR4 : in STD_LOGIC;
        --机器周期:W1(始终有效)，W2(当SHORT=TRUE时被跳过)，W3(LONG=TURE时才进入)
        --T3：每个机器周期的最后一个时钟周期
        W1, W2, W3, T3 : in STD_LOGIC;
        --进位和零标识
        C, Z : in STD_LOGIC;
        --中断标识
        PULSE : in STD_LOGIC;
        -------- OUTPUT SIGNAL --------
        --ALU运算模式
        S : out STD_LOGIC_VECTOR(3 downto 0);
        --SEL3-0，(3,2)为ALU左端口MUX输入，也是 DBUS2REGISTER 的片选信号.(1,0)为ALU右端口MUX输入
        SEL_L, SEL_R : out STD_LOGIC_VECTOR(1 downto 0);
        --写寄存器使能
        DRW : out STD_LOGIC;
        --读寄存器使能
        MEMW : out STD_LOGIC;
        --PCINC：PC自增，PCADD：+offset
        PCINC, PCADD : out STD_LOGIC;
        --写PC,AR,IR和标志寄存器使能
        LPC, LAR, LIR, LDZ, LDC : out STD_LOGIC;
        --AR自增
        ARINC : out STD_LOGIC;
        --停止产生时钟信号
        STP : out STD_LOGIC;
        --进入控制台模式
        SELCTL : out STD_LOGIC;
        --74181进位输入信号
        CIN : out STD_LOGIC;
        --运算模式:M=0为算术运算；M=1为逻辑运算
        M : out STD_LOGIC;
        --总线使能
        ABUS, SBUS, MBUS : out STD_LOGIC;
        --控制指令周期中机器周期数量，SHORT=TRUE时W2被跳过，LONG=TURE时才会进入W3
        SHORT, LONG : out STD_LOGIC
    );
end CPU_INT;

architecture struct of CPU_INT is
    signal SW : STD_LOGIC_VECTOR(2 downto 0);
    signal IR : STD_LOGIC_VECTOR(3 downto 0);
    signal ST0, SST0 : STD_LOGIC;
    signal EN_INT, IS_INT : STD_LOGIC;
    signal INT_FLAG, INT_FFLAG : INTEGER range 0 to 2;
begin
    SW <= SWC & SWB & SWA;
    IR <= IR7 & IR6 & IR5 & IR4;
    --main process
    process (W3, W2, W1, T3, SW, IR, CLR)
    begin
        --initialization
        S <= "0000";
        SEL_L <= "00";
        SEL_R <= "00";
        DRW <= '0';
        MEMW <= '0';
        PCINC <= '0';
        PCADD <= '0';
        LPC <= '0';
        LAR <= '0';
        LIR <= '0';
        LDZ <= '0';
        LDC <= '0';
        ARINC <= '0';
        STP <= '0';
        SELCTL <= '0';
        CIN <= '0';
        M <= '0';
        MEMW <= '0';
        ABUS <= '0';
        SBUS <= '0';
        MBUS <= '0';
        SHORT <= '0';
        LONG <= '0';

        --CLR=0 -> clear PC & IR & ST0 & EN_INT, INTFLAGS
        if CLR = '0' then
            ST0 <= '0';
            SST0 <= '0';
            EN_INT <= '0';
            IS_INT <= '0';
            INT_FLAG <= 0;
            INT_FFLAG <= 0;
            --assign SST0 2 ST0, INT_FFLAG 2 INT_FLAG
        elsif falling_edge(T3) then
            ST0 <= SST0;
            INT_FLAG <= INT_FFLAG;
        end if;
        if PULSE = '1' and EN_INT = '1' then
            IS_INT <= '1';
            EN_INT <= '0';
        end if;
        --SWCBA
        case SW is
            when "001" => --写存储器
                SBUS <= '1';
                STP <= '1';
                SHORT <= '1';
                SELCTL <= '1';
                LAR <= not ST0;
                MEMW <= ST0;
                ARINC <= ST0;
                if ST0 <= '0' then
                    SST0 <= '1';
                end if;
            when "010" => --读存储器   
                SHORT <= '1';
                STP <= '1';
                SELCTL <= '1';
                SBUS <= not ST0;
                LAR <= not ST0;
                MBUS <= ST0;
                ARINC <= ST0;
                if ST0 <= '0' then
                    SST0 <= '1';
                end if;
            when "100" => --写寄存器
                SBUS <= '1';
                SEL_L(1) <= ST0; --SEL3
                SEL_L(0) <= W2; --SEL2
                SEL_R(1) <= (not ST0 and W1) or (ST0 and W2); --SEL1
                SEL_R(0) <= W1; --SEL0
                if ST0 <= '0' and W2 = '1' then
                    SST0 <= '1';
                end if;
                SELCTL <= '1';
                DRW <= '1';
                STP <= '1';
            when "011" => --读寄存器
                SEL_L(1) <= W2;
                SEL_L(0) <= '0';
                SEL_R(1) <= W2;
                SEL_R(0) <= '1';
                SELCTL <= '1';
                STP <= '1';
            when "000" => --取指
                --is interrupt
                if IS_INT = '1' then
                    --save break point
                    case INT_FLAG is
                        when 0 =>
                            SBUS <= W1;
                            LAR <= W1;
                            M <= W2;
                            S <= W2 & W2 & W2 & W2;
                            ABUS <= W2;
                            MEMW <= W2;
                            SELCTL <= W2;
                            SEL_L <= W2 & W2;
                            ARINC <= W2;
                            if W2 = '1' then
                                INT_FFLAG <= 1;
                            end if;
                        when 1 =>
                            M <= '1';
                            S <= "1111";
                            ABUS <= '1';
                            MEMW <= '1';
                            SELCTL <= '1';
                            LONG <= '1';
                            SEL_L <= W3 & W2;
                            ARINC <= '1';
                            if W3 = '1' then
                                INT_FFLAG <= 2;
                            end if;
                        when 2 =>
                            MBUS <= '1';
                            DRW <= W1;
                            SEL_L <= W1 & W1;
                            LPC <= W2;
                            LIR <= W2;
                            PCINC <= W2;
                            if W2 = '1' then
                                INT_FFLAG <= 0;
                            end if;
                        when others =>
                            null;
                    end case;
                    --END CASE INT_FLAG
                else
                    if ST0 = '0' then
                        LPC <= W1;
                        SBUS <= W1 or W2;
                        STP <= W1 or W2;
                        DRW <= W2;
                        SELCTL <= W2;
                        SEL_L <= W2 & W2;
                        if ST0 <= '0' and W2 = '1'then
                            SST0 <= '1';
                        end if;
                    else
                        --Public Operation: LIR, PCINC & INC R3
                        S <= W1 & W1 & W1 & W1;
                        M <= not W1;
                        CIN <= not W1;
                        ABUS <= W1;
                        DRW <= W1;
                        SELCTL <= W1;
                        SEL_L <= W1 & W1;
                        LIR <= W1;
                        PCINC <= W1;
                        --IR Operation
                        case IR is
                            when "0000" => --NOP
                                null;
                            when "0001" => --ADD
                                S <= W2 & not W2 & not W2 & W2;
                                M <= not W2;
                                CIN <= W2;
                                ABUS <= W2;
                                DRW <= W2;
                                LDZ <= W2;
                                LDC <= W2;
                                --SHORT <= W1;
                            when "0010" => --SUB
                                S <= not W2 & W2 & W2 & not W2;
                                M <= W2;
                                CIN <= W2;
                                ABUS <= W2;
                                DRW <= W2;
                                LDZ <= W2;
                                LDC <= W2;
                                --SHORT <= W1;
                            when "0011" => --AND
                                M <= W2;
                                S <= W2 & not W2 & W2 & W2;
                                ABUS <= W2;
                                DRW <= W2;
                                LDZ <= W2;
                                --SHORT <= W1;
                            when "0100" => --INC
                                S <= not W2 & not W2 & not W2 & not W2;
                                M <= not W2;
                                ABUS <= W2;
                                CIN <= not W2;
                                DRW <= W2;
                                LDZ <= W2;
                                LDC <= W2;
                                --SHORT <= W1;
                            when "0101" => --LD
                                LONG <= W2;
                                S <= W2 & not W2 & W2 & not W2;
                                M <= W2;
                                ABUS <= W2;
                                LAR <= W2;
                                MBUS <= W3;
                                DRW <= W3;
                            when "0110" => --ST
                                LONG <= W2;
                                M <= W2 or W3;
                                if W2 = '1' then
                                    S <= "1111";
                                elsif W3 = '1' then
                                    S <= "1010";
                                end if;
                                ABUS <= W2 or W3;
                                LAR <= W2;
                                MEMW <= W3;
                            when "0111" => --JC
                                if C = '0' then
                                    null;
                                else
                                    LONG <= W2;
                                    M <= W2 or W3;
                                    if W2 = '1' or W3 = '1' then
                                        S <= "1111";
                                    end if;
                                    ABUS <= W2;
                                    LPC <= W2;
                                    SELCTL <= W3;
                                    SEL_L <= W3 & W3;
                                    DRW <= W3;
                                end if;
                            when "1000" => --JZ
                                if Z = '0' then
                                    null;
                                else
                                    LONG <= W2;
                                    M <= W2 or W3;
                                    if W2 = '1' or W3 = '1' then
                                        S <= "1111";
                                    end if;
                                    ABUS <= W2;
                                    LPC <= W2;
                                    SELCTL <= W3;
                                    SEL_L <= W3 & W3;
                                    DRW <= W3;
                                end if;
                            when "1001" => --JMP
                                LONG <= W2;
                                M <= W2 or W3;
                                if W2 = '1' or W3 = '1' then
                                    S <= "1111";
                                end if;
                                ABUS <= W2;
                                LPC <= W2;
                                SELCTL <= W3;
                                SEL_L <= W3 & W3;
                                DRW <= W3;
                            when "1010" => --EI
                                EN_INT <= '1';
                                LONG <= EN_INT;
                            when "1011" => --DI
                                EN_INT <= '0';
                            when "1100" => --OR
                                M <= W2;
                                S <= W2 & W2 & W2 & not W2;
                                ABUS <= W2;
                                DRW <= W2;
                                LDC <= W2;
                                --SHORT <= W1;
                            when "1101" => --*****OUT******
                                M <= W2;
                                S <= W2 & not W2 & W2 & not W2;
                                ABUS <= W2;
                                SHORT <= W2;
                            when "1110" => --STP
                                STP <= W2;
                            when "1111" => --IRET
                                --return to break point
                                case INT_FLAG is
                                    when 0 =>
                                        LONG <= W2;
                                        M <= W2;
                                        S <= W2 & W2 & W2 & W2;
                                        ABUS <= W2;
                                        LAR <= W2 or W3;
                                        SELCTL <= W2;
                                        SEL_L <= W2 & W2;
                                        MBUS <= W3;
                                        if W3 = '1' then
                                            INT_FFLAG <= 1;
                                        end if;
                                    when 1 =>
                                        MBUS <= '1';
                                        DRW <= W1;
                                        SELCTL <= W1;
                                        SEL_L <= W1 & W1;
                                        LPC <= W2;
                                        ARINC <= W2;
                                        if W2 = '1' then
                                            INT_FFLAG <= 2;
                                        end if;
                                    when 2 =>
                                        MBUS <= '1';
                                        LONG <= '1';
                                        DRW <= '1';
                                        SELCTL <= '1';
                                        SEL_L <= W3 & W2;
                                        ARINC <= W1 or W2;
                                        LIR <= W3;
                                        PCINC <= W3;
                                        if W3 = '1' then
                                            IS_INT <= '0';
                                            EN_INT <= '1';
                                            INT_FFLAG <= 0;
                                        end if;
                                    when others =>
                                        null;
                                end case;
                                --     --END CASE INT_FLAG
                                -- end if;
                            when others => null;
                        end case;
                        --END CASE IR
                    end if;
                    --END IF ST0
                end if;
                --END IF IS_INT
            when others => null;
        end case;
        --END CASE SW
    end process;
end struct;