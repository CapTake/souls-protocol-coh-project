//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../token/ISouls.sol";

/**
 * @title Summoner contract - genesis Soul NFT mint.
 * @author Boris Grit
 * @notice Implements minting logics:
 * Users can specify 7 core traits of their Soul NFT:
 * Agility, Charisma, Constitution, Dexterity, Intelligence, Strength, Wisdom.
 * Each trait is assigned with certain number of points in 2 - 10 range.
 * Total number of points is limited to 35 to make distribution between traits
 * challenging yet rewarding.
 * Cost of summon increases with every Epoch (certain number of mints),
 * thus awarding early adopters.
 */
contract Summoner is ReentrancyGuard, Ownable {
    using Address for address payable;
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    ISouls private _token;

    uint8 private constant MAX_CORE_CUMULATIVE_POINTS = 35;
    uint8 private constant MIN_CORE_TRAIT_POINTS = 2;
    uint8 private constant MAX_CORE_TRAIT_POINTS = 10;

    mapping(address => uint8) private _minters;

    Counters.Counter private _tokenIdCounter;

    address payable public treasury;

    uint256 public price = 5 ether;

    uint256 public epoch;

    uint256 public epochSize = 100;

    uint256 public bondingFactor = 2 ether;

    uint8 public perWalletLimit = 10;

    /**
     * Event for soul summon logging
     * @param summoner who paid for the tokens
     * @param value weis paid for purchase
     * @param id id of the token minted
     */
    event SoulSummoned(address indexed summoner, uint256 value, uint256 id);

    /**
     * @param _price price per summon
     * @param _epochSize size of the 'epoch' after each epoch there is a price increase by
     * @param _bondingFactor amount of Canto to add to price
     * @param _treasury Address where collected funds will be forwarded to
     * @param _nft Address of the token being sold
     */
    constructor(uint256 _price, uint256 _epochSize, uint256 _bondingFactor, address payable _treasury, ISouls _nft) {
        require(_price > 0, "Summoner: price is 0");
        require(_epochSize > 0, "Summoner: epoch is 0");
        require(_treasury != address(0), "Summoner: treasury is the zero address");
        require(address(_nft) != address(0), "Summoner: token is the zero address");

        epoch = 0;

        price = _price;
        bondingFactor = _bondingFactor;
        epochSize = _epochSize;
        treasury = _treasury;
        _token = _nft;
    }

    function setTreasury(address payable _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function summoned() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     */
    function summon(uint8 _agi, uint8 _cha, uint8 _con, uint8 _dex, uint8 _int, uint8 _str, uint8 _wis)
        external
        payable
        nonReentrant
    {
        if (msg.sender != owner()) {
            uint8 minted = _minters[msg.sender];
            require(msg.value >= price, "Summoner: insufficient funds");
            require(minted < perWalletLimit, "Summoner: wallet mint limit reached");
            _minters[msg.sender] = minted + 1;
        }

        uint16 cumulative = _agi + _cha + _con + _dex + _int + _str + _wis;

        require(cumulative <= MAX_CORE_CUMULATIVE_POINTS, "Summoner: MAX points allocation exceeded");
        require(_agi <= MAX_CORE_TRAIT_POINTS && _agi >= MIN_CORE_TRAIT_POINTS, "Summoner: AGI is out of range");
        require(_cha <= MAX_CORE_TRAIT_POINTS && _cha >= MIN_CORE_TRAIT_POINTS, "Summoner: CHA is out of range");
        require(_con <= MAX_CORE_TRAIT_POINTS && _con >= MIN_CORE_TRAIT_POINTS, "Summoner: CON is out of range");
        require(_dex <= MAX_CORE_TRAIT_POINTS && _dex >= MIN_CORE_TRAIT_POINTS, "Summoner: DEX is out of range");
        require(_int <= MAX_CORE_TRAIT_POINTS && _int >= MIN_CORE_TRAIT_POINTS, "Summoner: INT is out of range");
        require(_str <= MAX_CORE_TRAIT_POINTS && _str >= MIN_CORE_TRAIT_POINTS, "Summoner: STR is out of range");
        require(_wis <= MAX_CORE_TRAIT_POINTS && _wis >= MIN_CORE_TRAIT_POINTS, "Summoner: WIS is out of range");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current(); // tokenIds started from 1

        // Encrease the price at the start of new epoch
        if (_tokenIdCounter.current() % epochSize == 0) {
            epoch.add(1);
            price.add(bondingFactor);
        }

        Kokoro memory _soul = Kokoro(_agi, _cha, _con, _dex, _int, _str, _wis, 0);

        _token.summon(msg.sender, tokenId, _soul);

        emit SoulSummoned(msg.sender, msg.value, tokenId);

        treasury.sendValue(msg.value);
    }
}
