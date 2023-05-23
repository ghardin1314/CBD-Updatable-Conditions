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

struct DynamicCondition {
    address target;
    bytes4 selector;
    address callDataModifier;
    bytes4 callDataModifierSelector;
    bytes callData;
    bytes returnData;
}

struct FunctionTarget {
    address target;
    bytes4 selector;
}

contract ConditionsEntrypoint {
    mapping(bytes32 => Strategy) _strategies;
    mapping(bytes32 => mapping(uint256 => DynamicCondition)) _conditions;

    function createStrategy(bytes32 id, DynamicCondition[] calldata conditions) public {
        _strategies[id] = Strategy(true, conditions.length);

        for (uint256 i; i < conditions.length; i++) {
            DynamicCondition memory condition = conditions[i];
            _conditions[id][i] = condition;
        }
    }

    function verifyStrategy(bytes32 id, bytes[] calldata context) public view returns (bool) {
        Strategy memory strategy = _strategies[id];

        if (!strategy.initialized) {
            return false;
        }

        for (uint256 i; i < strategy.conditionLength; i++) {
            DynamicCondition memory condition = _conditions[id][i];

            bytes memory callData = condition.callData;
            if (condition.callDataModifier != address(0)) {

                (bool modSuccess, bytes memory modResult) = condition.callDataModifier.staticcall(
                    abi.encodeWithSelector(condition.callDataModifierSelector, callData, context[i])
                );

                // Probably revert here
                if (!modSuccess) {
                    return false;
                }

                callData = modResult;
            }

            (bool success, bytes memory result) =
                condition.target.staticcall(bytes.concat(condition.selector, callData));

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
