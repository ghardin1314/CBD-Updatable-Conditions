// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ConditionsEntrypoint.sol";

import {ERC721} from "./interfaces/ERC721.i.sol";


contract Base is Test {
	ConditionsEntrypoint entrypoint;

	function setUp() public {
		entrypoint = new ConditionsEntrypoint();
	}
}

contract ERC721Conditions is Base {

	address target = makeAddr("ERC721");
	address subject = makeAddr("Subject");
	bytes32 id = bytes32("1111");

	function testBalanceOf() public {
		
		bytes4 selector = ERC721.balanceOf.selector;
		bytes memory callData = abi.encode(subject);
		bytes memory returnValue = abi.encode(2);

		StaticCondition[] memory conditions = new StaticCondition[](1);
		conditions[0] = StaticCondition(target, selector, callData, returnValue);

		entrypoint.createStrategy(id, conditions);

		vm.mockCall(subject, abi.encodeWithSelector(selector), abi.encode(0));
		assertFalse(entrypoint.verifyStrategy(id));

		vm.mockCall(subject, abi.encodeWithSelector(selector), abi.encode(2));
		assertTrue(entrypoint.verifyStrategy(id));
	}
}
