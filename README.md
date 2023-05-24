# CBD-Updatable-Conditions

POC for blockchain based updatable conditions using Threshold CBD

## Entrypoint

Contract for controlling all conditions. Currently allows for only immutable conditions sets. Ideally this Strategy `id` would be unique and directly tied to the CBD strategy. In this POC implementation the user would first create the strategy set onchain and then use the `id` to create the CBD strategy.

## Dynamic Condition

This struct is the basis for a single condition that must be met. There are 4 main parts to this struct:

### Target

The target smart contract of the condition. This is where the logic of the condition is implemented. This is the contract that will be called to check if the condition is met (i.e. does this user have enough tokens to meet the condition).

### Call Data

This is the data that will be set to the target contract as an input. The `DynamicCondition.callData` is the static portion of the input data. This is set at the initiation of the Strategy and is immutable (until we add condition updating).

`callDataModifier` and `callDataModifierSelector` are used to modify the `callData` before it is sent to the target contract. This allows for dynamic inputs to the target contract using the `inputContext` parameter at validation time. For example, if the target contract is a token contract, the `callDataModifier` could be used to extract the address of the user. This would allow the condition to check if the user has enough tokens to meet the condition.

### Return Value

This is the value that is checked against what the target contract returns. This is used to check if the condition is met. Again, the `DynamicCondition.returnData` is the static portion of the return data. This is set at the initiation of the Strategy and is immutable (until we add condition updating).

`returnDataModifier` and `returnDataModifierSelector` are used to modify the `returnData` before it is checked against the data returned by the target. This allows for checking against parameters supplied at validation. For example, if the target contract is a token contract, the `returnDataModifier` could be used to extract the address of the user from the `returnContext` param. This would allow the condition to check if the user owns the correct ERC721 `tokenId` for which this Condition applies.

### Validation

This is the function that is called to check if the condition is met. A few generally useful validations have been added to the entrypoint contract for convenience but it could theoretically be any custom validation needed. It takes in 2 parameters:

- The data returned by the target contract
- The returnData from the Condition (possibly modified by the `returnDataModifier`)

And must return a single boolean if the condition is satisfied.

## Condition Updating Access Control

This is the next big piece to add (and really the whole reason for doing this POC), but it should be some pretty trivial blockchain logic. For more static condition updating we could use something like `AccessControl` from [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/7e814a3074baa921db584c180ff6e300cdec8735/contracts/access/AccessControl.sol) where each role corresponds to a different Strategy. 

Or we can allow for something similar to how this is making dynamic contract calls for validation. For instance, you could call the ERC721 `ownerOf` function to check if the user owns the correct token. Would love some more input here.

## Threshold-ts API updates

Will probably need some level of updates to the API to allow for dynamic conditions. Mostly just some additional `abi.encode` of parameters provided by the user before submitting to the blockchain for validation. Will experiment more when I have some time. Might wait until after the upcoming DKG api updates to see if there are any changes that need to be made.

## Examples

Check ./contracts/tests for some examples. Currently only checks `balanceOf` and `ownerOf` for ERC721 but I think this gives a good idea of how dynamic input and return data params can be used. 

## Features

- [x] Create a new condition set (Strategy)
- [x] Allow for validation time input parameters
- [x] Allow for validation time return parameters
- [x] Allow for dynamic validation functions
- [ ] Allow for updating conditions
- [ ] Updating conditions access controls
- [ ] `OR` condition combinations (currently only AND)
- [ ] optimize storage/encoding scheme
