//
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import {Kokoro, Souls, InvalidSummonData} from "src/token/Souls.sol";
import "src/team/Summoner.sol";
import "src/team/Splitter.sol";

contract SummonerTest is Test {
    Souls c;
    Summoner s;
    Splitter t;
    Kokoro internal validMint;
    address internal owner;
    address internal alice;
    address internal bob;
    address internal trevor;

    uint256 internal price = 3 ether;
    uint256 internal bonding = 1 ether;
    uint256 internal epochSize = 5;
    uint8 internal perWallet = 10;
    uint16 internal totalSupply = 20;
    uint256[] public shares = [100];
    address[] public payees;

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
        owner = msg.sender;
        validMint = Kokoro(2, 3, 4, 5, 6, 5, 10, 0);
        alice = vm.addr(0xA11CE); // private key - returns address
        bob = vm.addr(0xB0B);
        payees.push(bob);
        t = new Splitter(payees, shares);
        trevor = address(t);
        c = new Souls(trevor);
        s = new Summoner(epochSize, perWallet, totalSupply, payable(trevor), c);
        s.setPricing(price, bonding);
        s.setPause(true);

        c.addMinter(address(s));
    }

    function testSummonByAlice() public {
        uint256 tokenId = 1;
        s.setPause(false);
        vm.deal(alice, (price * 10));
        vm.prank(alice);
        s.summon{value: price}(
            validMint.agi, validMint.cha, validMint.con, validMint.dex, validMint.it, validMint.str, validMint.wis
        );
        Kokoro memory minted = c.soul(tokenId);
        assertMintsEqual(minted, validMint);
        assertEq(c.balanceOf(alice), 1);
        assertEq(c.ownerOf(tokenId), alice);
        uint256 bobOldBalance = bob.balance;
        t.release(payable(bob));
        assertEq(bob.balance, bobOldBalance + price);
    }

    function testFailSummonPausedByAlice() public {
        vm.deal(alice, (price * 10));
        vm.prank(alice);
        s.summon{value: price}(
            validMint.agi, validMint.cha, validMint.con, validMint.dex, validMint.it, validMint.str, validMint.wis
        );
    }

    function testSummonMultipleByAlice() public {
        Kokoro memory customMint = Kokoro(2, 2, 2, 2, 2, 2, 2, 0);
        Kokoro memory minted;
        s.setPause(false);
        vm.deal(alice, (price * 10));
        vm.startPrank(alice);
        s.summon{value: price}(
            customMint.agi,
            customMint.cha,
            customMint.con,
            customMint.dex,
            customMint.it,
            customMint.str,
            customMint.wis
        );
        customMint.agi++;
        s.summon{value: price}(
            customMint.agi,
            customMint.cha,
            customMint.con,
            customMint.dex,
            customMint.it,
            customMint.str,
            customMint.wis
        );
        customMint.agi++;
        s.summon{value: price}(
            customMint.agi,
            customMint.cha,
            customMint.con,
            customMint.dex,
            customMint.it,
            customMint.str,
            customMint.wis
        );
        vm.stopPrank();
        customMint.agi = 2;
        minted = c.soul(1);
        assertMintsEqual(minted, customMint);
        customMint.agi++;
        minted = c.soul(2);
        assertMintsEqual(minted, customMint);
        customMint.agi++;
        minted = c.soul(3);
        assertMintsEqual(minted, customMint);
        assertEq(c.balanceOf(alice), 3);
        assertEq(s.summoned(), 3);
        assertEq(trevor.balance, price * 3);
    }

    function testChangeEpoch() public {
        Kokoro memory customMint = Kokoro(2, 2, 2, 2, 2, 2, 2, 0);
        s.setPause(false);
        vm.deal(alice, (price * 10));
        vm.startPrank(alice);
        uint256 prevEpoch = s.epoch();
        assertEq(s.epoch(), 0);
        for (uint256 i = 0; i < epochSize; i++) {
            s.summon{value: price}(
                customMint.agi,
                customMint.cha,
                customMint.con,
                customMint.dex,
                customMint.it,
                customMint.str,
                customMint.wis
            );
        }
        // console.log("%s", s.epoch()); // doesn't show up in console
        // console.log("%s", s.price());
        assertEq(s.epoch() - prevEpoch, 1);
        assertEq(s.price(), price + bonding);
        vm.stopPrank();
    }

    function testFailMintOverWalletLimit() public {
        Kokoro memory customMint = Kokoro(2, 2, 2, 2, 2, 2, 2, 0);
        s.setPause(false);
        vm.deal(alice, price * perWallet * 2);
        vm.startPrank(alice);
        uint256 _price;
        for (uint256 i = 0; i < perWallet + 1; i++) {
            _price = s.price();
            s.summon{value: _price}(
                customMint.agi,
                customMint.cha,
                customMint.con,
                customMint.dex,
                customMint.it,
                customMint.str,
                customMint.wis
            );
        }
        vm.stopPrank();
    }

    function testFailInsufficientFunds() public {
        s.setPause(false);
        vm.prank(alice);
        s.summon(validMint.agi, validMint.cha, validMint.con, validMint.dex, validMint.it, validMint.str, validMint.wis);
    }

    function testFailInvalidTraitValue() public {
        Kokoro memory customMint = Kokoro(2, 2, 2, 2, 2, 2, 11, 0);
        s.setPause(false);
        vm.prank(alice);
        s.summon(
            customMint.agi,
            customMint.cha,
            customMint.con,
            customMint.dex,
            customMint.it,
            customMint.str,
            customMint.wis
        );
    }

    function testFailInvalidCumulativeValue() public {
        Kokoro memory customMint = Kokoro(2, 2, 10, 10, 10, 2, 10, 0);
        s.setPause(false);
        vm.prank(alice);
        s.summon(
            customMint.agi,
            customMint.cha,
            customMint.con,
            customMint.dex,
            customMint.it,
            customMint.str,
            customMint.wis
        );
    }
}
