require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  // solidity: "0.8.24",
  networks: {
    hardhat: {
        forking: {
            // url: "https://rpc.ankr.com/eth",
            // blockNumber: 19376367,
            url: "https://arbitrum-one-rpc.publicnode.com"
        },
        // gasPrice: 95904110618
      }
    },
    solidity: {
      compilers: [
          {
              version: '0.8.24',
              settings: {
                  optimizer: {
                      enabled: true,
                      runs: 1000000,
                  },
              },
          },
      ],
  },
  gasReporter: {
    enabled: true,
    currency: "USD",
    outputFile: "gas-reporter.txt",
    noColors: true,
    coinmarketcap: "5c6a0212-f8a5-45e5-a88a-611f1f3f273d"
    // baseFee: 95904110618
  }
};
