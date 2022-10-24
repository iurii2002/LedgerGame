// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "../interfaces/INFTInterface.sol";

contract WorldOfLedgerFactory is Ownable, VRFConsumerBaseV2 {
    bytes32 keyHash;
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    Boss public currentBoss;
    bool public bossAlive;
    address public bossContractAddress;
    uint64 subscriptionId;
    uint32 callbackGasLimit = 500000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 2;
    uint8 public healSpellLevel;
    uint8 public fireBoltSpellLevel;
    uint64 public fireBoltCooldownPeriod;

    mapping(uint256 => address) public requestIdToAddress;
    mapping(uint256 => uint256[]) public requestIdToRandomWords;
    mapping(address => Character) public usersCharacters;

    event SubscriptionCreated(uint64 indexed subId);
    event ConsumerAdded(uint64 indexed subId, address consumer);
    event RequestedRandomness(uint256 requestId);
    event BossCreated(uint256 bossID, string tokenURI);

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
        address _vrfCoordinator,
        bytes32 _keyHash,
        address _bossContract,
        address _linkToken
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = COORDINATOR.createSubscription();
        emit SubscriptionCreated(subscriptionId);

        COORDINATOR.addConsumer(subscriptionId, address(this));
        emit ConsumerAdded(subscriptionId, address(this));
        LINKTOKEN = LinkTokenInterface(_linkToken);

        keyHash = _keyHash;

        bossContractAddress = _bossContract;
        bossAlive = false;

        healSpellLevel = 2;
        fireBoltSpellLevel = 3;
        fireBoltCooldownPeriod = 1 days;
    }

    function setHealSpellLevel(uint8 newLevel) external onlyOwner {
        healSpellLevel = newLevel;
    }

    function setFireBoltSpellLevel(uint8 newLevel) external onlyOwner {
        fireBoltSpellLevel = newLevel;
    }

    function setFireBoltCooldownPeriod(uint8 timeInDays) external onlyOwner {
        fireBoltCooldownPeriod = timeInDays * 1 days;
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
        INFTInterface bossContract = INFTInterface(bossContractAddress);
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
        string memory bossURI = bossContract.tokenURI(id);
        currentBoss = Boss(hp, damage, reward, id);
        bossAlive = true;
        emit BossCreated(id, bossURI);
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

    function fundSubscription(uint96 amount) public {
        LINKTOKEN.transferFrom(msg.sender, address(this), amount);
        LINKTOKEN.transferAndCall(
            address(COORDINATOR),
            amount,
            abi.encode(subscriptionId)
        );
    }

    function cancelSubscription() external onlyOwner {
        COORDINATOR.cancelSubscription(subscriptionId, msg.sender);
    }
}
