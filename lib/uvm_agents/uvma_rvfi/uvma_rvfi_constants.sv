// Copyright 2020 OpenHW Group
// Copyright 2020 Datum Technology Corporation
// Copyright 2020 Silicon Labs, Inc.
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


`ifndef __UVMA_RVFI_CONSTANTS_SV__
`define __UVMA_RVFI_CONSTANTS_SV__


localparam ORDER_WL         = 64;
localparam MODE_WL          = 2;
localparam IXL_WL           = 2;
localparam GPR_ADDR_WL      = 5;
localparam RVFI_DBG_WL      = 3;

localparam DEFAULT_ILEN     = 32;
localparam DEFAULT_XLEN     = 32;
localparam DEFAULT_NRET     = 1;

`endif // __UVMA_RVFI_CONSTANTS_SV__
