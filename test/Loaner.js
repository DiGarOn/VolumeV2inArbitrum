const { expect } = require("chai");
const { ethers, waffle } = require("hardhat")

describe("Hard", function() {
    let owner;
    let token0;
    let token1;
    let main;

    before(async () => {
        // let keeper = await ethers.getImpersonatedSigner("0x8EB8a3b98659Cce290402893d0123abb75E3ab28"); // mainnet
        let keeper = await ethers.getImpersonatedSigner("0xC3E5607Cd4ca0D5Fe51e09B60Ed97a0Ae6F874dd"); // arbitrum
        // const uniswapV2Router = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"; // mainnet
        const uniswapV2Router = "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506";

        [owner] = await ethers.getSigners();

        NNT = await hre.ethers.getContractFactory("NonameToken");
        noNameToken = await NNT.connect(owner).deploy(owner.address, owner.address, owner.address);
        await noNameToken.connect(owner).transfer(noNameToken.target, 50000000000000000000000n);

        await owner.sendTransaction({
            to: noNameToken.target,
            value: ethers.parseEther("0.0002")
        });

        await noNameToken.connect(owner).approve(uniswapV2Router, 1000000000000000000000000000000000n);
        console.log("here");
        await noNameToken.initialize();
        await noNameToken.openTrading();
        await noNameToken.connect(keeper).approve(uniswapV2Router, 1000000000000000000000000000000000n);

        const uniswapV2Pair = await noNameToken.uniswapV2Pair();

        MAIN = await hre.ethers.getContractFactory("main");
        main = await MAIN.deploy(await noNameToken.target, uniswapV2Pair);
        noNameToken.add_isExcludedFromFee(main.target);
        await noNameToken.connect(owner).transfer(main.target, 10000000000000000000000n);
        await owner.sendTransaction({
            to: main.target,
            value: ethers.parseEther("100.0"), // Sends exactly 1.0 ether
        });
        await main.setup(1,5000000000000000000000n,8);

        await noNameToken.connect(keeper).approve(main.target, 1000000000000000000000000000000000n);
        await noNameToken.connect(keeper).approve(uniswapV2Router, 1000000000000000000000000000000000n);

        let WETH = await hre.ethers.getContractAt("Token", await main.token1());
        await WETH.connect(owner).approve(await main.uniswapV2Router(), 1000000000000000000000000000000000n);
        await WETH.connect(keeper).approve(main.target, 1000000000000000000000000000000000n);

        console.log(owner.address);

        await main.addLiq(1000000000n, 100n);
    });
    it("test", async () => {
        await main.flashLoan();
    });
});
