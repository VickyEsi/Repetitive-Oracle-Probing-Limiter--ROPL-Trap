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

    function setUp() public {
        // Deploy the mock contracts
        target = new MockTargetContract();
        response = new MockResponseContract();

        // Link them using their setter functions
        target.setResponseContract(address(response));
        response.setTargetContract(address(target));

        // Instantiate the stateless trap
        trap = new RateLimiterTrap();
    }

    function test_NormalOperation() public {
        vm.prank(regularUser);
        target.guardedOperation(); // Should not revert
    }

    function test_ShouldRespond_TriggersOnThreshold() public view {
        uint256 numCalls = trap.PROBE_THRESHOLD() + 1;
        bytes[] memory collectedData = new bytes[](numCalls);

        for (uint i = 0; i < numCalls; i++) {
            collectedData[i] = abi.encode(offender);
        }

        (bool should, bytes memory responseData) = trap.shouldRespond(collectedData);

        assertTrue(should, "Trap should have triggered.");
        (address flaggedOffender) = abi.decode(responseData, (address));
        assertEq(flaggedOffender, offender, "Response data should contain the offender's address.");
    }

    function test_ShouldRespond_DoesNotTriggerBelowThreshold() public view {
        uint256 numCalls = trap.PROBE_THRESHOLD();
        bytes[] memory collectedData = new bytes[](numCalls);

        for (uint i = 0; i < numCalls; i++) {
            collectedData[i] = abi.encode(offender);
        }

        (bool should, ) = trap.shouldRespond(collectedData);

        assertFalse(should, "Trap should not have triggered.");
    }

    function test_E2E_RateLimitingFlow() public {
        // 1. Simulate probing from the offender
        uint256 numCalls = trap.PROBE_THRESHOLD() + 1;
        bytes[] memory collectedData = new bytes[](numCalls);
        for (uint i = 0; i < numCalls; i++) {
            collectedData[i] = abi.encode(offender);
        }

        // 2. The Drosera trap logic should trigger a response
        (bool should, bytes memory responseData) = trap.shouldRespond(collectedData);
        assertTrue(should, "Trap should trigger");

        // 3. The Drosera network calls the response contract
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
