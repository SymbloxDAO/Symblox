const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("gSYMNFT Contract", function () {
  let gSYMNFT;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    const gSYMNFTContract = await ethers.getContractFactory("gSYMNFT");
    gSYMNFT = await gSYMNFTContract.deploy();
    await gSYMNFT.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await gSYMNFT.owner()).to.equal(owner.address);
    });

    it("Should set the right admin", async function () {
      expect(await gSYMNFT.admin()).to.equal(owner.address);
    });
  });

  describe("Minting", function () {
    it("Should mint a new token and assign it to addr1", async function () {
      const tokenId = await gSYMNFT.connect(owner).mint(addr1.address);
      expect(await gSYMNFT.ownerOf(tokenId)).to.equal(addr1.address);
    });

    it("Should fail if mint is called by non-owner", async function () {
      await expect(
        gSYMNFT.connect(addr1).mint(addr1.address)
      ).to.be.revertedWith("Unauthorized");
    });
  });

  describe("gSYMNFT Metadata", function () {
    it("Should return the correct staked SYM amount for the token ID", async function () {
      const tokenId = await gSYMNFT.connect(owner).mint(addr1.address);
      await gSYMNFT.connect(owner).updateStakedSYM(tokenId, 100);
      expect(await gSYMNFT.getStakedSYM(tokenId)).to.equal(100);
    });

    it("Should update the staked SYM amount for the token ID", async function () {
      const tokenId = await gSYMNFT.connect(owner).mint(addr1.address);
      await gSYMNFT.connect(owner).updateStakedSYM(tokenId, 100);
      await gSYMNFT.connect(owner).updateStakedSYM(tokenId, 200);
      expect(await gSYMNFT.getStakedSYM(tokenId)).to.equal(200);
    });

    it("Should revert if trying to get staked SYM of non-existent token", async function () {
      await expect(gSYMNFT.getStakedSYM(999)).to.be.revertedWith(
        "gSYMNFT: tokenId does not exist"
      );
    });
  });

  describe("Transfers", function () {
    it("Should transfer tokens between accounts", async function () {
      const tokenId = await gSYMNFT.connect(owner).mint(addr1.address);
      await gSYMNFT
        .connect(addr1)
        ["safeTransferFrom(address,address,uint256)"](
          addr1.address,
          addr2.address,
          tokenId
        );
      expect(await gSYMNFT.ownerOf(tokenId)).to.equal(addr2.address);
    });
  });
});
