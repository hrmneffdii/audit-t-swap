// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import { Test } from "forge-std/Test.sol";
import { TSwapPool } from "../../src/TSwapPool.sol";
import { ERC20Mock } from "../mocks/ERC20Mocks.sol";

contract Handler is Test {
    TSwapPool pool;
    ERC20Mock weth;
    ERC20Mock poolToken;

    address lp = makeAddr("lp");
    address user = makeAddr("user");

    // ghost variable
    int256 public actualDeltaY;
    int256 public expectedDeltaY;

    int256 public actualDeltaX;
    int256 public expectedDeltaX;

    int256 public startingX;
    int256 public startingY;

    constructor(TSwapPool pool_) {
        pool = pool_;
        weth = ERC20Mock(address(pool_.getWeth()));
        poolToken = ERC20Mock(address(pool_.getPoolToken()));
    }

    function swapPoolTokenForWethBasedOnOutputWeth(uint256 wethOutput) public {
        if (weth.balanceOf(address(pool)) <= pool.getMinimumWethDepositAmount()) {
            return;
        }

        wethOutput = bound(wethOutput, pool.getMinimumWethDepositAmount(), weth.balanceOf(address(pool)));

        if (wethOutput == weth.balanceOf(address(pool))) {
            return;
        }

        uint256 poolTokenAmount = pool.getInputAmountBasedOnOutput(
            wethOutput, poolToken.balanceOf(address(pool)), weth.balanceOf(address(pool))
        );

        if (poolTokenAmount > type(uint64).max) {
            return;
        }

        _updateStartingDeltas(int256(wethOutput) * -1, int256(poolTokenAmount));

        if (poolToken.balanceOf(user) < poolTokenAmount) {
            poolToken.mint(user, poolTokenAmount - poolToken.balanceOf(user) + 1);
        }

        vm.startPrank(user);
        poolToken.approve(address(pool), type(uint256).max);
        pool.swapExactOutput(poolToken, weth, wethOutput, uint64(block.timestamp));
        vm.stopPrank();

        _updateEndingDeltas();
    }

    function deposit(uint256 wethAmount) public {
        wethAmount = bound(wethAmount, pool.getMinimumWethDepositAmount(), type(uint64).max);
        uint256 amountPoolTokensToDepositBasedOnWeth = pool.getPoolTokensToDepositBasedOnWeth(wethAmount);
        _updateStartingDeltas(int256(wethAmount), int256(amountPoolTokensToDepositBasedOnWeth));

        vm.startPrank(lp);
        weth.mint(lp, wethAmount);
        poolToken.mint(lp, amountPoolTokensToDepositBasedOnWeth);

        weth.approve(address(pool), wethAmount);
        poolToken.approve(address(pool), amountPoolTokensToDepositBasedOnWeth);

        pool.deposit(wethAmount, 0, amountPoolTokensToDepositBasedOnWeth, uint64(block.timestamp));
        vm.stopPrank();
        _updateEndingDeltas();
    }

    function _updateStartingDeltas(int256 wethAmount, int256 poolTokenAmount) internal {
        startingY = int256(poolToken.balanceOf(address(pool)));
        startingX = int256(weth.balanceOf(address(pool)));

        expectedDeltaX = wethAmount;
        expectedDeltaY = poolTokenAmount;
    }

    function _updateEndingDeltas() internal {
        uint256 endingPoolTokenBalance = poolToken.balanceOf(address(pool));
        uint256 endingWethBalance = weth.balanceOf(address(pool));

        // sell tokens == x == poolTokens
        int256 actualDeltaPoolToken = int256(endingPoolTokenBalance) - int256(startingY);
        int256 deltaWeth = int256(endingWethBalance) - int256(startingX);

        actualDeltaX = deltaWeth;
        actualDeltaY = actualDeltaPoolToken;
    }
}
