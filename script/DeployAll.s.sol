// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "src/team/Splitter.sol";
import "src/team/Summoner.sol";
import "src/token/Souls.sol";

contract DeployScript is Script {
    uint256[] public shares = [100];
    address[] public payees;
    uint256 private price = 5 ether;
    uint256 private bonding = 2 ether;
    uint256 private epochSize = 100;
    uint8 private perWallet = 10;
    uint256 private totalSupply = 2500;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("TEST_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Splitter treasury = new Splitter(payees, shares);

        Souls nft = new Souls(address(treasury));

        Summoner summoner = new Summoner(price, epochSize, bonding, perWallet, totalSupply, payable(treasury), nft);

        nft.addMinter(address(summoner));

        vm.stopBroadcast();
    }
}
