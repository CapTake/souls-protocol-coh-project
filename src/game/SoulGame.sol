// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Context.sol";
import "../token/ISouls.sol";

/**
 * @title Soul Game - module for interacting with the Soul NFT contract.
 * @author Boris Grit
 * This module is used through inheritance. It will make available the modifier
 * `onlyNFTOwner`, which can be applied to your functions to restrict their use to
 * the owner of Soul NFT. Use this as base for your on chain game;
 */
abstract contract SoulGame is Context {
    ISouls private _limbo;

    uint64 private _incarnates;

    mapping(uint256 => Kokoro) private _existence;

    event SoulReIncarnated(address indexed owner, uint256 indexed id);

    error NotIncarnated();

    error IncarnatedAlready();

    error NotTheOwner();

    /**
     * @dev store the address of the ISouls implementation.
     * @param _souls implementation of ISouls
     */
    constructor(ISouls _souls) {
        _limbo = _souls;
    }

    /**
     * @dev Throws if called by any account other than the Soul NFT owner.
     * @param _soulId The ID of the Soul NFT
     */
    modifier onlyNFTOwner(uint256 _soulId) {
        _checkNFTOwnership(_soulId);
        _;
    }

    /**
     * @dev Throws if Soul incarnate not exists in the game.
     * @param _soulId The ID of the Soul NFT
     */
    modifier mustExist(uint256 _soulId) {
        if (!_exists(_soulId)) revert NotIncarnated();
        _;
    }

    /**
     * @dev Throws if the sender is not the Soul NFT owner.
     * @param _soulId The ID of the Soul NFT
     */
    function _checkNFTOwnership(uint256 _soulId) internal view virtual {
        if (_limbo.ownerOf(uint256(_soulId)) != _msgSender()) revert NotTheOwner();
    }

    /**
     * @param _soulId The ID of the Soul NFT
     * @return bool indicating if Soul has been imported in game
     */
    function _exists(uint256 _soulId) internal view virtual returns (bool) {
        Kokoro storage soul = _existence[_soulId];

        return soul.agi > 0;
    }

    /**
     * @dev Copies core traits from Soul NFT in game. Overwrites previous value.
     * @param _soulId The ID of the Soul NFT
     */
    function _reset(uint256 _soulId) private {
        Kokoro memory soul = _limbo.soul(_soulId);

        _beforeIncarnate(soul);

        _existence[_soulId] = soul;

        _afterIncarnate(_soulId, soul);

        emit SoulReIncarnated(_msgSender(), _soulId);
    }

    /**
     * @param _soulId The ID of the Soul NFT
     * @return struct Kokoro containing core traits
     */
    function _coreTraits(uint256 _soulId) internal view virtual mustExist(_soulId) returns (Kokoro memory) {
        return _existence[_soulId];
    }

    /**
     * @dev Modifies the AGI of character. Use this for in game character progress.
     * @param _soulId The ID of the Soul NFT.
     * @param _new new value overwrites the old one.
     */
    function _updateAgility(uint256 _soulId, uint8 _new) internal virtual mustExist(_soulId) {
        Kokoro storage core = _existence[_soulId];
        core.agi = _new;
    }

    /**
     * @dev Modifies the CHA of character. Use this for in game character progress.
     * @param _soulId The ID of the Soul NFT.
     * @param _new new value overwrites the old one.
     */
    function _updateCharisma(uint256 _soulId, uint8 _new) internal virtual mustExist(_soulId) {
        Kokoro storage core = _existence[_soulId];
        core.cha = _new;
    }

    /**
     * @dev Modifies the CON of character. Use this for in game character progress.
     * @param _soulId The ID of the Soul NFT.
     * @param _new new value overwrites the old one.
     */
    function _updateConstitution(uint256 _soulId, uint8 _new) internal virtual mustExist(_soulId) {
        Kokoro storage core = _existence[_soulId];
        core.con = _new;
    }

    /**
     * @dev Modifies the DEX of character. Use this for in game character progress.
     * @param _soulId The ID of the Soul NFT.
     * @param _new new value overwrites the old one.
     */
    function _updateDexterity(uint256 _soulId, uint8 _new) internal virtual mustExist(_soulId) {
        Kokoro storage core = _existence[_soulId];
        core.dex = _new;
    }

    /**
     * @dev Modifies the INT of character. Use this for in game character progress.
     * @param _soulId The ID of the Soul NFT.
     * @param _new new value overwrites the old one.
     */
    function _updateIntelligence(uint256 _soulId, uint8 _new) internal virtual mustExist(_soulId) {
        Kokoro storage core = _existence[_soulId];
        core.it = _new;
    }

    /**
     * @dev Modifies the STR of character. Use this for in game character progress.
     * @param _soulId The ID of the Soul NFT.
     * @param _new new value overwrites the old one.
     */
    function _updateStrength(uint256 _soulId, uint8 _new) internal virtual mustExist(_soulId) {
        Kokoro storage core = _existence[_soulId];
        core.str = _new;
    }

    /**
     * @dev Modifies the WIS of character. Use this for in game character progress.
     * @param _soulId The ID of the Soul NFT.
     * @param _new new value overwrites the old one.
     */
    function _updateWisdom(uint256 _soulId, uint8 _new) internal virtual mustExist(_soulId) {
        Kokoro storage core = _existence[_soulId];
        core.wis = _new;
    }

    /**
     * @return uint64 number of unique Souls incarnated (Soul NFTs joined this game)
     */
    function incarnates() external view returns (uint64) {
        return _incarnates;
    }

    /**
     * @param _soulId The ID of the Soul NFT.
     * @return bool true if Soul exists in this game
     */
    function exists(uint256 _soulId) external view virtual returns (bool) {
        return _exists(_soulId);
    }

    /**
     * @param _soulId The ID of the Soul NFT.
     * @return struct Kokoro with current in game progress
     */
    function progress(uint256 _soulId) external view virtual returns (Kokoro memory) {
        return _coreTraits(_soulId);
    }

    /**
     * @dev Hook that is called before Soul incarnation in game. It meant to be used for the
     * various traits fitness for the game checks. Revert if needed.
     * @param _soul Kokoro struct with the core traits.
     */
    function _beforeIncarnate(Kokoro memory _soul) internal virtual {}

    /**
     * @dev Hook that is called before Soul incarnation in game. Use it to set things up when
     * player joined or resetted their game stats. Revert if needed.
     * @param _soulId The ID of the Soul NFT.
     * @param _soul Kokoro struct with the core traits.
     */
    function _afterIncarnate(uint256 _soulId, Kokoro memory _soul) internal virtual {}

    /**
     * @dev This is where player joins the game. Copies core traits of Soul NFT in game contract
     * Can only be called by the current NFT owner.
     * @param _soulId The ID of the Soul NFT.
     * @notice If Incarnated before will throw an error.
     */
    function incarnate(uint256 _soulId) external virtual onlyNFTOwner(_soulId) {
        if (_exists(_soulId)) revert IncarnatedAlready();
        _incarnates++;
        _reset(_soulId);
    }

    /**
     * @dev Called by the player willing to reset their game progress. Resets core traits of Soul NFT in game contract
     * Can only be called by the current NFT owner.
     * @param _soulId The ID of the Soul NFT.
     * @notice If not incarnated before will throw an error.
     */
    function resetProgress(uint256 _soulId) external virtual mustExist(_soulId) onlyNFTOwner(_soulId) {
        _reset(_soulId);
    }
}
