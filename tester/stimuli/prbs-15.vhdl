/*
	This file is part of the Galois Linear Feedback Shift Register 
	(galois_lfsr) project:
		http://www.opencores.org/project,galois_lfsr
	
	Description
	Synthesisable use case for Galois LFSR.
	This example is a CRC generator that uses a Galois LFSR.
	
	ToDo: 
	
	Author(s): 
	- Daniel C.K. Kho, daniel.kho@opencores.org | daniel.kho@tauhop.com
	
	Copyright (C) 2012-2013 Authors and OPENCORES.ORG
	
	This source file may be used and distributed without 
	restriction provided that this copyright statement is not 
	removed from the file and that any derivative work contains 
	the original copyright notice and the associated disclaimer.
	
	This source file is free software; you can redistribute it 
	and/or modify it under the terms of the GNU Lesser General 
	Public License as published by the Free Software Foundation; 
	either version 2.1 of the License, or (at your option) any 
	later version.
	
	This source is distributed in the hope that it will be 
	useful, but WITHOUT ANY WARRANTY; without even the implied 
	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
	PURPOSE. See the GNU Lesser General Public License for more 
	details.
	
	You should have received a copy of the GNU Lesser General 
	Public License along with this source; if not, download it 
	from http://www.opencores.org/lgpl.shtml.
*/
library ieee; use ieee.std_logic_1164.all, ieee.numeric_std.all; use ieee.math_real.all;
/* Enable for synthesis; comment out for simulation.
        For this design, we just need boolean_vector. This is already included in Questa/ModelSim, 
        but Quartus doesn't yet support this.
*/
library tauhop; use tauhop.types.all;

entity prbs15 is
	generic(
		parallelLoad:boolean:=false;
		tapVector:boolean_vector:=(
			/* Example polynomial from Wikipedia:
				http://en.wikipedia.org/wiki/Computation_of_cyclic_redundancy_checks
			*/
			--0|1|2|8=>true, 7 downto 3=>false
			0|1|15=>true, 14 downto 2=>false
		)
	);
	port(
		/* Comment-out for simulation. */
		clk,reset:in std_ulogic;
		seed:in unsigned(tapVector'high downto 0):=16x"ace1";		--9x"57";
		prbs:out unsigned(15 downto 0):=(others=>'0')
	);
end entity prbs15;

architecture rtl of prbs15 is
	signal n,c:natural;
	
	/* Tester signals. */
	signal d:std_ulogic;
	/* synthesis translate_off */
--	signal clk,reset:std_ulogic:='0';
	/* synthesis translate_on */
	
	signal loadEn:std_ulogic;		-- clock gating.
--	signal loadEn,computeClk:std_ulogic;		-- clock gating.
	signal loaded:boolean;
--	signal computed,i_computed:boolean;
	
begin
--	loadEn<=clk when reset='0' and not i_computed else '0';
	loadEn<=clk when reset='0' else '0';
	
	/* Galois LFSR instance. */
	i_lfsr: entity work.lfsr(rtl)
		generic map(taps=>tapVector)
		/*generic map(taps => (
			0|1|2|8=>true,
			7 downto 3=>false
		))*/
		port map(nReset=>not reset, clk=>loadEn,
			load=>parallelLoad,
			seed=>seed,
			d=>d,
			q=>prbs(prbs'range)
	);
	
	/* Load message into LFSR. */
	process(reset,loadEn) is begin
		if reset then loaded<=false; n<=seed'length-1; d<='0';
--		if reset then loaded<=false; n<=seed'length-1;
		elsif rising_edge(loadEn) then
			d<='0';
			
			/* for parallel mode, LFSR automatically loads the seed in parallel. */
			if parallelLoad then d<='0'; loaded<=true;
--			if parallelLoad then loaded<=true;
			else
				if not loaded then d<=seed(n); end if;
				
				if n>0 then n<=n-1;
				else loaded<=true;
				end if;
			end if;
		end if;
	end process;
	
--	d<=seed(n) when rising_edge(loadEn);
end architecture rtl;
