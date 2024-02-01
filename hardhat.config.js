require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();

const { PRIVATE_KEY, ETHERSCAN_API_KEY, GOERLI_NETWORK_AUX, MENMONIC } =
  process.env;
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "hardhat",
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
  bscscan: {
    apiKey: ETHERSCAN_API_KEY,
    customChains: [
      {
        network: "opbnb",
        chainId: 204,
        urls: {
          apiURL: "https://opbnb-mainnet-rpc.bnbchain.org",
          browserURL: "https://opbnbscan.com/",
        },
      },
    ],
  },
  solidity: {
    version: "0.8.17",
    settings: {},
  },
  networks: {
    hardhat: {
      forking: {
        url: "https://eth.llamarpc.com",
      },
    },
    localhost: {
      url: "http://localhost:8545",
    },
    goerli: {
      url: `${GOERLI_NETWORK_AUX}`,
      accounts: [PRIVATE_KEY],
      chainId: 5,
    },
    mainnet: {
      url: "https://bsc-dataseed2.ninicoin.io",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: {
        mnemonic: MENMONIC,
      },
    },
    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      gasPrice: 20000000000,
      accounts: [PRIVATE_KEY],
    },
    bnbtestnet: {
      url: "https://bsc-testnet.blockpi.network/v1/rpc/public",
      chainId: 97,
      accounts: {
        mnemonic: MENMONIC,
      },
    },
    opbnb: {
      url: "https://opbnb-mainnet-rpc.bnbchain.org",
      chainId: 204,
      accounts: {
        mnemonic: MENMONIC,
      },
    },
    optestnet: {
      url: "https://opbnb-testnet-rpc.bnbchain.org",
      chainId: 5611,
      gasPrice: 20000000000,
      accounts: [PRIVATE_KEY],
    },
    hedera_testnet: {
      url: "https://testnet.hashio.io/api",
      chainId: 296,
      accounts: [PRIVATE_KEY],
      gasPrice: 1080,
    },
    fuji_testnet: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      chainId: 43113,
      accounts: [PRIVATE_KEY],
      gasPrice: 1000,
    },
    velas_mainnet: {
      url: "https://explorer.velas.com/rpc",
      chainId: 106,
      accounts: [PRIVATE_KEY],
    },
    velas_testnet: {
      url: "https://evmexplorer.testnet.velas.com/rpc",
      chainId: 111,
      accounts: [PRIVATE_KEY],
    },
  },
};
