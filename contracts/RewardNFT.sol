// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

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

    function createReward(
        uint256 damage,
        uint256 reward,
        uint256 id
    ) internal returns (uint256 newNFTid) {
        Reward memory newReward = Reward({
            name: "World Of Ledger. Reward for boss defeated.",
            damageMade: damage,
            rewardReceived: reward,
            bossID: id
        });
        newNFTid = _tokenIds.current();
        NFTidToReward[newNFTid] = newReward;
        _tokenIds.increment();
        return newNFTid;
    }

    function addAllowanceToUser(
        address user,
        uint256 damage,
        uint256 reward,
        uint256 id
    ) internal {
        uint256 rewardId = createReward(damage, reward, id);
        userToNFTAllowed[user].push(rewardId);
    }

    function _mintReward(address minter) internal {
        for (uint256 i = 0; i < userToNFTAllowed[minter].length; i++) {
            uint256 NFTid = userToNFTAllowed[minter][i];
            _safeMint(minter, NFTid);
        }
        delete userToNFTAllowed[minter];
    }
}
