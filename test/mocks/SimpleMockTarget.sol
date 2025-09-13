// SPDX-License-Identifier: MIT
// FOR TESTING ONLY
pragma solidity ^0.8.20;

contract SimpleMockTarget {
    address public lastCaller;
    address public userToRateLimit;

    function rateLimitAddress(address user) external {
        lastCaller = msg.sender;
        userToRateLimit = user;
    }
}