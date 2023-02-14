pragma solidity 0.8.18;

import "forge-std/Test.sol";
import {Kokoro, Souls, InvalidSummonData} from "src/token/Souls.sol";

contract SoulsTest is Test {
    Souls c;
    Kokoro internal validMint;
    address internal owner;
    address internal alice;
    address internal bob;

    function assertMintsEqual(Kokoro memory m1, Kokoro memory m2) internal {
        assertEq(m1.agi, m2.agi);
        assertEq(m1.cha, m2.cha);
        assertEq(m1.con, m2.con);
        assertEq(m1.dex, m2.dex);
        assertEq(m1.it, m2.it);
        assertEq(m1.str, m2.str);
        assertEq(m1.wis, m2.wis);
        assertEq(m1.gen, m2.gen);
    }

    function setUp() public {
        c = new Souls(msg.sender);
        owner = msg.sender;
        validMint = Kokoro(2, 3, 4, 5, 6, 7, 8, 0);
        alice = vm.addr(0xA11CE); // private key - returns address
        bob = vm.addr(0xB0B);
    }

    function testSummonByOwnerToAlice() public {
        uint256 tokenId = 1;
        c.summon(alice, tokenId, validMint);
        Kokoro memory minted = c.soul(tokenId);
        assertMintsEqual(minted, validMint);
    }

    function testFail_InvalidSummonData() public {
        uint256 tokenId = 1;
        c.summon(alice, tokenId, Kokoro(0, 1, 2, 3, 4, 5, 6, 0));
    }

    function testFail_InvalidMinter() public {
        uint256 tokenId = 1;
        vm.prank(alice, alice); // Sets msg.sender, tx.origin to the specified address for the next call.
        c.summon(alice, tokenId, validMint);
    }

    function testFail_DuplicateTokenId() public {
        uint256 tokenId = 1;
        c.summon(alice, tokenId, validMint);
        c.summon(alice, tokenId, validMint);
    }
}
