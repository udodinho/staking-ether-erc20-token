// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UdvToken is ERC20("UDV Token", "UDVT") {
    address public owner;

    constructor() {
        owner = msg.sender;
        _mint(msg.sender, 100000e5);
    }

    function mint(uint _amount) external {
        require(msg.sender == owner, "you are not owner");
        _mint(msg.sender, _amount * 1e5);
    }
}