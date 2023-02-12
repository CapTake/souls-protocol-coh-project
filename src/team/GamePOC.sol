// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../game/SoulGame.sol";

struct CharacterStats {
    uint8 level;
    uint16 hp;
    uint16 mp;
    uint16 fp;
    uint16 speed;
    uint16 dodge;
    uint16 parryL;
    uint16 parryH;
    uint16 dfm;
    uint16 atm;
    uint8 up;
    uint64 money;
    uint64 xp;
    uint64 timestamp;
}

contract IdleHeroesGamePOC is SoulGame, Ownable {
    mapping(uint256 => CharacterStats) private _heroes;

    constructor(ISouls _souls) SoulGame(_souls) {}

    function _afterIncarnate(uint256 _soulId, Kokoro memory _soul) internal override {
        uint8 athletics = _soul.agi + _soul.con;
        _heroes[_soulId] = CharacterStats({
            level: 1,
            hp: _soul.con * 2,
            mp: _soul.it * _soul.wis,
            fp: _soul.con + _soul.str,
            speed: athletics / 2,
            dodge: athletics,
            parryL: (_soul.agi + _soul.dex) / 2, // fighting light / 2
            parryH: (_soul.agi + _soul.dex) / 2, // fighting heavy / 2
            dfm: 0,
            atm: 0,
            up: 0,
            money: 0,
            xp: 0,
            timestamp: uint64(block.timestamp)
        });
    }
}
