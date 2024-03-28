// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "./BalancerFlashLoan.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {NonameToken} from "./NoNameToken.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import "hardhat/console.sol";

contract main {
    //how many jumps of work you need
    uint public interactions;
    uint256 public amountForSwaps;
    uint public numberOfSwaps;

    address public constant vault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address public constant keeper = 0x095454F216EC9485da86D49aDffAcFD0Fa3e5BE5;

    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Pair public uniswapV2Pair;

    NonameToken public token0; // NNT
    IERC20 public token1 = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH

    constructor (address payable _noNameToken) {
        token0 = NonameToken(_noNameToken);
        uniswapV2Pair = IUniswapV2Pair(IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(token0), address(token1)));
    }

    receive() external payable {}

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory
    ) external {
        work(tokens, amounts);

        for (uint256 i; i < tokens.length; ) {
            IERC20 token = tokens[i];
            uint256 amount = amounts[i];

            disadvantage(token, amount);

            console.log("borrowed amount:", amount);
            uint256 feeAmount = feeAmounts[i];
            console.log("flashloan fee: ", feeAmount);

            // Return loan
            token.transfer(vault, amount);

            unchecked {
                ++i;
            }
        }
    }

    function flashLoan() external {
        IERC20[] memory tokens = new IERC20[](1);
        uint256[] memory amounts = new uint256[](1);

        tokens[0] = token1;
        // подсчет количества эфира для нужного количества токенов + комса на свапы и эфир на свапы
        amounts[0] = countAmountOfTokens();

        for(uint i; i < interactions; ){
            IBalancerVault(vault).flashLoan(
                IFlashLoanRecipient(address(this)),
                tokens,
                amounts,
                ""
            );

            unchecked {
                ++i;
            }
        }
    }

    function setup(uint _interactions, uint256 _amountForSwaps, uint _numberOfSwaps) external {
        interactions = _interactions;
        amountForSwaps = _amountForSwaps;
        numberOfSwaps = _numberOfSwaps;
        token1.approve(address(uniswapV2Router), type(uint256).max);
        token0.approve(address(uniswapV2Router), type(uint256).max);
        token1.approve(address(uniswapV2Pair), type(uint256).max);
        token0.approve(address(uniswapV2Pair), type(uint256).max);
        console.log("made some approves");
    }

    function addLiq(uint256 amount_token_0, uint256 amount_token_1) external {
        console.log("token0 balance is:", token0.balanceOf(address(this)));
        console.log("eth balance is:", address(this).balance);
        console.log("amount_token_0 is:", amount_token_0);
        console.log("amount_token_1 is:", amount_token_1);
        uniswapV2Router.addLiquidityETH{ value:amount_token_1 }(
            address(token0),
            amount_token_0,
            0,
            0,
            address(this),
            3600000000000000
        );
    }

    function work (
        IERC20[] memory tokens,
        uint256[] memory amounts
        ) public {
        uniswapV2Router.addLiquidity(
            address(token0),
            address(tokens[0]),
            token0.balanceOf(address(this)),
            amounts[0] - amountForSwaps,
            0,
            0,
            address(this),
            36000000000);
        uint256 start_balance_0 = token0.balanceOf(address(this));
        uint256 start_balance_1 = tokens[0].balanceOf(address(this));
        for (uint i = 0; i < numberOfSwaps; i++) {
            if (i % 2 == 0) {
                address[] memory path = new address[](2);
                path[0] = address(tokens[0]);
                path[1] = address(token0);
                uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    start_balance_1,
                    0,
                    path,
                    address(this),
                    36000000000
                );
            } else {
                address[] memory path = new address[](2);
                path[0] = address(token0);
                path[1] = address(tokens[0]);
                uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    start_balance_0,
                    0,
                    path,
                    address(this),
                    36000000000
                );
            }
            uint256 start_balance_0 = token0.balanceOf(address(this));
            uint256 start_balance_1 = tokens[0].balanceOf(address(this));
        }

        uniswapV2Router.removeLiquidity(
            address(token0),
            address(tokens[0]),
            uniswapV2Pair.balanceOf(address(this)),
            0,
            0,
            address(this),
            36000000
        );
    }

    function disadvantage(IERC20 token, uint256 amount) internal {
        uint256 currentAmount = token.balanceOf(address(this));

        if(currentAmount < amount) {
            uint256 missingQuantity = amount - currentAmount;
            token.transferFrom(keeper, address(this), missingQuantity);
        }
    }

    function countAmountOfTokens() internal view returns (uint256) {
        uint256 count_0 = token0.balanceOf(address(this));
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = uniswapV2Pair.getReserves();
        require((reserve0 > 0) && (reserve1 > 0), "Empty pool");
        // x / y = (x + x1) / (y + y1) => x * y + x * y1 = x * y + x1 * y => x * y1 = x1 * y => y1 = x1 * y / x
        return count_0 * reserve1 / reserve0 + amountForSwaps;
    }
}
