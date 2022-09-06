LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY PCM IS
    PORT (
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
END ENTITY PCM;

ARCHITECTURE BEHAVORIAL OF PCM IS

    COMPONENT prom_a2l IS

        GENERIC (
            data_size : INTEGER := 16;
            prom_size : INTEGER := 256;
            addr_size : INTEGER := 8
        );

        PORT (
            address : IN STD_LOGIC_VECTOR(addr_size - 1 DOWNTO 0);

            data_out : OUT STD_LOGIC_VECTOR(data_size - 1 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT prom_l2u IS

        GENERIC (
            data_size : INTEGER := 8;
            prom_size : INTEGER := 8192;
            addr_size : INTEGER := 13
        );

        PORT (
            address : IN STD_LOGIC_VECTOR(addr_size - 1 DOWNTO 0);

            data_out : OUT STD_LOGIC_VECTOR(data_size - 1 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL DR_INPUT1 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL DR_INPUT2 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL DR_INPUT3 : STD_LOGIC_VECTOR(12 DOWNTO 0);
    SIGNAL TIMESLOT_NUMBER : STD_LOGIC_VECTOR (4 DOWNTO 0);--For DEBUG 
    SIGNAL DATAOUT1 : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL DATAOUT2 : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL TSBCONTER : STD_LOGIC_VECTOR (2 DOWNTO 0); --FOR DEBUG

    SIGNAL DATAOUT3 : STD_LOGIC_VECTOR (7 DOWNTO 0);

    SIGNAL D1, D2 : STD_LOGIC_VECTOR(12 DOWNTO 0);
BEGIN

    D1 <= DATAOUT1(15 DOWNTO 3);
    D2 <= DATAOUT2(15 DOWNTO 3);
    A2L_Dev0 : prom_a2l PORT MAP(DR_INPUT1, DATAOUT1);
    A2L_Dev1 : prom_a2l PORT MAP(DR_INPUT2, DATAOUT2);

    A2U_Dev0 : prom_l2u PORT MAP(DR_INPUT3, DATAOUT3);
    DR_INPUT3 <= D1 + D2;
    PROCESS (BCLK)

        VARIABLE timeSlot_Counter : STD_LOGIC_VECTOR (4 DOWNTO 0) := "00000";
        VARIABLE timeSlot_Bit_Counter, timeSlot_Bit_Counter2 : STD_LOGIC_VECTOR (2 DOWNTO 0) := "000";

        VARIABLE batman_rise : STD_LOGIC := '0';
        VARIABLE DO_IN_THE_NEXT_CLOCK : STD_LOGIC := 'X';
        VARIABLE DR1_temp : STD_LOGIC_VECTOR (7 DOWNTO 0);
        VARIABLE FLAG_COUNTER : STD_LOGIC_VECTOR (8 DOWNTO 0) := "000000000";
        VARIABLE DR2_temp : STD_LOGIC_VECTOR (7 DOWNTO 0);
        VARIABLE FrameStarted_Flag : BIT := '0'; -- Flag Bit in order to Determine that FS has been started or not 
    BEGIN
        IF (BCLK'event) THEN

            IF (ENABLE = '1') THEN
                IF (RESET = '1') THEN
                    timeSlot_Bit_Counter := "000";
                    timeSlot_Counter := "00000";
                    FrameStarted_Flag := '0';
                    DO_IN_THE_NEXT_CLOCK := 'X';

                ELSIF (FrameSync = '1') THEN
                    FrameStarted_Flag := '1';
                    FLAG_COUNTER := "000000000";

                ELSIF (FLAG_COUNTER > "100000000") THEN
                    FrameStarted_Flag := '0';
                ELSIF (FrameStarted_Flag = '1') THEN

                    IF (DO_IN_THE_NEXT_CLOCK = '0') THEN
                        DR_INPUT1 <= DR1_temp;
                        DO_IN_THE_NEXT_CLOCK := 'X';
                    ELSIF (DO_IN_THE_NEXT_CLOCK = '1') THEN
                        DR_INPUT2 <= DR2_temp;
                        DO_IN_THE_NEXT_CLOCK := 'X';
                    END IF;

                    IF (RISING_EDGE(BCLK)) THEN

                        TIMESLOT_NUMBER <= timeSlot_Counter;
                        batman_rise := '1';
                        FLAG_COUNTER := FLAG_COUNTER + 1;
                        IF (timeSlot_Counter = OutST2) THEN
                            DX <= DATAOUT3(CONV_INTEGER(timeSlot_Bit_Counter));
                        ELSE
                            DX <= 'Z';
                        END IF;

                        IF (timeSlot_Counter = "11111" AND timeSlot_Bit_Counter = "111") THEN
                            IF (timeSlot_Counter = inST1) THEN
                                DO_IN_THE_NEXT_CLOCK := '0';

                            END IF;
                            IF (timeSlot_Counter = inST2) THEN
                                DO_IN_THE_NEXT_CLOCK := '1';

                            END IF;
                            timeSlot_Bit_Counter := "000";
                            timeSlot_Counter := "00000";
                        ELSIF (timeSlot_Bit_Counter = "111") THEN
                            IF (timeSlot_Counter = inST1) THEN
                                DO_IN_THE_NEXT_CLOCK := '0';

                            END IF;
                            IF (timeSlot_Counter = inST2) THEN
                                DO_IN_THE_NEXT_CLOCK := '1';

                            END IF;
                            timeSlot_Bit_Counter := "000";
                            timeSlot_Counter := timeSlot_Counter + 1;
                        ELSE

                            timeSlot_Bit_Counter := (timeSlot_Bit_Counter + 1);
                        END IF;
                    END IF;

                    IF (FALLING_EDGE (BCLK) AND batman_rise = '1') THEN
                        TSBCONTER <= timeSlot_Bit_Counter2;
                        IF (timeSlot_Counter = inST1) THEN
                            DR1_temp(CONV_INTEGER(timeSlot_Bit_Counter2)) := DR;

                        END IF;
                        IF (timeSlot_Counter = inST2) THEN
                            DR2_temp(CONV_INTEGER(timeSlot_Bit_Counter2)) := DR;
                        END IF;
                        timeSlot_Bit_Counter2 := timeSlot_Bit_Counter2 + 1;
                    END IF;

                END IF;
            END IF;
        END IF;
    END PROCESS;

END BEHAVORIAL;