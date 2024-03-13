const hre = require("hardhat");

async function main() {
  const SymContract = await hre.ethers.getContractFactory("SYMToken");
  const symContract = await SymContract.deploy();

  await symContract.deployed();

  console.log(`SYMToken has deployed:`, mmmContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
