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
        admin = newAdmin;
        recipient = newRecipient;
        chef = newChef;
        pid = newPid;
    }

    /// @notice harvest pending rewards of recipient
    function harvest() public {
        IMiniChef(chef).harvest(pid, recipient);
        emit Harvest(recipient);
    }

    /// @notice withdraw & burn tokens to reduce or end recipient’s rewards
    /// @param amount - amount of deposited tokens to withdraw
    function withdraw(uint amount) public onlyAdmin(msg.sender) {
        harvest();
        IMiniChef(chef).withdraw(pid, amount, BURN_ADDRESS);
        emit Withdraw(amount);
    }

    function changeChef(address newChef, uint newPid)
        public
        onlyAdmin(msg.sender)
    {
        chef = newChef;
        pid = newPid;
        emit NewChef(chef, pid);
    }

    function changeRecipient(address newRecipient)
        public
        onlyAdmin(msg.sender)
    {
        recipient = newRecipient;
        emit NewRecipient(recipient);
    }

    function changeAdmin(address newAdmin) public onlyAdmin(msg.sender) {
        admin = newAdmin;
        emit NewAdmin(admin);
    }

    modifier onlyAdmin(address sender) {
        require(sender == admin, "sender not admin");
        _;
    }

    event NewAdmin(address newAdmin);
    event NewRecipient(address newRecipient);
    event NewChef(address newChef, uint newPid);
    event Harvest(address to);
    event Withdraw(uint amount);
}
