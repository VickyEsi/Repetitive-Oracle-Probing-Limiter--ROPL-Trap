// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {TargetContract} from "./TargetContract.sol";

contract TargetContractTest is Test {
    address public responseContract = makeAddr("responseContract");
    address public user = makeAddr("user");
    TargetContract public target;

    function setUp() public {
        target = new TargetContract(responseContract);
    }

    function test_GuardedOperation() public {
        vm.prank(user);
        target.guardedOperation();

        address[] memory recentCallers = target.getRecentCallers();
        assertEq(recentCallers[0], user);
    }

    function test_RateLimitAddress() public {
        vm.prank(responseContract);
        target.rateLimitAddress(user);

        uint256 rateLimitedUntil = target.rateLimitedUntil(user);
        assertTrue(rateLimitedUntil > block.timestamp);
    }

    function test_RateLimitAddress_RevertsIfNotResponseContract() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(TargetContract.Unauthorized.selector));
        target.rateLimitAddress(user);
    }

    function test_GuardedOperation_RevertsIfRateLimited() public {
        vm.prank(responseContract);
        target.rateLimitAddress(user);

        uint256 expectedExpiry = target.rateLimitedUntil(user);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(TargetContract.RateLimited.selector, expectedExpiry));
        target.guardedOperation();
    }
}
