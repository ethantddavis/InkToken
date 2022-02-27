// SPDX-License-Identifier: MIT
// Written by Andrew Olson

pragma solidity >=0.7.0 <0.9.0;

import "./Ink.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol";


contract SadBearsClub is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.2 ether;
  uint256 public maxSupply = 5555;
  uint256 public maxMintAmountPerTx = 5;
  uint256 public nftPerAddressLimit = 5;
  


  bytes32 public merkleRoot;

  bool public paused = true;
  bool public revealed = false;
  bool public publicMint = false;

  mapping(address => uint256) public addressMintedBalance;
  mapping(address => bool) public Burned;

  // ADDED CODE
  mapping(uint256 => address) public addressBurned;

  // ADDED CODE
  InkToken public ink;

  constructor() ERC721("Sad Bears Club", "SBC") {
    setHiddenMetadataUri("ipfs://QmewVS81BNac8SghgkbEr7bTTUqxXa6MrXw6gvvJGsqjBL/unrevealed.json");
  }

  // ADDED CODE
  function setInkAddress(address _inkAddress) external onlyOwner {
	  ink = InkToken(_inkAddress);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    uint256 ownerMintedAmount = addressMintedBalance[msg.sender];
    require(ownerMintedAmount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");

    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function WhitelistMint(bytes32[] calldata _merkleProof, uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    require(publicMint == false, "The public mint is live.");
    require(msg.value >= cost * _mintAmount, "Insufficient funds.");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof.");
   
    _mintLoop(msg.sender, _mintAmount);
  }

  function Mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(publicMint == true, "The whitelist mint is live.");
    require(!paused, "The contract is paused!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");

    _mintLoop(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function setPublicMint(bool _state) public onlyOwner {
    publicMint = _state;
  }

  function setmerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }
  
  function setMaxSupply(uint256 _newSupply) public onlyOwner {
    maxSupply = _newSupply;
  }
   
  function burn(uint256 tokenId) public virtual {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");
        
    // ADDED CODE
    ink.updateReward(msg.sender, address(0));
    addressBurned[tokenId] = msg.sender;
        
        _burn(tokenId);
    Burned[msg.sender] = true;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  // ADDED CODE
  function transferFrom(address from, address to, uint256 tokenId) public override {
    ink.updateReward(from, to);
	  super.transferFrom(from, to, tokenId);
  }

  // ADDED CODE
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
    ink.updateReward(from, to);
	  super.safeTransferFrom(from, to, tokenId, _data);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();

      // ADDED CODE
      ink.updateReward(address(0), _receiver);

      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
