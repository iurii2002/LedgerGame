// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFTInterface {
    function tokenURI(uint256 Id) external view returns (string memory);

    function totalSupply() external view returns (uint256);
}
