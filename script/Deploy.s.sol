// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/NFTFactory.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        AIBasedNFTFactory factory = new AIBasedNFTFactory();
        
        vm.stopBroadcast();

        console.log("NFTFactory deployed at:", address(factory));
    }
}