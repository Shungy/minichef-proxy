// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

interface IMiniChef {
    function harvest(uint256 pid, address to) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
}

contract MiniChefProxy {

    address public admin;
    address public recipient;
    address public chef;
    uint public pid;

    address constant private BURN_ADDRESS =
        address(0x000000000000000000000000000000000000dEaD);

    constructor(
        address newAdmin,
        address newRecipient,
        address newChef,
        uint newPid
    ) {
        require(
            newAdmin != address(0) &&
            newRecipient != address(0) &&
            newChef != address(0),
            "invalid address(es)"
        );
        admin = newAdmin;
        recipient = newRecipient;
        chef = newChef;
        pid = newPid;
    }

    /// @notice harvest pending rewards for the recipient
    function harvest() public {
        IMiniChef(chef).harvest(pid, recipient);
        emit Harvest(recipient);
    }

    /// @notice withdraw & burn tokens to reduce or end rewards
    /// @param amount - amount of deposited tokens to withdraw
    function withdraw(uint amount) public onlyAdmin(msg.sender) {
        require(amount != 0, "invalid withdraw amount");
        IMiniChef(chef).withdraw(pid, amount, BURN_ADDRESS);
        emit Withdraw(amount);
    }

    /// @notice harvest & withdraw & burn tokens to reduce or end rewards
    /// @param amount - amount of deposited tokens to withdraw
    function harvestAndWithdraw(uint amount) public onlyAdmin(msg.sender) {
        harvest();
        withdraw(amount);
    }

    /// @notice change chef address and pid. this will make any
    /// pending rewards in a previous pool unharvestable
    /// @param newChef - address of the MiniChef contract
    /// @param newPid - pool id of the deposit token
    function changeChef(address newChef, uint newPid)
        public
        onlyAdmin(msg.sender)
    {
        require(newChef != address(0), "invalid new chef address");
        chef = newChef;
        pid = newPid;
        emit NewChef(chef, pid);
    }

    /// @notice harvest then change chef address and pid.
    /// @param newChef - address of the MiniChef contract
    /// @param newPid - pool id of the deposit token
    function harvestAndChangeChef(address newChef, uint newPid)
        public
        onlyAdmin(msg.sender)
    {
        harvest();
        changeChef(newChef, newPid);
    }

    /// @notice change who will receive the reward tokens
    /// @param newRecipient - address of the new recipient
    function changeRecipient(address newRecipient)
        public
        onlyAdmin(msg.sender)
    {
        require(newRecipient != address(0), "invalid new recipient address");
        recipient = newRecipient;
        emit NewRecipient(recipient);
    }

    /// @notice change contract administrator
    /// @param newAdmin - address of the new contract administrator/owner
    function changeAdmin(address newAdmin) public onlyAdmin(msg.sender) {
        require(newAdmin != address(0), "invalid new admin address");
        admin = newAdmin;
        emit NewAdmin(admin);
    }

    modifier onlyAdmin(address sender) {
        require(sender == admin, "unpriviledged message sender");
        _;
    }

    event NewAdmin(address newAdmin);
    event NewRecipient(address newRecipient);
    event NewChef(address newChef, uint newPid);
    event Harvest(address to);
    event Withdraw(uint amount);
}
