// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/StdUtils.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "../src/Three.sol";

contract ThreeTest is Test {
    uint256 constant WAD = 10 ** 18;
    Three public three;
    ERC20 food = new ERC20("Food", "FOOD");
    ERC20 wood = new ERC20("Wood", "WOOD");
    ERC20 coin = new ERC20("Coin", "COIN");

    address alice = address(4);
    address bob = address(5);
    address charlie = address(6);

    function setUp() public {
        three = new Three(address(food), address(wood), address(coin), alice);
    }

    function testSetup() public {
        address owner = three.getOwner();
        assertEq(owner, address(4));
        assertEq(address(three.getFood()), address(food));
        assertEq(address(three.getWood()), address(wood));
        assertEq(address(three.getCoin()), address(coin));
    }

    function testRates() public {
        uint256 woodFood = 5 * WAD;
        uint256 coinFood = 3 * WAD;

        vm.prank(bob);
        vm.expectRevert("Must be owner");
        three.file(woodFood, coinFood);

        vm.prank(alice);
        three.file(woodFood, coinFood);

        assertEq(three.getWoodFood(), woodFood);
        assertEq(three.getCoinFood(), coinFood);

        vm.prank(alice);
        vm.expectRevert("Must not be a fractional woodFood rate");
        three.file(5 * 10 ** 17, coinFood);

        vm.prank(alice);
        vm.expectRevert("Must not be a fractional coinFood rate");
        three.file(woodFood, 5 * 10 ** 17);
    }

    function testSimpleFarm() public {
        deal(address(food), address(alice), 1_000 * WAD);
        deal(address(wood), address(bob), 1_000 * WAD);
        deal(address(coin), address(charlie), 1_000 * WAD);

        uint256 woodFood = 5 * WAD;
        uint256 coinFood = 3 * WAD;

        // Switch to Alice
        vm.startPrank(alice);

        // Alice sets the rate 5:1
        three.file(woodFood, coinFood);
        assertEq(three.getWoodFood(), woodFood);
        assertEq(three.getCoinFood(), coinFood);

        // Alice transfers 500 food to the contract
        food.transfer(address(three), 500 * WAD);
        vm.stopPrank();

        // Switch to Bob
        vm.startPrank(bob);
        // Bob then exchanges 3 WAD wood for 1 WAD food
        wood.approve(address(three), 5 * WAD);
        three.farm(Three.Resource.WOOD, 5 * WAD);
        assertEq(food.balanceOf(address(bob)), 1 * WAD);

        // Bob then exchanges 8 WAD wood for 1.4 WAD food
        wood.approve(address(three), 7 * WAD);
        three.farm(Three.Resource.WOOD, 7 * WAD);
        assertEq(food.balanceOf(address(bob)) - 1 * WAD, 14 * 10 ** 17);

        // Bob then exchanges 0.5 WAD wood for 0.1 WAD food
        wood.approve(address(three), 5 * 10 ** 17);
        three.farm(Three.Resource.WOOD, 5 * 10 ** 17);
        assertEq(food.balanceOf(address(bob)) - 24 * 10 ** 17, 1 * 10 ** 17);

        vm.stopPrank();

        // Switch to Charlie
        vm.startPrank(charlie);
        // Charlie then exchanges 3 WAD coin for 1 WAD food

        coin.approve(address(three), 3 * WAD);
        three.farm(Three.Resource.COIN, 3 * WAD);
        assertEq(food.balanceOf(address(charlie)), 1 * WAD);

        // Charlie then exchanges 8 WAD coin for 2.67 WAD food

        coin.approve(address(three), 8 * WAD);
        three.farm(Three.Resource.COIN, 8 * WAD);
        assertEq(
            food.balanceOf(address(charlie)) - 1 * WAD,
            2_666_666_666_666_666_666
        );

        // Charlie then exchanges 0.3 WAD coin for 0.1 WAD food
        coin.approve(address(three), 3 * 10 ** 17);
        three.farm(Three.Resource.COIN, 3 * 10 ** 17);
        assertEq(
            food.balanceOf(address(charlie)) - 3_666_666_666_666_666_666,
            1 * 10 ** 17
        );

        vm.stopPrank();
    }

    function testFractionalFarm() public {
        deal(address(food), address(alice), 1_000 * WAD);
        deal(address(wood), address(bob), 1_000 * WAD);
        deal(address(coin), address(charlie), 1_000 * WAD);

        uint256 woodFood = 5 * WAD;
        uint256 coinFood = 3 * WAD;

        // Switch to Alice
        vm.startPrank(alice);

        // Alice sets the rate 5:1
        three.file(woodFood, coinFood);
        assertEq(three.getWoodFood(), woodFood);

        // Alice transfers 500 food to the contract
        food.transfer(address(three), 500 * WAD);
        vm.stopPrank();

        vm.startPrank(bob);
        // Bob exchanges 5 wei wood for 1 wei food
        wood.approve(address(three), 5);
        three.farm(Three.Resource.WOOD, 5);
        //assertEq(food.balanceOf(address(bob)), 1 * WAD);
        assertEq(food.balanceOf(address(bob)), 1);

        // Bob then fails to exchange 4 wei wood for 1 wei food
        wood.approve(address(three), 4);
        vm.expectRevert("Must not be a fractional amount");
        three.farm(Three.Resource.WOOD, 4);

        vm.stopPrank();

        vm.startPrank(charlie);
        // Charlie exchanges 5 wei wood for 1 wei food
        coin.approve(address(three), 5);
        three.farm(Three.Resource.COIN, 5);
        //assertEq(food.balanceOf(address(bob)), 1 * WAD);
        assertEq(food.balanceOf(address(charlie)), 1);

        // Charlie then fails to exchange 2 wei wood for 1 wei food
        coin.approve(address(three), 2);
        vm.expectRevert("Must not be a fractional amount");
        three.farm(Three.Resource.COIN, 2);

        vm.stopPrank();
    }

    function testSimpleChop() public {
        deal(address(wood), address(alice), 5_000 * WAD);
        deal(address(food), address(bob), 1_000 * WAD);
        deal(address(coin), address(charlie), 3_000 * WAD);

        uint256 woodFood = 5 * WAD;
        uint256 coinFood = 3 * WAD;

        // Switch to Alice
        vm.startPrank(alice);

        // Alice sets the rate 5:1
        three.file(woodFood, coinFood);
        assertEq(three.getWoodFood(), woodFood);
        assertEq(three.getCoinFood(), coinFood);

        // Alice transfers 500 wood to the contract
        wood.transfer(address(three), 500 * WAD);
        vm.stopPrank();

        // Switch to Bob
        vm.startPrank(bob);
        // Bob then exchanges 5 WAD food for 25 WAD wood
        food.approve(address(three), 5 * WAD);
        three.chop(Three.Resource.FOOD, 5 * WAD);
        assertEq(wood.balanceOf(address(bob)), 25 * WAD);

        // Bob then exchanges 7 WAD food for 35 WAD wood
        food.approve(address(three), 7 * WAD);
        three.chop(Three.Resource.FOOD, 7 * WAD);
        assertEq(wood.balanceOf(address(bob)) - 25 * WAD, 35 * WAD);
        // Bob then exchanges 0.5 WAD food for 2.5 WAD wood

        food.approve(address(three), 5 * 10 ** 17);
        three.chop(Three.Resource.FOOD, 5 * 10 ** 17);
        assertEq(wood.balanceOf(address(bob)) - 60 * WAD, 25 * 10 ** 17);

        vm.stopPrank();
        vm.prank(alice);
        wood.transfer(address(three), 1000 * WAD);
        // Switch to Charlie
        vm.startPrank(charlie);
        // Charlie then exchanges 3 WAD coin for 5 WAD wood
        coin.approve(address(three), 3 * WAD);
        three.chop(Three.Resource.COIN, 3 * WAD);
        assertEq(wood.balanceOf(address(charlie)), 4_999_999_999_999_999_998);

        // Charlie then exchanges 7 WAD coin for 11.67 WAD wood
        coin.approve(address(three), 7 * WAD);
        three.chop(Three.Resource.COIN, 7 * WAD);
        assertEq(
            wood.balanceOf(address(charlie)) - 4_999_999_999_999_999_998,
            11_666_666_666_666_666_662
        );
        // Charlie then exchanges 0.5 WAD coin for 0.83 WAD wood

        coin.approve(address(three), 5 * 10 ** 17);
        three.chop(Three.Resource.COIN, 5 * 10 ** 17);
        assertEq(
            wood.balanceOf(address(charlie)) -
                4_999_999_999_999_999_998 -
                11_666_666_666_666_666_662,
            833_333_333_333_333_333
        );

        vm.stopPrank();
    }

    function testFractionalChop() public {
        deal(address(wood), address(alice), 5_000 * WAD);
        deal(address(food), address(bob), 1_000 * WAD);
        deal(address(coin), address(charlie), 3_000 * WAD);

        uint256 woodFood = 5 * WAD;
        uint256 coinFood = 3 * WAD;

        // Switch to Alice
        vm.startPrank(alice);

        // Alice sets the rate 5:1
        three.file(woodFood, coinFood);
        assertEq(three.getWoodFood(), woodFood);

        // Alice transfers 500 wood to the contract
        wood.transfer(address(three), 500 * WAD);
        vm.stopPrank();

        vm.startPrank(bob);
        // Bob exchanges 1 wei food for 5 wei wood
        food.approve(address(three), 1);
        three.chop(Three.Resource.FOOD, 1);
        assertEq(wood.balanceOf(address(bob)), 5);

        vm.stopPrank();

        //console.log(three.getWoodFood());
        //console.log(three.getCoinFood());
        //console.log((three.getWoodFood() * WAD) / three.getCoinFood());

        vm.startPrank(charlie);
        // Charlie exchanges 9 wei coin for 14 wei wood
        coin.approve(address(three), 9);
        three.chop(Three.Resource.COIN, 9);
        assertEq(wood.balanceOf(address(charlie)), 14);
        // rate is actually 1666666666666666666 at this stage because of rounding

        vm.stopPrank();
    }

    function testSimpleMine() public {
        deal(address(coin), address(alice), 5_000 * WAD);
        deal(address(food), address(bob), 1_000 * WAD);
        deal(address(wood), address(charlie), 3_000 * WAD);

        uint256 woodFood = 5 * WAD;
        uint256 coinFood = 3 * WAD;

        uint256 rate = ((coinFood * WAD) / woodFood);
        uint256 coinamt = (10 * WAD * rate) / WAD;

        // Switch to Alice
        vm.startPrank(alice);

        // Alice sets the rate 5:1
        three.file(woodFood, coinFood);
        assertEq(three.getWoodFood(), woodFood);
        assertEq(three.getCoinFood(), coinFood);

        // Alice transfers 5000 coin to the contract
        coin.transfer(address(three), 5000 * WAD);
        vm.stopPrank();

        // Switch to Bob
        vm.startPrank(bob);
        // Bob then exchanges 5 WAD food for 15 WAD coin
        food.approve(address(three), 5 * WAD);
        three.mine(Three.Resource.FOOD, 5 * WAD);
        assertEq(coin.balanceOf(address(bob)), 15 * WAD);

        // Bob then exchanges 7 WAD food for 21 WAD wood
        food.approve(address(three), 7 * WAD);
        three.mine(Three.Resource.FOOD, 7 * WAD);
        assertEq(coin.balanceOf(address(bob)) - 15 * WAD, 21 * WAD);
        // Bob then exchanges 0.5 WAD food for 1.5 WAD wood

        food.approve(address(three), 5 * 10 ** 17);
        three.mine(Three.Resource.FOOD, 5 * 10 ** 17);
        assertEq(coin.balanceOf(address(bob)) - 36 * WAD, 15 * 10 ** 17);

        vm.stopPrank();

        // Switch to Charlie
        vm.startPrank(charlie);
        // Charlie then exchanges 10 WAD wood for 6 WAD coin
        wood.approve(address(three), 10 * WAD);

        three.mine(Three.Resource.WOOD, 10 * WAD);
        assertEq(coin.balanceOf(address(charlie)), 6 * WAD);

        // Charlie then exchanges 7 WAD wood for 4.2 WAD coin
        wood.approve(address(three), 7 * WAD);
        three.mine(Three.Resource.WOOD, 7 * WAD);
        assertEq(coin.balanceOf(address(charlie)) - 6 * WAD, 42 * 10 ** 17);
        // Charlie then exchanges 0.5 WAD wood for 0.3 WAD coin

        wood.approve(address(three), 5 * 10 ** 17);
        three.mine(Three.Resource.WOOD, 5 * 10 ** 17);
        assertEq(
            coin.balanceOf(address(charlie)) - 6 * WAD - 42 * 10 ** 17,
            3 * 10 ** 17
        );

        vm.stopPrank();
    }

    function testQuit() public {
        deal(address(food), address(three), 1_000 * WAD);
        three.quit();
        assertEq(food.balanceOf(address(three)), 0);
        assertEq(food.balanceOf(address(alice)), 1_000 * WAD);

        deal(address(food), address(three), 1_000 * WAD);
        deal(address(wood), address(three), 2_000 * WAD);
        three.quit();
        assertEq(food.balanceOf(address(three)), 0);
        assertEq(food.balanceOf(address(alice)), 2_000 * WAD);
        assertEq(wood.balanceOf(address(three)), 0);
        assertEq(wood.balanceOf(address(alice)), 2_000 * WAD);

        deal(address(food), address(three), 1_000 * WAD);
        deal(address(wood), address(three), 2_000 * WAD);
        deal(address(coin), address(three), 3_000 * WAD);
        three.quit();
        assertEq(food.balanceOf(address(three)), 0);
        assertEq(food.balanceOf(address(alice)), 3_000 * WAD);
        assertEq(wood.balanceOf(address(three)), 0);
        assertEq(wood.balanceOf(address(alice)), 4_000 * WAD);
        assertEq(coin.balanceOf(address(three)), 0);
        assertEq(coin.balanceOf(address(alice)), 3_000 * WAD);

        vm.expectRevert(
            "At least one of the tokens must have a positive balance"
        );
        three.quit();
    }
}
