// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "../interfaces/INFTInterface.sol";

/// @author Iurii Zozulynskyi
/// @title World Of Ledger Factory contract to create Boss and Characters.
/// @notice Use this contract in combination of the main World Of Ledger contract
contract WorldOfLedgerFactory is Ownable, VRFConsumerBaseV2 {
    bytes32 keyHash;
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    Boss public currentBoss;
    bool public bossAlive;
    address public bossContractAddress;
    uint8 public healSpellLevel;
    uint8 public fireBoltSpellLevel;
    uint16 requestConfirmations = 3;
    uint32 numWords = 2;
    uint32 callbackGasLimit = 500000;
    uint64 public fireBoltCooldownPeriod;
    uint64 subscriptionId;

    mapping(uint256 => address) public requestIdToAddress;
    mapping(uint256 => uint256[]) public requestIdToRandomWords;
    mapping(address => Character) public usersCharacters;

    event SubscriptionCreated(uint256 indexed subId);
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

    /**
        @dev Change the character level to spell heal 
        @param _vrfCoordinator address of the VRFV2Coordinator contract
        @param _keyHash Key hash value from Chainlink documentation
        @param _bossContract address of the Boss contract
        @param _linkToken address of the Link token contract
        @notice refer to https://docs.chain.link/docs/vrf/v2/subscription/examples/get-a-random-number/ for details
        @notice boss contract address is used to get metadata for our boss. This contract should gave tokenURI and totalSupply functions
    */

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

    /**
        @dev Change the character level to spell heal 
        @param newLevel The new level of heal spell
        @notice Default character level to spell heal is 2
    */
    function setHealSpellLevel(uint8 newLevel) external onlyOwner {
        healSpellLevel = newLevel;
    }

    /**
        @dev Change the character level to spell firebolt 
        @param newLevel The new level of firebolt spell
        @notice Default character level to spell firebolt is 3
    */
    function setFireBoltSpellLevel(uint8 newLevel) external onlyOwner {
        fireBoltSpellLevel = newLevel;
    }

    /**
        @dev Change the cooldown period for firebolt spell
        @param timeInDays The number of days for cooldows
        @notice Default character level to firebolt cooldown period is 1 day
    */
    function setFireBoltCooldownPeriod(uint8 timeInDays) external onlyOwner {
        fireBoltCooldownPeriod = timeInDays * 1 days;
    }

    /**
        @dev Creates random Character
        @notice User can not create second character if the first one alive
    */
    function createRandomCharacter() public {
        require(
            _userHasCharacter(msg.sender) == false,
            "You can not create more then one character"
        );
        _createRandomCharacter();
    }

    /**
        @dev calls requestRandomWords function to get random numbers from Chainlink nodes
        @dev receives requstID and emits event accordingly
        @notice private function 
    */
    function _createRandomCharacter() private {
        uint256 requestId = requestRandomWords();
        emit RequestedRandomness(requestId);
    }

    /**
        @dev makes a request to VRFV2Coordinator to get random numbers for new character
        @return requestId the uint number of requestID provided by Chainling VRFV2Coordinator
        @notice Will revert if subscription is not set and funded. 
    */
    function requestRandomWords() public returns (uint256 requestId) {
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

    /**
        @dev Callback function called by VRFV2 Coordinator 
        @dev Creates user character and store it to the mapping
        @param requestId requestID got from requestRandomWords function
        @param randomWords 2 random numbers provided by VRFV2Coordinator for hp and damage
        @notice %100 sets the upper limit of the hp and damage
        @notice four other parameters of a new Character are:
             xp, level, firebolt cooldown time - set to 0
             isAlive - set to True
    */
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

    /**
        @dev Checks if user has character
        @param  user address of user
        @return bool 
        @notice internal function 
    */
    function _userHasCharacter(address user) internal view returns (bool) {
        return (usersCharacters[user].damage != 0) ? true : false;
    }

    /**
        @dev Checks if user character is alive
        @param  user address of user
        @return bool
        @notice internal function 
    */
    function _hasAliveCharacter(address user) internal view returns (bool) {
        return usersCharacters[user].isAlive;
    }

    /**
        @dev creates new Boss 
        @param hp uint number of health points of the new boss 
        @param damage uint number of damage made by the new boss 
        @param reward uint number of reward for boss killing 
        @notice may be called only by the creator of the contract 
        @notice boss id is a pseudo random number
        @notice emits BossCreated event with bossId and it's uri 
    */
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

    /**
        @dev Funds VRFV2Coordinator subscription to pay for random numbers
        @param amount of link token funding
        @notice you should approve this contract to use Link your link tokens before calling this function
    */
    function fundSubscription(uint256 amount) public {
        LINKTOKEN.transferFrom(msg.sender, address(this), amount);
        LINKTOKEN.transferAndCall(
            address(COORDINATOR),
            amount,
            abi.encode(subscriptionId)
        );
    }

    /**
        @dev Cancel VRFV2Coordinator subscription and return unused Link to the owner
        @notice may be used only by owner
        @notice there is no way to create new subsction after calling this function. Hence there is no way to create new boss
    */
    function cancelSubscription() external onlyOwner {
        COORDINATOR.cancelSubscription(subscriptionId, msg.sender);
    }
}
