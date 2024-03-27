const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Hard", function() {
    let owner;
    let token0;
    let token1;
    let main;

    before(async () => {
        owner = await ethers.getImpersonatedSigner("0x3a3eE61F7c6e1994a2001762250A5E17B2061b6d");

        // token0 = await hre.ethers.getContractAt("Token", "0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919");
        // token1 = await hre.ethers.getContractAt("Token", "0x6B175474E89094C44Da98b954EedeAC495271d0F");

        // main = await hre.ethers.getContractAt("main", "0x24ecc5e6eaa700368b8fac259d3fbd045f695a08");
        NNT = await hre.ethers.getContractFactory("NonameToken");
        noNameToken = await NNT.deploy();
        MAIN = await hre.ethers.getContractFactory("main");
        noNameToken = await NNT.deploy(noNameToken.address());
    });
    it("test", async () => {

        console.log(noNameToken.address())
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
