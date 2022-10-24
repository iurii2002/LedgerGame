// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./WorldOfLedgerFactory.sol";
import "./RewardNFT.sol";
import "../interfaces/INFTInterface.sol";

/// @author Iurii Zozulynskyi
/// @title World Of Ledger game contract.
contract WorldOfLedger is WorldOfLedgerFactory, RewardNFT {
    uint256 _totalUsers;
    uint256 _totalDamage;
    mapping(address => uint256) public damageMade;
    mapping(address => uint256) public usersRewards;
    mapping(uint256 => address) public users;

    event DamageMade(address user, uint256 amount);

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
    )
        WorldOfLedgerFactory(
            _vrfCoordinator,
            _keyHash,
            _bossContract,
            _linkToken
        )
        RewardNFT()
    {
        _totalUsers = 0;
    }

    /**
        @dev Character attacks boss. Both character and boss get damage according to their attribute
        @notice User should have alive character to call this function
    */
    function attackBoss() public {
        require(
            _userHasCharacter(msg.sender) == true,
            "You should have a Character"
        );
        require(
            _hasAliveCharacter(msg.sender) == true,
            "Your Character should be alive"
        );
        require(bossAlive == true, "There is no active Boss right now");

        _userAttackProcess(usersCharacters[msg.sender].damage);
        _bossAttackProcess();
        _checkHealthAfterFight();
    }

    /**
        @dev Checks if character or boss health less than 0
        @notice internal function
    */
    function _checkHealthAfterFight() internal {
        if (usersCharacters[msg.sender].hp == 0) {
            _character_died();
        }
        if (currentBoss.hp == 0) {
            _finalizeRound();
        }
    }

    /**
        @dev Called if character hp below 0. Drops character xp and level to 0 and isAlive to false
        @notice internal function
    */
    function _character_died() internal {
        usersCharacters[msg.sender].isAlive == false;
        usersCharacters[msg.sender].xp = 0;
        _updateUserLevel(msg.sender);
    }

    /**
        @dev user attack process. Stores damage made by character to the damageMade mapping
        @param userDamage amount of damage that character made to boss        
        @notice internal function
    */
    function _userAttackProcess(uint256 userDamage) internal {
        if (damageMade[msg.sender] == 0) {
            _totalUsers++;
            users[_totalUsers] = msg.sender;
        }

        if (userDamage > currentBoss.hp) {
            uint256 _actualDamage = currentBoss.hp;
            _totalDamage += _actualDamage;
            damageMade[msg.sender] += _actualDamage;
            emit DamageMade(msg.sender, _actualDamage);
            currentBoss.hp = 0;
        } else {
            _totalDamage += userDamage;
            currentBoss.hp -= userDamage;
            damageMade[msg.sender] += userDamage;
            emit DamageMade(msg.sender, userDamage);
        }
    }

    /**
        @dev boss attack process
        @notice internal function
    */
    function _bossAttackProcess() internal {
        if (currentBoss.damage > usersCharacters[msg.sender].hp) {
            usersCharacters[msg.sender].hp = 0;
        } else {
            usersCharacters[msg.sender].hp -= currentBoss.damage;
        }
    }

    /**
        @dev health another user. User should have alive character, can't heal own character
        @dev character level should be >= healSpellLevel set be setHealSpellLevel function (default = 2)
        @param healed_user user address that we want to heal
        @notice Character heals in the same amount as make damage
    */
    function healCharacter(address healed_user) public {
        require(
            _userHasCharacter(msg.sender) == true,
            "You should have a Character"
        );
        require(
            _hasAliveCharacter(msg.sender) == true,
            "Your Character should be alive"
        );
        require(
            usersCharacters[msg.sender].xp > 0,
            "Only players who already earn experiences can cast the heal spell"
        );
        require(
            _userHasCharacter(healed_user) == true,
            "User should have Character to heal it"
        );
        require(
            usersCharacters[msg.sender].level >= healSpellLevel,
            "Only players level 2 or above may cast the heal spell"
        );
        require(healed_user != msg.sender, "You can not heal YOUR character");

        usersCharacters[healed_user].hp += usersCharacters[msg.sender].damage;
    }

    /**
        @dev cast firebolt spell. User should have alive character
        @dev character level should be >= fireBoltSpellLevel set be setFireBoltSpellLevel function (default = 3)
        @notice Firebolt makes x2 of the character damage
    */
    function castFireBolt() public {
        require(
            usersCharacters[msg.sender].level >= fireBoltSpellLevel,
            "Only players level 3 or above may cast the heal spell"
        );
        require(
            block.timestamp >= usersCharacters[msg.sender].fireBoltTime,
            "You may cast spell only once a day"
        );
        usersCharacters[msg.sender].fireBoltTime =
            block.timestamp +
            fireBoltCooldownPeriod;
        _userAttackProcess(usersCharacters[msg.sender].damage * 2);
    }

    /**
        @dev called when boss xp drops to 0
        @dev calculate user rewards according to their damage made to boss and create allowance for NFT mint for them
        @notice internal function
    */
    function _finalizeRound() internal {
        bossAlive == false;
        for (uint256 i = 1; i <= _totalUsers; i++) {
            usersRewards[users[i]] +=
                currentBoss.reward *
                (damageMade[users[i]] / _totalDamage);
            addAllowanceToUser(
                users[i],
                damageMade[users[i]],
                usersRewards[users[i]],
                currentBoss.id
            );
            delete damageMade[users[i]];
            delete users[i];
        }
        _totalUsers = 0;
        _totalDamage = 0;
    }

    /**
        @dev mints reward nft by user that killed boss
        @notice user should have attacked dead boss to get reward NFT 
    */
    function mintRewardNFT() public {
        require(
            userToNFTAllowed[msg.sender].length > 0,
            "User doesn't have any NFT to mint"
        );
        _mintReward(msg.sender);
    }

    /**
        @dev user may claim reward after killing boss
        @dev characters get experience according to the damage made to boss and get level update accordinaly
    */
    function claimRewards() public {
        _addExperience(msg.sender, usersRewards[msg.sender]);
        _updateUserLevel(msg.sender);
        _clearRewards(msg.sender);
    }

    /**
        @dev internal function that adds experience to the character 
        @param user character whos experince should be changed
        @param amount of experience to add
    */
    function _addExperience(address user, uint256 amount) internal {
        usersCharacters[user].xp += amount;
    }

    /**
        @dev drop rewards after their distribution
        @param user character whos reward should be dropped
    */
    function _clearRewards(address user) internal {
        usersRewards[user] = 0;
    }

    /**
        @dev updated character level
        @dev level calculated as a square root of character xp multiplied to 20 and divided to 100
        @param user character whos level should be calculated
    */
    function _updateUserLevel(address user) internal {
        uint256 newUserLevel = uint256(
            ((_sqrt(usersCharacters[user].xp)) * 20) / 100
        );
        usersCharacters[user].level = newUserLevel;
        _checkHealthAfterFight();
    }

    /**
        @dev calculates the square root of the number
        @param y number from which we need a square root
        @return z result of the math function
    */
    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
