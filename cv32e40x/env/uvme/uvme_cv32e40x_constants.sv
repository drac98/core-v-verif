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


`ifndef __UVME_CV32E40X_CONSTANTS_SV__
`define __UVME_CV32E40X_CONSTANTS_SV__


parameter uvme_cv32e40x_sys_default_clk_period   =  1_500; // 10ns
parameter uvme_cv32e40x_debug_default_clk_period = 10_000; // 10ns

// For RVFI/RVVI
parameter ILEN = 32;
parameter XLEN = 32;
parameter RVFI_NRET = 1;

// Control how often to print core scoreboard checked heartbeat messages
parameter PC_CHECKED_HEARTBEAT = 10_000;

`endif // __UVME_CV32E40X_CONSTANTS_SV__
