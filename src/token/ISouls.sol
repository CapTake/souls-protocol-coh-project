//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

struct Kokoro {
    uint8 agi; // Agility
    uint8 cha; // Charisma
    uint8 con; // Constitution
    uint8 dex; // Dexterity
    uint8 it; // Intelligence
    uint8 str; // Strength
    uint8 wis; // Wisdom
    uint8 gen; // generation
}

/**
 * @title Soul NFT - core traits of onchain game characters
 * @author Boris Grit
 */
interface ISouls is IERC721 {
    /**
     * @dev Used for minting of the 'Soul' NFT containing core traits of game character.
     * These traits are 'factory default settings' upon actual character creation in game
     * contract.
     * @param _to address of the NFT receiver.
     * @param _tokenId the id of NFT minted.
     * @param _soul - struct containing core traits.
     * @notice Summoner is responsible for consistency and fitness of provided traits.
     * Throws if caller has no rights to mint or any of provided traits has 0 value.
     */
    function summon(address _to, uint256 _tokenId, Kokoro calldata _soul) external;

    /**
     * @dev Meant to be used by game contract for reading core traits of 'Soul'
     * in response of user action.
     * @param _tokenId the id of NFT.
     * @notice Throws if NFT not exists.
     */
    function soul(uint256 _tokenId) external view returns (Kokoro memory);
}
