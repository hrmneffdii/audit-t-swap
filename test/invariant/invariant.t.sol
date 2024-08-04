// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import {Test} from "@forge-std/Test.sol";
import {StdInvariant} from "@forge-std/StdInvariant.sol";
import {ERC20Mock} from "../mocks/ERC20Mocks.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";
import {TSwapPool} from "../../src/TSwapPool.sol";
import {Handler} from "../invariant/handler.t.sol";

contract Invariant is StdInvariant, Test{
    // we have two assets
    ERC20Mock poolToken;
    ERC20Mock weth;

    Handler handler;

    // we are gonna need the contract
    PoolFactory factory;
    TSwapPool pool;

    // starting amount
    int256 constant STARTING_X = 100e18; // Starting ERC20 / X
    int256 constant STARTING_Y = 50e18;  // Starting WETH

    function setUp() public {
        weth = new ERC20Mock();
        poolToken = new ERC20Mock();
        factory = new PoolFactory(address(weth));
        pool = TSwapPool(factory.createPool(address(poolToken)));

        // create those balances x and y
        poolToken.mint(address(this), uint256(STARTING_X));
        weth.mint(address(this), uint256(STARTING_Y));

        // approve
        poolToken.approve(address(pool), uint256(STARTING_X));
        weth.approve(address(pool), uint256(STARTING_Y));

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
    }

    function invariant_constantFormulaProductStaysTheSame() public view {
        assertEq(handler.actualDeltaX(), handler.expectedDeltaX());
    }
}