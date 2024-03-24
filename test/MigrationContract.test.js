const { expect } = require("chai");
const { ethers } = require("hardhat");
const { deploy } = require("hardhat-libutils"); // make sure you have this utility function defined

describe("MigrationContract test", function () {
  before(async function () {
    [this.deployer, this.user] = await ethers.getSigners();

    // Deploy mock tokens
    const OldToken = await ethers.getContractFactory("OldTokenMock");
    this.oldToken = await OldToken.deploy();
    await this.oldToken.deployed();

    const NewToken = await ethers.getContractFactory("NewTokenMock");
    this.newToken = await NewToken.deploy();
    await this.newToken.deployed();

    // Deploy the migration contract
    const MigrationContract = await ethers.getContractFactory(
      "MigrationContract"
    );
    this.migrationContract = await deploy(
      "MigrationContract",
      this.oldToken.address,
      this.newToken.address
    );

    // Mint old tokens to the user
    await this.oldToken
      .connect(this.deployer)
      .mint(this.user.address, ethers.utils.parseUnits("1000", 18));
  });

  it("should migrate tokens successfully", async function () {
    const amountToMigrate = ethers.utils.parseUnits("1000", 18);

    // User approves MigrationContract to spend their old tokens
    await this.oldToken
      .connect(this.user)
      .approve(this.migrationContract.address, amountToMigrate);

    // User calls migrate function
    await this.migrationContract.connect(this.user).migrate(amountToMigrate);

    // Check balances after migration
    const oldBalance = await this.oldToken.balanceOf(this.user.address);
    const newBalance = await this.newToken.balanceOf(this.user.address);

    // Verify that all old tokens were migrated
    expect(oldBalance).to.equal(0);

    // Verify that new tokens were received
    expect(newBalance).to.equal(amountToMigrate);
  });

  it("update token addresses", async function () {
    // Create additional mock tokens to update addresses
    const ExtraOldToken = await ethers.getContractFactory("OldTokenMock");
    const extraOldToken = await ExtraOldToken.deploy();
    await extraOldToken.deployed();

    const ExtraNewToken = await ethers.getContractFactory("NewTokenMock");
    const extraNewToken = await ExtraNewToken.deploy();
    await extraNewToken.deployed();

    // Update oldToken address and check
    await this.migrationContract.setOldToken(extraOldToken.address);
    expect(await this.migrationContract.oldToken()).to.equal(
      extraOldToken.address
    );

    // Update newToken address and check
    await this.migrationContract.setNewToken(extraNewToken.address);
    expect(await this.migrationContract.newToken()).to.equal(
      extraNewToken.address
    );

    // Additional checks can be made for onlyOwner modifier
  });
});
