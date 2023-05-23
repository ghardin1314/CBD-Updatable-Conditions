// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ConditionsEntrypoint.sol";

import {ERC721Mock} from "./mocks/ERC721.sol";
import {ERC721} from "./interfaces/ERC721.i.sol";

contract Base is Test {
    ConditionsEntrypoint entrypoint;

    function setUp() public virtual {
        entrypoint = new ConditionsEntrypoint();
    }
}

contract ERC721Conditions is Base {
    address subject = makeAddr("Subject");
    bytes32 id = bytes32("1111");
    ERC721Mock target;

    function setUp() public override {
        super.setUp();
        target = new ERC721Mock();
    }

    function testBalanceOf() public {
        bytes4 selector = ERC721.balanceOf.selector;
        bytes memory callData = abi.encode(subject);
        bytes memory returnValue = abi.encode(2);

        StaticCondition[] memory conditions = new StaticCondition[](1);
        conditions[0] = StaticCondition(address(target), selector, callData, returnValue);

        entrypoint.createStrategy(id, conditions);
        assertFalse(entrypoint.verifyStrategy(id));

        target.mint(subject, 1);
        target.mint(subject, 2);
        assertTrue(entrypoint.verifyStrategy(id));
    }

    function testOwnerOf() public {
        uint256 tokenId = 2;
        bytes4 selector = ERC721.ownerOf.selector;
        bytes memory callData = abi.encode(tokenId);
        bytes memory returnValue = abi.encode(subject);

        StaticCondition[] memory conditions = new StaticCondition[](1);
        conditions[0] = StaticCondition(address(target), selector, callData, returnValue);

        entrypoint.createStrategy(id, conditions);
        assertFalse(entrypoint.verifyStrategy(id));

        target.mint(subject, 2);
        assertTrue(entrypoint.verifyStrategy(id));
    }
}
