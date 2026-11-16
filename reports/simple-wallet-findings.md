# SimpleWallet: Findings

- [L-1] No way to change the owner: a lost key locks the ETH forever
- [L-2] Owner can be a contract that rejects ETH: withdraw would always fail
- [I-1] No receive() function: direct ETH transfers are rejected
- [I-2] withdraw works with 0 balance: emits a useless event
- [I-3] Floating pragma: pin one Solidity version