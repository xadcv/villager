// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

/// @title  A smol contract for AoE II related commodities that is definitely Not An Exchange
contract Two {
    uint256 constant WAD = 10 ** 18;
    // --- Internal  ---
    IERC20 private food;
    IERC20 private wood;

    enum Resource {
        FOOD,
        WOOD
    }

    address private owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // --- Rates ---
    uint256 woodFood;

    // --- Events ---
    event File(uint256 woodFood, uint256 coinFood);
    event Quit(uint256 food, uint256 wood, uint256 coin);
    event Farm(address to, uint256 amt, Two.Resource resource);
    event Chop(address to, uint256 amt, Two.Resource resource);

    // --- Init ---
    constructor(address food_, address wood_, address owner_) {
        food = IERC20(food_);
        wood = IERC20(wood_);

        owner = owner_;
    }

    // --- Administration ---
    function getFood() public view returns (IERC20) {
        return food;
    }

    function getWood() public view returns (IERC20) {
        return wood;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getWoodFood() public view returns (uint256) {
        return woodFood;
    }

    function getFoodWood() public virtual returns (uint256) {
        return (1 * WAD) / woodFood;
    }

    // --- Function Implementation ---

    ///@dev Needs an exchange rate expressed in WAD
    function file(uint256 woodFood_) public onlyOwner returns (bool) {
        require(woodFood_ / WAD > 0, "Must not be a fractional rate");
        woodFood = woodFood_;

        emit File(woodFood, 0);
        return true;
    }

    ///@dev Exchanges the provided resource for food at the resource rate
    function farm(Resource name_, uint256 amount_) public {
        require(name_ != Resource.FOOD, "Must be a different resource to food");
        if (name_ == Resource.WOOD) {
            require(
                wood.balanceOf(msg.sender) >= amount_,
                "Must have enough wood balance"
            );
            require(
                wood.allowance(msg.sender, address(this)) >= amount_,
                "Must have wood allowance"
            );
            require(
                food.balanceOf(address(this)) > (amount_ * WAD) / woodFood,
                "Contract does not have enough food"
            );
            require(
                (amount_ * WAD) / woodFood > 0,
                "Must not be a fractional amount"
            );
            wood.transferFrom(msg.sender, address(this), amount_);
            food.transfer(msg.sender, (amount_ * WAD) / woodFood);
            emit Farm(msg.sender, (amount_ * WAD) / woodFood, Resource.WOOD);
        }
    }

    ///@dev Exchanges the provided resource for wood at the resource rate
    function chop(Resource name_, uint256 amount_) public {
        require(name_ != Resource.WOOD, "Must be a different resource to wood");
        if (name_ == Resource.FOOD) {
            require(
                food.balanceOf(msg.sender) >= amount_,
                "Must have enough food balance"
            );
            require(
                food.allowance(msg.sender, address(this)) >= amount_,
                "Must have food allowance"
            );
            require(
                wood.balanceOf(address(this)) > amount_ * (woodFood / WAD),
                "Contract does not have enough wood"
            );
            require(
                amount_ * (woodFood / WAD) > 0,
                "Must not be a fractional amount"
            );
            food.transferFrom(msg.sender, address(this), amount_);
            wood.transfer(msg.sender, amount_ * (woodFood / WAD));
            emit Chop(msg.sender, amount_ * (woodFood / WAD), Resource.FOOD);
        }
    }

    ///@dev Wipes the balance of each token to owner
    function quit() public onlyOwner {
        require(
            food.balanceOf(address(this)) > 0 ||
                wood.balanceOf(address(this)) > 0,
            "At least one of the tokens must have a positive balance"
        );
        food.transfer(owner, food.balanceOf(address(this)));
        wood.transfer(owner, wood.balanceOf(address(this)));
        emit Quit(
            food.balanceOf(address(this)),
            wood.balanceOf(address(this)),
            0
        );
    }
}
