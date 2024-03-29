const { expect } = require("chai");
const { ethers, waffle } = require("hardhat")

describe("Hard", function() {
    let owner;
    let token0;
    let token1;
    let main;

    before(async () => {
        const uniswapV2Router = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
        let provider = ethers.getDefaultProvider();

        [owner] = await ethers.getSigners();
        // console.log(await owner.address);

        NNT = await hre.ethers.getContractFactory("NonameToken");
        noNameToken = await NNT.connect(owner).deploy(owner.address, owner.address, owner.address);
        await noNameToken.connect(owner).transfer(noNameToken.target, 10000000000000000000000n);
        await owner.sendTransaction({
            to: noNameToken.target,
            value: ethers.parseEther("100.0"), // Sends exactly 1.0 ether
        });
        await noNameToken.connect(owner).approve(uniswapV2Router, 1000000000000000000000000000000000n);
        await noNameToken.initialize();
        await noNameToken.openTrading();
        const uniswapV2Pair = await noNameToken.uniswapV2Pair();
        // await uniswapV2Pair.connect(owner).approve(uniswapV2Router, 1000000000000000000000000000000000n)
        // console.log(await noNameToken.balanceOf(owner));

        MAIN = await hre.ethers.getContractFactory("main");
        // console.log("2");
        main = await MAIN.deploy(await noNameToken.target, uniswapV2Pair);
        await noNameToken.connect(owner).transfer(main.target, 10000000000000000000000n);
        await owner.sendTransaction({
            to: main.target,
            value: ethers.parseEther("100.0"), // Sends exactly 1.0 ether
        });
        await main.setup(1,1,1);

        let WETH = await hre.ethers.getContractAt("Token", await main.token1());

        await WETH.connect(owner).approve(await main.uniswapV2Router(), 1000000000000000000000000000000000n);

        console.log(owner.address);
        // await main.connect(owner).token0().approve(await main.uniswapV2Router(), 10000000000000000000000000000n);
        // await main.token1().connect(owner).approve(await main.uniswapV2Router(), 10000000000000000000000000000n);
        await main.addLiq(1000000000n, 100n);
        // console.log("3");
    });
    it("test", async () => {

        // console.log(main.target)
        // console.log(await main.interactions());
        // console.log(await main.amountForSwaps());
        // console.log(await main.numberOfSwaps());
        await main.flashLoan()
        // await token0.connect(owner).approve(main.target, 115792089237316195423570985008687907853269984665640564039457584007913129639935n);
        // await token1.connect(owner).approve(main.target, 115792089237316195423570985008687907853269984665640564039457584007913129639935n);

        // await token0.connect(owner).transfer(main.target, 1000000000000000000n);


        // await main.flashLoanPrimary();

        // await main.flashLoanSecondary();


        /*
            Что делает данный тест?

            1. Даем 2 апрува на адрес смарт контракта
            2. Отправляем на адрес смарт контракта 1 RAI
            3. Вызываем основную функцию в смарт контракте, которая будет накручивать обьем. В смарт контракте прописываем, сколько раз совершать накрутку обьема.

        */

    });
});
