-------------------------------------------------------------------------------
--
-- Title       : openMAC_DMAmaster
-- Design      : POWERLINK
--
-------------------------------------------------------------------------------
--
-- File        : c:\my_designs\POWERLINK\compile\openMAC_DMAmaster.vhd
-- Generated   : Tue Sep  6 16:39:07 2011
-- From        : c:\my_designs\POWERLINK\src\openMAC_DMAmaster.bde
-- By          : Bde2Vhdl ver. 2.6
--
-------------------------------------------------------------------------------
--
--    (c) B&R, 2011
--
--    Redistribution and use in source and binary forms, with or without
--    modification, are permitted provided that the following conditions
--    are met:
--
--    1. Redistributions of source code must retain the above copyright
--       notice, this list of conditions and the following disclaimer.
--
--    2. Redistributions in binary form must reproduce the above copyright
--       notice, this list of conditions and the following disclaimer in the
--       documentation and/or other materials provided with the distribution.
--
--    3. Neither the name of B&R nor the names of its
--       contributors may be used to endorse or promote products derived
--       from this software without prior written permission. For written
--       permission, please contact office@br-automation.com
--
--    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
--    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
--    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
--    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
--    COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
--    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
--    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
--    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
--    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
--    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
--    POSSIBILITY OF SUCH DAMAGE.
--
-------------------------------------------------------------------------------
-- Design unit header --
--
-- This is the toplevel of the openMAC DMA master component.
-- It introduces a generic master device applying burst transfers for
-- RX and TX packet data transfers via a common bus.
--
-------------------------------------------------------------------------------
--
-- 2011-08-03  	V0.01	zelenkaj    First version
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

entity openMAC_DMAmaster is
  generic(
       simulate : boolean := false;
       dma_highadr_g : integer := 31;
       gen_tx_fifo_g : boolean := true;
       gen_rx_fifo_g : boolean := true;
       tx_fifo_word_size_g : integer := 32;
       rx_fifo_word_size_g : integer := 32;
       fifo_data_width_g : integer := 16;
       m_burstcount_width_g : integer := 4;
       m_tx_burst_size_g : integer := 16;
       m_rx_burst_size_g : integer := 16
  );
  port(
       dma_clk : in std_logic;
       dma_req_rd : in std_logic;
       dma_req_wr : in std_logic;
       m_clk : in std_logic;
       m_readdatavalid : in std_logic;
       m_waitrequest : in std_logic;
       mac_rx_off : in std_logic;
       mac_rx_on : in std_logic;
       mac_tx_off : in std_logic;
       mac_tx_on : in std_logic;
       rst : in std_logic;
       dma_addr : in std_logic_vector(dma_highadr_g downto 1);
       dma_dout : in std_logic_vector(fifo_data_width_g-1 downto 0);
       m_readdata : in std_logic_vector(fifo_data_width_g-1 downto 0);
       dma_ack_rd : out std_logic;
       dma_ack_wr : out std_logic;
       m_read : out std_logic;
       m_write : out std_logic;
       dma_din : out std_logic_vector(fifo_data_width_g-1 downto 0);
       m_address : out std_logic_vector(29 downto 0);
       m_burstcount : out std_logic_vector(m_burstcount_width_g-1 downto 0);
       m_byteenable : out std_logic_vector(1 downto 0);
       m_writedata : out std_logic_vector(fifo_data_width_g-1 downto 0)
  );
end openMAC_DMAmaster;

architecture strct of openMAC_DMAmaster is

---- Component declarations -----

component dma_handler
  generic(
       dma_highadr_g : integer := 31;
       gen_rx_fifo_g : boolean := true;
       gen_tx_fifo_g : boolean := true;
       rx_fifo_word_size_log2_g : natural := 5;
       tx_fifo_word_size_log2_g : natural := 5
  );
  port (
       dma_addr : in std_logic_vector(dma_highadr_g downto 1);
       dma_clk : in std_logic;
       dma_req_rd : in std_logic;
       dma_req_wr : in std_logic;
       mac_rx_off : in std_logic;
       mac_rx_on : in std_logic;
       mac_tx_off : in std_logic;
       mac_tx_on : in std_logic;
       rst : in std_logic;
       rx_wr_clk : in std_logic;
       rx_wr_empty : in std_logic;
       rx_wr_full : in std_logic;
       rx_wr_usedw : in std_logic_vector(rx_fifo_word_size_log2_g-1 downto 0);
       tx_rd_clk : in std_logic;
       tx_rd_empty : in std_logic;
       tx_rd_full : in std_logic;
       tx_rd_usedw : in std_logic_vector(tx_fifo_word_size_log2_g-1 downto 0);
       dma_ack_rd : out std_logic;
       dma_ack_wr : out std_logic;
       dma_addr_out : out std_logic_vector(dma_highadr_g downto 1);
       dma_new_addr_rd : out std_logic;
       dma_new_addr_wr : out std_logic;
       rx_aclr : out std_logic;
       rx_wr_req : out std_logic;
       tx_rd_req : out std_logic
  );
end component;
component master_handler
  generic(
       dma_highadr_g : integer := 31;
       gen_rx_fifo_g : boolean := true;
       gen_tx_fifo_g : boolean := true;
       m_burst_wr_const_g : boolean := true;
       m_burstcount_width_g : integer := 4;
       m_rx_burst_size_g : integer := 16;
       m_tx_burst_size_g : integer := 16;
       rx_fifo_word_size_log2_g : natural := 5;
       tx_fifo_word_size_log2_g : natural := 5
  );
  port (
       dma_addr_in : in std_logic_vector(dma_highadr_g downto 1);
       dma_new_addr_rd : in std_logic;
       dma_new_addr_wr : in std_logic;
       m_clk : in std_logic;
       m_readdatavalid : in std_logic;
       m_waitrequest : in std_logic;
       mac_rx_off : in std_logic;
       mac_rx_on : in std_logic;
       mac_tx_off : in std_logic;
       mac_tx_on : in std_logic;
       rst : in std_logic;
       rx_rd_clk : in std_logic;
       rx_rd_empty : in std_logic;
       rx_rd_full : in std_logic;
       rx_rd_usedw : in std_logic_vector(rx_fifo_word_size_log2_g-1 downto 0);
       tx_wr_clk : in std_logic;
       tx_wr_empty : in std_logic;
       tx_wr_full : in std_logic;
       tx_wr_usedw : in std_logic_vector(tx_fifo_word_size_log2_g-1 downto 0);
       m_address : out std_logic_vector(29 downto 0);
       m_burstcount : out std_logic_vector(m_burstcount_width_g-1 downto 0);
       m_byteenable : out std_logic_vector(1 downto 0);
       m_read : out std_logic;
       m_write : out std_logic;
       rx_rd_req : out std_logic;
       tx_aclr : out std_logic;
       tx_wr_req : out std_logic
  );
end component;
component OpenMAC_DMAFifo
  generic(
       fifo_data_width_g : natural := 16;
       fifo_word_size_g : natural := 32;
       fifo_word_size_log2_g : natural := 5
  );
  port (
       aclr : in std_logic;
       rd_clk : in std_logic;
       rd_req : in std_logic;
       wr_clk : in std_logic;
       wr_data : in std_logic_vector(fifo_data_width_g-1 downto 0);
       wr_req : in std_logic;
       rd_data : out std_logic_vector(fifo_data_width_g-1 downto 0);
       rd_empty : out std_logic;
       rd_full : out std_logic;
       rd_usedw : out std_logic_vector(fifo_word_size_log2_g-1 downto 0);
       wr_empty : out std_logic;
       wr_full : out std_logic;
       wr_usedw : out std_logic_vector(fifo_word_size_log2_g-1 downto 0)
  );
end component;
component slow2fastSync
  generic(
       doSync_g : boolean := TRUE
  );
  port (
       clkDst : in std_logic;
       clkSrc : in std_logic;
       dataSrc : in std_logic;
       rstDst : in std_logic;
       rstSrc : in std_logic;
       dataDst : out std_logic
  );
end component;
component sync
  generic(
       doSync_g : boolean := true
  );
  port (
       clk : in std_logic;
       din : in std_logic;
       rst : in std_logic;
       dout : out std_logic
  );
end component;

---- Architecture declarations -----
--constants
constant tx_fifo_word_size_c : natural := natural(tx_fifo_word_size_g);
constant tx_fifo_word_size_log2_c : natural := natural(ceil(log2(real(tx_fifo_word_size_c))));
constant rx_fifo_word_size_c : natural := natural(rx_fifo_word_size_g);
constant rx_fifo_word_size_log2_c : natural := natural(ceil(log2(real(rx_fifo_word_size_c))));


---- Signal declarations used on the diagram ----

signal dma_new_addr_rd : std_logic;
signal dma_new_addr_wr : std_logic;
signal m_mac_rx_off : std_logic;
signal m_mac_rx_on : std_logic;
signal m_mac_tx_off : std_logic;
signal m_mac_tx_on : std_logic;
signal m_new_dma_addr_rd : std_logic;
signal m_new_dma_addr_wr : std_logic;
signal rx_aclr : std_logic;
signal rx_rd_clk : std_logic;
signal rx_rd_empty : std_logic;
signal rx_rd_full : std_logic;
signal rx_rd_req : std_logic;
signal rx_wr_clk : std_logic;
signal rx_wr_empty : std_logic;
signal rx_wr_full : std_logic;
signal rx_wr_req : std_logic;
signal tx_aclr : std_logic;
signal tx_rd_clk : std_logic;
signal tx_rd_empty : std_logic;
signal tx_rd_full : std_logic;
signal tx_rd_req : std_logic;
signal tx_wr_clk : std_logic;
signal tx_wr_empty : std_logic;
signal tx_wr_full : std_logic;
signal tx_wr_req : std_logic;
signal dma_addr_trans : std_logic_vector (dma_highadr_g downto 1);
signal m_addr_trans : std_logic_vector (dma_highadr_g downto 1);
signal rd_data : std_logic_vector (fifo_data_width_g-1 downto 0);
signal rx_rd_usedw : std_logic_vector (rx_fifo_word_size_log2_c-1 downto 0);
signal rx_wr_usedw : std_logic_vector (rx_fifo_word_size_log2_c-1 downto 0);
signal tx_rd_usedw : std_logic_vector (tx_fifo_word_size_log2_c-1 downto 0);
signal tx_wr_usedw : std_logic_vector (tx_fifo_word_size_log2_c-1 downto 0);
signal wr_data : std_logic_vector (fifo_data_width_g-1 downto 0);

begin

---- User Signal Assignments ----
--endian conversion
wr_data <= dma_dout(7 downto 0) & dma_dout(15 downto 8);
dma_din <= rd_data(7 downto 0) & rd_data(15 downto 8);

----  Component instantiations  ----

rx_rd_clk <= m_clk;

U15 : slow2fastSync
  port map(
       clkDst => m_clk,
       clkSrc => dma_clk,
       dataDst => m_mac_tx_on,
       dataSrc => mac_tx_on,
       rstDst => rst,
       rstSrc => rst
  );

U16 : slow2fastSync
  port map(
       clkDst => m_clk,
       clkSrc => dma_clk,
       dataDst => m_mac_tx_off,
       dataSrc => mac_tx_off,
       rstDst => rst,
       rstSrc => rst
  );

U17 : slow2fastSync
  port map(
       clkDst => m_clk,
       clkSrc => dma_clk,
       dataDst => m_mac_rx_on,
       dataSrc => mac_rx_on,
       rstDst => rst,
       rstSrc => rst
  );

U18 : slow2fastSync
  port map(
       clkDst => m_clk,
       clkSrc => dma_clk,
       dataDst => m_mac_rx_off,
       dataSrc => mac_rx_off,
       rstDst => rst,
       rstSrc => rst
  );

U3 : dma_handler
  generic map (
       dma_highadr_g => dma_highadr_g,
       gen_rx_fifo_g => gen_rx_fifo_g,
       gen_tx_fifo_g => gen_tx_fifo_g,
       rx_fifo_word_size_log2_g => rx_fifo_word_size_log2_c,
       tx_fifo_word_size_log2_g => tx_fifo_word_size_log2_c
  )
  port map(
       dma_ack_rd => dma_ack_rd,
       dma_ack_wr => dma_ack_wr,
       dma_addr => dma_addr( dma_highadr_g downto 1 ),
       dma_addr_out => dma_addr_trans( dma_highadr_g downto 1 ),
       dma_clk => dma_clk,
       dma_new_addr_rd => dma_new_addr_rd,
       dma_new_addr_wr => dma_new_addr_wr,
       dma_req_rd => dma_req_rd,
       dma_req_wr => dma_req_wr,
       mac_rx_off => mac_rx_off,
       mac_rx_on => mac_rx_on,
       mac_tx_off => mac_tx_off,
       mac_tx_on => mac_tx_on,
       rst => rst,
       rx_aclr => rx_aclr,
       rx_wr_clk => rx_wr_clk,
       rx_wr_empty => rx_wr_empty,
       rx_wr_full => rx_wr_full,
       rx_wr_req => rx_wr_req,
       rx_wr_usedw => rx_wr_usedw( rx_fifo_word_size_log2_c-1 downto 0 ),
       tx_rd_clk => tx_rd_clk,
       tx_rd_empty => tx_rd_empty,
       tx_rd_full => tx_rd_full,
       tx_rd_req => tx_rd_req,
       tx_rd_usedw => tx_rd_usedw( tx_fifo_word_size_log2_c-1 downto 0 )
  );

U4 : master_handler
  generic map (
       dma_highadr_g => dma_highadr_g,
       gen_rx_fifo_g => gen_rx_fifo_g,
       gen_tx_fifo_g => gen_tx_fifo_g,
       m_burst_wr_const_g => true,
       m_burstcount_width_g => m_burstcount_width_g,
       m_rx_burst_size_g => m_rx_burst_size_g,
       m_tx_burst_size_g => m_tx_burst_size_g,
       rx_fifo_word_size_log2_g => rx_fifo_word_size_log2_c,
       tx_fifo_word_size_log2_g => tx_fifo_word_size_log2_c
  )
  port map(
       dma_addr_in => m_addr_trans( dma_highadr_g downto 1 ),
       dma_new_addr_rd => m_new_dma_addr_rd,
       dma_new_addr_wr => m_new_dma_addr_wr,
       m_address => m_address,
       m_burstcount => m_burstcount( m_burstcount_width_g-1 downto 0 ),
       m_byteenable => m_byteenable,
       m_clk => m_clk,
       m_read => m_read,
       m_readdatavalid => m_readdatavalid,
       m_waitrequest => m_waitrequest,
       m_write => m_write,
       mac_rx_off => m_mac_rx_off,
       mac_rx_on => m_mac_rx_on,
       mac_tx_off => m_mac_tx_off,
       mac_tx_on => m_mac_tx_on,
       rst => rst,
       rx_rd_clk => rx_rd_clk,
       rx_rd_empty => rx_rd_empty,
       rx_rd_full => rx_rd_full,
       rx_rd_req => rx_rd_req,
       rx_rd_usedw => rx_rd_usedw( rx_fifo_word_size_log2_c-1 downto 0 ),
       tx_aclr => tx_aclr,
       tx_wr_clk => tx_wr_clk,
       tx_wr_empty => tx_wr_empty,
       tx_wr_full => tx_wr_full,
       tx_wr_req => tx_wr_req,
       tx_wr_usedw => tx_wr_usedw( tx_fifo_word_size_log2_c-1 downto 0 )
  );

tx_rd_clk <= dma_clk;

rx_wr_clk <= dma_clk;

tx_wr_clk <= m_clk;


----  Generate statements  ----

txFifoGen : if gen_tx_fifo_g generate
begin
  U1 : OpenMAC_DMAFifo
    generic map (
         fifo_data_width_g => fifo_data_width_g,
         fifo_word_size_g => tx_fifo_word_size_c,
         fifo_word_size_log2_g => tx_fifo_word_size_log2_c
    )  
    port map(
         aclr => tx_aclr,
         rd_clk => tx_rd_clk,
         rd_data => rd_data( fifo_data_width_g-1 downto 0 ),
         rd_empty => tx_rd_empty,
         rd_full => tx_rd_full,
         rd_req => tx_rd_req,
         rd_usedw => tx_rd_usedw( tx_fifo_word_size_log2_c-1 downto 0 ),
         wr_clk => tx_wr_clk,
         wr_data => m_readdata( fifo_data_width_g-1 downto 0 ),
         wr_empty => tx_wr_empty,
         wr_full => tx_wr_full,
         wr_req => tx_wr_req,
         wr_usedw => tx_wr_usedw( tx_fifo_word_size_log2_c-1 downto 0 )
    );
end generate txFifoGen;

rxFifoGen : if gen_rx_fifo_g generate
begin
  U2 : OpenMAC_DMAFifo
    generic map (
         fifo_data_width_g => fifo_data_width_g,
         fifo_word_size_g => rx_fifo_word_size_c,
         fifo_word_size_log2_g => rx_fifo_word_size_log2_c
    )  
    port map(
         aclr => rx_aclr,
         rd_clk => rx_rd_clk,
         rd_data => m_writedata( fifo_data_width_g-1 downto 0 ),
         rd_empty => rx_rd_empty,
         rd_full => rx_rd_full,
         rd_req => rx_rd_req,
         rd_usedw => rx_rd_usedw( rx_fifo_word_size_log2_c-1 downto 0 ),
         wr_clk => rx_wr_clk,
         wr_data => wr_data( fifo_data_width_g-1 downto 0 ),
         wr_empty => rx_wr_empty,
         wr_full => rx_wr_full,
         wr_req => rx_wr_req,
         wr_usedw => rx_wr_usedw( rx_fifo_word_size_log2_c-1 downto 0 )
    );
end generate rxFifoGen;

syncDmaAddrGen : for i in dma_highadr_g downto 1 generate
begin
  g2 : if gen_rx_fifo_g or gen_tx_fifo_g generate
  begin
    U5 : sync
      port map(
           clk => m_clk,
           din => dma_addr_trans(i),
           dout => m_addr_trans(i),
           rst => rst
      );
  end generate g2;
end generate syncDmaAddrGen;

newWrAddrSync : if gen_rx_fifo_g generate
begin
  U6 : slow2fastSync
    port map(
         clkDst => m_clk,
         clkSrc => dma_clk,
         dataDst => m_new_dma_addr_wr,
         dataSrc => dma_new_addr_wr,
         rstDst => rst,
         rstSrc => rst
    );
end generate newWrAddrSync;

newRdAddrSync : if gen_tx_fifo_g generate
begin
  U11 : slow2fastSync
    port map(
         clkDst => m_clk,
         clkSrc => dma_clk,
         dataDst => m_new_dma_addr_rd,
         dataSrc => dma_new_addr_rd,
         rstDst => rst,
         rstSrc => rst
    );
end generate newRdAddrSync;

end strct;
