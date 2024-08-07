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