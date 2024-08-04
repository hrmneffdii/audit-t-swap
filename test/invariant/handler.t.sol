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
    int256 public startingX;
    int256 public startingY;
    int256 public expectedDeltaX;
    int256 public expectedDeltaY;
    int256 public actualDeltaX;
    int256 public actualDeltaY;

    address lp = makeAddr("lp");
    address sw = makeAddr("sw");

    constructor(TSwapPool pool_) {
        pool = pool_;
        weth = ERC20Mock(pool_.getWeth());
        poolToken = ERC20Mock(pool_.getPoolToken());
    }  

    function swapPoolTokenForWethBasedOnOutputWeth(uint256 wethOutput) public {
        wethOutput = bound(wethOutput, 0, type(uint64).max);

        if(wethOutput >= weth.balanceOf(address(pool))){
            return;
        }

        uint256 poolTokenAmount = pool.getInputAmountBasedOnOutput(wethOutput, poolToken.balanceOf(address(pool)), weth.balanceOf(address(pool)));

        if(poolTokenAmount >= type(uint64).max){
            return;
        }

        startingY = int256(weth.balanceOf(address(this)));
        startingX = int256(poolToken.balanceOf(address(this)));
        expectedDeltaY = int256(-1) * int256(wethOutput);
        expectedDeltaX = int256(pool.getPoolTokensToDepositBasedOnWeth(wethOutput));

        if(poolToken.balanceOf(sw) <= poolTokenAmount){
            poolToken.mint(sw, poolTokenAmount - poolToken.balanceOf(sw) + 1);
        }

        vm.startPrank(sw);
        poolToken.approve(address(pool), type(uint256).max);
        pool.swapExactOutput(poolToken, weth, wethOutput, uint64(block.timestamp));
        vm.stopPrank();

        uint256 endingY = weth.balanceOf(address(this));
        uint256 endingX = poolToken.balanceOf(address(this));

        actualDeltaX = int256(startingX) - int256(endingX);
        actualDeltaY = int256(startingY) - int256(endingY);
    }

    function deposit(uint256 wethAmount) public {
        uint256 minWeth = pool.getMinimumWethDepositAmount();

        wethAmount = bound(wethAmount, minWeth, type(uint64).max);

        startingY = int256(weth.balanceOf(address(this)));
        startingX = int256(poolToken.balanceOf(address(this)));
        expectedDeltaY = int256(wethAmount);
        expectedDeltaX = int256(pool.getPoolTokensToDepositBasedOnWeth(wethAmount));

        vm.startPrank(lp);
        weth.mint(lp, wethAmount);
        poolToken.mint(lp, uint256(expectedDeltaX));
        weth.approve(address(pool), type(uint256).max);
        poolToken.approve(address(pool), type(uint256).max);
        pool.deposit(wethAmount, 0, uint256(expectedDeltaX), uint64(block.timestamp));
        vm.stopPrank();

        uint256 endingY = weth.balanceOf(address(this));
        uint256 endingX = poolToken.balanceOf(address(this));

        actualDeltaX = int256(startingX) - int256(endingX);
        actualDeltaY = int256(startingY) - int256(endingY);
    }
}