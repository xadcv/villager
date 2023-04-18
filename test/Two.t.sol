// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/StdUtils.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "../src/Two.sol";

contract TwoTest is Test {
    uint256 constant WAD = 10 ** 18;
    Two public two;
    ERC20 food = new ERC20("Food", "FOOD");
    ERC20 wood = new ERC20("Wood", "WOOD");

    address alice = address(1);
    address bob = address(2);
    address charlie = address(3);

    function setUp() public {
        two = new Two(address(food), address(wood), alice);
    }

    function testSetup() public {
        address owner = two.getOwner();
        assertEq(owner, address(1));
        assertEq(address(two.getFood()), address(food));
        assertEq(address(two.getWood()), address(wood));
    }

    function testFoodRates() public {
        uint256 woodFood = 5 * WAD;

        vm.prank(alice);
        two.file(woodFood);

        assertEq(two.getWoodFood(), woodFood, "woodFood rate set successfully");

        vm.prank(alice);
        vm.expectRevert("Must not be a fractional rate");
        two.file(5 * 10 ** 17);
    }

    function testSimpleFarm() public {
        deal(address(food), address(alice), 1_000 * WAD);
        deal(address(wood), address(bob), 1_000 * WAD);

        uint256 woodFood = 5 * WAD;

        // Switch to Alice
        vm.startPrank(alice);

        // Alice sets the rate 5:1
        two.file(woodFood);
        assertEq(two.getWoodFood(), woodFood);

        // Alice transfers 500 food to the contract
        food.transfer(address(two), 500 * WAD);
        vm.stopPrank();

        // Switch to Bob
        vm.startPrank(bob);
        // Bob then exchanges 5 WAD wood for 1 WAD food
        wood.approve(address(two), 5 * WAD);
        two.farm(Two.Resource.WOOD, 5 * WAD);
        assertEq(food.balanceOf(address(bob)), 1 * WAD);

        // Bob then exchanges 7 WAD wood for 1.4 WAD food
        wood.approve(address(two), 7 * WAD);
        two.farm(Two.Resource.WOOD, 7 * WAD);
        assertEq(food.balanceOf(address(bob)) - 1 * WAD, 14 * 10 ** 17);
        // Bob then exchanges 0.5 WAD wood for 0.1 WAD food

        wood.approve(address(two), 5 * 10 ** 17);
        two.farm(Two.Resource.WOOD, 5 * 10 ** 17);
        assertEq(food.balanceOf(address(bob)) - 24 * 10 ** 17, 1 * 10 ** 17);

        vm.stopPrank();
    }

    function testFractionalFarm() public {
        deal(address(food), address(alice), 1_000 * WAD);
        deal(address(wood), address(bob), 1_000 * WAD);

        uint256 woodFood = 5 * WAD;

        // Switch to Alice
        vm.startPrank(alice);

        // Alice sets the rate 5:1
        two.file(woodFood);
        assertEq(two.getWoodFood(), woodFood);

        // Alice transfers 500 food to the contract
        food.transfer(address(two), 500 * WAD);
        vm.stopPrank();

        vm.startPrank(bob);
        // Bob exchanges 5 wei wood for 1 wei food
        wood.approve(address(two), 5);
        two.farm(Two.Resource.WOOD, 5);
        //assertEq(food.balanceOf(address(bob)), 1 * WAD);
        assertEq(food.balanceOf(address(bob)), 1);

        // Bob then fails to exchange 4 wei wood for 1 wei food
        wood.approve(address(two), 4);
        vm.expectRevert("Must not be a fractional amount");
        two.farm(Two.Resource.WOOD, 4);

        vm.stopPrank();
    }

    function testSimpleChop() public {
        deal(address(wood), address(alice), 5_000 * WAD);
        deal(address(food), address(bob), 1_000 * WAD);

        uint256 woodFood = 5 * WAD;

        // Switch to Alice
        vm.startPrank(alice);

        // Alice sets the rate 5:1
        two.file(woodFood);
        assertEq(two.getWoodFood(), woodFood);

        // Alice transfers 500 wood to the contract
        wood.transfer(address(two), 500 * WAD);
        vm.stopPrank();

        // Switch to Bob
        vm.startPrank(bob);
        // Bob then exchanges 5 WAD food for 25 WAD wood
        food.approve(address(two), 5 * WAD);
        two.chop(Two.Resource.FOOD, 5 * WAD);
        assertEq(wood.balanceOf(address(bob)), 25 * WAD);

        // Bob then exchanges 7 WAD food for 35 WAD wood
        food.approve(address(two), 7 * WAD);
        two.chop(Two.Resource.FOOD, 7 * WAD);
        assertEq(wood.balanceOf(address(bob)) - 25 * WAD, 35 * WAD);
        // Bob then exchanges 0.5 WAD food for 2.5 WAD wood

        food.approve(address(two), 5 * 10 ** 17);
        two.chop(Two.Resource.FOOD, 5 * 10 ** 17);
        assertEq(wood.balanceOf(address(bob)) - 60 * WAD, 25 * 10 ** 17);

        vm.stopPrank();
    }

    function testQuit() public {
        deal(address(food), address(two), 1_000 * WAD);
        two.quit();
        assertEq(food.balanceOf(address(two)), 0);
        assertEq(food.balanceOf(address(alice)), 1_000 * WAD);

        deal(address(food), address(two), 1_000 * WAD);
        deal(address(wood), address(two), 2_000 * WAD);
        two.quit();
        assertEq(food.balanceOf(address(two)), 0);
        assertEq(food.balanceOf(address(alice)), 2_000 * WAD);
        assertEq(wood.balanceOf(address(two)), 0);
        assertEq(wood.balanceOf(address(alice)), 2_000 * WAD);

        vm.expectRevert(
            "At least one of the tokens must have a positive balance"
        );
        two.quit();
    }
}
