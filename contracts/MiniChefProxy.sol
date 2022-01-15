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
    }

    function changeChef(address newChef, uint newPid)
        public
        onlyAdmin(msg.sender)
    {
        chef = newChef;
        pid = newPid;
    }

    function changeRecipient(address newRecipient) public onlyAdmin(msg.sender) {
        recipient = newRecipient;
    }

    function changeAdmin(address newAdmin) public onlyAdmin(msg.sender) {
        admin = newAdmin;
    }

    modifier onlyAdmin(address sender) {
        require(sender == admin, "sender not admin");
        _;
    }
}
