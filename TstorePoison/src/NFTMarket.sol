// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

contract NFTMarket {
    // ======== persistent storage ========
    mapping(uint256 => address) public nftOwner; // slot 0 base
    mapping(uint256 => address) public approvals; // slot 1 base

    // ======== transient storage ========
    address internal transient _cachedCaller; // tslot 0

    // for test setup
    function mint(address to, uint256 id) external {
        require(nftOwner[id] == address(0), "already minted");
        nftOwner[id] = to;
    }

    function approve(address spender, uint256 id) external {
        require(msg.sender == nftOwner[id], "not owner");
        approvals[id] = spender;
    }

    // selector: 0x09c5eabe - lower than transferFrom
    // Contains the first "delete address" in generation order.
    // This caches storage_set_to_zero_t_address with TSTORE.
    function execute(bytes calldata) external {
        require(_cachedCaller == address(0), "reentrant");
        _cachedCaller = msg.sender;

        //  callback logic

        delete _cachedCaller; // transient delete address - CACHED FIRST with tstore
    }

    // selector: 0x23b872dd - higher than execute
    // `delete approvals[id]` reuses the tstore version of storage_set_to_zero_t_address
    function transferFrom(address from, address to, uint256 id) public {
        require(nftOwner[id] == from, "wrong owner");
        require(msg.sender == from || msg.sender == approvals[id], "unauthorized");

        nftOwner[id] = to;
        delete approvals[id];
        // tstore(slot, 0) instead of sstore(slot, 0)
        // approval appears cleared within this tx but persists across transactions.
    }

    // View helpers (can be omitted)
    function getApproval(uint256 id) external view returns (address) {
        return approvals[id];
    }

    function readSlot(bytes32 slot) external view returns (bytes32 result) {
        assembly { result := sload(slot) }
    }

    function readTransient(bytes32 slot) external view returns (bytes32 result) {
        assembly { result := tload(slot) }
    }
}
