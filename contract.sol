// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ECDSALib {
    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`.
     * This replicates the behavior of the eth_sign JSON-RPC method.
     */
    function toEthSignedMessageHash(
        bytes32 hash
    ) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

contract OfflinePaymentProtocol {
    // Mapping of user address to on-chain balance.
    mapping(address => uint256) public balances;
    // Mapping of nonces to prevent replay attacks (per user).
    mapping(address => uint256) public nonces;

    // Events for logging key actions.
    event Deposit(address indexed account, uint256 amount);
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 timestamp,
        uint256 nonce
    );
    event Reconcile(address indexed account, uint256 balance);
    event Logout(address indexed account, uint256 amount);

    /**
     * @notice Deposits ETH into the sender's account.
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Transfers funds from the sender to another address.
     * @dev The function expects an "offline transaction" to be submitted:
     *      The sender signs a message containing (from, to, amount, timestamp, nonce).
     *      The contract recovers the signer using ecrecover and verifies the signature.
     *
     * @param to The recipient's address.
     * @param amount The amount to transfer.
     * @param timestamp The timestamp when the offline transaction was created.
     * @param nonce A sequential number to avoid replay attacks.
     * @param v The recovery byte of the signature.
     * @param r Half of the ECDSA signature pair.
     * @param s Half of the ECDSA signature pair.
     */
    function transfer(
        address to,
        uint256 amount,
        uint256 timestamp,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Check that the nonce is exactly one more than the stored nonce.
        require(nonce == nonces[msg.sender] + 1, "Invalid nonce");

        // Check sufficient balance.
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Ensure the offline transaction is timely (adjust time window as needed).
        require(block.timestamp >= timestamp, "Invalid timestamp");
        require(block.timestamp - timestamp < 5 minutes, "Transaction expired");

        // Reconstruct the message that should have been signed offline.
        bytes32 messageHash = keccak256(
            abi.encodePacked(msg.sender, to, amount, timestamp, nonce)
        );
        bytes32 ethSignedMessageHash = ECDSALib.toEthSignedMessageHash(
            messageHash
        );

        // Recover the signer and verify that it matches the sender.
        address recoveredSigner = ecrecover(ethSignedMessageHash, v, r, s);
        require(recoveredSigner == msg.sender, "Invalid signature");

        // Update the nonce.
        nonces[msg.sender] = nonce;
        // Perform the transfer.
        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount, timestamp, nonce);
    }

    /**
     * @notice Returns the on-chain balance of the sender.
     */
    function reconcile() external view returns (uint256) {
        return balances[msg.sender];
    }

    /**
     * @notice Logs out the user by withdrawing their entire balance.
     * @dev In a full protocol, additional state cleanup might be required.
     */
    function logout() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");

        // Reset state.
        balances[msg.sender] = 0;
        nonces[msg.sender] = 0;

        // Transfer the funds back to the sender.
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Logout(msg.sender, amount);
    }

    // Fallback function to accept ETH.
    receive() external payable {
        require(msg.value > 0, "Amount must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
}
