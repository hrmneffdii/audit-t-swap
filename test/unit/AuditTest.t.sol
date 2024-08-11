// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import {TSwapPoolTest} from "./TSwapPool.t.sol";
import { Test, console } from "forge-std/Test.sol";

contract AuditTest is TSwapPoolTest {

    uint64[] public boundResults = [
        196999693141235218,
        4286131349,
        224704038107275,
        1889567281,
        864605657370145095,
        1000000003,
        244866384630,
        577408235369742,
        1000000002,
        947295180945
    ];

    function testGetInputAmountBasedOnOutput() public view {
        uint256 outputAmount = 50e18; 
        uint256 inputReserves = 200e18;
        uint256 outputReserves = 100e18;
        
        uint256 expected = ((inputReserves * outputAmount) * 1000) / ((outputReserves - outputAmount) * 997);
        uint256 result = pool.getInputAmountBasedOnOutput(outputAmount, inputReserves, outputReserves);

        assert(result >= expected);
    }
    
    modifier deposited {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 50e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(50e18, 0, 100e18, uint64(block.timestamp));
        vm.stopPrank();
        _;
    }

    function testSwapExactInput() public deposited {
        vm.startPrank(user);
        weth.approve(address(pool), 1e18);
        uint256 result = pool.swapExactInput(weth, 1e18, poolToken, 1e17, uint64(block.timestamp));
        vm.stopPrank();

        assert(result == 0);
    }

    function testSwapExactOutput() public {
        // initialitation
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 10e18);
        poolToken.approve(address(pool), 50e18);
        pool.deposit(10e18, 0, 50e18, uint64(block.timestamp));
        vm.stopPrank();

        console.log(pool.getPriceOfOneWethInPoolTokens() / 1e18);
        // returned 1 weth = 4 poolToken

        // the market price changes suddenly
        vm.startPrank(user);
        poolToken.approve(address(pool), 6 ether);
        pool.swapExactOutput(poolToken, weth, 1 ether, uint64(block.timestamp));
        vm.stopPrank();

        console.log(pool.getPriceOfOneWethInPoolTokens() / 1e18);
    }

    function testInvariantBroken() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        uint256 outputWeth = 1e17;

        vm.startPrank(user);
        poolToken.approve(address(pool), type(uint256).max);
        poolToken.mint(user, 100e18);
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));

        int256 startingY = int256(weth.balanceOf(address(pool)));
        int256 expectedDeltaY = int256(-1) * int256(outputWeth);

        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        vm.stopPrank();

        uint256 endingY = weth.balanceOf(address(pool));
        int256 actualDeltaY = int256(endingY) - int256(startingY);
        assertEq(actualDeltaY, expectedDeltaY);
    }
}