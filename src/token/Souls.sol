//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @title Souls - a core contract for blockchain gaming characters
/// @author B. Grit
/// @dev This is first version POC
/// @custom:experimental This is an experimental contract.

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./ISouls.sol";

interface Turnstile {
    function register(address) external returns (uint256);
}

error InvalidSummonData();
error SoulNotExists();

contract Souls is ISouls, ERC721Enumerable, ERC721Royalty, AccessControl, ERC721Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(uint256 => Kokoro) private _souls;

    constructor(address _royalty) ERC721("Hero Souls", "SOUL") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        _setDefaultRoyalty(_royalty, 500);

        // Canto Mainnet Only
        if (block.chainid == 7700) {
            Turnstile _turnstile = Turnstile(0xEcf044C5B4b867CFda001101c617eCd347095B44);
            _turnstile.register(msg.sender);
        }
    }

    function addMinter(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, _account);
    }

    function removeMinter(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, _account);
    }

    function summon(address _to, uint256 _tokenId, Kokoro calldata _soul) external onlyRole(MINTER_ROLE) {
        // We are not interfering with summoner logic here, but envorcing each core trait exists i.e. > 0
        if (
            _soul.agi == 0 || _soul.cha == 0 || _soul.con == 0 || _soul.dex == 0 || _soul.it == 0 || _soul.str == 0
                || _soul.wis == 0
        ) revert InvalidSummonData();

        _souls[_tokenId] = _soul;
        _safeMint(_to, _tokenId);
    }

    function soul(uint256 _tokenId) external view returns (Kokoro memory) {
        if (!_exists(_tokenId)) revert SoulNotExists();

        return _souls[_tokenId];
    }

    function _attributes(Kokoro storage s) internal view returns (string memory) {
        return string.concat(
            '[{"trait_type":"Generation","value":"',
            toString(s.gen),
            '"},',
            '{"trait_type":"Agility","value":"',
            toString(s.agi),
            '"},',
            '{"trait_type":"Charisma","value":"',
            toString(s.cha),
            '"},',
            '{"trait_type":"Constitution","value":"',
            toString(s.con),
            '"},',
            '{"trait_type":"Dexterity","value":"',
            toString(s.dex),
            '"},',
            '{"trait_type":"Intelligence","value":"',
            toString(s.it),
            '"},',
            '{"trait_type":"Strength","value":"',
            toString(s.str),
            '"},',
            '{"trait_type":"Wisdom","value":"',
            toString(s.wis),
            '"}]'
        );
    }

    function _arributeSvg(string memory attrName, uint8 value, uint8 y) internal pure returns (string memory) {
        return string.concat(
            '<g transform="translate(0,',
            toString(y),
            ')">' '<text x="-43" y="16">',
            attrName,
            '</text><rect rx="1" x="0" y="0" height="20" width="192" class="t" /><rect x="2" y="2" height="16" width="190" class="t" />',
            '<rect rx="1" x="2" y="3" height="14" width="',
            toString(19 * value - 3),
            '" class="i">',
            '<animate attributeName="width" begin="0.',
            toString(value),
            's" additive="sum" values="0.3;-0.3;0.6;0.3;0.6;-0.6;0.5;-0.3;0.3" dur="0.5" repeatCount="indefinite" /></rect>',
            '<rect x="2" y="4" height="12" width="190" class="t" /><rect rx="1" x="3" y="6" height="3" width="187" class="s" /></g>'
        );
    }

    function _svgImage(Kokoro storage s) internal view returns (string memory) {
        return string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 280 280"><defs>',
            '<style type="text/css">text {fill:#fe0039;font:bold 16px monospace;paint-order:stroke fill;stroke:rgba(254,0,57,0.3);stroke-width:2px;stroke-linejoin:round;}.t {fill:rgba(255,255,255,0.1)}.i {fill:#fe0039;}.s {fill:#fff}</style></defs>',
            '<rect x="0" y="0" height="280" width="280" fill="#0a1627" /><g transform="translate(65, 45)">',
            _arributeSvg("AGI", s.agi, 0),
            _arributeSvg("CHA", s.cha, 28),
            _arributeSvg("CON", s.con, 56),
            _arributeSvg("DEX", s.dex, 84),
            _arributeSvg("INT", s.it, 112),
            _arributeSvg("STR", s.str, 140),
            _arributeSvg("WIS", s.wis, 168),
            "</g></svg>"
        );
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        Kokoro storage _soul = _souls[tokenId];

        string memory json = Base64.encode(
            bytes(
                string.concat(
                    '{"name":"Hero Soul #',
                    toString(tokenId),
                    '",',
                    '"description":"The Immutable Soul of you game character incarnation. Stored completely on chain. Forever.","image":"data:image/svg+xml;base64,',
                    Base64.encode(bytes(_svgImage(_soul))),
                    '",',
                    '"attributes":',
                    _attributes(_soul),
                    "}"
                )
            )
        );

        return string.concat("data:application/json;base64,", json);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721, ERC721Enumerable, ERC721Royalty, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
