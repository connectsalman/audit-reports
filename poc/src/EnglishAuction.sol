// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract EnglishAuction {
    // events
    event Start(uint256 startTime, uint256 endTime);
    event Bid(address indexed bidder, uint256 value);
    event End(address highestBidder, uint256 value);
    event Withdraw(address indexed bidder, uint256 value);

    // auction state
    bool public started;
    bool public ended;
    uint256 public endTime;
    uint256 public highestBid;
    address public highestBidder;
    mapping(address => uint256) public allBids;

    address payable public immutable owner;
    uint256 public immutable nftId;
    IERC721 public immutable nft;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call the function");
        _;
    }

    constructor(address _nft, uint256 _nftId) {
        owner = payable(msg.sender);
        nft = IERC721(_nft);
        nftId = _nftId;
    }

    function bid() external payable {
        require(started, "Auction has not started");
        require(msg.value > highestBid, "Bid price is lower than the current highest bid");
        require(block.timestamp < endTime, "Auction has ended");

        // refund logic for the PREVIOUS highest bidder
        // (only if there was a real previous bidder, not address(0))
        if (highestBidder != address(0)) {
            allBids[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = msg.sender;

        emit Bid(msg.sender, msg.value);
    }

    function start(uint256 _openingBid, uint256 _duration) external onlyOwner {
        require(!started, "Auction has already started");

        highestBid = _openingBid;
        endTime = block.timestamp + _duration;
        nft.transferFrom(owner, address(this), nftId);
        started = true;

        emit Start(block.timestamp, endTime);
    }

    function end() external onlyOwner {
        require(started, "Auction has not started");
        require(block.timestamp >= endTime, "Auction has not ended");
        require(!ended, "Auction has already ended");

        ended = true;
        nft.transferFrom(address(this), highestBidder, nftId);

        // FIXED: correct call syntax with {value: ...}
        (bool success,) = owner.call{value: highestBid}("");
        require(success, "Transfer to owner failed");

        emit End(highestBidder, highestBid);
    }

    function withdraw() external {
        uint256 value = allBids[msg.sender];

        // checks-effects-interactions: zero out BEFORE sending
        allBids[msg.sender] = 0;

        if (value > 0) {
            // FIXED: send "value" to "msg.sender" (the actual caller)
            (bool success,) = payable(msg.sender).call{value: value}("");
            require(success, "Transfer failed");
        }

        emit Withdraw(msg.sender, value);
    }
}
