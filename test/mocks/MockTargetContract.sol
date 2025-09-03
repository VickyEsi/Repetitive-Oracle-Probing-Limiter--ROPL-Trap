// SPDX-License-Identifier: MIT
// FOR TESTING ONLY
pragma solidity ^0.8.20;

import {TargetContract} from "../../src/TargetContract.sol";

contract MockTargetContract {
    address public responseContract;
    uint256 public constant RATE_LIMIT_DURATION = 1 hours;
    mapping(address => uint256) public rateLimitedUntil;

    error RateLimited(uint256 expiryTimestamp);
    error Unauthorized();

    modifier onlyResponseContract() {
        if (msg.sender != responseContract) {
            revert Unauthorized();
        }
        _;
    }

    function setResponseContract(address _responseContract) public {
        responseContract = _responseContract;
    }

    function guardedOperation() public view {
        if (block.timestamp < rateLimitedUntil[msg.sender]) {
            revert RateLimited(rateLimitedUntil[msg.sender]);
        }
    }

    function rateLimitAddress(address user) external onlyResponseContract {
        rateLimitedUntil[user] = block.timestamp + RATE_LIMIT_DURATION;
    }
}
