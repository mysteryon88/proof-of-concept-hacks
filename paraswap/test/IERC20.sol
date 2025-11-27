// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function decimals() external view returns (uint256);
}
