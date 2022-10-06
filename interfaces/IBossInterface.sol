// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBossInterface {
    function tokenURI(uint256 berdieId) external view returns (string memory);

    function totalSupply() external view returns (uint256);
}
