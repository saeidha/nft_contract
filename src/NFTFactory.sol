// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTCollection.sol";


contract NFTFactory is Ownable {
    address[] public deployedCollections;
    
    constructor() Ownable(msg.sender) {} 
    
    event CollectionCreated(
        address indexed collection,
        string name,
        string symbol,
        uint256 maxSupply,
        uint256 maxTime,
        string baseURI,
        bool mintPerWallet,
        address owner
    );

    function createCollection(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 maxSupply,
        uint256 maxTime,
        bool mintPerWallet) public returns (address) {
        NFTCollection collection = new NFTCollection(
            name,
            symbol,
            maxSupply,
            maxTime,
            baseURI,
            mintPerWallet,
            msg.sender
        );
        
        deployedCollections.push(address(collection));
        emit CollectionCreated(address(collection), name, symbol, maxSupply, maxTime, baseURI, mintPerWallet, msg.sender);
        return address(collection);
    }

    function getCollections() public view returns (address[] memory) {
        return deployedCollections;
    }
}