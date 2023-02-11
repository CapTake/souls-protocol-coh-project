// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../game/SoulGame.sol';

contract GamePOC is SoulGame, Ownable {

    constructor(ISouls _souls) SoulGame(_souls) {

    }
}