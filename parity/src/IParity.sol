// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IParity {
    function isOwner(address _addr) external view returns (bool);

    function kill(address _to) external;

    function execute(address _to, uint256 _value, bytes memory _data) external;

    function initWallet(address[] memory _owners, uint256 _required, uint256 _daylimit) external;
}
