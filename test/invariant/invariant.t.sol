// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import {Test, StdInvariant} from "@forge-std/Test.sol";
import {ERC20Mock} from "../mocks/ERC20Mocks.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";
import {TSwapPool} from "../../src/TSwapPool.sol";
import {Handler} from "../invariant/handler.t.sol";

contract Invariant is StdInvariant, Test{
    PoolFactory factory;
    TSwapPool pool;
    ERC20Mock poolToken;
    ERC20Mock weth;

    int256 constant STARTING_X = 100e18; // Starting ERC20 
    int256 constant STARTING_Y = 50e18;  // Starting WETH
    uint256 constant FEE = 997e15;
    int256 constant MATH_PRECISION = 1e18;

    Handler handler;

    function setUp() public {
        weth = new ERC20Mock();
        poolToken = new ERC20Mock();
        factory = new PoolFactory(address(weth));
        pool = TSwapPool(factory.createPool(address(poolToken)));

        // create the initial values for the pool 
        poolToken.mint(address(this), uint256(STARTING_X));
        weth.mint(address(this), uint256(STARTING_Y));

        // approve
        poolToken.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);

        // deposit
        pool.deposit(
            uint256(STARTING_Y),
            uint256(STARTING_Y),
            uint256(STARTING_X),
            uint64(block.timestamp)
        );

        handler = new Handler(pool);

        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = handler.deposit.selector;
        selectors[1] = handler.swapPoolTokenForWethBasedOnOutputWeth.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    function invariant_constantFormulaProductStaysTheSame() public view {
        assertEq(handler.actualDeltaX(), handler.expectedDeltaX());
    }

    function invariant_deltaYFollowsMath() public view {
        assertEq(handler.actualDeltaY(), handler.expectedDeltaY());
    }
}