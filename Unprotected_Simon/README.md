
# Uprotected Simon Implementation
This unprotected implementation is based on the work of Aydin Aysu etc. from Virginia Tech. Please find their paper at http://ieeexplore.ieee.org/document/6782431/.

+++ unprotected_Simon_Core.v

This file contains the RTL decription of the unprotected Simon encryption core with key size and block size of 128 bits.

The inputs are the bitstreams of the plaintexts and keys. The outputs are ciphertext in bits and a 'Done' signal indicating the finish of the encryption. A 'Trig' signal is used for waveform measurement.

+++ datapath.v

This source file contains the logic for datapath of bitserialized Simon.

+++ key_schedule.v

This source file contains the logic for key scheduling of bitserialized Simon.


+++ Unprotected_Simon_TopModule.v

This file is actually a wrapper for the core to interface the external module such as the controller logic.

+++ Unprotected_Simon_TopModule_tb.v

The testbench code to simulate the behavior of the above module.


