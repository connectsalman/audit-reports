# English Auction: Notes

## State variables
- owner: who deployed the contract and starts the auction (immutable)
- nft, nftId: the NFT being auctioned (immutable)
- started, ended: auction status flags
- endTime: when bidding closes
- highestBid, highestBidder: the best bid so far and who made it
- allBids: ETH that outbid bidders can take back

## Functions
- start: only owner, moves the NFT into the contract, sets the opening bid and end time
- bid: anyone, must send more than highestBid before endTime, and the old highest bid goes to allBids
- end: only owner, after endTime, sends the NFT to highestBidder and highestBid to owner
- withdraw: anyone, takes their own balance from allBids

## Where ETH moves
- bid: ETH comes in from the bidder
- end: highestBid goes out to the owner
- withdraw: outbid bidders take their ETH back