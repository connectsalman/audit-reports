# English Auction: Findings

- [H-1] NFT stuck if nobody bids: end() reverts when highestBidder is address(0)
- [M-1] Only the owner can call end(): the winner's NFT and ETH depend on the owner
- [L-1] Owner can bid on their own auction: free shill bidding
- [L-2] transferFrom instead of safeTransferFrom: NFT can get stuck in a contract winner
- [I-1] start() makes an external call before setting started = true