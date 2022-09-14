// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is ERC721Enumerable, Ownable {
    mapping(address => uint256[]) private __userTokens;
    mapping(uint256 => string) private __tokenHashForId;
    mapping(string => uint256) private __tokenIdForHash;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override {
        address tokenOwner_ = ownerOf(_tokenId);
        removeFromList(__userTokens[tokenOwner_], _tokenId);
        __userTokens[_to].push(_tokenId);

        super._transfer(_from, _to, _tokenId);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return __tokenHashForId[_tokenId];
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

        __userTokens[_to].push(tokenId_);

        super._mint(_to, tokenId_);
    }

    function burn(uint256 _tokenId) external {
        _isApprovedOrOwner(_msgSender(), _tokenId);
        _requireMinted(_tokenId);
        delete __tokenIdForHash[__tokenHashForId[_tokenId]];
        delete __tokenHashForId[_tokenId];

        address tokenOwner_ = ownerOf(_tokenId);
        removeFromList(__userTokens[tokenOwner_], _tokenId);

        super._burn(_tokenId);
    }

    function userTokens(address _user) external view returns (uint256[] memory) {
        return __userTokens[_user];
    }

    function removeFromList(uint256[] storage list, uint256 element) internal {
        uint256[] memory cachedList_ = list;
        uint256 cachedListLength_ = cachedList_.length;
        uint256 index_;

        while (index_ < cachedListLength_) {
            if (list[index_] == element) {
                break;
            } else {
                index_++;
            }
        }

        list[index_] = list[cachedListLength_ - 1];
        list.pop();
    }
}
