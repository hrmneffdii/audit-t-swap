// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import {TSwapPoolTest} from "./TSwapPool.t.sol";
import { Test, console } from "forge-std/Test.sol";

contract AuditTest is TSwapPoolTest {

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
        weth.approve(address(pool), 10e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(10e18, 0, 100e18, uint64(block.timestamp));
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
}