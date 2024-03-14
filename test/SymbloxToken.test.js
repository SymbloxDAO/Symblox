const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SymbloxToken", function () {
  let SymbloxToken, symbloxToken, owner, reserveAddress, userAcc;

  beforeEach(async function () {
    [owner, reserveAddress, userAcc] = await ethers.getSigners();

    SymbloxToken = await ethers.getContractFactory("SymbloxToken");
    symbloxToken = await SymbloxToken.deploy(reserveAddress.address);
    await symbloxToken.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right reserve address", async function () {
      const initialBalance = await symbloxToken.balanceOf(
        reserveAddress.address
      );
      expect(initialBalance).to.equal(symbloxToken.INITIAL_RESERVE_AMOUNT);
    });
  });

  describe("adjustRewardsAPR", function () {
    it("Should be able to adjust the rewards APR", async function () {
      const newAPR = 10;
      await symbloxToken.adjustRewardsAPR(newAPR);
      expect(await symbloxToken.rewardsAPR()).to.equal(newAPR);
    });

    it("Should emit RewardsAPRAdjusted event on APR change", async function () {
      const newAPR = 15;
      await expect(symbloxToken.adjustRewardsAPR(newAPR))
        .to.emit(symbloxToken, "RewardsAPRAdjusted")
        .withArgs(newAPR);
    });

    it("Should revert if a non-owner tries to adjust the APR", async function () {
      const newAPR = 20;
      await expect(
        symbloxToken.connect(userAcc).adjustRewardsAPR(newAPR)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("mint", function () {
    it("Owner should be able to mint new tokens", async function () {
      const mintAmount = ethers.utils.parseEther("1000");
      await symbloxToken.mint(userAcc.address, mintAmount);
      const balance = await symbloxToken.balanceOf(userAcc.address);
      expect(balance).to.equal(mintAmount);
    });

    it("Non-owner should not be able to mint new tokens", async function () {
      const mintAmount = ethers.utils.parseEther("1000");
      await expect(
        symbloxToken.connect(userAcc).mint(userAcc.address, mintAmount)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("mintRewards", function () {
    it("Should correctly mint rewards based on reward base and APR", async function () {
      const rewardBase = ethers.utils.parseEther("1000");
      const apr = 10; // 10% Reward APR
      await symbloxToken.adjustRewardsAPR(apr);

      const expectedRewardAmount = rewardBase.mul(apr).div(100);
      await symbloxToken.mintRewards(userAcc.address, rewardBase);

      const balance = await symbloxToken.balanceOf(userAcc.address);
      expect(balance).to.equal(expectedRewardAmount);
    });
  });
});
