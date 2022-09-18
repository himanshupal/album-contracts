// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is ERC721Enumerable, Ownable {
    /// @dev Sale fees basis points
    uint256 private constant SALE_FEES_BPS = 1e6;

    /// @notice Keeps track of total number of token minted
    uint256 public tokensMinted;

    /// @notice Fee applicable on token sale, raised to 1e6
    uint256 public saleFees;

    /// @dev Current (fee deducted) unclaimed amount of tokens earned by users
    uint256 private tokensLocked;

    /// @dev Used for overriding
    string private baseURI;

    /// @dev Keeps the track of individual token prices by their ids
    mapping(uint256 => uint256) private tokenPrice;

    /// @dev Keeps the count of tokens a user holds
    mapping(address => uint256) private userTokens;

    /// @dev Keeps the track of earnings for inidividual users which is not withdrawn yet
    mapping(address => uint256) private userEarnings;

    /// @dev Indicates whether a token is open for sale
    mapping(uint256 => bool) private isOpenForSale;

    /// @dev Keeps track of ipfs hash to avoid minting same data more than once
    mapping(string => bool) private uriExists;

    /// @dev Keeps track of tokenURIs
    mapping(uint256 => string) private tokenURIs;

    /// @dev On successful purchase
    event Purchase(address indexed previousOwner, address indexed newOwner, uint256 tokenId, uint256 amount);

    /// @dev On price update
    event PriceUpdate(uint256 indexed tokenId, uint256 oldPrice, uint256 newPrice);

    /// @dev On withdrawl
    event Withdraw(address indexed receiver, uint256 amount);

    /// @dev On token availability status update
    event StatusUpdate(uint256 indexed tokenId, bool status);

    /**
     * @notice Sets default fees to 0.1% of token price
     * @param name contract name
     * @param symbol contract symbol
     * @param baseURI_ the base URI for all the tokens to follow, e.g. a web server path or some domain name
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI_
    ) ERC721(name, symbol) {
        require(bytes(baseURI_).length != 0, "Marketplace: BaseURI_ is required");
        baseURI = baseURI_;
        saleFees = 1e3;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Reads the complete URI for a token
     * @param tokenId id to get URI for
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return string(abi.encodePacked(_baseURI(), "/", tokenURIs[tokenId]));
    }

    /**
     * @notice Tells if a token is available for purchase or not
     * @param tokenId id to check status for
     */
    function isTokenOnSale(uint256 tokenId) external view returns (bool status) {
        _requireMinted(tokenId);
        return isOpenForSale[tokenId];
    }

    /**
     * @notice Reads the price of a token
     * @param tokenId id of the token to get price of
     */
    function priceOfToken(uint256 tokenId) external view returns (uint256) {
        return tokenPrice[tokenId];
    }

    /**
     * @notice Reads the total sale value for a seller
     * @param seller address of the seller
     */
    function userEarning(address seller) external view returns (uint256) {
        return userEarnings[seller];
    }

    /**
     * @notice Reads the count of tokens a user have
     * @param user address of the user
     */
    function userTokenCount(address user) external view returns (uint256) {
        return userTokens[user];
    }

    /**
     * @notice To be called by the buyer with an amount equal to the token price listed by its owner
     * @param tokenId id of the token to purchase
     */
    function purchase(uint256 tokenId) external payable {
        require(isOpenForSale[tokenId], "Marketplace: unavailable for sale");
        uint256 price = tokenPrice[tokenId];
        uint256 amountSent = msg.value;
        require(amountSent >= price, "Marketplace: less value sent");

        address tokenOwner = ownerOf(tokenId);
        address newOwner = _msgSender();

        _transfer(tokenOwner, newOwner, tokenId);
        isOpenForSale[tokenId] = false;

        emit Purchase(tokenOwner, newOwner, tokenId, price);

        uint256 earningAfterFees = price - ((price * saleFees) / SALE_FEES_BPS);
        userEarnings[tokenOwner] += earningAfterFees;
        tokensLocked += earningAfterFees;

        userTokens[tokenOwner] = userTokens[tokenOwner] - 1;
        userTokens[newOwner] = userTokens[newOwner] + 1;
    }

    /**
     * @notice Allows token owners to withdraw their earnings from sales
     */
    function withdraw() external {
        address caller = _msgSender();
        uint256 amount = userEarnings[caller];
        require(amount > 0, "Marketplace: no sale");

        tokensLocked -= amount;
        (bool success, ) = payable(caller).call{value: amount}("");
        require(success, "Marketplace: failed sending ETH");

        emit Withdraw(caller, amount);
    }

    /**
     * @notice Allows contract owner to withdraw any excess funds in contract
     */
    function withdrawExcessFunds() external onlyOwner {
        uint256 amount = address(this).balance - tokensLocked;
        require(amount > 0, "Marketplace: not required");

        (bool success, ) = payable(Ownable.owner()).call{value: amount}("");
        require(success, "Marketplace: failed sending ETH");
    }

    /**
     * @notice Mints a token to the {to} address provided
     * @param to address to mint token to
     * @param tokenURI_ unique path of the token, e.g. ipfsHash
     * @param tokenPrice_ price at which the token is to be sold
     */
    function mint(
        address to,
        string memory tokenURI_,
        uint256 tokenPrice_
    ) external {
        require(bytes(tokenURI_).length != 0, "Marketplace: tokenURI_ is required");
        require(!uriExists[tokenURI_], "Marketplace: same data exists");
        uint256 tokenId = ++tokensMinted;

        uriExists[tokenURI_] = true;
        isOpenForSale[tokenId] = true;
        tokenURIs[tokenId] = tokenURI_;
        tokenPrice[tokenId] = tokenPrice_;
        userTokens[to] = userTokens[to] + 1;

        _safeMint(to, tokenId);
    }

    /**
     * @notice Burns a token removing all of its details from contract
     * @param tokenId id of the token to be burned
     */
    function burn(uint256 tokenId) external {
        _isApprovedOrOwner(_msgSender(), tokenId);
        uriExists[tokenURIs[tokenId]] = false;
        address tokenOwner = ownerOf(tokenId);

        delete tokenURIs[tokenId];
        delete tokenPrice[tokenId];
        delete isOpenForSale[tokenId];
        userTokens[tokenOwner] = userTokens[tokenOwner] - 1;

        _burn(tokenId);
    }

    /**
     * @notice Allows token owner or someone with its approval to update token availability status
     * @param tokenId id to chage status for
     * @param status updated sale status
     */
    function setTokenSaleStatus(uint256 tokenId, bool status) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Marketplace: not authorized");
        require(isOpenForSale[tokenId] != status, "Marketplace: already set");

        isOpenForSale[tokenId] = status;
        emit StatusUpdate(tokenId, status);
    }

    /**
     * @notice Allows token owner or someone with its approval to update token price
     * @param tokenId id of the token to update price for
     * @param newPrice updated price of the token
     */
    function setTokenPrice(uint256 tokenId, uint256 newPrice) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Marketplace: not authorized");

        uint256 oldPrice = tokenPrice[tokenId];
        tokenPrice[tokenId] = newPrice;
        emit PriceUpdate(tokenId, oldPrice, newPrice);
    }

    /**
     * @notice Allows contract owner to update the fees applicable on token sale
     * @param newSaleFees new sale fees in percentage (can only be set to a maximum of 33% of token price)
     */
    function setSaleFees(uint256 newSaleFees) external onlyOwner {
        require(newSaleFees <= SALE_FEES_BPS / 3, "Marketplace: already set");
        saleFees = newSaleFees;
    }
}
