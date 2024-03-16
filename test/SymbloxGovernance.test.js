const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SymbloxGovernance Contract", function () {
  let SymbloxGovernance;
  let govContract;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    SymbloxGovernance = await ethers.getContractFactory("SymbloxGovernance");
    [owner, addr1, addr2] = await ethers.getSigners();
    govContract = await SymbloxGovernance.deploy();
  });

  describe("Staking", function () {
    const stakeAmount = ethers.utils.parseEther("100");

    it("Should emit Staked event and update user balance", async function () {
      // Listen for the event
      await expect(govContract.connect(addr1).stake(stakeAmount))
        .to.emit(govContract, "Staked")
        .withArgs(addr1.address, stakeAmount);

      // Check user balance
      const user = await govContract.users(addr1.address);
      expect(user.stakedAmount).to.equal(stakeAmount);
    });

    it("Should fail staking zero amount", async function () {
      await expect(govContract.connect(addr1).stake(0)).to.be.revertedWith(
        "Amount must be greater than zero"
      );
    });

    it("Should prevent staking if already staked", async function () {
      await govContract.connect(addr1).stake(stakeAmount);
      await expect(
        govContract.connect(addr1).stake(stakeAmount)
      ).to.be.revertedWith("Already staked");
    });
  });

  describe("Unstaking", function () {
    const stakeAmount = ethers.utils.parseEther("100");

    beforeEach(async function () {
      await govContract.connect(addr1).stake(stakeAmount);
    });

    it("Should emit Unstaked event and reset user balance", async function () {
      // Listen for the event
      await expect(govContract.connect(addr1).unstake())
        .to.emit(govContract, "Unstaked")
        .withArgs(addr1.address, stakeAmount);

      // Check user balance
      const user = await govContract.users(addr1.address);
      expect(user.stakedAmount).to.equal(0);
    });

    it("Should fail unstaking when not staked", async function () {
      await govContract.connect(addr1).unstake(); // First unstake

      await expect(govContract.connect(addr1).unstake()) // Trying to unstake again
        .to.be.revertedWith("Not staked");
    });
  });

  // Add more tests here for other functionalities like voting, staking as oracle node, etc.
});
