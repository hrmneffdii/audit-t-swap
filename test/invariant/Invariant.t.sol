// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import { Test, StdInvariant,console } from "forge-std/Test.sol";
import { TSwapPool } from "../../src/PoolFactory.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";
import {ERC20Mock} from "../mocks/ERC20Mocks.sol";
import {Handler} from "./Handler.t.sol";

contract Invariant is StdInvariant, Test{
    ERC20Mock weth;
    ERC20Mock poolToken;
    TSwapPool pool;
    PoolFactory factory;
    Handler handler;

    address lp = makeAddr("lp");
    address user = makeAddr("user");

    int256 constant STARTING_X = 100e18; // starting poolToken(X)
    int256 constant STARTING_Y = 50e18; // starting weth(Y)

    function setUp() public {
        weth = new ERC20Mock();
        poolToken = new ERC20Mock();
        factory = new PoolFactory(address(weth));
        pool = TSwapPool(factory.createPool(address(poolToken)));

        handler = new Handler(pool);

        // initialize X and Y in pool
        vm.startPrank(lp);
        poolToken.mint(lp, uint256(STARTING_X));
        poolToken.approve(address(pool), type(uint256).max);
        weth.mint(lp, uint256(STARTING_Y));
        weth.approve(address(pool), type(uint256).max);
        pool.deposit({
            wethToDeposit: uint256(STARTING_Y),
            minimumLiquidityTokensToMint: uint256(STARTING_Y),
            maximumPoolTokensToDeposit: uint256(STARTING_X),
            deadline: uint64(block.timestamp)
        });
        vm.stopPrank();

        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = handler.deposit.selector;
        selectors[1] = handler.swapPoolTokenForWethBasedOnOutputWeth.selector;

        targetContract(address(handler));
        targetSelector(FuzzSelector({
            addr: address(handler),
            selectors: selectors
        }));
    }

    function invariant_deltaXStaySame() public view{
        assertEq(handler.expectedDeltaX(), handler.actualDeltaX());
    }

    function invariant_deltaYStaySame() public view{
        assertEq(handler.expectedDeltaY(), handler.actualDeltaY());
    }

}