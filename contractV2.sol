// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract offlinePaymentProtocol {
    // TODO: implement the signature verification logic
    function getAccountBalance(address account) public view returns (uint256) {
        return account.balance;
    }
}
