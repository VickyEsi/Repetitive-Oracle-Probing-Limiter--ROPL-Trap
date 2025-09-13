// SPDX-License-Identifier: MIT
// FOR TESTING ONLY
pragma solidity ^0.8.20;

import {TargetContract} from "../../src/TargetContract.sol";

contract MockTargetContract {
    address public responseContract;
    uint256 public constant RATE_LIMIT_DURATION = 1 hours;
    uint256 public constant RECENT_CALLERS_BUFFER_SIZE = 100;

    mapping(address => uint256) public rateLimitedUntil;
    address[RECENT_CALLERS_BUFFER_SIZE] public recentCallers;
    uint256 public callerIndex;

    error RateLimited(uint256 expiryTimestamp);
    error Unauthorized();

    modifier onlyResponseContract() {
        if (msg.sender != responseContract) {
            revert Unauthorized();
        }
        _;
    }

    constructor(address _responseContract) {
        responseContract = _responseContract;
    }

    function setResponseContract(address _responseContract) public {
        responseContract = _responseContract;
    }

    function guardedOperation() public {
        if (block.timestamp < rateLimitedUntil[msg.sender]) {
            revert RateLimited(rateLimitedUntil[msg.sender]);
        }
        recentCallers[callerIndex] = msg.sender;
        callerIndex = (callerIndex + 1) % RECENT_CALLERS_BUFFER_SIZE;
    }

    function rateLimitAddress(address user) external onlyResponseContract {
        rateLimitedUntil[user] = block.timestamp + RATE_LIMIT_DURATION;
    }

    function getRecentCallers() external view returns (address[] memory) {
        address[] memory callers = new address[](RECENT_CALLERS_BUFFER_SIZE);
        for (uint i = 0; i < RECENT_CALLERS_BUFFER_SIZE; i++) {
            callers[i] = recentCallers[i];
        }
        return callers;
    }
}
