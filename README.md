# Lightweight-Threshold-Implementations

2TI_Simon

2TI_Simon is a masked implementation of lightweight block cipher Simon and the masking scheme adopted is based on the state-of-the-art Threshold Implementation (TI) which is considered as an effective countermeasure againt glitches.

While regular TI requires at least 3 uniformly random shares to represent any secret value in order for first-order leakage resistance, 2TI_Simon is proposed as a preliminary attempt to use only 2 shares to reduce the resource usage while keep the same level of the security.

Correctness, Non-conpleteness and Uniformity, which are three key rules for a valid 3-share TI scheme, are still retained in 2-share TI to guanrantee the leakage resistance even in the presence of glitches.

===============================================

Usage of the core
The design is ported to Sasebo GII board for side-channel evaluation. It could be simply embedded into the Verilog codes provided by Sasebo project from http://satoh.cs.uec.ac.jp/SAKURA/hardware/SASEBO-GII.html.

One import modification of the control core is the random number generator in order for data sharing. We use a LFSR to implement this function while you can design you own randomness source as you want. But one may need to remember that the randomness source is better to be placed in the control core instead of the crypto core.

================================================

Publications:

1. SpecTre: A Tiny Side-Channel Resistant Speck Core for FPGAs

https://link.springer.com/chapter/10.1007/978-3-319-54669-8_5

2. A Tale of Two Shares: Why Two-Share Threshold Implementation Seems Worthwhile—and Why it is Not

https://eprint.iacr.org/2016/434
