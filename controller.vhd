library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity CPU_controller is
    port (
        -------- INPUT SIGNAL--------
        --复位信号，低电平有效
        CLR_ : in STD_LOGIC;
        --运行模式:读写寄存器/RAM，执行程序
        SWA, SWB, SWC : in STD_LOGIC;
        --指令
        IR : in STD_LOGIC_VECTOR(3 downto 0);
        --机器周期:W1(始终有效)，W2(当SHORT=TRUE时被跳过)，W3(LONG=TURE时才进入)
        --T3：每个机器周期的最后一个时钟周期
        --QD：Wi的节拍电位产生器
        W1, W2, W3, T3，QD : in STD_LOGIC;
        --进位和零标识
        C, Z : in STD_LOGIC;

        -------- OUTPUT SIGNAL --------
        --ALU运算模式
        S : out STD_LOGIC_VECTOR(3 downto 0);
        --SEL3-0，(3,2)为ALU左端口MUX输入，也是 DBUS2REGISTER 的片选信号。(1,0)为ALU右端口MUX输入
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
        --运算模式:M=0 为算术运算；M=1 逻辑运算
        M : out STD_LOGIC;
        --总线使能
        ABUS, SBUS, MBUS : out STD_LOGIC;
        --控制指令周期中机器周期数量， SHORT=TRUE时W2被跳过，LONG=TURE时才会进入W3
        SHORT, LONG : out STD_LOGIC
    );
end CPU_controller;