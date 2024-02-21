const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SymbloxToken Contract", function () {
  let Token;
  let symbloxToken;
  let owner;
  let reserveAddress;
  let user1;
  let user2;
  let initialReserveAmount;

  before(async function () {
    // Get the ContractFactory and Signers here.
    Token = await ethers.getContractFactory("SymbloxToken");
    [owner, reserveAddress, user1, user2] = await ethers.getSigners();

    initialReserveAmount = ethers.utils.parseUnits("200000000", "ether");
  });

  beforeEach(async function () {
    // Deploy a new contract before each test
    symbloxToken = await Token.deploy(reserveAddress.address);
    await symbloxToken.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right reserve address", async function () {
      expect(await symbloxToken.reserveAddress()).to.equal(
        reserveAddress.address
      );
    });

    it("Should mint initial supply to the reserve address", async function () {
      expect(await symbloxToken.balanceOf(reserveAddress.address)).to.equal(
        initialReserveAmount
      );
    });
  });

  describe("Transactions", function () {
    it("Should transfer tokens between accounts", async function () {
      // Transfer 50 tokens from reserveAddress to user1
      let transferAmount = ethers.utils.parseUnits("50", "ether");
      await symbloxToken
        .connect(reserveAddress)
        .transfer(user1.address, transferAmount);

      // Check balances
      expect(await symbloxToken.balanceOf(reserveAddress.address)).to.equal(
        initialReserveAmount.sub(transferAmount)
      );
      expect(await symbloxToken.balanceOf(user1.address)).to.equal(
        transferAmount
      );
    });

    it("Should fail if sender doesn’t have enough tokens", async function () {
      // Try to send 1 token from user1 (0 tokens) to reserveAddress (200 million tokens)
      let transferAmount = ethers.utils.parseUnits("1", "ether");
      await expect(
        symbloxToken
          .connect(user1)
          .transfer(reserveAddress.address, transferAmount)
      ).to.be.revertedWith("Transfer amount exceeds balance");
    });
  });

  // Add more tests as needed
});
