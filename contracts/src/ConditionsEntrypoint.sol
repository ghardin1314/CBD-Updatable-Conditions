// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

struct Strategy {
    bool initialized;
    uint256 conditionLength;
}

// struct Condition {
//     address target;
//     address callDataModifier;
//     address returnValueModifier;
//     bytes staticCallData;
//     bytes staticReturnValue;
// }

struct StaticCondition {
    address target;
    bytes4 selector;
    bytes callData;
    bytes returnData;
}

contract ConditionsEntrypoint {
    mapping(bytes32 => Strategy) _strategies;
    mapping(bytes32 => mapping(uint256 => StaticCondition)) _conditions;

    function createStrategy(bytes32 id, StaticCondition[] calldata conditions) public {
        _strategies[id] = Strategy(true, conditions.length);

        for (uint256 i; i < conditions.length; i++) {
            StaticCondition memory condition = conditions[i];
            _conditions[id][i] = condition;
        }
    }

    function verifyStrategy(bytes32 id) public view returns (bool) {
        Strategy memory strategy = _strategies[id];

        if (!strategy.initialized) {
            return false;
        }

        for (uint256 i; i < strategy.conditionLength; i++) {
            StaticCondition memory condition = _conditions[id][i];

            (bool success, bytes memory result) =
                condition.target.staticcall(bytes.concat(condition.selector, condition.callData));

            if (!success) {
                return false;
            }
            if (keccak256(result) != keccak256(condition.returnData)) {
                return false;
            }
        }

        return true;
    }
}
