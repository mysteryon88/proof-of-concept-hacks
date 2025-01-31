// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Wallet {
    fallback() external payable {
        payable(msg.sender).transfer(address(this).balance);
    }
}
