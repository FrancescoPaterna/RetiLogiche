----------------------------------------------------------------------------------
-- Politecnico Di Milano
-- Francesco Paterna
-- Matricola 843367
-- Prova Finale Di Reti Logiche 2019
----------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------
-- Entity Progetto Reti Logiche
--------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;



entity project_reti_logiche is
    Port ( i_clk : in STD_LOGIC;
           i_start : in STD_LOGIC;
           i_rst : in STD_LOGIC;
           i_data : in STD_LOGIC_VECTOR(7 downto 0);
           o_address : out STD_LOGIC_VECTOR(15 downto 0);
           o_done : out STD_LOGIC;
           o_en : out STD_LOGIC;
           o_we : out STD_LOGIC;
           o_data : out STD_LOGIC_VECTOR(7 downto 0)
     );
          
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

--------------------------------------------------------------------------------------------
-- Definizione Type -- Rappresentano gli stati della mia macchina a stati finiti
--------------------------------------------------------------------------------------------

type state_type is(
    START,  -- Stato Iniziale Della Macchina
    MASK_LOADER, -- Carica Maschera D'ingresso
    X_POINT_LOADER,  -- Carca Coordinata X del punto da valutare
    Y_POINT_LOADER,  -- Carica Coordinata Y del punto da valutare
    WAIT_MEM,  -- Aspetta che la memoria carichi i dati
    SCALX, -- Seleziona un centroide valido e carica la variabile X (Select Centroid And Load X)
    LOAD_Y, -- Carica la variabile Y del centroide valido
    CALC_XI, -- Calcola la distanza orizzontale tra punto da valutare e centroide
    CALC_YI, -- Calcola la distanza verticale tra punto da valutare e centroide
    CALC_MAN, -- Calcola la distanza Manhattan
    MASK_WRITER, -- Scrivi la maschera d'uscita
    DONE, -- Porta il segnale o_done a 1
    DONE_WAIT -- Attende un segnale di start a 0, dopodichè porta Done a 0 e riporta la fsm allo stato iniziale
    );
    
signal STATE, P_STATE : state_type; --Variabil che tengono traccia dei cambiamenti di stato

begin
    process(i_clk, i_rst)
 
 
 
 --------------------------------------------------------------------------------------------
-- Variabili Utilizzate
--------------------------------------------------------------------------------------------
   
    variable MI: std_logic_vector(7 downto 0); -- vettore per contenere le maschere di ingresso e uscita
    variable MO: std_logic_vector(7 downto 0); -- vettore per contenere la maschera d'uscita
    variable address : std_logic_vector(15 downto 0); --indirizzo generico per contenere un indirizzo 
    variable Dmin : integer range 0 to 510;  --distanza manhattan del centroide più vicino
    variable yi : integer range 0 to 510; --distanza manhattan centroide analizzato
    variable xi : integer range 0 to 255; -- distanze orizzontali e verticali centroide analizzato
    variable yo , xo : std_logic_vector(7 downto 0); -- coordinate x,y del centroide analizzato
    variable xp , yp : std_logic_vector(7 downto 0); -- coordinate x,y del punto preso in considerazione
    variable k: std_logic_vector(7 downto 0); -- vettpre utilizzato per selezionare il centroide dalla maschera d'ingresso
     
begin 


--------------------------------------------------------------------------------------------
-- Architecture Progetto Reti Logiche
--------------------------------------------------------------------------------------------


    if(i_rst = '1') then -- Nel caso arrivi un segnale di reset, RESETTA LE VARIABILI
        --report "--------RESET--------"; 
        o_en <= '0';    --riporta a 0 il segnale di lettura a memoria
        o_we <= '0';    --riporta a 0 il segnale di scrittura a memoria
        o_done <= '0';  --riporta a 0 il segnale di fine elaborazione
        MO := "00000000"; --Valore Maschera d'Uscita
        Dmin := 510; --Distanza Manhattan minima
        k := "00000001"; --Selezionatore di Centroidi
        address := x"0001"; -- Puntatore sulla coordinata X del primo centroide da valutare
        P_STATE <= START; -- Riporta la macchina allo stato iniziale
        STATE <= START;  -- Riporta la macchina allo stato inizile  
    
    
    elsif(rising_edge(i_clk)) then -- Se è passato un ciclo di clock e sono sul fronte di salita
        case state is           -- Definiamo gli stati
                 
            when START =>
                if (i_start = '1' AND i_rst = '0') then                                                      
                    o_address <= x"0000";  -- inidirizzo maschera 
                    o_en <= '1';
                    o_we <= '0';
                    STATE <= WAIT_MEM;     -- stato dove voglio andare
                    P_STATE <= START;      -- stato dove mi trovo adesso "Present State";
                end if; 
                
                
               
            when WAIT_MEM =>       
                if(P_STATE = START) then
                    STATE <= MASK_LOADER;
                elsif(P_STATE = MASK_LOADER) then 
                    STATE <= X_POINT_LOADER;
                elsif(P_STATE = X_POINT_LOADER) then
                    STATE <= Y_POINT_LOADER;
                elsif(P_STATE = Y_POINT_LOADER) then
                    STATE <= SCALX;
                elsif(P_STATE = SCALX) then
                    STATE <= LOAD_Y;
                elsif(P_STATE = LOAD_Y) then
                   STATE <= CALC_XI;
                elsif(P_STATE = MASK_WRITER) then
                    STATE <= DONE;
                else
                    STATE <= DONE_WAIT;
                end if;
                    

            
             when MASK_LOADER =>
                MI := i_data;  -- Salvo la Maschera d'Ingresso
                --report "MASCHERA INPUT : "& integer'image(to_integer(unsigned(MI)));
                o_address <= x"0011"; -- Chiedo alla memoria la coordinata X del punto da valutare
                P_STATE <= MASK_LOADER;
                STATE <= WAIT_MEM;
             
            
            
             when X_POINT_LOADER =>
                xp := i_data; -- Salvo la coordinata X del punto da valutare
                --report "COORDINATA XP : "& integer'image(to_integer(unsigned(xp)));
                o_address <= x"0012"; -- Chiedo alla memoria la coordinata Y del punto da valutare
                P_STATE <= X_POINT_LOADER;
                STATE <= WAIT_MEM;
                
           
           
             when Y_POINT_LOADER =>
                yp := i_data; -- Salvo la coordinata X del punto da valutare
                --report "COORDINATA YP : "& integer'image(to_integer(unsigned(yp)));
                o_address <= address;
                P_STATE <= Y_POINT_LOADER;
                STATE <= WAIT_MEM; 
             
            
            
             when SCALX =>
                if(k = "00000000") then  -- Se ho verificato tutta la maschera d'ingresso
                    --report "MASCHERA OUTPUT : "& integer'image(to_integer(unsigned(MO)));
                    o_address <= x"0013"; -- Setto il puntatore all'indirizzo DEC(19), dove salvare la Maschera d'uscita
                    o_data <= MO; -- Setto il segnale o_data con la mascherà d'uscita
                    STATE <= MASK_WRITER;
                    
                elsif((MI and k) = k) then -- Se il centroide K considerato appartiene alla mia maschera d'ingresso
                    xo := i_data; -- Salva la coordinata x del centroide analizzato
                    report "COORDINATA XO : "& integer'image(to_integer(unsigned(xo)));
                    address := address + x"0001"; -- Chiedi alla memoria la coordinata y del centroide analizzato
                    o_address <= address; 
                    P_STATE <= SCALX;
                    STATE <= WAIT_MEM;
                    
                else -- Se il centroide K considerato NON appartiene alla maschera d'ingresso
                  -- report "SCARTATO K : "& integer'image(to_integer(unsigned(k)));
                  k := (k(6 downto 0) & '0'); -- shifta k a sinistra di una posizione     ES  K= 00000001  =>  K = 00000010
                  address := address + x"0002"; --Salta Direttamente all'inidizzo contente la coordinata X del prossimo centroide
                  o_address <= address;
                  P_STATE <= Y_POINT_LOADER;
                   STATE <= WAIT_MEM;
                end if;  
           
           
            
             when LOAD_Y => 
                yo := i_data; -- Salva la coordinata Y del centroide analizzato
                --report "COORDINATA YO : "& integer'image(to_integer(unsigned(yo)));
                address := address + x"0001"; -- Chiedi alla memoria la coordinata X del prossimo centroide
                o_address <= address;
                P_STATE <= LOAD_Y;
                STATE <= WAIT_MEM;
                
            
            
            when CALC_XI =>
                if (to_integer(unsigned(xp))> to_integer(unsigned(xo))) then      --Effettua una banale sottrazione delle coordinate
                    xi := to_integer(unsigned(xp)) - to_integer(unsigned(xo));    -- X del punto da valutare e del centroide,
                    STATE <= CALC_YI;                                             -- ponendo il numero maggiore come Minuendo
                else
                    xi := to_integer(unsigned(xo)) - to_integer(unsigned(xp));
                    STATE <= CALC_YI;
                end if;


            
            when CALC_YI =>                                                       --Identica a CALC_XI ma per le coordinate Y
                if (to_integer(unsigned(yp))> to_integer(unsigned(yo))) then
                    yi := to_integer(unsigned(yp)) - to_integer(unsigned(yo));
                    STATE <= CALC_MAN;
                else
                    yi := to_integer(unsigned(yo)) - to_integer(unsigned(yp));
                    STATE <= CALC_MAN;
                end if;
            
            
            
            when CALC_MAN =>            
                --report "XI CALCOLATO: "& integer'image(xi);
                --report "YI CALCOLATO: "& integer'image(yi);                                
                yi := yi + xi;  -- Somma i termini trovati con CALC_XI e CALC_YI
                --report "DISTANZA MANHATTAN CALCOLATA: "& integer'image(yi); 

                if(yi > Dmin) then  -- Se il centroide non è il più vicino al punto da valutare
                 k := (k(6 downto 0) & '0'); -- Passiamo al nuovo centroide shiftando k a sinistra 
                    STATE <= SCALX;

                elsif(yi = Dmin) then -- Se il centroide è contende il posto con un altro centroide di pari distanza
                    MO := (MO xor k); -- Facciamo uno XOR tra K e maschera d'uscita, per considerarli entrambi
                    k := (k(6 downto 0) & '0'); -- Passiamo al nuovo centroide shiftando k a sinistra
                    STATE <= SCALX;
                elsif(yi < Dmin) then -- Se il centroide è il più vicino al punto da valutare
                    MO := k; -- La maschera d'uscità sarà il centroide stesso
                    Dmin := yi; -- Aggiorno la distanza più vicina al punto da valutare
                    k := (k(6 downto 0) & '0'); -- Passiamo al nuovo centroide shiftando k a sinistra
                    STATE <= SCALX;
                end if;
               
               
                
              when MASK_WRITER =>
                o_we <= '1'; -- Abilito la scrittura della memoria
                P_STATE <= MASK_WRITER;
                STATE <= WAIT_MEM;
                
                
                
              when DONE =>
                o_en <= '0'; -- Disabilito la lettura
                o_we <= '0'; -- Disabilito la scrittura
                o_done <= '1'; -- Alzo il segnale di DOne
                STATE <= DONE_WAIT; 
                
                
                
              when DONE_WAIT =>
                if(i_start = '0') then -- Attneod che start si abbassi per abbassare il done
                    o_done <= '0'; -- Abbasso il Done
                    P_STATE <= START; -- Torno allo stato iniziale
                    STATE <= START; -- Torno Allo stato iniziale
                end if;
                
              
                            
          end case;
      end if;                
  end process;
end Behavioral;
