// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MarketPlace is ERC721Enumerable, Ownable {
    string private __baseURI;
    mapping(uint256 => string) private __tokenHashForId;
    mapping(string => uint256) private __tokenIdForHash;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) ERC721(name_, symbol_) {
        require(bytes(baseURI_).length >= 5, "MarketPlace: invalid baseURI length");
        __baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        __baseURI = baseURI_;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireMinted(_tokenId);
        return string(abi.encodePacked(_baseURI(), "/", __tokenHashForId[_tokenId]));
    }

    function tokenId(string memory tokenHash) public view returns (uint256) {
        uint256 tokenId_ = __tokenIdForHash[tokenHash];
        _requireMinted(tokenId_);
        return tokenId_;
    }

    function mint(address _to, string memory _ipfsHash) external {
        require(__tokenIdForHash[_ipfsHash] == 0, "MarketPlace: same hash data exists");
        uint256 tokenId_ = totalSupply() + 1;

        __tokenIdForHash[_ipfsHash] = tokenId_;
        __tokenHashForId[tokenId_] = _ipfsHash;

        super._mint(_to, tokenId_);
    }

    function burn(uint256 _tokenId) external {
        _requireMinted(_tokenId);
        delete __tokenIdForHash[__tokenHashForId[_tokenId]];
        delete __tokenHashForId[_tokenId];
        super._burn(_tokenId);
    }

    function burn(string memory _tokenHash) external {
        uint256 tokenId_ = __tokenIdForHash[_tokenHash];
        _requireMinted(tokenId_);
        delete __tokenHashForId[tokenId_];
        delete __tokenIdForHash[_tokenHash];
        super._burn(tokenId_);
    }
}
