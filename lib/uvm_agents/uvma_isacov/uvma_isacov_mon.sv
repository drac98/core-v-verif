// Copyright 2021 OpenHW Group
// Copyright 2021 Silicon Labs, Inc.
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
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0

`uvm_analysis_imp_decl(_rvfi_instr)

class uvma_isacov_mon_c#(int ILEN=DEFAULT_ILEN,
                         int XLEN=DEFAULT_XLEN) extends uvm_monitor;

  `uvm_component_param_utils(uvma_isacov_mon_c);

  uvma_isacov_cntxt_c                        cntxt;
  uvm_analysis_port#(uvma_isacov_mon_trn_c)  ap;
  instr_name_t                               instr_name_lookup[string];

  // Analysis export to receive instructions from RVFI
  uvm_analysis_imp_rvfi_instr#(uvma_rvfi_instr_seq_item_c#(ILEN,XLEN), uvma_isacov_mon_c) rvfi_instr_export;

  extern function new(string name = "uvma_isacov_mon", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);  

  /**
   * Convert enumeration from <instr_name_t> to match Spike disassembler
   */
  extern function string convert_instr_to_spike_name(string instr_name);

  /**
   * Analysis port write from RVFI instruction retirement monitor
   */
  extern virtual function void write_rvfi_instr(uvma_rvfi_instr_seq_item_c#(ILEN,XLEN) rvfi_instr);

endclass : uvma_isacov_mon_c


function uvma_isacov_mon_c::new(string name = "uvma_isacov_mon", uvm_component parent = null);

  super.new(name, parent);

  rvfi_instr_export = new("rvfi_instr_export", this);
endfunction : new


function void uvma_isacov_mon_c::build_phase(uvm_phase phase);

  instr_name_t in;

  super.build_phase(phase);

  void'(uvm_config_db#(uvma_isacov_cntxt_c)::get(this, "", "cntxt", cntxt));
  if (!cntxt) begin
    `uvm_fatal("CNTXT", "Context handle is null")
  end

  ap = new("ap", this);
  
  dasm_set_config(32, "rv32imc", 0);

  // Use the enumerations in <instr_name_t> to setup the instr_name_lookup 
  // convert the enums to lower-case and substitute underscore with . to match 
  // Spike disassembler
  in = in.first;
  repeat(in.num) begin
    string instr_name_key = convert_instr_to_spike_name(in.name());
        
    `uvm_info("ISACOV", $sformatf("Converting: %s to %s", in.name(), instr_name_key), UVM_HIGH);
    instr_name_lookup[instr_name_key] = in;
    in = in.next;
  end

endfunction : build_phase

function string uvma_isacov_mon_c::convert_instr_to_spike_name(string instr_name);

  string spike_instr_name;

  foreach (instr_name[i]) begin
    string chr;

    chr = instr_name.substr(i,i).tolower();

    if (chr == "_") chr = ".";
  
    spike_instr_name = { spike_instr_name, chr };
  end

  // But fence.i is encoded as fence_i in the disassembler
  if (spike_instr_name == "fence.i")
    spike_instr_name = "fence_i";
  // Ugh
  if (spike_instr_name == "lr.w")
    spike_instr_name = "lr_w";
  if (spike_instr_name == "bset") 
    spike_instr_name = "bset (args unknown)";
  if (spike_instr_name == "bseti") 
    spike_instr_name = "bseti (args unknown)";
  if (spike_instr_name == "bclr") 
    spike_instr_name = "bclr (args unknown)";
  if (spike_instr_name == "bclri") 
    spike_instr_name = "bclri (args unknown)";
  if (spike_instr_name == "binv") 
    spike_instr_name = "binv (args unknown)";
  if (spike_instr_name == "binvi") 
    spike_instr_name = "binvi (args unknown)";
  if (spike_instr_name == "bext") 
    spike_instr_name = "bext (args unknown)";
  if (spike_instr_name == "bexti") 
    spike_instr_name = "bexti (args unknown)";

  return spike_instr_name;

endfunction : convert_instr_to_spike_name

function void uvma_isacov_mon_c::write_rvfi_instr(uvma_rvfi_instr_seq_item_c#(ILEN,XLEN) rvfi_instr);   

  uvma_isacov_mon_trn_c mon_trn;
  string                instr_name;
  bit [63:0]            instr;
  
  // Some trapped instructions should not be logged in functional coverage
  // Will use mcause value to determine whether to skip
  // 1 - Instruction access fault
  // 2 - Illegal instruction
  if (rvfi_instr.trap) begin
    if (rvfi_instr.csrs["mcause"].get_csr_retirement_data() inside {1,2}) begin
      `uvm_info("ISACOV", $sformatf("Skip coverage of trapped instruction: 0x%08x, mcause: 0x%08x", 
                                    rvfi_instr.insn,
                                    rvfi_instr.csrs["mcause"].get_csr_retirement_data()), UVM_HIGH);
      return;
    end
  end

  mon_trn = uvma_isacov_mon_trn_c::type_id::create("mon_trn");
  mon_trn.instr = uvma_isacov_instr_c::type_id::create("mon_instr");
  
  instr_name = dasm_name(rvfi_instr.insn);
  if (instr_name_lookup.exists(instr_name)) begin
    mon_trn.instr.name = instr_name_lookup[instr_name];    
  end else begin
    mon_trn.instr.name = UNKNOWN;
    `uvm_warning("ISACOVMON", $sformatf("error couldn't look up '%s'", instr_name));
  end
  
  `uvm_info("ISACOVMON", $sformatf("rvfi = 0x%08x %s", rvfi_instr.insn, instr_name), UVM_HIGH);

  mon_trn.instr.itype = get_instr_type(mon_trn.instr.name);
  mon_trn.instr.ext   = get_instr_ext(mon_trn.instr.name);
  mon_trn.instr.group = get_instr_group(mon_trn.instr.name, rvfi_instr.mem_addr);

  instr = $signed(rvfi_instr.insn);

  // Disassemble the instruction using Spike (via DPI)
  if (mon_trn.instr.ext == C_EXT) begin
    mon_trn.instr.rs1     = dasm_rvc_rs1(instr);
    mon_trn.instr.rs2     = dasm_rvc_rs2(instr);
    mon_trn.instr.rd      = dasm_rd(instr);
    mon_trn.instr.c_rdrs1 = dasm_rd(instr);
    mon_trn.instr.c_rs1s  = dasm_rvc_rs1s(instr);
    mon_trn.instr.c_rs2s  = dasm_rvc_rs2s(instr);
    mon_trn.instr.c_imm   = dasm_rvc_imm(instr);
  end
  else begin
    mon_trn.instr.rs1  = dasm_rs1(instr);
    mon_trn.instr.rs2  = dasm_rs2(instr);
    mon_trn.instr.rd   = dasm_rd(instr);
    mon_trn.instr.immi = dasm_i_imm(instr);
    mon_trn.instr.imms = dasm_s_imm(instr);
    mon_trn.instr.immb = dasm_sb_imm(instr) >> 1;
    mon_trn.instr.immu = dasm_u_imm(instr) >> 12;
    mon_trn.instr.immj = dasm_uj_imm(instr);
  end

  mon_trn.instr.pc = rvfi_instr.pc_rdata;
  mon_trn.instr.mem_addr = rvfi_instr.mem_addr;

  // Cast CSR address unless illegal CSR
  if (mon_trn.instr.group == CSR_GROUP) begin
    if (!$cast(mon_trn.instr.csr, dasm_csr(instr))) begin      
      // If trap is signaled then throw out this instruction
      if (rvfi_instr.trap)
        return;

      // Consider it a fatal error to have unmapped CSR,
      // this implies we need to update CSR enumerations
      `uvm_fatal("ISACOVMON", $sformatf("CSR: 0x%03x unmappable", dasm_csr(instr)));
    end
  end

  // Set enumerations for each immediate value (if applicable)
  if (mon_trn.instr.itype == B_TYPE) 
    mon_trn.instr.immb_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.imms, 13, 1);

  if (mon_trn.instr.itype == S_TYPE) 
    mon_trn.instr.imms_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.imms, 12, 1);

  if (mon_trn.instr.itype == U_TYPE) 
    mon_trn.instr.immu_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.immu, 20, 0);

  if (mon_trn.instr.itype == I_TYPE) 
    mon_trn.instr.immi_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.immi, 12, immi_is_signed[mon_trn.instr.name]);

  if (mon_trn.instr.itype == J_TYPE) 
    mon_trn.instr.immj_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.immj, 20, 1);

  if (mon_trn.instr.itype == CI_TYPE) begin
    case (mon_trn.instr.name)
      C_ADDI:      mon_trn.instr.c_imm_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.c_imm, 6, 1);
      C_ADDI16SP:  mon_trn.instr.c_imm_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.c_imm, 10, 1);
      C_LWSP:      mon_trn.instr.c_imm_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.c_imm, 8, 1);
      C_SLLI:      mon_trn.instr.c_imm_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.c_imm, 6, 0);
      C_LI:        mon_trn.instr.c_imm_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.c_imm, 6, 1);
      C_LUI:       mon_trn.instr.c_imm_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.c_imm, 18, 0);
      default:     `uvm_fatal("ISACOV", $sformatf("unhandled CI instruction: %s", mon_trn.instr.name.name()))
    endcase
  end
  if (mon_trn.instr.itype == CSS_TYPE) begin
    case (mon_trn.instr.name)
      C_SWSP: mon_trn.instr.c_imm_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.c_imm, 8, 0);
      default:     `uvm_fatal("ISACOV", $sformatf("unhandled CSS instruction: %s", mon_trn.instr.name.name()))
    endcase
  end
  if (mon_trn.instr.itype == CIW_TYPE) begin
    case (mon_trn.instr.name)
      C_ADDI4SPN: mon_trn.instr.c_imm_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.c_imm, 10, 0);
      default:     `uvm_fatal("ISACOV", $sformatf("unhandled CIW instruction: %s", mon_trn.instr.name.name()))
    endcase
  end
  if (mon_trn.instr.itype == CL_TYPE) begin
    case (mon_trn.instr.name)
      C_LW: mon_trn.instr.c_imm_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.c_imm, 8, 0);
      default:     `uvm_fatal("ISACOV", $sformatf("unhandled CL instruction: %s", mon_trn.instr.name.name()))
    endcase
  end
  if (mon_trn.instr.itype == CS_TYPE) begin
    case (mon_trn.instr.name)
      C_SW: mon_trn.instr.c_imm_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.c_imm, 7, 0);
      default:     `uvm_fatal("ISACOV", $sformatf("unhandled CS instruction: %s", mon_trn.instr.name.name()))
    endcase
  end
  if (mon_trn.instr.itype == CB_TYPE) begin
    case (mon_trn.instr.name)
      C_BEQZ,
      C_BNEZ: mon_trn.instr.c_imm_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.c_imm, 9, 1);
      C_ANDI: mon_trn.instr.c_imm_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.c_imm, 6, 1);
      C_SRLI,
      C_SRAI: mon_trn.instr.c_imm_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.c_imm, 6, 0);
      default:     `uvm_fatal("ISACOV", $sformatf("unhandled CB instruction: %s", mon_trn.instr.name.name()))
    endcase
  end
  if (mon_trn.instr.itype == CJ_TYPE) begin
    case (mon_trn.instr.name)
      C_J,
      C_JAL: mon_trn.instr.c_imm_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.c_imm, 12, 1);
      default:     `uvm_fatal("ISACOV", $sformatf("unhandled CJ instruction: %s", mon_trn.instr.name.name()))
    endcase
  end

  mon_trn.instr.set_valid_flags();

  // Set enumerations for register values as reported from RVFI
  if (mon_trn.instr.rs1_valid) begin
    mon_trn.instr.rs1_value = rvfi_instr.rs1_rdata;    
    mon_trn.instr.rs1_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.rs1_value, 32, rs1_is_signed[mon_trn.instr.name]);
  end
  if (mon_trn.instr.rs2_valid) begin
    mon_trn.instr.rs2_value = rvfi_instr.rs2_rdata;
    mon_trn.instr.rs2_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.rs2_value, 32, rs2_is_signed[mon_trn.instr.name]);
  end
  if (mon_trn.instr.rd_valid) begin
    mon_trn.instr.rd_value  = rvfi_instr.rd1_wdata;
    mon_trn.instr.rd_value_type = mon_trn.instr.get_instr_value_type(mon_trn.instr.rd_value, 32, rd_is_signed[mon_trn.instr.name]);
  end

  // // For branches determine if the branch was taken by evaluating the instruction
  // if (mon_trn.instr.is_conditional_branch()) begin
  //   instr.branch_taken = mon_trn.instr.is_branch_taken();
  // end

  // Write to analysis port
  ap.write(mon_trn);

endfunction : write_rvfi_instr

