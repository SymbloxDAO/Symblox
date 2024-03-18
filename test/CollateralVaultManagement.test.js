const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SYM and VLX Vaults", function () {
  let SYMVault;
  let VLXVault;
  let symVault;
  let vlxVault;
  let owner;
  let addr1;

  beforeEach(async function () {
    // Setting up the testing environment
    [owner, addr1] = await ethers.getSigners();

    // Deploying the vaults with appropriate factories
    const SYMVaultContract = await ethers.getContractFactory("SYMVault");
    const VLXVaultContract = await ethers.getContractFactory("VLXVault");

    symVault = await SYMVaultContract.deploy();
    vlxVault = await VLXVaultContract.deploy(200); // Initialize with a ratio of 200

    await symVault.deployed();
    await vlxVault.deployed();
  });

  describe("Overcollateralization Ratios", function () {
    it("Should allow owner to adjust SYM overcollateralization ratio", async function () {
      const newRatio = 300;
      await symVault.adjustCollateralizationRatio(newRatio);
      expect(await symVault.overcollateralizationRatio()).to.equal(newRatio);
    });

    it("Should fail to adjust SYM overcollateralization ratio from non-owner account", async function () {
      const newRatio = 300;
      await expect(
        symVault.connect(addr1).adjustCollateralizationRatio(newRatio)
      ).to.be.revertedWith("caller is not the owner");
    });

    it("Should initialize VLX vault with correct overcollateralization ratio", async function () {
      expect(await vlxVault.overcollateralizationRatio()).to.equal(200);
    });

    it("Should allow owner to adjust VLX overcollateralization ratio", async function () {
      const newRatio = 250;
      await vlxVault.adjustCollateralizationRatio(newRatio);
      expect(await vlxVault.overcollateralizationRatio()).to.equal(newRatio);
    });

    it("Should fail to adjust VLX overcollateralization ratio from non-owner account", async function () {
      const newRatio = 250;
      await expect(
        vlxVault.connect(addr1).adjustCollateralizationRatio(newRatio)
      ).to.be.revertedWith("caller is not the owner");
    });
  });

  // Additional tests for other functions can be added here
});
