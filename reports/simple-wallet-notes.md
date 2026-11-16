# SimpleWallet: Notes

## State variables
- owner: the deployer, set in the constructor

## Functions
- deposit: anyone, must send more than 0 ETH
- getBalance: anyone, shows the wallet's ETH
- withdraw: only owner, sends all ETH to the owner

## Where ETH moves
- deposit: ETH comes in from anyone
- withdraw: all ETH goes out to the owner