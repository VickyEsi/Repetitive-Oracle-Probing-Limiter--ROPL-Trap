// SPDX-License-Identifier: MIT
// FOR TESTING ONLY
pragma solidity ^0.8.20;

interface IMockTargetContract {
    function rateLimitAddress(address user) external;
}

contract MockResponseContract {
    address public targetContract;

    function setTargetContract(address _targetContract) public {
        targetContract = _targetContract;
    }

    function executeResponse(bytes calldata responseData) external {
        (address offender) = abi.decode(responseData, (address));
        IMockTargetContract(targetContract).rateLimitAddress(offender);
    }
}
