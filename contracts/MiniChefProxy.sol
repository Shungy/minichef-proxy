// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

interface IMiniChef {
    function harvest(uint256 pid, address to) external;
}

contract MiniChefProxy {

    address public admin;
    address public recipient;
    address public chef;
    uint public pid;

    constructor(
        address newAdmin,
        address newRecipient,
        address newChef,
        uint newPid
    ) {
        admin = newAdmin;
        recipient = newRecipient;
        chef = newChef;
        pid = newPid;
    }

    function harvest() public {
        IMiniChef(chef).harvest(pid, recipient);
        emit RewardsHarvested(recipient);
    }

    function changeChef(address newChef, uint newPid)
        public
        onlyAdmin(msg.sender)
    {
        chef = newChef;
        pid = newPid;
        emit ChefChanged(chef, pid);
    }

    function changeRecipient(address newRecipient) public onlyAdmin(msg.sender) {
        recipient = newRecipient;
        emit RecipientChanged(recipient);
    }

    function changeAdmin(address newAdmin) public onlyAdmin(msg.sender) {
        admin = newAdmin;
        emit AdminChanged(admin);
    }

    modifier onlyAdmin(address sender) {
        require(sender == admin, "sender not admin");
        _;
    }

    event AdminChanged(address newAdmin);
    event RecipientChanged(address newRecipient);
    event ChefChanged(address newChef, uint newPid);
    event RewardsHarvested(address to);
}
