# Lightweight-Threshold-Implementations

2TI_Simon

2TI_Simon is a masked implementation of lightweight block cipher Simon and the masking scheme adopted is based on the state-of-the-art Threshold Implementation (TI) which is considered as an effective countermeasure againt glitches.

While regular TI requires at least 3 uniformly random shares to represent any secret value in order for first-order leakage resistance, 2TI_Simon is proposed as a preliminary attempt to use only 2 shares to reduce the resource usage while keep the same level of the security.

Correctness, Non-conpleteness and Uniformity, which are three key rules for a valid 3-share TI scheme, are still retained in 2-share TI to guanrantee the leakage resistance even in the presence of glitches.

In order to fairly assess the performance and cost of 2-share TI implementations, 3-share TI Simon core and unprotected Simon core are provided as well. 

===============================================

3-share TI Speck

Speck is a sister lightweight block cipher of Simon introduced by NSA in 2013. Speck has been optimized for performance in software implementations. But, it also shows its great performance in hardware platform. 

We implement FPGA based bit-serialized engine of Speck, to achieve minimal area footprint. We further propose a Speck core that is provably secure against first-order side-channel attacks using TI. The resulting design is a tiny crypto core that provides AES-like security in under 45 slices on a low-cost Xilinx Spartan 3 FPGA. The first-order side-channel resistant version of the same core needs less than 100 slices. The security of the protected core is validated by state-of-the-art side-channel leakage detection tests.

===============================================

Usage of the core

The designs are ported to Sasebo GII board for side-channel evaluation. It could be simply embedded into the Verilog codes provided by Sasebo project from http://satoh.cs.uec.ac.jp/SAKURA/hardware/SASEBO-GII.html.

One import modification of the control core is the random number generator in order for data sharing of TI version of the ciphers. We use a LFSR to implement this function while you can design you own randomness source as you want. But one may need to remember that the randomness source is better to be placed in the control core instead of the crypto core.

===============================================

Publications:

1. SpecTre: A Tiny Side-Channel Resistant Speck Core for FPGAs

https://link.springer.com/chapter/10.1007/978-3-319-54669-8_5

2. A Tale of Two Shares: Why Two-Share Threshold Implementation Seems Worthwhile—and Why it is Not

https://link.springer.com/chapter/10.1007/978-3-662-53887-6_30

3. Silent Simon: A threshold implementation under 100 slices

http://ieeexplore.ieee.org/abstract/document/7140227/
===============================================

Acknowledgment:

This work is supported by the National Science Foundation under Grant CNS-1261399 and Grant CNS-1314770
