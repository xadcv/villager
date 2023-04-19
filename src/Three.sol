// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

/// @title  A smol contract for AoE II related commodities that is definitely Not An Exchange
contract Three {
    uint256 constant WAD = 10 ** 18;
    // --- Internal  ---
    IERC20 private food;
    IERC20 private wood;
    IERC20 private coin;

    enum Resource {
        FOOD,
        WOOD,
        COIN
    }

    address private owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    // --- Rates ---
    uint256 woodFood;
    uint256 coinFood;

    // --- Events ---
    event File(uint256 woodFood, uint256 coinFood);
    event Quit(uint256 food, uint256 wood, uint256 coin);
    event Farm(address to, uint256 amt, Three.Resource resource);
    event Chop(address to, uint256 amt, Three.Resource resource);
    event Mine(address to, uint256 amt, Three.Resource resource);

    // --- Init ---
    constructor(address food_, address wood_, address coin_, address owner_) {
        food = IERC20(food_);
        wood = IERC20(wood_);
        coin = IERC20(coin_);

        owner = owner_;
    }

    // --- Administration ---
    function getFood() public view returns (IERC20) {
        return food;
    }

    function getWood() public view returns (IERC20) {
        return wood;
    }

    function getCoin() public view returns (IERC20) {
        return coin;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getWoodFood() public view returns (uint256) {
        return woodFood;
    }

    function getCoinFood() public view returns (uint256) {
        return coinFood;
    }

    function getFoodWood() public virtual returns (uint256) {
        return (1 * WAD) / woodFood;
    }

    function getFoodCoin() public virtual returns (uint256) {
        return (1 * WAD) / coinFood;
    }

    function getCoinWood() public virtual returns (uint256) {
        return (1 * ((coinFood * WAD) / woodFood)) / WAD;
    }

    function getWoodCoin() public virtual returns (uint256) {
        return (1 * ((woodFood * WAD) / coinFood)) / WAD;
    }

    // --- Function Implementation ---

    ///@dev Needs an exchange rate expressed in WAD
    function file(
        uint256 woodFood_,
        uint256 coinFood_
    ) public onlyOwner returns (bool) {
        require(woodFood_ / WAD > 0, "Must not be a fractional woodFood rate");
        require(coinFood_ / WAD > 0, "Must not be a fractional coinFood rate");
        woodFood = woodFood_;
        coinFood = coinFood_;

        emit File(woodFood, coinFood);
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
        } else if (name_ == Resource.COIN) {
            require(
                coin.balanceOf(msg.sender) >= amount_,
                "Must have enough coin balance"
            );
            require(
                coin.allowance(msg.sender, address(this)) >= amount_,
                "Must have coin allowance"
            );
            require(
                food.balanceOf(address(this)) > (amount_ * WAD) / coinFood,
                "Contract does not have enough food"
            );
            require(
                (amount_ * WAD) / coinFood > 0,
                "Must not be a fractional amount"
            );
            coin.transferFrom(msg.sender, address(this), amount_);
            food.transfer(msg.sender, (amount_ * WAD) / coinFood);
            emit Farm(msg.sender, (amount_ * WAD) / coinFood, Resource.COIN);
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
        } else if (name_ == Resource.COIN) {
            uint256 rate = ((woodFood * WAD) / coinFood);

            require(
                coin.balanceOf(msg.sender) >= amount_,
                "Must have enough coin balance"
            );
            require(
                coin.allowance(msg.sender, address(this)) >= amount_,
                "Must have coin allowance"
            );
            require(
                wood.balanceOf(address(this)) > (amount_ * rate) / WAD,
                "Contract does not have enough wood"
            );
            require(
                (amount_ * rate) / WAD > 0,
                "Must not be a fractional amount"
            );
            coin.transferFrom(msg.sender, address(this), amount_);
            wood.transfer(msg.sender, (amount_ * rate) / WAD);
            emit Chop(msg.sender, (amount_ * rate) / WAD, Resource.COIN);
        }
    }

    ///@dev Exchanges the provided resource for coin at the resource rate
    function mine(Resource name_, uint256 amount_) public {
        require(name_ != Resource.COIN, "Must be a different resource to coin");
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
                coin.balanceOf(address(this)) > amount_ * (coinFood / WAD),
                "Contract does not have enough coin"
            );
            require(
                amount_ * (coinFood / WAD) > 0,
                "Must not be a fractional amount"
            );
            food.transferFrom(msg.sender, address(this), amount_);
            coin.transfer(msg.sender, amount_ * (coinFood / WAD));
            emit Mine(msg.sender, amount_ * (coinFood / WAD), Resource.FOOD);
        } else if (name_ == Resource.WOOD) {
            uint256 rate = ((coinFood * WAD) / woodFood);

            require(
                wood.balanceOf(msg.sender) >= amount_,
                "Must have enough wood balance"
            );
            require(
                wood.allowance(msg.sender, address(this)) >= amount_,
                "Must have wood allowance"
            );
            require(
                coin.balanceOf(address(this)) > (amount_ * rate) / WAD,
                "Contract does not have enough coin"
            );
            require(
                (amount_ * rate) / WAD > 0,
                "Must not be a fractional amount"
            );
            wood.transferFrom(msg.sender, address(this), amount_);
            coin.transfer(msg.sender, (amount_ * rate) / WAD);
            emit Mine(msg.sender, (amount_ * rate) / WAD, Resource.WOOD);
        }
    }

    ///@dev Wipes the balance of each token to owner
    function quit() public onlyOwner {
        require(
            food.balanceOf(address(this)) > 0 ||
                wood.balanceOf(address(this)) > 0 ||
                coin.balanceOf(address(this)) > 0,
            "At least one of the tokens must have a positive balance"
        );
        food.transfer(owner, food.balanceOf(address(this)));
        wood.transfer(owner, wood.balanceOf(address(this)));
        coin.transfer(owner, coin.balanceOf(address(this)));
        emit Quit(
            food.balanceOf(address(this)),
            wood.balanceOf(address(this)),
            coin.balanceOf(address(this))
        );
    }
}
