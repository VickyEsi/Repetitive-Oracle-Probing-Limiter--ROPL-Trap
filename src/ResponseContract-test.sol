// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "./ResponseContract.sol";

contract ResponseContractTest is ResponseContract, Test {
    function setTargetContract(address targetContract) external {
        // This is a test-only function to set the target contract address.
        // It uses vm.store to bypass the constant nature of the real contract.
        vm.store(
            address(this),
            bytes32(uint256(0)), // Storage slot 0 for TARGET_CONTRACT
            bytes32(uint256(uint160(targetContract)))
        );
    }
}
