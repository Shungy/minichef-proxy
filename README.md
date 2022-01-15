# MiniChef Proxy

This is a simple contract to divert portion of MiniChef emissions to another address.

## Setup

Below is the instructions to trustlessly set this up with minimal multisig transactions. In this context, multisig refers to MiniChefV2 owner, and deployer refers to any account that will deploy the contracts to aid the multisig.

1. Deployer deploys DummyERC20 and mints 10 tokens
2. Deployer transfers the tokens to multisig
3. Deployer transfers the ownership of DummyERC20 to multisig
4. Multisig adds a new MiniChefV2 pool with `addPool()` function
	* Inserts DummyERC20 address for the `_lpToken` parameter
5. Deployer deploys the MiniChefProxy contract based on recipient and pid supplied by the multisig
6. Deployer transfers the ownership of MiniChefProxy to multisig
7. Multisig confirms the recipient is correctly set in MiniChefProxy
8. Multisig deposits 10 DummyERC20 tokens to MiniChefV2 with `deposit()` function
	* Inserts MiniChefProxy address for the `to` parameter
