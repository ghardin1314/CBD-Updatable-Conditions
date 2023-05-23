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
    address returnValueModifier;
    bytes4 returnValueModifierSelector;
    address validationTarget;
    bytes4 validationSelector;
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

    function verifyStrategy(bytes32 id, bytes[] calldata inputContext, bytes[] calldata returnContext)
        public
        view
        returns (bool)
    {
        Strategy memory strategy = _strategies[id];

        if (!strategy.initialized) {
            return false;
        }

        for (uint256 i; i < strategy.conditionLength; i++) {
            DynamicCondition memory condition = _conditions[id][i];

            // Dynamic Input Parameters based on context
            bytes memory callData = condition.callData;
            if (condition.callDataModifier != address(0)) {
                (bool modSuccess, bytes memory modResult) = condition.callDataModifier.staticcall(
                    abi.encodeWithSelector(condition.callDataModifierSelector, callData, inputContext[i])
                );

                // Probably revert here
                if (!modSuccess) {
                    return false;
                }

                callData = modResult;
            }

            // Dynamic Return Value based on context
            bytes memory returnData = condition.returnData;
            if (condition.returnValueModifier != address(0)) {
                (bool modSuccess, bytes memory modResult) = condition.returnValueModifier.staticcall(
                    abi.encodeWithSelector(condition.returnValueModifierSelector, returnData, returnContext[i])
                );

                // Probably revert here
                if (!modSuccess) {
                    return false;
                }

                returnData = modResult;
            }

            (bool success, bytes memory result) =
                condition.target.staticcall(bytes.concat(condition.selector, callData));

            if (!success) {
                return false;
            }

            (bool validationSuccess, bytes memory validationResult) = condition.validationTarget.staticcall(
                abi.encodeWithSelector(condition.validationSelector, result, returnData)
            );

            if (!validationSuccess || !abi.decode(validationResult, (bool))) {
                return false;
            }
        }

        return true;
    }

    function eq(bytes memory a, bytes memory b) public pure returns (bool) {
        return keccak256(a) == keccak256(b);
    }

    /**
     * @dev assumes that the length of the bytes is 32 or less
     */
    function gt(bytes memory a, bytes memory b) public pure returns (bool) {
        (uint256 valA) = abi.decode(a, (uint256));
        (uint256 valB) = abi.decode(b, (uint256));

        return valA > valB;
    }

    /**
     * @dev assumes that the length of the bytes is 32 or less
     */
    function gte(bytes memory a, bytes memory b) public pure returns (bool) {
        (uint256 valA) = abi.decode(a, (uint256));
        (uint256 valB) = abi.decode(b, (uint256));

        return valA >= valB;
    }

    /**
     * @dev assumes that the length of the bytes is 32 or less
     */
    function lt(bytes memory a, bytes memory b) public pure returns (bool) {
        (uint256 valA) = abi.decode(a, (uint256));
        (uint256 valB) = abi.decode(b, (uint256));

        return valA < valB;
    }

    /**
     * @dev assumes that the length of the bytes is 32 or less
     */
    function lte(bytes memory a, bytes memory b) public pure returns (bool) {
        (uint256 valA) = abi.decode(a, (uint256));
        (uint256 valB) = abi.decode(b, (uint256));

        return valA <= valB;
    }
}
