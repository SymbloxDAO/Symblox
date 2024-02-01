// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  // const MemeMatch = await hre.ethers.getContractFactory("MemeMatch");
  // const memeContract = await MemeMatch.deploy();

  // await memeContract.deployed();

  // console.log(
  //   `MMM token has deployed:`, memeContract.address
  // );
  // const gasLimit = await memeContract.estimateGas.enableTrading();
  // memeContract.enableTrading({gasLimit:gasLimit.mul(2)});
  // console.log(
  //   `tradingEnabled`
  // );

  const MMMToken = await hre.ethers.getContractFactory("SYMToken");
  const mmmContract = await MMMToken.deploy();

  await mmmContract.deployed();

  console.log(`SYMToken has deployed:`, mmmContract.address);
  // const ownerAddress = await vipContract.owner();
  // if (ownerAddress === "0x0000000000000000000000000000000000000000") {
  //   console.error("Invalid owner address");
  //   return;
  // }

  // const totalSupply = await vipContract.totalSupply();
  // console.log("totalSupply:",totalSupply);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
