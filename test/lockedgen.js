const helpers = require("./helpers");
const LGN = artifacts.require("./LockedGEN.sol");
const TokenMock = artifacts.require("./test/TokenMock.sol");

let lgn;
let gen;
let lockTime = 3600; // 1h;
let initBalance = 10000; // 1h;

const setup = async function (accounts) {
  // Create mock gen:
  gen = await TokenMock.new();
  gen.mint(accounts[0], 10000);

  lgn = await LGN.new(gen.address, lockTime);
};

contract('LockedGEN',  accounts =>  {

  it("check setup", async () => {
    await setup(accounts);

    assert.equal(await gen.balanceOf(accounts[0]), initBalance);
    assert.equal(await lgn.genToken(), gen.address);
    assert.equal(await lgn.lockTime(), lockTime);
  });

  it("create lgn", async () => {
    await setup(accounts);

    await gen.approve(lgn.address, 100);
    await lgn.mintLGN(100);

    assert.equal(await gen.balanceOf(accounts[0]), initBalance - 100);
    assert.equal(await lgn.balanceOf(accounts[0]), 100);
  });

  it("return lgn and create a lock", async () => {
    await setup(accounts);

    await gen.approve(lgn.address, 100);
    await lgn.mintLGN(100);
    await lgn.burnLGN(50);


    assert.equal(await lgn.balanceOf(accounts[0]), 50);
    let lock = await lgn.locks.call(0);
    assert.equal(lock.owner, accounts[0]);
    assert.equal(lock.amount, 50);
    assert.equal(lock.released, false);
  });

  it("releese gen", async () => {
    await setup(accounts);

    await gen.approve(lgn.address, 100);
    await lgn.mintLGN(100);
    await lgn.burnLGN(50);

    // Try to release before locktime finished:
    try{
      await lgn.releaseGEN(0);
      assert(false, "Should not be able to release gen");
    } catch (ex) {
        // helpers.assertVMException(ex);
    }

    // Run time forward and release:
    await helpers.increaseTime(lockTime+1);
    assert.equal(await gen.balanceOf(accounts[0]), initBalance - 100);
    await lgn.releaseGEN(0, { from: accounts[1] });
    assert.equal(await gen.balanceOf(accounts[0]), initBalance - 50);
    assert.equal(await lgn.balanceOf(accounts[0]), 50);

    let lock = await lgn.locks.call(0);
    assert.equal(lock.owner, accounts[0]);
    assert.equal(lock.amount, 50);
    assert.equal(lock.released, true);
  });

});
