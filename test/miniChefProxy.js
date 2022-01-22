const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MiniChef Proxy", function () {
  before(async function () {
    [this.deployer, this.multisig, this.geyser] = await ethers.getSigners();

    // Deploy PNG and send all balance to multisig
    this.PNG = await ethers.getContractFactory("Png");
    this.png = await this.PNG.deploy(this.multisig.address);
    this.png = await this.png.connect(this.multisig);
    await this.png.deployed();

    // Deploy MiniChef
    this.Chef = await ethers.getContractFactory("MiniChefV2");
    this.chef = await this.Chef.deploy(this.png.address, this.multisig.address);
    this.chef = await this.chef.connect(this.multisig);
    await this.chef.deployed();

    // Approve PNG spending and fund MiniChef for 538 days
    await this.png.approve(
      this.chef.address,
      ethers.utils.parseUnits("538000000", 18)
    );
    await this.chef.fundRewards(
      ethers.utils.parseUnits("538000000", 18),
      538*86400 // funding duration
    );

    // Deploy DummyERC20 and mint 10 tokens to the deployer
    this.DummyERC20 = await ethers.getContractFactory("DummyERC20");
    this.dummyERC20 = await this.DummyERC20.deploy("10");
    await this.dummyERC20.deployed();

    // Transfer DummyERC20 tokens and ownership to multisig
    await this.dummyERC20.transfer(this.multisig.address,"10");
    await this.dummyERC20.transferOwnership(this.multisig.address);
    this.dummyERC20 = await this.dummyERC20.connect(this.multisig);

    // Add DummyERC20 pool to MiniChef with 5x (500) weight
    await this.chef.addPool(
      500,
      this.dummyERC20.address,
      ethers.constants.AddressZero
    );
  });

  it("deploys proxy", async function () {
    this.Proxy = await ethers.getContractFactory("MiniChefProxy");
    this.proxy = await this.Proxy.deploy(
      this.multisig.address, // admin
      this.geyser.address,   // recipient
      this.chef.address,     // minichef
      0                      // minichef pid
    );
  });
  it("deposits dummy erc20 to minichef", async function () {
    await this.dummyERC20.approve(
      this.chef.address,
      10
    );
    allowance = await this.dummyERC20.allowance(
      this.multisig.address,
      this.chef.address
    );
    await this.chef.deposit(0, 10, this.proxy.address);
  });
  it("diverts rewards to geyser", async function () {
    await network.provider.send("evm_increaseTime", [86400])
    await expect(this.proxy.harvest()).to.emit(this.proxy, "Harvest");
    await expect(this.png.balanceOf(this.geyser.address)).to.not.equal(0);
  });
  it("changes admin", async function() {
    var admin;
    var proxy = await this.proxy.connect(this.multisig);
    await expect(proxy.changeAdmin(this.deployer.address))
      .to.emit(proxy, "NewAdmin");
    admin = await this.proxy.admin();
    expect(admin).to.equal(this.deployer.address);
    proxy = await this.proxy.connect(this.deployer);
    await expect(proxy.changeAdmin(this.multisig.address))
      .to.emit(proxy, "NewAdmin");
    admin = await this.proxy.admin();
    expect(admin).to.equal(this.multisig.address);
  });
  it("changes recipient", async function() {
    var recipient;
    var proxy = await this.proxy.connect(this.multisig);
    await expect(proxy.changeRecipient(this.deployer.address))
      .to.emit(proxy, "NewRecipient");
    recipient = await this.proxy.recipient();
    expect(recipient).to.equal(this.deployer.address);
    await expect(proxy.changeRecipient(this.geyser.address))
      .to.emit(proxy, "NewRecipient");
    recipient = await this.proxy.recipient();
    expect(recipient).to.equal(this.geyser.address);
  });
  it("changes minichef", async function() {
    var minichef;
    var pid;
    var proxy = await this.proxy.connect(this.multisig);
    await expect(proxy.harvestAndChangeChef(this.deployer.address,1))
      .to.emit(proxy, "Harvest").and.to.emit(proxy, "NewChef");
    chef = await this.proxy.chef();
    pid = await this.proxy.pid();
    expect(chef).to.equal(this.deployer.address);
    expect(pid).to.equal(1);
    await expect(proxy.changeChef(this.chef.address,0))
      .to.emit(proxy, "NewChef");
    chef = await this.proxy.chef();
    pid = await this.proxy.pid();
    expect(chef).to.equal(this.chef.address);
    expect(pid).to.equal(0);
  });
  it("unpriveledged cannot change variables", async function() {
    var proxy = await this.proxy.connect(this.deployer);
    var balance = (await this.chef.userInfo(0,proxy.address)).amount;
    await expect(proxy.changeRecipient(this.deployer.address))
      .to.be.revertedWith("unpriviledged message sender");
    await expect(proxy.harvestAndWithdraw(balance))
      .to.be.revertedWith("unpriviledged message sender");
    await expect(proxy.changeAdmin(this.deployer.address))
      .to.be.revertedWith("unpriviledged message sender");
    await expect(proxy.harvestAndChangeChef(this.deployer.address,0))
      .to.be.revertedWith("unpriviledged message sender");
  });
  it("withdraws and burns", async function() {
    var proxy = await this.proxy.connect(this.multisig);
    var balance = (await this.chef.userInfo(0,proxy.address)).amount;
    await expect(proxy.harvestAndWithdraw(balance))
      .to.emit(proxy, "Harvest").and.to.emit(proxy, "Withdraw");
    balance = (await this.chef.userInfo(0,proxy.address)).amount;
    expect(balance).to.equal(0);
  });
});
