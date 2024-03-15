const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@openzeppelin/test-helpers");

describe("SYMStakingContract", function () {
  let symStaking, symblox, xUSD;
  let owner, addr1, addr2;
  const lockDuration = 7 * 24 * 60 ** 60; // fixed from ^ to **
  const symAmountToStake = ethers.utils.parseEther("100");

  before(async function () {
    // Get signers
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy mock SYMBLOX token
    const Symblox = await ethers.getContractFactory("MockSymblox");
    symblox = await Symblox.deploy();

    // Deploy mock xUSD token
    const xUSDToken = await ethers.getContractFactory("MockxUSD");
    xUSD = await xUSDToken.deploy();

    // Deploy SYMStakingContract
    const SYMStaking = await ethers.getContractFactory("SYMStakingContract");
    symStaking = await SYMStaking.deploy(symblox.address, xUSD.address);
  });

  describe("Staking functionality", function () {
    it("Should allow users to stake SYM and mint xUSD", async function () {
      // Set up collateralisation ratio and balance for addr1
      await symblox.setCollateralisationRatio(addr1.address, 200); // Example ratio
      await symblox.mint(addr1.address, symAmountToStake);

      // Approve tokens
      await symblox
        .connect(addr1)
        .approve(symStaking.address, symAmountToStake);

      // Perform staking
      await expect(symStaking.connect(addr1).stakeAndMint(symAmountToStake))
        .to.emit(symStaking, "SYMStaked") // Assuming there is such an event
        .withArgs(addr1.address, symAmountToStake);

      // Check balances and stake details
      const stakeDetails = await symStaking.stakes(addr1.address);
      const newBalance = await xUSD.balanceOf(addr1.address);

      expect(stakeDetails.amount).to.equal(symAmountToStake);
      expect(newBalance).to.be.above(0); // Should have received xUSD
    });

    it("Should not allow users to withdraw SYM before lock duration expires", async function () {
      // Attempt withdrawal before time
      await expect(symStaking.connect(addr1).withdrawSNX()).to.be.revertedWith(
        "Your SYM is still locked."
      );
    });

    it("Should allow users to withdraw SYM after lock duration", async function () {
      // Increase time to after lock duration
      await time.increase(lockDuration + 1);

      // Withdraw tokens
      await expect(symStaking.connect(addr1).withdrawSNX())
        .to.emit(symStaking, "SYMWithdrawn") // Assuming there is such an event
        .withArgs(addr1.address, symAmountToStake);
    });
  });

  // Continue writing tests for reward calculations and claiming rewards...
});
