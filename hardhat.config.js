require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  // solidity: "0.8.24",
  networks: {
    hardhat: {
        forking: {
            url: "https://rpc.ankr.com/eth",
            blockNumber: 19376367,
        }
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
};
