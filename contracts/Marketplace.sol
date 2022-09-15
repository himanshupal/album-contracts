// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is ERC721Enumerable, Ownable {
    uint256 private excessFunds;
    mapping(address => uint256[]) private __userTokens;
    mapping(uint256 => string) private __tokenHashForId;
    mapping(string => uint256) private __tokenIdForHash;
    mapping(uint256 => uint256) private __tokenPrice;
    mapping(address => uint256) private __totalSale;
    mapping(uint256 => bool) private __isOpenForSale;

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

    function mint(
        address _to,
        string memory _ipfsHash,
        uint256 _price
    ) external {
        require(__tokenIdForHash[_ipfsHash] == 0, "Marketplace: same hash data exists");
        uint256 tokenId_ = totalSupply() + 1;

        __tokenIdForHash[_ipfsHash] = tokenId_;
        __tokenHashForId[tokenId_] = _ipfsHash;
        __isOpenForSale[tokenId_] = true;
        __tokenPrice[tokenId_] = _price;

        __userTokens[_to].push(tokenId_);

        super._mint(_to, tokenId_);
    }

    function burn(uint256 _tokenId) external {
        _isApprovedOrOwner(_msgSender(), _tokenId);
        _requireMinted(_tokenId);
        delete __tokenIdForHash[__tokenHashForId[_tokenId]];
        delete __tokenHashForId[_tokenId];
        delete __tokenPrice[_tokenId];
        address tokenOwner_ = ownerOf(_tokenId);
        removeFromList(__userTokens[tokenOwner_], _tokenId);
        super._burn(_tokenId);
    }

    function userTokens(address _user) external view returns (uint256[] memory) {
        return __userTokens[_user];
    }

    function updatePrice(uint256 _tokenId, uint256 _price) external {
        require(_msgSender() == ownerOf(_tokenId), "Marketplace: not called by token owner");
        __tokenPrice[_tokenId] = _price;
    }

    function purchase(uint256 _tokenId) external payable {
        uint256 tokenPrice_ = __tokenPrice[_tokenId];
        require(msg.value >= tokenPrice_, "Marketplace: less value sent");
        address tokenOwner_ = ownerOf(_tokenId);
        _transfer(tokenOwner_, _msgSender(), _tokenId);
        __totalSale[tokenOwner_] += tokenPrice_;
        __isOpenForSale[_tokenId] = false;
        if (msg.value > tokenPrice_) {
            excessFunds += msg.value - tokenPrice_;
        }
    }

    function withdraw(bool _withdrawUnused) external {
        address caller_ = _msgSender();
        bool calledByContractOwnerForUnusedFunds_ = (caller_ == owner()) && _withdrawUnused;
        bool success;
        require(calledByContractOwnerForUnusedFunds_ || __totalSale[caller_] > 0, "Marketplace: no sale");
        if (calledByContractOwnerForUnusedFunds_) {
            (success, ) = payable(owner()).call{value: excessFunds}("");
        } else {
            (success, ) = payable(_msgSender()).call{value: __totalSale[caller_]}("");
        }
        require(success, "Marketplace: failed sending ETH");
    }

    function setTokenSaleStatus(uint256 _tokenId, bool _openForSale) external {
        require(_msgSender() == ownerOf(_tokenId), "Marketplace: not called by token owner");
        __isOpenForSale[_tokenId] = _openForSale;
    }

    function removeFromList(uint256[] storage list, uint256 element) private {
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
