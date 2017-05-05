// my_incl.vh
// If we have not included file before,
// this symbol _my_incl_vh_ is not defined.
`ifndef _my_incl_vh_
`define _my_incl_vh_

// 128/128
`define KEY_BLK 2
`define P_SIZE 128
`define KEY_SIZE 128
`define BIT_COUNTER 7 
`define ROUNDS 68
`define ROUND_COUNTER 7
`define Z_VALUE 66'b101011110111000000110100100110001010000100011111100101101100111010
`define Z_SIZE 66
`define PLAINTEXT 128'h63736564207372656c6c657661727420
`define KEY 128'h0f0e0d0c0b0a09080706050403020100

`endif //_my_incl_vh
