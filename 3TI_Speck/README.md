===============================================

3-share TI Speck

Speck is a sister lightweight block cipher of Simon introduced by NSA in 2013. 
Speck has been optimized for performance in software implementations. 
But, it also shows its great performance in hardware platform. 

We implement FPGA based bit-serialized engine of Speck, to achieve minimal area footprint. 
We further propose a Speck core that is provably secure against first-order side-channel attacks using TI. 
The resulting design is a tiny crypto core that provides AES-like security in under 45 slices on a low-cost Xilinx Spartan 3 FPGA. 
The first-order side-channel resistant version of the same core needs less than 100 slices. 
The security of the protected core is validated by state-of-the-art side-channel leakage detection tests.
