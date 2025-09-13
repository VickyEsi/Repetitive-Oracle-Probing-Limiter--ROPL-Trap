// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TargetContract
 * @author Gemini
 * @notice This is the main contract that an attacker might probe.
 * It contains a function that can be rate-limited and the logic to block users.
 * The rate limit is applied by a separate ResponseContract.
 */
contract TargetContract {
    address public immutable RESPONSE_CONTRACT;

    uint256 public constant RATE_LIMIT_DURATION = 1 hours;
    uint256 public constant RECENT_CALLERS_BUFFER_SIZE = 100;

    mapping(address => uint256) public rateLimitedUntil;
    address[RECENT_CALLERS_BUFFER_SIZE] public recentCallers;
    uint256 public callerIndex;

    // --- Errors ---
    error RateLimited(uint256 expiryTimestamp);
    error Unauthorized();

    // --- Modifiers ---
    modifier onlyResponseContract() {
        if (msg.sender != RESPONSE_CONTRACT) {
            revert Unauthorized();
        }
        _;
    }

    constructor(address responseContract) {
        RESPONSE_CONTRACT = responseContract;
    }

    /**
     * @notice A function that is protected by the rate-limiting mechanism.
     * Probing this function repeatedly can get an address rate-limited.
     */
    function guardedOperation() public {
        if (block.timestamp < rateLimitedUntil[msg.sender]) {
            revert RateLimited(rateLimitedUntil[msg.sender]);
        }
        recentCallers[callerIndex] = msg.sender;
        callerIndex = (callerIndex + 1) % RECENT_CALLERS_BUFFER_SIZE;
    }

    /**
     * @notice Applies a rate limit to a specified user address.
     * Can only be called by the authorized ResponseContract.
     * @param user The address of the user to rate-limit.
     */
    function rateLimitAddress(address user) external onlyResponseContract {
        rateLimitedUntil[user] = block.timestamp + RATE_LIMIT_DURATION;
    }

    /**
     * @notice Returns the list of recent callers.
     */
    function getRecentCallers() external view returns (address[] memory) {
        address[] memory callers = new address[](RECENT_CALLERS_BUFFER_SIZE);
        for (uint i = 0; i < RECENT_CALLERS_BUFFER_SIZE; i++) {
            callers[i] = recentCallers[i];
        }
        return callers;
    }
}
