# The World Of Ledger Game (made according to [LedgerHQ exercise](https://github.com/LedgerHQ/solidity-exercise))

## Environment
Created using Brownie v1.19.2 and Python 3.10

## Before deploy
There are two prerequisites we need before deploying the contract:
* **Boss contract address**. You can use any ERC-721 contract while deploying, however it should have *tokenURI* and *totalSupply* functions;
* **VRFV2Coordinator** address, **Key hash**, **Link token** address. As the contract uses chainlink random number generator for character generation, you need to provide these data to work correctly. Please refer to [Chainlink docs](https://docs.chain.link/docs/vrf/v2/subscription/examples/get-a-random-number/)

## After deploy
You have to create and fund chainlink subscription with some Link tokens. Players won't be able to generate new Characters without funded subscription. 

You have to: 
1. Give contract approval to use your Link tokens.
2. Use *fundSubscription* function of the contract.

It is possibally to cancel subscription and get your Link tokens back at any time. However, you won't be able to fund it anymore and thus create new characters for the game.

## Game features
- Users may generate characters with random HP and Damage (**NOTE** *createRandomCharacter* function will require some time for Chainlink nodes to generate random numers)
- Owner of the contract may create boss;
- Users may attack boss with their character and able to claim rewards of defeated bosses;
- Characters level is calculated according to formula: sqrt(xp) * 20 / 100;
- Everytime a player attack the boss, the boss will counterattack the player. Both will loose life points;

- Default requirement for heal spell - 2, firebolt spell - 3. May be changed by the contract owner;
- Default cooldown period for firebolt spell - 1 day. May be changed by the contract owner;
- Firebolt cast twice more damage then basic attack of the charater;
- Heal spell heals the same amount of hp as the basic attack of the character;

- Players can mint NFT after bosses defeat;

## Example
The example contract deployed on Goerli chain - [0xCa5514eF8426D4cd09BAB16Fb03dC6Ce6267a1Ae](https://goerli.etherscan.io/token/0xca5514ef8426d4cd09bab16fb03dc6ce6267a1ae#code))

