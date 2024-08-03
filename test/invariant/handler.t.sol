// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {TSwapPool} from "../../src/TSwapPool.sol";
import {ERC20Mock} from "../mocks/ERC20Mocks.sol";

contract Handler is Test {
    TSwapPool pool;
    ERC20Mock weth;
    ERC20Mock poolToken;

    // ghost variable
    uint256 startingX;
    uint256 startingY;
    uint256 expectedDeltaX;
    uint256 expectedDeltaY;
    int256 actualDeltaX;
    int256 actualDeltaY;

    address lp = makeAddr("lp");

    constructor(TSwapPool pool_) {
        pool = pool_;
        weth = ERC20Mock(pool_.getWeth());
        poolToken = ERC20Mock(pool_.getPoolToken());
    }  

    function deposit(uint256 wethAmount) public {
        wethAmount = bound(wethAmount, 0, type(uint64).max);

        startingY = weth.balanceOf(address(this));
        startingX = poolToken.balanceOf(address(this));
        expectedDeltaX = pool.getPoolTokensToDepositBasedOnWeth(wethAmount);
        expectedDeltaY = wethAmount;

        vm.startPrank(lp);
        weth.mint(lp, wethAmount);
        poolToken.mint(lp, expectedDeltaX);
        weth.approve(address(pool), wethAmount);
        poolToken.approve(address(pool), expectedDeltaX);
        pool.deposit(wethAmount, 0, expectedDeltaX, uint64(block.timestamp));
        vm.stopPrank();

        uint256 endingY = weth.balanceOf(address(this));
        uint256 endingX = poolToken.balanceOf(address(this));

        actualDeltaX = int256(startingX) - int256(endingX);
        actualDeltaY = int256(startingY) - int256(endingY);
    }
}