library ieee;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity test is 
end entity ;

architecture testnbench of test is 
    component  PCM is 
        port 
        (
            BCLK : IN STD_LOGIC;
            RESET : IN STD_LOGIC;
            ENABLE : IN STD_LOGIC;
            FrameSync : IN STD_LOGIC;
            DR : IN STD_LOGIC;
            inST1 : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
            inST2 : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
            OutST2 : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
            DX : OUT STD_LOGIC
        );
    end component ;
   -- for all : PCM use entity work.voice_adder(structural);

    signal BCLK : std_logic := '0';  
    signal  DR  : std_logic := '0';  
    signal RESET , ENABLE , FrameSync , DX : std_logic;
    signal inST1 , inST2 , OutST2 :  STD_LOGIC_VECTOR(4 DOWNTO 0);

begin 

    uut : PCM port map 
    (
        BCLK    => BCLK ,
        RESET   => RESET ,
        Enable  => Enable ,
        FrameSync      => FrameSync ,
        DR      => DR ,
        inST1 => inST1 ,
        inST2 => inST2 ,
        OutST2 => OutST2 ,
        DX      => DX 
    );

    bclk <= not bclk after 5 ns ;

    Reset   <= '1' , '0' after 20 ns ;
    Enable  <= '0' , '0' after 30 ns , '1' after 60 ns ; 
    FrameSync      <= '0' , '1' after 80  ns , '0' after 100  ns ;-- '1' after 1355 ns , '0' after 1360 ns , '1' after 2640 ns, '0' after 2645 ns , '1' after 3925 ns , '0' after 3930 ns;
    DR      <= NOT DR AFTER 13 NS ; --'0' , '0' after 375 ns , '0' after 380 ns , '0' after 385 ns , '1' after 390 ns , '0' after 395 ns , '0' after 400 ns , '1' after 405 ns , '1' after 410 ns , '0' after 525 ns , '0' after 530 ns , '0' after 535 ns , '0' after 540 ns , '1' after 545 ns , '1' after 550 ns , '1' after 555 ns , '1' after 560 ns; 
    inST1 <= "00101";
    inST2 <= "00111";
    OutST2 <= "01001";

end testnbench; 