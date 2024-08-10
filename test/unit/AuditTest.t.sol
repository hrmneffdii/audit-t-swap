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

    /**
     * Scenario
     * 
     * a users always swap pool token for weth 10 times exactly
     */
    function test_breakTheInvariant() public deposited {

        int256 startingX = int256(poolToken.balanceOf(address(pool)));
        int256 startingY = int256(weth.balanceOf(address(pool)));

        for(uint64 i; i < boundResults.length; i++){
            vm.startPrank(user);
            poolToken.mint(user, boundResults[i]);
            poolToken.approve(address(pool), boundResults[i]);
            pool.swapExactOutput({
                inputToken: poolToken,
                outputToken: weth,
                outputAmount: boundResults[i],
                deadline: uint64(block.timestamp)
            });
            vm.stopPrank();
        }
        
        int256 endingX = int256(poolToken.balanceOf(address(pool)));
        int256 endingY = int256(weth.balanceOf(address(pool)));

        // balance x always decrease since a user doing swap token for eth, other hand, balance y always increase due to the protocol receive eth
        assert(startingX >= endingX);
        assert(startingY <= endingY);
    }
}