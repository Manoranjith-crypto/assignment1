// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts@4.7.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.7.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.7.0/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts@4.7.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.7.0/utils/Counters.sol";

// Using Error revert instead of require -- for Gas Optimization.
error InvalidAmount(uint sentAmount, uint requiredAmount);
error AtleastOneWei();
error NullAddress();

contract NFT is ERC721, ERC721URIStorage, ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    function Mint(address to, string memory uri) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}

contract TokenFactory is Ownable {
    // Events
    event nftTokenCreated(
        address indexed createdContract,
        string tokenName,
        string tokenSymbol
    );

    address payable admin;
    uint deployFee;

    constructor(address _admin, uint _fee) {
        admin = payable(_admin);
        deployFee = _fee;
    }

    struct NFTcontracts {
        NFT token;
        address creator;
        string name;
        string symbol;
    }

    NFTcontracts[] public nftContracts;
    uint public nftContractsCount;

    // Deploy ERC721 Token
    function deployNewERC721Token(string memory name, string memory symbol)
        external
        payable
        returns (address)
    {
        if (msg.value != deployFee) {
            uint amount = msg.value;
            revert InvalidAmount({
                sentAmount: amount,
                requiredAmount: deployFee
            });
        }

        admin.transfer(msg.value);
        NFT t = new NFT(name, symbol);
        NFTcontracts memory newContract;
        newContract.token = t;
        newContract.creator = msg.sender;
        newContract.name = name;
        newContract.symbol = symbol;

        nftContracts.push(newContract);
        nftContractsCount++;
        emit nftTokenCreated(address(t), name, symbol);
        return address(t);
    }

    // to get current deployFee!
    function getDeployFee() public view returns (uint) {
        return deployFee;
    }

    // to change DeployFee
    function setDeployFee(uint _newDeployFee)
        external
        onlyOwner
        returns (bool)
    {
        if (_newDeployFee <= 0) {
            revert AtleastOneWei();
        }
        deployFee = _newDeployFee;
        return true;
    }

    // to change new admin
    function changeAdminAddress(address _newAdmin)
        external
        onlyOwner
        returns (bool)
    {
        if(_newAdmin == address(0)){
            revert NullAddress();
        }
        admin = payable(_newAdmin);
        return true;
    }
}
