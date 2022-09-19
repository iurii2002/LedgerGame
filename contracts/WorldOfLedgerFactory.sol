// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract WorldOfLedgerFactory is Ownable {
    // VRFCoordinatorV2Interface COORDINATOR;
    // uint64 s_subscriptionId;
    // uint32 callbackGasLimit = 100000;
    // uint16 requestConfirmations = 3;
    // uint32 numWords = 2;
    // uint256[] public s_randomWords;
    // uint256 public s_requestId;
    // address s_owner;
    // bytes32 keyhash;

    Boss public current_boss;
    bool public boss_alive;

    mapping(address => Character) public usersCharacters;

    struct Character {
        uint256 hp;
        uint256 damage;
        uint256 xp;
        uint256 level;
        bool is_alive;
    }

    struct Boss {
        uint256 hp;
        uint256 damage;
        uint256 reward;
    }

    constructor() {
        boss_alive = false;
    }

    function createRandomCharacter() public {
        require(
            _userHasCharacter(msg.sender) == false,
            "You can not create more then one character"
        );
        usersCharacters[msg.sender] = _createRandomCharacter();
    }

    function _userHasCharacter(address user) internal view returns (bool) {
        return (usersCharacters[user].damage != 0) ? true : false;
    }

    function _hasAliveCharacter(address user) internal view returns (bool) {
        return usersCharacters[user].is_alive;
    }

    // TODO Add randomeness

    function _createRandomCharacter() private view returns (Character memory) {
        // % 100 sets the upper limit of the hp and damage
        uint256 hp = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp))
        ) % 100;
        uint256 damage = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp, hp))
        ) % 100;
        Character memory new_character = Character(hp, damage, 0, 1, true);
        return new_character;
    }

    function populate_boss(
        uint256 hp,
        uint256 damage,
        uint256 reward
    ) public onlyOwner {
        require(
            boss_alive == false,
            "You can not pupulate new boss while there is another alive"
        );
        current_boss = Boss(hp, damage, reward);
        boss_alive = true;
    }
}
