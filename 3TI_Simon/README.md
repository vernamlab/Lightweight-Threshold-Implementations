# 3TI 

This folder contains the verilog files for bitserialzied implementation of 3TI Simon. 
The work is published at Hardware Oriented Security and Trust (HOST) 2015 as "Silent Simon: A threshold implementation under 100 slices".
http://ieeexplore.ieee.org/abstract/document/7140227/.

+++ 3TI_Simon_Core.v

The core is based on the bitserialized implemenation. https://eprint.iacr.org/2015/172.pdf.
The inputs are the bitstreams of shares of the plaintexts and keys. The outputs are ciphertext in bits and a 'Done' signal indicating the finish of the encryption. 
A 'Trig' signal is used for waveform measurement.

