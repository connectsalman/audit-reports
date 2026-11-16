// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SimpleWallet} from "../src/SimpleWallet.sol";

contract RejectingOwner {
    SimpleWallet public wallet;

    constructor() {
        wallet = new SimpleWallet();
    }

    function callWithdraw() external {
        wallet.withdraw();
    }
}

contract L2Test is Test {
    function test_L2_fundsStuckIfOwnerRejectsEth() public {
        RejectingOwner owner = new RejectingOwner();
        SimpleWallet wallet = owner.wallet();

        vm.deal(address(this), 1 ether);
        wallet.deposit{value: 1 ether}();

        vm.expectRevert("Withdraw failed");
        owner.callWithdraw();

        assertEq(wallet.getBalance(), 1 ether);
    }
}
