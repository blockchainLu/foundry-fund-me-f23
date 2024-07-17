//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("Alice");
    uint256 constant SEND_VALUE = 0.2 ether; //0.1 ether
    uint256 constant WITHDRAW_VALUE = 0.1 ether; //0.1 ether
    uint256 constant STARTING_VALUE = 3 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_VALUE);
    }

    function testMinimumAmountIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testWhoIsTheOwner() public view {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedIsAccutare() public view {
        uint256 versionNumber = fundMe.getVersion();
        assertEq(versionNumber, 4);
    }

    function testFundFailWithoutEnoughtEth() public {
        vm.expectRevert(); //expect to fails, then revert
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
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

    function testWithdrawToFunder() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASilgleFunder() public funded {
        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        // console.log(startingOwnerBalance);
        // console.log(endingOwnerBalance);
        // console.log(startingFundMeBalance);
        // console.log(startingFundMeBalance);
        // console.log(startingFundMeBalance + startingOwnerBalance);

        vm.expectRevert();
        assertEq(startingOwnerBalance, endingOwnerBalance);

        vm.expectRevert();
        assertEq(startingFundMeBalance, endingFundMeBalance);
    }

    function testWithdrawFromMultipleFunders() public {
        uint160 numberOfFunders = 10; //uint160 stands for addresses
        uint160 startingFundersIndex = 1;
        for (uint160 i = startingFundersIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);

            fundMe.fund{value: SEND_VALUE}();
            assertEq(address(fundMe).balance, SEND_VALUE);
            vm.prank(fundMe.getOwner());
            fundMe.withdraw();
            assertEq(address(fundMe).balance, 0);
        }
    }

    function testWithdrawFromMultipleFundersCheaper() public {
        uint160 numberOfFunders = 10; //uint160 stands for addresses
        uint160 startingFundersIndex = 1;
        for (uint160 i = startingFundersIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);

            fundMe.fund{value: SEND_VALUE}();
            assertEq(address(fundMe).balance, SEND_VALUE);
            vm.prank(fundMe.getOwner());
            fundMe.cheaperWithdraw();
            assertEq(address(fundMe).balance, 0);
        }
    }
}
