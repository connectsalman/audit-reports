// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {EnglishAuction} from "../src/EnglishAuction.sol";

contract MockNFT {
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => address) public approved;

    function mint(address to, uint256 id) external {
        ownerOf[id] = to;
    }

    function approve(address spender, uint256 id) external {
        approved[id] = spender;
    }

    function transferFrom(address from, address to, uint256 id) external {
        require(to != address(0), "Invalid receiver");
        require(ownerOf[id] == from, "Not owner");
        require(msg.sender == from || msg.sender == approved[id], "Not approved");
        ownerOf[id] = to;
    }
}

contract H1Test is Test {
    MockNFT public nft;
    EnglishAuction public auction;

    function setUp() public {
        nft = new MockNFT();
        auction = new EnglishAuction(address(nft), 1);
        nft.mint(address(this), 1);
        nft.approve(address(auction), 1);
    }

    function test_H1_nftStuckIfNoBids() public {
        auction.start(1 ether, 1 days);
        vm.warp(block.timestamp + 1 days + 1);

        vm.expectRevert();
        auction.end();

        assertEq(nft.ownerOf(1), address(auction));
    }
}
