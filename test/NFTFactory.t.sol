// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/NFTFactory.sol";
import "../src/NFTCollection.sol";

contract NFTFactoryTest is Test {
    NFTFactory factory;
    address userOwner = address(0x12323);
    address user = address(0x123);
    address user2 = address(0x124);

    address owner = address(this);

    uint256 defaultMaxTime = block.timestamp + 120;
    uint256 defaultGenerateFee = 0.0001 ether;



    NFTFactory.CollectionDetails emptyCollectionDetails = NFTFactory.CollectionDetails({
        collectionAddress: address(0),
        name: "",
        description: "",
        tokenIdCounter: 0,
        maxSupply: 0,
        baseImageURI: "",
        maxTime: 0,
        mintPerWallet: false,
        mintPrice: 0,
        isDisable: false,
        isUltimateMintTime: false,
        isUltimateMintQuantity: false
    });


    receive() external payable {} 

    function setUp() public {
        vm.prank(userOwner);
        factory = new NFTFactory();
    }

    function testCreateCollection() public {
        vm.startPrank(owner);
        address collectionAddress = factory.createCollection("Test", "Test Description", "TST", "ipfs://QmTestHash/", 1000, defaultMaxTime, false, 0, false, false);
        
        // Verify collection creation
        assertTrue(collectionAddress != address(0));
        assertEq(factory.getCollections().length, 1);
        
        // Verify collection properties
        NFTCollection collection = NFTCollection(collectionAddress);
        assertEq(collection.name(), "Test");
        assertEq(collection.symbol(), "TST");
        assertEq(collection.maxSupply(), 1000);
        assertEq(collection.owner(), owner);
    }

    function testMintNFTs() public {
        address collectionAddress = factory.createCollection("Test", "Test Description", "TST", "ipfs://QmTestHash/", 10, defaultMaxTime, false, 0, false, false);
        NFTCollection collection = NFTCollection(collectionAddress);
        
        vm.deal(user, 1 ether);
        // Mint as user
        vm.prank(user);
        // Mint 5 NFTs
        factory.mintNFT{value: 0.0006 ether}(collectionAddress, user, 5);
        assertEq(collection.totalSupply(), 5);
        assertEq(collection.ownerOf(1), user);
        assertEq(collection.ownerOf(5), user);
        
        // Test max supply limit
        vm.expectRevert("Exceeds max supply");
        factory.mintNFT{value: 0.0006 ether}(collectionAddress, user, 6);
    }

    function testMetadata() public {
    address collectionAddress = factory.createCollection("Test", "TST", "Test Description", "ipfs://QmTestHash/", 10, defaultMaxTime, false, 0, false, false);
    NFTCollection collection = NFTCollection(collectionAddress);
    
    // 3. Mint NFT
    factory.mintNFT{value: 0.0001 ether}(collectionAddress, user, 1);
    
    // 4. Verify URI
    assertEq(collection.tokenURI(1), "data:application/json;base64,eyJuYW1lIjogIlRlc3QgIzEiLCJkZXNjcmlwdGlvbiI6IlRTVCIsImltYWdlIjogImlwZnM6Ly9RbVRlc3RIYXNoLyJ9");
}

    function testMaxTimeRestriction() public {
        // Create a collection with maxTime = 1 minute
        address collectionAddress = factory.createCollection("Test", "Test Description", "TST", "ipfs://QmTestHash/", 10, defaultMaxTime, false, 0, false, false);
        NFTCollection collection = NFTCollection(collectionAddress);

        // Mint within the allowed time
        factory.mintNFT{value: 0.0001 ether}(collectionAddress, user, 1);
        assertEq(collection.totalSupply(), 1);

        // Simulate time passing (1 second)
        vm.warp(block.timestamp + 1 hours + 1 seconds); // 61 seconds later
        vm.deal(user, 1 ether);
        // Attempt to mint after maxTime has passed
        vm.expectRevert("Minting period has ended");
        factory.mintNFT{value: 0.0001 ether}(collectionAddress, user, 1);
    }

    function testDefaultMaxTime() public {
        // Create a collection with maxTime = 0 (defaults to 7 days)
        address collectionAddress = factory.createCollection("Test", "Test Description", "TST", "ipfs://QmTestHash/", 10, defaultMaxTime, false, 0, false, false);
        NFTCollection collection = NFTCollection(collectionAddress);

        // Mint within the default 7-day period
        factory.mintNFT{value: 0.0001 ether}(collectionAddress, user, 1);
        assertEq(collection.totalSupply(), 1);

        // Simulate time passing (7 days + 1 second)
        vm.warp(block.timestamp + 7 days + 1);
        vm.deal(user, 1 ether);
        // Attempt to mint after 7 days
        vm.expectRevert("Minting period has ended");
        factory.mintNFT{value: 0.0001 ether}(collectionAddress, user, 1);
    }


    
    // Test should FAIL if minting works after maxTime (showing contract vulnerability)
    function testMaxTimeRestrictionFailure() public {
        // Create a collection with maxTime = 1 hour
        address collectionAddress = factory.createCollection("Test", "Test Description", "TST", "ipfs://QmTestHash/", 10, defaultMaxTime, false, 0, false, false);
        NFTCollection collection = NFTCollection(collectionAddress);

        // Simulate time passing (2 hours later)
        vm.warp(block.timestamp + 2 hours); // 2 hours later
        vm.deal(user, 1 ether);
        // Attempt to mint after maxTime has passed
        // This should REVERT if the contract is working correctly
        // If it does NOT revert, the test will pass (indicating a vulnerability)
        vm.expectRevert("Minting period has ended");
        factory.mintNFT{value: 0.0001 ether}(collectionAddress, user, 1);
    }

    function testPaidMintAnotherUser() public {
    // Define addresses
    address nftOwner = address(0x122342343); // Explicit owner address
    address user22 = address(0x999999);

    // Set up owner balance tracking
    vm.deal(nftOwner, 0); // Ensure owner starts with 0 ETH
    uint256 ownerBalanceBefore = nftOwner.balance;

    // Create collection as owner
    vm.prank(nftOwner);
    uint nftPrice = 0.01 ether;
    uint platformFee = 0.0005 ether;
    address collectionAddress = factory.createCollection(
        "Paid", "Test Description", "PAID", "ipfs://paid/", 
        10,       // maxSupply
        defaultMaxTime,        // maxTime (1 hour)
        false,    // mintPerWallet
        nftPrice // mintPrice
        , false, false
    );
    NFTCollection collection = NFTCollection(collectionAddress);
    
    // Fund user2 with ETH (1 ETH)
    vm.deal(user22, 1 ether);
    
    // Execute mint from user2
    vm.prank(user22);
    factory.mintNFT{value: nftPrice + platformFee}(collectionAddress, user22, 1);
    
    // Verify balances
    assertEq(collection.totalSupply(), 1, "Mint failed");
    assertEq(user22.balance, 0.9895 ether, "User ETH not deducted"); // 1 ETH - 0.01 ETH
    assertEq(nftOwner.balance, ownerBalanceBefore + nftPrice, "Owner didn't receive ETH");
}

    function testMintWithoutPayment() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        address collectionAddress = factory.createCollection(
            "Paid", "Test Description", "PAID", "ipfs://paid/", 
            10, defaultMaxTime, false, 0.01 ether, false, false
        );
        NFTCollection collection = NFTCollection(collectionAddress);
        vm.expectRevert("Insufficient ETH sent");
        factory.mintNFT{value: 0.000005 ether}(collectionAddress, user, 1); // No ETH sent
    }


    function testMintByCreatorPayment() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        address collectionAddress = factory.createCollection(
            "Paid", "Test Description", "PAID", "ipfs://paid/", 
            10, defaultMaxTime, false, 0.2 ether, false, false
        );
        NFTCollection collection = NFTCollection(collectionAddress);
        
        // vm.expectRevert("Insufficient ETH sent");
        // factory.mintNFT{value: 0.00005 ether}(user, 1); // No ETH sent

        factory.mintNFT{value: 0.01 ether}(collectionAddress, user, 1); // No ETH sent
    }

    function testInsufficientPayment() public {
        // Create a paid collection
        address collectionAddress = factory.createCollection(
            "Paid", "Test Description", "PAID", "ipfs://paid/", 
            10, defaultMaxTime, false, 0.01 ether // mintPrice = 0.01 ETH
            , false, false
        );
        NFTCollection collection = NFTCollection(collectionAddress);
        vm.deal(user, 1 ether);
        // Attempt to mint with insufficient payment
        vm.prank(user);
        vm.expectRevert("Insufficient ETH sent");
        factory.mintNFT{value: 0.0001 ether}(collectionAddress, user, 1); // Send 0.005 ETH
    }

    function testWalletRestriction() public {
        // Create a collection with wallet restriction
        address collectionAddress = factory.createCollection(
            "Restricted", "Test Description", "RST", "ipfs://restricted/", 
            10, defaultMaxTime, true, 0 // mintPerWallet = true
            , false, false
        );
        NFTCollection collection = NFTCollection(collectionAddress);
        
        vm.deal(user, 1 ether);
        // Mint as user
        vm.prank(user);
        factory.mintNFT{value: 0.0001 ether}(collectionAddress, user, 1); // Mint 1 NFT
        
        // Attempt to mint again
        vm.prank(user);
        vm.expectRevert("Wallet already minted");
        factory.mintNFT{value: 0.0001 ether}(collectionAddress, user, 1); // Should fail
    }



function testCreateAndMintFunction() public {
    address user = address(0x123); // Define an EOA
    vm.deal(user, 1 ether); // Fund the user

    vm.startPrank(user); // 👈 Execute as user, not test contract
    
    // Calculate required payment (mintPrice + platform fee)
    uint256 initialPrice = 0.0001 ether;
    uint256 totalPrice = initialPrice + 0.0001 ether; // Platform fee for <=0.002 ETH

    factory.createAndMint{value: totalPrice}(
        "TestCollection",
        "Test Description",
        "TST",
        "ipfs://test.png"
    );
    
    // Verify collection creation
    address[] memory collections = factory.getCollections();
    address[] memory mintpadCollections = factory.getMintPadCollections();
    assertEq(collections.length, 1, "Collection not created");

    assertEq(mintpadCollections.length, 0, "Mintpad Collection not created");
}

function testCalculatePlatformFee() public {
    // Create collection with different price scenarios
    address lowPriceCollection = factory.createCollection(
        "Low", "Desc", "LOW", "ipfs://low", 
        100, defaultMaxTime, false, 0.001 ether, false, false
    );
    address highPriceCollection = factory.createCollection(
        "High", "Desc", "HIGH", "ipfs://high", 
        100, defaultMaxTime, false, 0.003 ether, false, false
    );
    
    NFTCollection low = NFTCollection(lowPriceCollection);
    NFTCollection high = NFTCollection(highPriceCollection);
    
    // Should return 0.0001 ether for <= 0.002 ether
    assertEq(low.mintPrice(), 0.001 ether + 0.0001 ether, "Low price fee miscalculation");
    
    // Should return 5% of 0.003 ether = 0.00015 ether
    assertEq(high.mintPrice(), 0.003 ether + (0.003 ether * 5 / 100), "High price fee miscalculation");
}


function testAdminWithdraw() public {
    // Setup
    address admin = factory.owner();
    address nftOwner = address(0x1343);
    vm.deal(admin, 1 ether);

    // Create collection
    vm.prank(nftOwner);

    uint nftPrice = 0.003 ether;
    uint platformFee = 0.00015 ether;

    address collectionAddress = factory.createCollection(
        "High", "Desc", "HIGH", "ipfs://high", 
        100, defaultMaxTime, false, nftPrice, false, false
    );
    NFTCollection collection = NFTCollection(collectionAddress);

    // Mint NFTs (accumulate fees)
    vm.deal(user, 1 ether);
    vm.prank(user);
    factory.mintNFT{value: nftPrice + platformFee}(collectionAddress, user, 1);

    // Verify withdrawal
    uint256 contractBalanceBefore = address(collection).balance;
    vm.prank(admin);
    collection.withdraw();
    
    assertEq(address(collection).balance, 0);
    assertEq(admin.balance, 1 ether + contractBalanceBefore);
}





function testAdminFunctionsAccessControl() public {
    
    uint nftFee = 0.001 ether;
    address collectionAddress = factory.createCollection(
        "AdminTest", "Desc", "ADM", "ipfs://admin", 
        100, defaultMaxTime, false, nftFee, false, false
    );
    NFTCollection collection = NFTCollection(collectionAddress);
    
    // Test admin-only functions with non-admin
    vm.deal(user, 1 ether);
    vm.startPrank(user);
    
    vm.expectRevert("Only admin");
    collection.setMaxSupply(200);
    
    vm.expectRevert("Only admin");
    collection.setMaxTime(200);
    
    vm.expectRevert("Only admin");
    collection.changePlatformFee(0.0002 ether);
    
    // Test with admin (factory owner)
    vm.stopPrank();
    vm.startPrank(factory.owner());
    
    collection.setMaxSupply(200);
    assertEq(collection.maxSupply(), 200, "Max supply not updated");
    
    collection.setMaxTime(200);
    assertEq(collection.maxTime(), 200, "Max time not updated");
    
    uint changeFee = 0.0002 ether;
    collection.changePlatformFee(changeFee);

    vm.stopPrank();
    vm.startPrank(user);
    
    // Verify fee change through mint price calculation
    factory.mintNFT{value: nftFee + changeFee}(collectionAddress, user, 1);
}

    function testIsDisabledConditions() public {

        vm.deal(userOwner, 1 ether);
        vm.startPrank(userOwner);
        // Create restricted collection
        address collectionAddress = factory.createCollection(
            "DisabledTest", "Desc", "DIS", "ipfs://disabled", 
            1, // maxSupply = 1
            block.timestamp + 60, // 1 minute duration
            true, // mintPerWallet
            0.001 ether, false, false
        );
        NFTCollection collection = NFTCollection(collectionAddress);
        
        // Initial state should be enabled
        assertFalse(collection.isDisabled(userOwner), "Should not be disabled initially");
        
        // Test supply limit
        factory.mintNFT{value: 0.0011 ether}(collectionAddress, userOwner, 1);
        assertTrue(collection.isDisabled(userOwner), "Should disable after max supply");
        
        // Create time-based test collection
        address timeCollectionAddress = factory.createCollection(
            "TimeTest", "Desc", "TIME", "ipfs://time", 
            10, 
            block.timestamp + 60, 
            false, 
            0.001 ether, false, false
        );
        NFTCollection timeCollection = NFTCollection(timeCollectionAddress);
        
        // Advance past maxTime
        vm.warp(block.timestamp + 61);
        assertTrue(timeCollection.isDisabled(userOwner), "Should disable after maxTime");
        
        // Test wallet restriction
        address restrictedCollectionAddress = factory.createCollection(
            "WalletTest", "Desc", "WALL", "ipfs://wallet", 
            10, 
            block.timestamp + 1000, 
            true, // mintPerWallet
            0.001 ether, false, false
        );
        NFTCollection restrictedCollection = NFTCollection(restrictedCollectionAddress);
        
        factory.mintNFT{value: 0.0011 ether}(restrictedCollectionAddress, user, 1);
        assertTrue(restrictedCollection.isDisabled(user), "Should disable after wallet mint");
        assertFalse(restrictedCollection.isDisabled(user2), "Should allow other wallets");
    }

    // Test payGenerateFee with sufficient ETH
    function testPayGenerateFeeSuccess() public {
        uint256 fee = defaultGenerateFee;
        vm.deal(user, fee);
        
        vm.prank(user);
        factory.payGenerateFee{value: fee}();

        assertEq(address(factory).balance, fee, "Contract should have received fee");
    }

    // Test payGenerateFee with insufficient ETH
    function testPayGenerateFeeInsufficient() public {
        vm.startPrank(userOwner);
        uint256 newFee = 0.0001 ether;
        factory.setGenerateFee(newFee);
        uint256 fee = defaultGenerateFee;
        
        
        vm.stopPrank();
        vm.deal(user, fee - 1);
        vm.startPrank(user);
        vm.expectRevert("Payable: msg.value must be equal to amount");
        factory.payGenerateFee{value: fee - 1}();
    }

    // Test owner withdrawal
    function testWithdrawAsOwner() public {
        
        uint256 fee = defaultGenerateFee;
        vm.startPrank(userOwner);
        factory.setGenerateFee(fee);
        vm.stopPrank();


        vm.deal(user, fee);
        
        // Fund contract
        vm.prank(user);
        factory.payGenerateFee{value: fee}();

        uint256 contractBalanceBefore = address(factory).balance;
        uint256 ownerBalanceBefore = userOwner.balance;

        vm.prank(userOwner);
        factory.withdraw();

        assertEq(address(factory).balance, 0, "Contract balance should be 0");
        assertEq(
            userOwner.balance,
            ownerBalanceBefore + contractBalanceBefore,
            "Owner should receive contract balance"
        );
    }

    // Test non-owner withdrawal attempt
    function testWithdrawAsNonOwner() public {
        vm.prank(user);
        vm.expectRevert("Only admin");
        factory.withdraw();
    }

    // Test fee update by owner
    function testSetGenerateFeeAsOwner() public {
        vm.startPrank(userOwner);
        uint256 newFee = 0.2 ether;
        factory.setGenerateFee(newFee);
        assertEq(factory.getFee(), newFee, "Fee should update");
    }

 // Test fee payment functionality
    function testPayGenerateFee() public {
        uint256 fee = 0.001 ether;
        
        // Set fee by owner
        vm.prank(userOwner);
        factory.setGenerateFee(fee);

        // Test successful payment
        vm.deal(user, fee);
        vm.prank(user);
        factory.payGenerateFee{value: fee}();
        assertEq(address(factory).balance, fee, "Fee not received");

        // Test insufficient payment
        vm.deal(user2, fee - 1);
        vm.prank(user2);
        vm.expectRevert("Payable: msg.value must be equal to amount");
        factory.payGenerateFee{value: fee - 1}();
    }

    // Test withdrawal functionality
    function testWithdraw() public {
        uint256 fee = 0.001 ether;
        
        // Setup
        vm.prank(userOwner);
        factory.setGenerateFee(fee);
        
        vm.deal(user, fee);
        vm.prank(user);
        factory.payGenerateFee{value: fee}();

        // Test owner withdrawal
        uint256 initialBalance = userOwner.balance;
        vm.prank(userOwner);
        factory.withdraw();
        
        assertEq(address(factory).balance, 0, "Funds not withdrawn");
        assertEq(userOwner.balance, initialBalance + fee, "Funds not received");

        // Test non-owner withdrawal attempt
        vm.prank(user);
        vm.expectRevert("Only admin");
        factory.withdraw();
    }

    // Test fee management
    function testFeeManagement() public {
        uint256 newFee = 0.002 ether;
        
        // Test owner sets fee
        vm.startPrank(userOwner);
        factory.setGenerateFee(newFee);
        assertEq(factory.getFee(), newFee, "Fee not updated");
        vm.stopPrank();
        // Test non-owner sets fee
        vm.startPrank(user);
        vm.expectRevert("Only admin");
        factory.setGenerateFee(newFee);
    }

 // Test retrieving details for a valid contract address
    function testGetDetailsByValidAddress() public {
        // Create a test collection
        address collectionAddress = createTestCollection(userOwner, 100, block.timestamp + 1 days, false);
        
        // Retrieve details
        NFTFactory.CollectionDetails memory details = factory.getCollectionDetailsByContractAddress(collectionAddress);
        
        // Verify returned details
        assertEq(details.collectionAddress, collectionAddress, "Incorrect collection address");
        assertEq(details.maxSupply, 100, "Incorrect max supply");
        assertEq(details.mintPerWallet, false, "Incorrect mint restriction");
        assertEq(details.isDisable, true, "Incorrect disable status");
    }

    // Test retrieving details for an invalid contract address
    function testGetDetailsByInvalidAddress() public {
        // Attempt to retrieve details for a non-existent collection
        address invalidAddress = address(0x999);
        
        // Expect the function to revert or return empty details
       NFTFactory.CollectionDetails memory invalidResult = factory.getCollectionDetailsByContractAddress(invalidAddress);
        assertTrue(emptyCollectionDetails.collectionAddress == invalidResult.collectionAddress, "Incorrect collection address");
    }

    // Test retrieving details for a collection with ultimate mint conditions
    function testGetDetailsWithUltimateMintConditions() public {
        // Create a time-sensitive collection (last hour)
        address timeCol = createTestCollection(userOwner, 1000, type(uint256).max, false);
        
        // Create a quantity-sensitive collection
        address quantityCol = createTestCollection(userOwner, type(uint256).max, block.timestamp + 1 days, false);

        // Retrieve details for time-sensitive collection
        NFTFactory.CollectionDetails memory timeDetails = factory.getCollectionDetailsByContractAddress(timeCol);
        assertTrue(timeDetails.isUltimateMintTime, "Should indicate ultimate mint time");

        // // Retrieve details for quantity-sensitive collection
        NFTFactory.CollectionDetails memory quantityDetails = factory.getCollectionDetailsByContractAddress(quantityCol);
        assertTrue(quantityDetails.isUltimateMintQuantity, "Should indicate ultimate mint quantity");
    }

    // Test retrieving details for a collection with minting restrictions
    function testGetDetailsWithMintRestrictions() public {
        // Create a restricted collection
        address restrictedCol = createTestCollection(userOwner, 10, block.timestamp + 1 days, true);
        
        // Mint from restricted collection to trigger wallet restriction
        vm.deal(user, 0.1 ether);
        vm.prank(user);
        factory.mintNFT{value: 0.0002 ether}(restrictedCol, user, 1);

        // Retrieve details
        NFTFactory.CollectionDetails memory details = factory.getCollectionDetailsByContractAddress(restrictedCol);
        
        // Verify restrictions
        assertTrue(details.mintPerWallet, "Should indicate mint per wallet restriction");
        assertTrue(details.isDisable, "Should indicate disabled status for restricted collection");
    }

    // Helper to create test collections
    function createTestCollection(address owner, uint256 maxSupply, uint256 maxTime, bool mintPerWallet) internal returns (address) {
        vm.prank(userOwner);
        return factory.createCollection(
            "Test",
            "Test Description",
            "TST",
            "ipfs://test",
            maxSupply,
            maxTime,
            mintPerWallet,
            0.0001 ether,
            false,
            false
        );
    }

    // Helper to mint multiple NFTs
    function mintMultiple(address collection, address minter, uint256 quantity) internal {
        
        vm.prank(minter);
        for (uint256 i = 0; i < quantity; i++) {
            factory.mintNFT{value: 0.0001 ether}(collection, minter, 1);
        }
    }


    function testCreateCollectionCGETSollection() public {
        string memory name = "Test Collection";
        string memory description = "A test NFT collection";
        string memory symbol = "TEST";
        string memory imageURL = "https://example.com/image.png";
        uint256 maxSupply = 100;
        uint256 maxTime = block.timestamp + 10 days;
        bool mintPerWallet = true;
        uint256 mintPrice = 0.01 ether;
        bool isUltimateMintTime = false;
        bool isUltimateMintQuantity = false;
        uint256 mintPriceWithFee = 0.0105 ether;
        // Create a new collection
        address collectionAddress = factory.createCollection(
            name,
            description,
            symbol,
            imageURL,
            maxSupply,
            maxTime,
            mintPerWallet,
            mintPrice,
            isUltimateMintTime,
            isUltimateMintQuantity
        );

        // Verify the collection was deployed
        NFTCollection collection = NFTCollection(collectionAddress);
        assertEq(collection.name(), name);
        assertEq(collection.symbol(), symbol);
        assertEq(collection.imageURL(), imageURL);
        assertEq(collection.maxSupply(), maxSupply);
        assertEq(collection.maxTime(), maxTime);
        assertEq(collection.mintPerWallet(), mintPerWallet);
        assertEq(collection.mintPrice(), mintPriceWithFee);

        // Verify the collection is added to deployedCollections
        address[] memory collections = factory.getCollections();

        assertEq(collections.length, 1);
        assertEq(collections[0], collectionAddress);

        NFTFactory.CollectionDetails[] memory avaiableColloctions = factory.getAvailableCollectionsToMintDetails();
        assertEq(avaiableColloctions.length, 1);
        assertEq(avaiableColloctions[0].collectionAddress, collectionAddress);
    }

    function testCreateWithDefaultCollectionWithDefaultTime() public {
        string memory name = "Default Time Collection";
        string memory description = "A test collection with default time";
        string memory symbol = "DFLT";
        string memory imageURL = "https://example.com/default-time.png";
        uint256 maxSupply = 50;
        bool mintPerWallet = true;
        uint256 mintPrice = 0.005 ether;

        // Create a collection with default time
        address collectionAddress = factory.createWithDefaultCollectionWithDefaultTime(
            name,
            description,
            symbol,
            imageURL,
            maxSupply,
            mintPerWallet,
            mintPrice,
            false
        );

        // Verify the collection was deployed with default maxTime
        NFTCollection collection = NFTCollection(collectionAddress);
        uint256 expectedMaxTime = block.timestamp + (60 * 60 * 24 * 7); // 1 week
        assertEq(collection.maxTime(), expectedMaxTime);
    }

    function testGetAvailableCollectionsDetails() public {
        // Create two collections
        address collection1 = factory.createCollection(
            "Collection 1",
            "Description 1",
            "COL1",
            "https://example.com/image1.png",
            100,
            block.timestamp + 365 days,
            true,
            0.01 ether,
            false,
            false
        );

        address collection2 = factory.createCollection(
            "Collection 2",
            "Description 2",
            "COL2",
            "https://example.com/image2.png",
            200,
            block.timestamp + 730 days,
            true,
            0.02 ether,
            false,
            false
        );

        // Set both collections to visible
        // NFTCollection(collection1).setCanShow(true);
        // NFTCollection(collection2).setCanShow(true);

        // Get available collection details
        NFTFactory.CollectionDetails[] memory details = factory.getAvailableCollectionsToMintDetails();

        // Verify details of the first collection
        assertEq(details.length, 2);
        assertEq(details[0].collectionAddress, collection1);
        assertEq(details[0].tokenIdCounter, 0);
        assertEq(details[0].maxSupply, 100);
        assertEq(details[0].baseImageURI, "https://example.com/image1.png");
        assertEq(details[0].maxTime, block.timestamp + 365 days);

        // Verify details of the second collection
        assertEq(details[1].collectionAddress, collection2);
        assertEq(details[1].tokenIdCounter, 0);
        assertEq(details[1].maxSupply, 200);
        assertEq(details[1].baseImageURI, "https://example.com/image2.png");
        assertEq(details[1].maxTime, block.timestamp + 730 days);

        vm.warp(block.timestamp + 366 days); 

            NFTFactory.CollectionDetails[] memory avaiableColloctions = factory.getAvailableCollectionsToMintDetails();
            assertEq(avaiableColloctions.length, 1);
            assertEq(avaiableColloctions[0].collectionAddress, details[1].collectionAddress);
    }



    // Test retrieving details for a collection with ultimate mint conditions
    function testGetDetailsWithMillionsOFCollections() public {
        vm.pauseGasMetering();
        uint256 length = 10_000;
        for (uint256 i = 0; i < length; i++) {
            // Create a time-sensitive collection (last hour)
            createTestCollection(userOwner, 1000, type(uint256).max, false);
        }
        // vm.resumeGasMetering();
        address[] memory details = factory.getCollections();
        NFTFactory.CollectionDetails[] memory detailsCollectios = factory.getAvailableCollectionsToMintDetails();
        assertEq(details.length, length);
        assertEq(detailsCollectios.length, length);
    }
}