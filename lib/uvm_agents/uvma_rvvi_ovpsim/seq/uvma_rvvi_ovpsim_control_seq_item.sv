// Copyright 2020 OpenHW Group
// Copyright 2020 Datum Technology Corporation
// 
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     https://solderpad.org/licenses/
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


`ifndef __UVMA_RVVI_OVPSIM_CONTROL_SEQ_ITEM_SV__
`define __UVMA_RVVI_OVPSIM_CONTROL_SEQ_ITEM_SV__


/**
 * Object created by Rvvi_control agent sequences extending uvma_rvvi_control_seq_base_c.
 */
class uvma_rvvi_ovpsim_control_seq_item_c#(int ILEN=uvma_rvvi_pkg::DEFAULT_ILEN,
                                           int XLEN=uvma_rvvi_pkg::DEFAULT_XLEN)  extends uvma_rvvi_control_seq_item_c#(ILEN,XLEN);


   // Set to signal this instructions is first instruction of interrupt handler
   rand bit intr;

   // Set to signa external debug request
   rand bit dbg_req;

   // Set to signal entry into NMI handler
   rand bit nmi;

   // For accuracy of mip model the irq_i inputs for each instrucion
   rand bit[ILEN-1:0] mip;

   // Hint to which instruction "won" the interrupt
   rand int unsigned intr_id;

   // Backdoor hint of register write for testing volatile CSR registers and ensuring RM tracks register value
   rand bit [GPR_ADDR_WL-1:0]    rd1_addr;
   rand bit [XLEN-1:0]           rd1_wdata;

   // Backdoor hint of memory read for ensuring memory model is updated with volatile read data
   rand bit [XLEN-1:0]           mem_addr;
   rand bit [XLEN-1:0]           mem_rdata;
   rand bit [XLEN/8-1:0]         mem_rmask;

   static protected string _log_format_string = "0x%08x %s 0x%01x 0x%08x";

   `uvm_object_param_utils_begin(uvma_rvvi_ovpsim_control_seq_item_c#(ILEN,XLEN))      
      `uvm_field_int(intr,      UVM_DEFAULT)
      `uvm_field_int(dbg_req,   UVM_DEFAULT)
      `uvm_field_int(nmi,       UVM_DEFAULT)
      `uvm_field_int(mip,       UVM_DEFAULT)
      `uvm_field_int(intr_id,   UVM_DEFAULT)
      `uvm_field_int(rd1_addr,  UVM_DEFAULT)
      `uvm_field_int(rd1_wdata, UVM_DEFAULT)
      `uvm_field_int(mem_addr,  UVM_DEFAULT)
      `uvm_field_int(mem_rdata, UVM_DEFAULT)
      `uvm_field_int(mem_rmask, UVM_DEFAULT)
   `uvm_object_utils_end
   
   /**
    * Default constructor.
    */
   extern function new(string name="uvma_rvvi_ovpsim_control_seq_item");

   /**
    * One-liner log message
    */
   extern function string convert2string();

endclass : uvma_rvvi_ovpsim_control_seq_item_c

`pragma protect begin


function uvma_rvvi_ovpsim_control_seq_item_c::new(string name="uvma_rvvi_ovpsim_control_seq_item");
   
   super.new(name);
   
endfunction : new

function string uvma_rvvi_ovpsim_control_seq_item_c::convert2string();

   return action.name();
   
endfunction : convert2string

`pragma protect end


`endif // __UVMA_RVVI_OVPSIM_CONTROL_SEQ_ITEM_SV__

