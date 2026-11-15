# Audit Report: EnglishAuction

## Summary
EnglishAuction is an NFT auction: the owner deposits an NFT, bidders compete with ETH, and the winner receives the NFT. This practice review found 5 issues: 1 High, 1 Medium, 2 Low and 1 Informational.

## Scope
- File: EnglishAuction.sol (from the English-Auction repo)
- Solidity ^0.8.20
- Method: manual review

## Findings Overview

| ID | Title | Severity |
|----|-------|----------|
| H-1 | NFT stuck forever if nobody bids | High |
| M-1 | Only the owner can end the auction | Medium |
| L-1 | Owner can bid on their own auction | Low |
| L-2 | `transferFrom` used to send the NFT to the winner | Low |
| I-1 | External call happens before `started = true` | Informational |

## Findings

### [H-1] NFT stuck forever if nobody bids

- Severity: High
- Location: EnglishAuction.sol, `end()`

**Description**
`start()` moves the NFT into the contract and sets `highestBid` to the opening bid, but no ETH is paid in. If nobody bids, `highestBidder` stays `address(0)`. Then `end()` tries to send the NFT to `address(0)`, which most ERC721 contracts reject. Even if that passed, the next line pays the opening bid to the owner from a contract that holds no ETH, which also reverts. No other function can return the NFT.

**Impact**
If an auction ends without bids, the NFT is locked in the contract forever.

**Proof of Concept**
1. The owner approves the NFT and calls `start(1 ether, 1 days)`.
2. Nobody bids.
3. After `endTime`, the owner calls `end()`.
4. The call reverts, and the NFT stays in the contract with no way out.

Foundry test: `poc/test/H1.t.sol` (`test_H1_nftStuckIfNoBids`)

**Recommendation**
Return the NFT to the owner when there is no bidder:
```solidity
if (highestBidder == address(0)) {
    nft.transferFrom(address(this), owner, nftId);
} else {
    nft.transferFrom(address(this), highestBidder, nftId);
    (bool success, ) = owner.call{value: highestBid}("");
    require(success, "Transfer to owner failed");
}
```

### [M-1] Only the owner can end the auction

- Severity: Medium
- Location: EnglishAuction.sol, `end()`

**Description**
`end()` has the `onlyOwner` modifier, so nobody else can finish the auction.

**Impact**
If the owner loses their key or refuses to call `end()`, the NFT and the highest bid stay locked in the contract. The winner cannot claim the NFT, and cannot withdraw their bid either, because the highest bid is not stored in `allBids`.

**Proof of Concept**
1. Bidders bid and the auction time passes.
2. The owner never calls `end()`.
3. The winner has no function to call, and the funds stay locked.

**Recommendation**
Remove `onlyOwner` from `end()`. After `endTime`, anyone can call it, and the NFT and ETH still go to the correct parties.

### [L-1] Owner can bid on their own auction

- Severity: Low
- Location: EnglishAuction.sol, `bid()`

**Description**
Nothing stops the owner from calling `bid()`.

**Impact**
The owner can raise the price to push real bidders to pay more. The owner gets their own bid back through `end()`, so this costs almost nothing.

**Proof of Concept**
1. A bidder bids 1 ETH.
2. The owner bids 1.1 ETH from another address or from the owner address.
3. The real bidder must now bid higher.

**Recommendation**
Add `require(msg.sender != owner, "Owner cannot bid");` in `bid()`. This does not stop the owner from using a second address, so it only reduces the problem.

### [L-2] `transferFrom` used to send the NFT to the winner

- Severity: Low
- Location: EnglishAuction.sol, `end()`

**Description**
`end()` sends the NFT with `transferFrom`, which does not check whether the receiver can handle NFTs.

**Impact**
If the winner is a contract that cannot hold ERC721 tokens, the NFT can get stuck in it.

**Proof of Concept**
1. A contract without ERC721 support wins the auction.
2. `end()` sends it the NFT.
3. The NFT is stuck in that contract.

**Recommendation**
Use `safeTransferFrom` (add it to the interface). `ended = true` is already set before the call, which limits reentrancy risk.

### [I-1] External call happens before `started = true`

- Severity: Informational
- Location: EnglishAuction.sol, `start()`

**Description**
`start()` calls `nft.transferFrom(...)` before it sets `started = true`.

**Impact**
There is no direct loss here, but the safer order is to update state first, then make external calls.

**Proof of Concept**
Not needed, this is a code-order issue.

**Recommendation**
Set `started = true` before the external call.