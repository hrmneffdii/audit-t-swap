// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {ERC20Mock} from "../mocks/ERC20Mocks.sol";
import {TSwapPool} from "../../src/TSwapPool.sol";
import {Test} from "@forge-std/Test.sol";

contract Handler is Test{
    ERC20Mock weth;
    ERC20Mock poolToken;
    TSwapPool pool;

    // actor
    address lp = makeAddr("liquidityProvider");
    address user = makeAddr("user");

    // y = Token Balance weth
    // x = Token Balance poolToken
    // x * y = k (constant formula)
    // x * y = (x + ∆x) * (y − ∆y) 

    // Our Ghost variables
    int256 public actualDeltaY;
    int256 public expectedDeltaY;

    int256 public actualDeltaX;
    int256 public expectedDeltaX;

    int256 public startingX;
    int256 public startingY;

    constructor(TSwapPool _pool) {
        pool = _pool;
        weth = ERC20Mock(pool.getWeth());
        poolToken = ERC20Mock(pool.getPoolToken());
    }
    
    // swap pool token for weth through swapExactOutput
    function swapPoolTokenForWethBasedOnOutputWeth(uint256 outputWethAmount) public {
        if(weth.balanceOf(address(pool)) <= pool.getMinimumWethDepositAmount()){
            return;
        }

        outputWethAmount = bound(outputWethAmount, pool.getMinimumWethDepositAmount(),type(uint64).max);
        if (outputWethAmount == weth.balanceOf(address(pool))) {
            return;
        }

        uint256 poolTokenAmount = pool.getInputAmountBasedOnOutput(outputWethAmount, poolToken.balanceOf(address(pool)), weth.balanceOf(address(pool)));

        if(poolTokenAmount >= type(uint64).max){
            return ;
        }

        if(poolToken.balanceOf(user) <= poolTokenAmount){
            poolToken.mint(user, poolTokenAmount + 1);
        }

        _updateStartingDelta(int256(outputWethAmount) * -1, int256(poolTokenAmount));

        vm.startPrank(user);
        poolToken.approve(address(pool), poolTokenAmount);
        pool.swapExactOutput({
            inputToken: poolToken,
            outputToken: weth,
            outputAmount: outputWethAmount,
            deadline: uint64(block.timestamp)
        });
        vm.stopPrank();

        _updateEndingDelta();
    }

    // deposit 
    function deposit(uint256 wethToDeposit) public {
        wethToDeposit = bound(wethToDeposit, pool.getMinimumWethDepositAmount(), type(uint64).max);
        uint256 poolTokenToDeposit = pool.getPoolTokensToDepositBasedOnWeth(wethToDeposit); 
    
        _updateStartingDelta(int256(wethToDeposit), int256(poolTokenToDeposit));

        vm.startPrank(lp);
        weth.mint(lp, wethToDeposit);
        weth.approve(address(pool), wethToDeposit);

        poolToken.mint(lp, poolTokenToDeposit);
        poolToken.approve(address(pool), poolTokenToDeposit);

        pool.deposit({
            wethToDeposit: wethToDeposit,
            minimumLiquidityTokensToMint: 0,
            maximumPoolTokensToDeposit: poolTokenToDeposit,
            deadline: uint64(block.timestamp)
        });
        vm.stopPrank();

        _updateEndingDelta();
    }

    function _updateStartingDelta(int256 wethAmount, int256 poolTokenAmount) internal {
        startingX = int256(poolToken.balanceOf(address(pool)));
        startingY = int256(weth.balanceOf(address(pool)));

        expectedDeltaX = poolTokenAmount;
        expectedDeltaY = wethAmount;
    }   

    function _updateEndingDelta() internal {
        uint256 endingX = poolToken.balanceOf(address(pool));
        uint256 endingY = weth.balanceOf(address(pool));

        actualDeltaX = int256(endingX) - startingX;
        actualDeltaY = int256(endingY) - startingY;
    }
}
