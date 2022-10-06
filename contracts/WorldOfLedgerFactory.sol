// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "../interfaces/IBossInterface.sol";

contract WorldOfLedgerFactory is Ownable, VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    uint64 subscriptionId;
    uint32 callbackGasLimit = 500000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 2;
    uint8 healSpellLevel = 2;
    uint8 fireBoltSpellLevel = 3;
    uint32 fireBoltCooldownPeriod = 1 days;

    mapping(uint256 => address) public requestIdToAddress;
    mapping(uint256 => uint256[]) public requestIdToRandomWords;
    mapping(address => Character) public usersCharacters;

    bytes32 keyHash;
    Boss public currentBoss;
    bool public bossAlive;
    address public bossContractAddress;

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
        IBossInterface bossContract = IBossInterface(bossContractAddress);
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
        // string memory bossURI = "testing boss";
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
