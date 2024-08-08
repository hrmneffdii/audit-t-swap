## High

### [H-1] Incorrect fee calculation in `TSwapPool::getInputAmountBasedOnOutput`, causes the protocol take fee too much from user.

**Description**

The `getInputAmountBasedOnOutput` is intended to calculate the amount of tokens a users should deposit give an amount of token of output token. However, the function currently miscalculate. it scale he amount by 10_000 instead of 1_000.

**Impact**

The protocol takes fees too much rather than expected.

**Proof of Concepts**

<details>

<summary> Code </summary>

```javascript
function testGetInputAmountBasedOnOutput() public view {
        uint256 outputAmount = 50e18; 
        uint256 inputReserves = 200e18;
        uint256 outputReserves = 100e18;
        
        uint256 expected = ((inputReserves * outputAmount) * 1000) / ((outputReserves - outputAmount) * 997);
        uint256 result = pool.getInputAmountBasedOnOutput(outputAmount, inputReserves, outputReserves);

        assert(result >= expected);
}
```


</details>

**Recommended mitigation**

```diff
    function getInputAmountBasedOnOutput(
        uint256 outputAmount,
        uint256 inputReserves,
        uint256 outputReserves
    )
        public
        pure
        revertIfZero(outputAmount)
        revertIfZero(outputReserves)
        returns (uint256 inputAmount)
    {
-    return ((inputReserves * outputAmount) * 10000) / ((outputReserves - outputAmount) * 997);
+    return ((inputReserves * outputAmount) * 1000) / ((outputReserves - outputAmount) * 997);
    }
```

## Medium

### [M-1] `TSwapPool::deposit` is missing deadline check, causing the transaction to complete even after the deadline

**Description**

The `deposit` function accepts a deadline as parameter, which according to documentation is "The deadline for the transaction to be completed by". However, this parameter is never used. As a consequence, that add liquidity to the pool might be execute at unexpected times, in market conditions where the deposit rate is unfavorable.

**Impact**

Transactions could be sent when the market conditions are unfavorable to deposit even we adding deadline as a parameter. 

**Proof of Concepts**

The `deadline` parameter is unused

**Recommended mitigation** 

Consider making the following function change 

```javascript
    function deposit(
            uint256 wethToDeposit,
            uint256 minimumLiquidityTokensToMint,
            uint256 maximumPoolTokensToDeposit,
            uint64 deadline
        )
            external
+            revertIfDeadlinePassed(deadline)
            revertIfZero(wethToDeposit)
            returns (uint256 liquidityTokensToMint)    
```

## Low

### [L-1] `TSwapPool::LiquidityAdd` event has a parameter out of order

**Description**

When the `LiquidityAdded` event is emitted by `TSwapPool::_addLiquidityMintAndTransfer` function, it's logs values in an incorrect order. The `PoolTokenDeposit` value should go in the third parameter position, whereas the `wethToDeposit` value should go in second.

**Impact**

Event emitted is incorrect, may lead to  incorect filling parameter as well

**Recommended mitigation**

```diff
-    emit LiquidityAdded(msg.sender, poolTokensToDeposit, wethToDeposit);
+    emit LiquidityAdded(msg.sender, wethToDeposit, poolTokensToDeposit);
```

### [L-2] Default value returned by `SwapExactInput` result in incorect return value given

**Description**

The `SwapExactInput` function is expected to return th actual amount of token bought by caller. However, while it declares the named return value `output` it is never assigned by value, nor uses explicit return statement.

**Impact**

The return value is always zero, it always give incorrect information for the caller.

**Proof of Concepts**

<details>

<summary> Code </summary>

```javascript
function testSwapExactInput() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 10e18);
        poolToken.approve(address(pool), 10e18);
        pool.deposit(10e18, 0, 10e18, uint64(block.timestamp));
        vm.stopPrank();

        
        vm.startPrank(user);
        weth.approve(address(pool), 1e18);
        uint256 result = pool.swapExactInput(weth, 1e18, poolToken, 1e17, uint64(block.timestamp));
        vm.stopPrank();

        assert(result == 0);
    }
```

</details>

**Recommended mitigation**

Shoul be corrected the name variable as result

```diff
    function swapExactInput(){
        ...
-       returns (uint256 output)
+       returns (uint256 outputAmount)
        ...
        }
```

## Informational

### [I-1] `PoolFactory::PoolFactory__PoolDoesNotExist` is not used and should be removed
 
```diff
-     error PoolFactory__PoolDoesNotExist(address tokenAddress);
```

### [I-2] Lacking zero address

```diff
    constructor(address wethToken) {
+       if(weth == address(0)){
+            revert();
+       }
        i_wethToken = wethToken;
    }
```

### [I-3] `PoolFactory::createPool` should use `.symbol()` instead of `.name()`

```diff
-    string memory liquidityTokenName = string.concat("T-Swap ", IERC20(tokenAddress).name());
-    string memory liquidityTokenSymbol = string.concat("ts", IERC20(tokenAddress).name());
+    string memory liquidityTokenName = string.concat("T-Swap ", IERC20(tokenAddress).symbol());
+    string memory liquidityTokenSymbol = string.concat("ts", IERC20(tokenAddress).symbol ());
```