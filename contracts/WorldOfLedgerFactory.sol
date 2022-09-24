// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

interface BossInterface {
    function tokenURI(uint256 berdieId) external view returns (string memory);

    function totalSupply() external view returns (uint256);
}

contract WorldOfLedgerFactory is Ownable, VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 subscriptionId;
    uint32 callbackGasLimit = 500000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 2;
    mapping(uint256 => address) public requestIdToAddress;
    mapping(uint256 => uint256[]) public requestIdToRandomWords;
    bytes32 keyHash;

    Boss public currentBoss;
    bool public bossAlive;
    address public bossContractAddress;

    mapping(address => Character) public usersCharacters;
    event RequestedRandomness(uint256 requestId);
    event BossCreated(string berdieTokenURI);

    struct Character {
        uint256 hp;
        uint256 damage;
        uint256 xp;
        uint256 level;
        bool isAlive;
        uint256 fireBoltTime;
    }

    struct Boss {
        uint256 hp;
        uint256 damage;
        uint256 reward;
        uint256 id;
    }

    constructor(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash,
        address _bossContract
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        bossContractAddress = _bossContract;
        bossAlive = false;
        // add subscription
        // subscriptionId = COORDINATOR.createSubscription();
        // COORDINATOR.addConsumer(subscriptionId, address(this));
    }

    function createRandomCharacter() public {
        require(
            _userHasCharacter(msg.sender) == false,
            "You can not create more then one character"
        );
        _createRandomCharacter();
    }

    function _userHasCharacter(address user) internal view returns (bool) {
        return (usersCharacters[user].damage != 0) ? true : false;
    }

    function _hasAliveCharacter(address user) internal view returns (bool) {
        return usersCharacters[user].isAlive;
    }

    function _createRandomCharacter() private {
        // % 100 sets the upper limit of the hp and damage
        uint256 requestId = requestRandomWords();
        emit RequestedRandomness(requestId);
    }

    function populate_boss(
        uint256 hp,
        uint256 damage,
        uint256 reward
    ) public onlyOwner {
        require(
            bossAlive == false,
            "You can not pupulate new boss while there is another alive"
        );
        BossInterface bossContract = BossInterface(bossContractAddress);
        uint256 totalSupply = bossContract.totalSupply();
        uint256 id = (uint256(
            (
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        msg.sender
                    )
                )
            )
        ) % totalSupply) + 1;
        currentBoss = Boss(hp, damage, reward, id);
        bossAlive = true;
        string memory bossURI = bossContract.tokenURI(id);
        emit BossCreated(bossURI);
    }

    function requestRandomWords() public returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        requestIdToAddress[requestId] = msg.sender;
        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        requestIdToRandomWords[requestId] = randomWords;

        usersCharacters[requestIdToAddress[requestId]] = Character(
            (requestIdToRandomWords[requestId][0] % 100) + 1,
            (requestIdToRandomWords[requestId][1] % 100) + 1,
            0,
            0,
            true,
            0
        );
    }
}
