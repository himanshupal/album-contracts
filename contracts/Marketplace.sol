// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is ERC721Enumerable, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    string private __baseURI;
    mapping(address => EnumerableSet.UintSet) private __userTokens;
    mapping(uint256 => string) private __tokenHashForId;
    mapping(string => uint256) private __tokenIdForHash;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) ERC721(name_, symbol_) {
        require(bytes(baseURI_).length >= 5, "Marketplace: invalid baseURI length");
        __baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override {
        __userTokens[ownerOf(_tokenId)].remove(_tokenId);
        __userTokens[_to].add(_tokenId);

        super._transfer(_from, _to, _tokenId);
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        require(bytes(baseURI_).length >= 5, "Marketplace: invalid baseURI length");
        __baseURI = baseURI_;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireMinted(_tokenId);
        return string(abi.encodePacked(_baseURI(), "/", __tokenHashForId[_tokenId]));
    }

    function tokenId(string memory _tokenHash) public view returns (uint256) {
        uint256 tokenId_ = __tokenIdForHash[_tokenHash];
        _requireMinted(tokenId_);
        return tokenId_;
    }

    function mint(address _to, string memory _ipfsHash) external {
        require(__tokenIdForHash[_ipfsHash] == 0, "Marketplace: same hash data exists");
        uint256 tokenId_ = totalSupply() + 1;

        __tokenIdForHash[_ipfsHash] = tokenId_;
        __tokenHashForId[tokenId_] = _ipfsHash;

        __userTokens[_to].add(tokenId_);

        super._mint(_to, tokenId_);
    }

    function burn(uint256 _tokenId) external {
        _isApprovedOrOwner(_msgSender(), _tokenId);
        _requireMinted(_tokenId);
        delete __tokenIdForHash[__tokenHashForId[_tokenId]];
        delete __tokenHashForId[_tokenId];

        address tokenOwner_ = ownerOf(_tokenId);
        __userTokens[tokenOwner_].remove(_tokenId);

        super._burn(_tokenId);
    }

    function userTokens(address _user) external view returns (uint256[] memory) {
        return __userTokens[_user].values();
    }

    function userTokensCount(address _user) external view returns (uint256) {
        return __userTokens[_user].length();
    }
}
