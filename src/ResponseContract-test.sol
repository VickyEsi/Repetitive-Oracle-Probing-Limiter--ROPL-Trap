// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ResponseContract} from "./ResponseContract.sol";
import {SimpleMockTarget} from "../test/mocks/SimpleMockTarget.sol";

contract ResponseContractTest is Test {
    address public guardian = makeAddr("guardian");
    address public offender = makeAddr("offender");
    SimpleMockTarget public target;
    ResponseContract public response;

    function setUp() public {
        target = new SimpleMockTarget();
        response = new ResponseContract(address(target), guardian);
    }

    function test_ExecuteResponse() public {
        vm.prank(guardian);
        response.executeResponse(abi.encode(offender));

        assertEq(target.userToRateLimit(), offender);
    }

    function test_ExecuteResponse_RevertsIfNotGuardian() public {
        vm.prank(offender);
        vm.expectRevert("Only guardian can call this function");
        response.executeResponse(abi.encode(offender));
    }
}
