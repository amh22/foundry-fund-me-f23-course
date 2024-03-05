// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant SEND_VALUE = 0.1 ether; // decimals don't work in Solidty howevr adding 'ether' is like saying 1^18
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    // Test the Owner is the Deployer of the contract
    function testOwnerIsMsgSender() public {
        // console.log(fundMe.i_owner());
        // console.log(msg.sender);
        // console.log(address(this));
        // assertEq(fundMe.i_owner(), msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
        // assertEq(fundMe.i_owner(), address(this));
    }

    // Unit test - A method of testing a particular code piece or function. In this case, we could argue that getVersion function was a unit test.

    // Integration test - Multi-contract testing to ensure that all interrelated contracts effectively work together.

    // Fork test - Testing our code in a simulated real environment.

    // Staging test - Deploying our code to a real environment like testnet or mainnet to validate that everything indeed works as it should.

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    // Test Funding Contract fails if the amount sent is less than the minimum amount of US$50
    function testFundFailsWithoutMinimumETH() public {
        vm.expectRevert(); // This is the same as writing an assert statement, so the next line should revert for the test to pass
        // eg: assert(inside here will fail);
        fundMe.fund(); // sending a value of 0 is < US$50 so it will fail and thus the revert assertion about will pass
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // The next TX will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testFunderAddedToFundersArray() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        // vm.prank(USER);  // now we use the modifier to create a user
        // fundMe.fund{value: SEND_VALUE}(); // now we use the modifier to fund the contract

        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw(); // The prank USER is not the owner so this should revert
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange

        uint256 startingOwnerBalance = fundMe.getOwner().balance; // Get the Owner's current balance before the withdrawal

        uint256 startingFundMeContractBalance = address(fundMe).balance; // Get the current balance of the contract

        // Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw(); // Withdraw the funds from the contract to the owner
        uint256 gasEnd = gasleft();

        uint256 gasUsed = (tx.gasprice * (gasStart - gasEnd)); // Calculate the gas cost
        console.log("gasUsed:", gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance; // Get the Owner's balance after the withdrawal

        uint256 endingFundMeContractBalance = address(fundMe).balance; // Get the balance of the contract after the withdrawal

        assertEq(endingFundMeContractBalance, 0); // The contract should have a balance of 0 after the withdrawal

        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundMeContractBalance); // The owner's balance should be the starting balance + the contract balance
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange
        // *NOTE: if working with addresses, you must use uint160 NOT uint256
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // *Note: start with index 1 not 0 as there are often sanity checks in the code to prevent the owner from being removed from the funder array
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            // hoax(<some_address>, <some_amount>); This is a combination of the above two lines
            hoax(address(i), SEND_VALUE);

            // fund the fundMe contract with the prank address
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance; // Get the Owner's current balance before the withdrawal

        uint256 startingFundMeContractBalance = address(fundMe).balance; // Get the current balance of the contract

        // Act

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(fundMe.getOwner().balance == startingOwnerBalance + startingFundMeContractBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        // *NOTE: if working with addresses, you must use uint160 NOT uint256
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // *Note: start with index 1 not 0 as there are often sanity checks in the code to prevent the owner from being removed from the funder array
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            // hoax(<some_address>, <some_amount>); This is a combination of the above two lines
            hoax(address(i), SEND_VALUE);

            // fund the fundMe contract with the prank address
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance; // Get the Owner's current balance before the withdrawal

        uint256 startingFundMeContractBalance = address(fundMe).balance; // Get the current balance of the contract

        // Act

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(fundMe.getOwner().balance == startingOwnerBalance + startingFundMeContractBalance);
    }
}
