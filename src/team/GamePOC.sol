// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../game/SoulGame.sol";

struct HeroState {
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
    uint16 up; // upgrade points
    uint16 upSpent; // how many upgrade points were spent
    uint64 money;
    uint64 xp;
    Kokoro core;
    uint64 timestamp;
}

/**
 * @dev This is work in progress, just started a POC game contract, as an example of how to use
 * SoulGame contract as a foundation. Nothing is works yet, but I hope to make it some day soon.
 */
contract IdleHeroesGamePOC is SoulGame, Ownable {
    mapping(uint256 => HeroState) private _heroes;

    event HeroProgressed(uint256 indexed soulId, Kokoro coreTraits);

    constructor(ISouls _souls) SoulGame(_souls) {}

    function _afterIncarnate(uint256 _soulId, Kokoro storage _soul) internal override {
        uint8 athletics = _soul.agi + _soul.con;
        _heroes[_soulId] = HeroState({
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
            upSpent: 0,
            money: 0,
            xp: 0,
            core: _soul,
            timestamp: uint64(block.timestamp)
        });
    }

    function levelUp(
        uint256 _id,
        uint8 _level, // user have to supply actual level everytime
        uint8 _agiup,
        uint8 _chaup,
        uint8 _conup,
        uint8 _dexup,
        uint8 _itup,
        uint8 _strup,
        uint8 _wisup
    ) external onlyNFTOwner(_id) {
        // no point in limiting access to owner here, just needed an example
        HeroState storage hero = _heroes[_id];
        // TODO: recalculate xp points regarding time spent on current quest
        // maximum level is 255
        if (hero.level < 255) {
            uint64 levelxp = 256 * _level * _level;

            uint64 nextlevelxp = 256 * (_level + 1) * (_level + 1);

            require(hero.xp >= levelxp && hero.xp < nextlevelxp, "Invalid level");

            hero.level = _level;

            hero.up = _level >> 2; // upgrade point added every 4 levels
        }
        hero.upSpent += (_agiup + _chaup + _conup + _dexup + _itup + _strup + _wisup);
        require(hero.up >= hero.upSpent, "Upgrade is out of range");
        hero.core.agi += _agiup;
        hero.core.cha += _chaup;
        hero.core.con += _conup;
        hero.core.dex += _dexup;
        hero.core.it += _itup;
        hero.core.str += _strup;
        hero.core.wis += _wisup;
        emit HeroProgressed(_id, hero.core);
    }
}
