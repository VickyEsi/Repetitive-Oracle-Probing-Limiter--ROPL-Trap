// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MockTargetContract} from "./mocks/MockTargetContract.sol";
import {MockResponseContract} from "./mocks/MockResponseContract.sol";
import {RateLimiterTrap} from "../src/RateLimiterTrap.sol";

contract RateLimiterTest is Test {
    MockTargetContract public target;
    MockResponseContract public response;
    RateLimiterTrap public trap;

    address public offender = makeAddr("offender");
    address public regularUser = makeAddr("regularUser");
    address public guardian = makeAddr("guardian");

    function setUp() public {
        // Deploy the mock contracts
        target = new MockTargetContract(address(0));
        response = new MockResponseContract(address(target), guardian);
        target.setResponseContract(address(response));

        // Instantiate the trap with the target's address
        trap = new RateLimiterTrap(address(target));
    }

    function test_NormalOperation() public {
        vm.prank(regularUser);
        target.guardedOperation(); // Should not revert
    }

    function test_ShouldRespond_TriggersOnThreshold() public {
        // Simulate offender calling the guarded function enough times to fill the buffer
        for (uint i = 0; i < trap.PROBE_THRESHOLD(); i++) {
            vm.prank(offender);
            target.guardedOperation();
        }

        // The data that the Drosera node would collect
        bytes memory collectedData = trap.collect();

        // The array of collected data from multiple blocks
        bytes[] memory dataHistory = new bytes[](1);
        dataHistory[0] = collectedData;

        (bool should, bytes memory responseData) = trap.shouldRespond(dataHistory);

        assertTrue(should, "Trap should have triggered.");
        (address flaggedOffender) = abi.decode(responseData, (address));
        assertEq(flaggedOffender, offender, "Response data should contain the offender's address.");
    }

    function test_ShouldRespond_DoesNotTriggerBelowThreshold() public {
        // Simulate offender calling the guarded function
        for (uint i = 0; i < trap.PROBE_THRESHOLD() - 1; i++) {
            vm.prank(offender);
            target.guardedOperation();
        }

        bytes memory collectedData = trap.collect();
        bytes[] memory dataHistory = new bytes[](1);
        dataHistory[0] = collectedData;

        (bool should, ) = trap.shouldRespond(dataHistory);

        assertFalse(should, "Trap should not have triggered.");
    }

    function test_E2E_RateLimitingFlow() public {
        // 1. Simulate probing from the offender
        for (uint i = 0; i < trap.PROBE_THRESHOLD(); i++) {
            vm.prank(offender);
            target.guardedOperation();
        }

        // 2. The Drosera node collects data and the trap logic should trigger a response
        bytes memory collectedData = trap.collect();
        bytes[] memory dataHistory = new bytes[](1);
        dataHistory[0] = collectedData;
        (bool should, bytes memory responseData) = trap.shouldRespond(dataHistory);
        assertTrue(should, "Trap should trigger");

        // 3. The Drosera network guardian calls the response contract
        vm.prank(guardian);
        response.executeResponse(responseData);

        // 4. Verify the offender is now rate-limited
        uint256 expectedExpiry = target.rateLimitedUntil(offender);
        assertTrue(expectedExpiry > block.timestamp, "Expiry should be in the future");

        vm.prank(offender);
        vm.expectRevert(abi.encodeWithSelector(MockTargetContract.RateLimited.selector, expectedExpiry));
        target.guardedOperation();

        // 5. Verify a regular user is not affected
        vm.prank(regularUser);
        target.guardedOperation(); // Should succeed

        // 6. Advance time and verify the rate limit has expired
        vm.warp(block.timestamp + target.RATE_LIMIT_DURATION() + 1);

        vm.prank(offender);
        target.guardedOperation(); // Should succeed again
    }
}
