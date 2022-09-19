// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./WorldOfLedgerFactory.sol";

contract WorldOfLedger is WorldOfLedgerFactory {
    uint256 _totalUsers;
    uint256 _totalDamage;
    mapping(address => uint256) public damageMade;
    mapping(address => uint256) public usersRewards;
    mapping(uint256 => address) public users;

    constructor() {
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
        require(boss_alive == true, "There is no active Boss right now");

        _userAttackProcess();
        _bossAttackProcess();
        _checkHealthAfterFight();
    }

    function _checkHealthAfterFight() internal {
        if (usersCharacters[msg.sender].hp == 0) {
            usersCharacters[msg.sender].is_alive == false;
        }
        if (current_boss.hp == 0) {
            finalizeRound();
        }
    }

    function _userAttackProcess() internal {
        if (damageMade[msg.sender] == 0) {
            _totalUsers++;
            users[_totalUsers] = msg.sender;
        }

        if (usersCharacters[msg.sender].damage > current_boss.hp) {
            _totalDamage += current_boss.hp;
            damageMade[msg.sender] += current_boss.hp;
            current_boss.hp = 0;
        } else {
            _totalDamage += usersCharacters[msg.sender].damage;
            current_boss.hp -= usersCharacters[msg.sender].damage;
            damageMade[msg.sender] += usersCharacters[msg.sender].damage;
        }
    }

    function _bossAttackProcess() internal {
        if (current_boss.damage > usersCharacters[msg.sender].hp) {
            usersCharacters[msg.sender].hp = 0;
        } else {
            usersCharacters[msg.sender].hp -= current_boss.damage;
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
        require(healed_user != msg.sender, "You can not heal YOUR character");

        // assuming that Character may heal in the same amount as make damage
        usersCharacters[healed_user].hp += usersCharacters[msg.sender].damage;
    }

    function finalizeRound() internal {
        boss_alive == false;
        for (uint256 i = 1; i <= _totalUsers; i++) {
            usersRewards[users[i]] +=
                current_boss.reward *
                (damageMade[users[i]] / _totalDamage);
            delete damageMade[users[i]];
            delete users[i];
        }
        _totalUsers = 0;
        _totalDamage = 0;
    }

    function claimRewards() public {
        _addExperience(msg.sender, usersRewards[msg.sender]);
        _clearRewards(msg.sender);
    }

    function _addExperience(address user, uint256 amount) internal {
        usersCharacters[user].xp += amount;
    }

    function _clearRewards(address user) internal {
        usersRewards[user] = 0;
    }
}
