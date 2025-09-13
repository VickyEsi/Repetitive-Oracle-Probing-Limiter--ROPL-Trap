// SPDX-License-Identifier: MIT
// FOR TESTING ONLY
pragma solidity ^0.8.20;

interface IMockTargetContract {
    function rateLimitAddress(address user) external;
}

contract MockResponseContract {
    address public TARGET_CONTRACT;
    address public GUARDIAN;

    modifier onlyGuardian() {
        require(msg.sender == GUARDIAN, "Only guardian can call this function");
        _;
    }

    constructor(address target, address guardian) {
        TARGET_CONTRACT = target;
        GUARDIAN = guardian;
    }

    function setTargetContract(address target) public {
        TARGET_CONTRACT = target;
    }

    function executeResponse(bytes calldata responseData) external onlyGuardian {
        (address offender) = abi.decode(responseData, (address));
        IMockTargetContract(TARGET_CONTRACT).rateLimitAddress(offender);
    }
}
