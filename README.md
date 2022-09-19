Exercise

The definition of done for a user story is:

    Feature work as expected
    Tests have been written
    Quality controls are passed

User stories

Please, read the following user stories to implement:

    As an owner I want to inherit the admin permissions of the smart contract once it is deployed
    As an admin I want to be the only one able to populate the contract with customizable bosses
    As an user I want to be able to randomly generated one character per address
    As an user I want to be able to attack the current boss with my character
    As an user I should be able to heal other characters with my character
    As an user I want to be able to claim rewards of defeated bosses

Additional rules

    Everytime a player attack the boss, the boss will counterattack the player. Both will loose life points
    A dead character can no longer do anything but can be healed
    Only characters who attacked the boss can receive the reward in xp
    A new boss can't be populated if the current one isn't defeated
    A player can't heal himself
    Only players who already earn experiences can cast the heal spell

Feature Requests

Please, read the following feature requests and pick one to implement:

    Earning experiences isn't enough. Implement a level system based on the experience gained. Casting the heal spell will require a level 2 character and casting a fire ball spell will require a level 3 character. The fire ball spell can only be casted every 24 hours. Each time a character dies, he must loose experience points
    We decided to use cryptopunks as bosses. Please, interface the cryptopunk contract to allow admin to generate cryptopunks bosses. Develop the smart contract in such a way that anyone can create a frontend connected to the contract and use the cryptopunk metadata to display the boss.

    Players should be able to brag their fights participations. Allow players to mint a non-fungible token when they claim the reward of a defeated boss. Inspired by the LOOT project, the NFT should be fully on-chain and display some information about the defeated boss. Don't be focus on the NFT itself, it doesn't need to be impressive or include any art
    
    To emboard new players we want to pay fees for them. Allow the contract to receive "meta-transaction" that we will broadcast in order to have players without native tokens.

Data structures

Here is the data shape of the character and boss object you'll have to implement. This data are only a base that you can modify and extend as you wish. Feel free to made your own implementation.

type Boss = {
    hp: number;
    damage: number;
    reward: number;
}

type Character = {
    hp: number;
    damage: number;
    xp: number;
}