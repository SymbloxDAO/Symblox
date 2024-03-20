const RewardEscrow = artifacts.require("RewardEscrow");
const { BN, expectEvent, expectRevert } = require("@openzeppelin/test-helpers");

contract(
  "RewardEscrow",
  ([owner, resolver, synthetixBridgeToOptimism, otherAccount]) => {
    let rewardEscrow;

    beforeEach(async () => {
      rewardEscrow = await RewardEscrow.new(owner, resolver);
      // Assuming that you have a functionality to set the address of the "SynthetixBridgeToOptimism" in your contract,
      // you would call it here to set up the bridge address.
    });

    describe("Function: burnForMigration", () => {
      it("should only allow SynthetixBridgeToOptimism to call burnForMigration", async () => {
        const entryIDs = [new BN(1), new BN(2)];

        // Attempt to call burnForMigration from another account should fail
        await expectRevert(
          rewardEscrow.burnForMigration(otherAccount, entryIDs, {
            from: otherAccount,
          }),
          "Can only be invoked by SynthetixBridgeToOptimism contract"
        );

        // Call from SynthetixBridgeToOptimism should succeed (simulate this by setting the message sender as the brid ge)
        // You need to write logic in your contract to make `synthetixBridgeToOptimism` callable for tests
        // or to mock the behavior of checking msg.sender.
        await rewardEscrow.burnForMigration(otherAccount, entryIDs, {
          from: synthetixBridgeToOptimism,
        });
      });

      it("should correctly burn escrow amounts and emit event", async () => {
        const entryIDs = [new BN(1), new BN(2)];
        const escrowedAmount = new BN(500);

        // Setup initial conditions such as escrow balances if necessary

        // We assume that burnForMigration is successful and emits the event BurnedForMigrationToL2
        const receipt = await rewardEscrow.burnForMigration(
          otherAccount,
          entryIDs,
          { from: synthetixBridgeToOptimism }
        );

        // Check that the escrow balances were updated accordingly

        // Check that the event was emitted with the correct data
        expectEvent(receipt, "BurnedForMigrationToL2", {
          account: otherAccount,
          entryIDs: entryIDs.map((id) => id.toString()),
          escrowedAmountMigrated: escrowedAmount.toString(),
          time: (
            await web3.eth.getBlock(receipt.receipt.blockNumber)
          ).timestamp.toString(),
        });
      });
    });
  }
);
