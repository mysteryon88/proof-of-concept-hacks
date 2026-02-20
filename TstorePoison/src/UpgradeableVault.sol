// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

contract UpgradeableVault {
    // ======== persistent storage ========
    address internal _owner; // slot 0
    uint256 internal _totalDeposits; // slot 1
    mapping(uint256 => address) _nftApprovals; // slot 2 base
    mapping(address => uint256) _balances; // slot 3 base

    // ======== transient storage ========
    address internal transient _txSender; // tslot 0

    // this will be attacked
    function initialize(address owner_) external {
        require(_owner == address(0), "already initialized");
        _owner = owner_;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "owner");
        _;
    }

    function withdrawAll(address to) external onlyOwner {
        uint256 bal = address(this).balance;
        (bool ok,) = to.call{value: bal}("");
        require(ok);
    }

    // selector: 0x095ea7b3
    function approve(address spender, uint256 id) external {
        _nftApprovals[id] = spender;
    }

    // selector: 0x23b872dd
    // Contains first "delete address" in the contract
    // This caches storage_set_to_zero_t_address with sstore
    function transferFrom(address from, address, uint256 id) public {
        require(msg.sender == from || msg.sender == _nftApprovals[id], "unauthorized");
        // ... transfer logic ...
        delete _nftApprovals[id]; // persistent delete address - CACHED FIRST
    }

    modifier senderGuard() {
        require(_txSender == address(0), "reentrant");
        _txSender = msg.sender;
        _;
        delete _txSender; // transient delete address reuses sstore
        // this zeroes the address-sized portion of persistent slot 0 = _owner
    }

    // selector higher than transferFrom
    function deposit() external payable senderGuard {
        _balances[msg.sender] += msg.value;
        _totalDeposits += msg.value;
    }

    function balanceOf(address user) external view returns (uint256) {
        return _balances[user];
    }

    // helper (can be omitted)
    function readTransient(bytes32 slot) external view returns (bytes32 result) {
        assembly { result := tload(slot) }
    }

    receive() external payable {}
}
