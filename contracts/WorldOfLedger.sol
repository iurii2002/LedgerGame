// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./WorldOfLedgerFactory.sol";
import "./RewardNFT.sol";
import "../interfaces/INFTInterface.sol";

contract WorldOfLedger is WorldOfLedgerFactory, RewardNFT {
    uint256 _totalUsers;
    uint256 _totalDamage;
    mapping(address => uint256) public damageMade;
    mapping(address => uint256) public usersRewards;
    mapping(uint256 => address) public users;

    event DamageMade(address user, uint256 amount);

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

    function _checkHealthAfterFight() internal {
        if (usersCharacters[msg.sender].hp == 0) {
            _user_died();
        }
        if (currentBoss.hp == 0) {
            finalizeRound();
        }
    }

    function _user_died() internal {
        usersCharacters[msg.sender].isAlive == false;
        usersCharacters[msg.sender].xp = 0;
        _updateUserLevel(msg.sender);
    }

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

    function _bossAttackProcess() internal {
        if (currentBoss.damage > usersCharacters[msg.sender].hp) {
            usersCharacters[msg.sender].hp = 0;
        } else {
            usersCharacters[msg.sender].hp -= currentBoss.damage;
        }
    }

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

        // assuming that Character may heal in the same amount as make damage
        usersCharacters[healed_user].hp += usersCharacters[msg.sender].damage;
    }

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

    function finalizeRound() internal {
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

    function mintRewardNFT() public {
        require(
            userToNFTAllowed[msg.sender][0] != 0,
            "User doen't have any NFT to mint"
        );
        _mintReward(msg.sender);
    }

    function claimRewards() public {
        _addExperience(msg.sender, usersRewards[msg.sender]);
        _updateUserLevel(msg.sender);
        _clearRewards(msg.sender);
    }

    function _addExperience(address user, uint256 amount) internal {
        usersCharacters[user].xp += amount;
    }

    function _clearRewards(address user) internal {
        usersRewards[user] = 0;
    }

    function _updateUserLevel(address user) internal {
        uint256 newUserLevel = uint256(
            ((_sqrt(usersCharacters[user].xp)) * 20) / 100
        );
        usersCharacters[user].level = newUserLevel;
        _checkHealthAfterFight();
    }

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
