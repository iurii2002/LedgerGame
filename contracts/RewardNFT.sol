// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @author Iurii Zozulynskyi
/// @title World Of Ledger Reward NFT contract
contract RewardNFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct Reward {
        string name;
        uint256 damageMade;
        uint256 rewardReceived;
        uint256 bossID;
    }

    mapping(address => uint256[]) public userToNFTAllowed;
    mapping(uint256 => Reward) public NFTidToReward;
    event createRewardNFT(uint256 indexed requestId, address requester);

    constructor() ERC721("WorldOfLedgerRewardNFT", "WOLR") {}

    /**
        @dev creates NFT reward Structure according to the parameters
        @param damage made by the user to the boss
        @param reward got by user killing the boss
        @param bossid that was killed
        @return newNFTid number
        @notice internal function
    */
    function createReward(
        uint256 damage,
        uint256 reward,
        uint256 bossid
    ) internal returns (uint256 newNFTid) {
        Reward memory newReward = Reward({
            name: "World Of Ledger. Reward for boss defeated.",
            damageMade: damage,
            rewardReceived: reward,
            bossID: bossid
        });
        _tokenIds.increment();
        newNFTid = _tokenIds.current();
        NFTidToReward[newNFTid] = newReward;
        return newNFTid;
    }

    /**
        @dev adds user allowance to mapping userToNFTAllowed and it ID
        @param damage made by the user to the boss
        @param reward got by user killing the boss
        @param bossid that was killed
        @notice internal function
    */
    function addAllowanceToUser(
        address user,
        uint256 damage,
        uint256 reward,
        uint256 bossid
    ) internal {
        uint256 rewardId = createReward(damage, reward, bossid);
        userToNFTAllowed[user].push(rewardId);
    }

    /**
        @dev called when user calls mintRewardNFT function. Loop through user available rewards and mint them 
        @notice internal function
    */
    function _mintReward(address minter) internal {
        for (uint256 i = 0; i < userToNFTAllowed[minter].length; i++) {
            uint256 NFTid = userToNFTAllowed[minter][i];
            _safeMint(minter, NFTid);
        }
        delete userToNFTAllowed[minter];
    }
}
