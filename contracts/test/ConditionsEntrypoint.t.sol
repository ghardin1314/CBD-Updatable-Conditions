// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ConditionsEntrypoint.sol";

import {ERC721Mock} from "./mocks/ERC721.sol";
import {ERC721} from "./interfaces/ERC721.i.sol";
import {ERC721Modifier} from "./modifiers/ERC721Modifier.sol";

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
    ERC721Modifier erc721Mod = new ERC721Modifier();

    function setUp() public override {
        super.setUp();
        target = new ERC721Mock();
    }

    function testBalanceOf() public {
        bytes4 selector = ERC721.balanceOf.selector;
        bytes memory callData = "";
        bytes memory returnData = abi.encode(2);

        DynamicCondition[] memory conditions = new DynamicCondition[](1);
        conditions[0] = DynamicCondition({
            target: address(target),
            selector: selector,
            callDataModifier: address(erc721Mod),
            callDataModifierSelector: ERC721Modifier.balanceOf.selector,
            callData: callData,
            returnData: returnData
        });
        bytes[] memory context = new bytes[](1);
        context[0] = abi.encode(subject);

        entrypoint.createStrategy(id, conditions);
        assertFalse(entrypoint.verifyStrategy(id, context));

        target.mint(subject, 1);
        target.mint(subject, 2);
        assertTrue(entrypoint.verifyStrategy(id, context));
    }

    function testOwnerOf() public {
        uint256 tokenId = 2;
        bytes4 selector = ERC721.ownerOf.selector;
        bytes memory callData = abi.encode(tokenId);
        bytes memory returnData = abi.encode(subject);

        DynamicCondition[] memory conditions = new DynamicCondition[](1);

        conditions[0] = DynamicCondition({
            target: address(target),
            selector: selector,
            callDataModifier: address(0),
            callDataModifierSelector: bytes4(0),
            callData: callData,
            returnData: returnData
        });

        bytes[] memory context = new bytes[](1);
        context[0] = "";

        entrypoint.createStrategy(id, conditions);
        assertFalse(entrypoint.verifyStrategy(id, context));

        target.mint(subject, 2);
        assertTrue(entrypoint.verifyStrategy(id, context));
    }
}
