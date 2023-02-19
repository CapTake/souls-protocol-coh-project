// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "src/team/Splitter.sol";
import "src/team/Summoner.sol";
import "src/token/Souls.sol";

contract DeployScript is Script {
    uint256[] public shares = [500, 500];
    address[] public payees;
    uint256 private price = 5 ether;
    uint256 private bonding = 3 ether;
    uint256 private epochSize = 100;
    uint8 private perWallet = 10;
    uint16 private totalSupply = 2500;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("MAINNET_PRIVATE_KEY");

        address payee1 = vm.envAddress("PAYEE1");
        require(payee1 != address(0), "Payee1 address not found");
        address payee2 = vm.envAddress("PAYEE2");
        require(payee2 != address(0), "Payee2 address not found");

        payees.push(payee1);
        payees.push(payee2);

        vm.startBroadcast(deployerPrivateKey);

        Splitter treasury = new Splitter(payees, shares);

        Souls nft = new Souls(address(treasury));

        Summoner summoner = new Summoner(epochSize, perWallet, totalSupply, payable(treasury), nft);

        summoner.setPricing(price, bonding);

        summoner.setPause(true);

        nft.addMinter(address(summoner));

        vm.stopBroadcast();
    }
}
