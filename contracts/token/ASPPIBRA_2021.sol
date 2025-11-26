// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BEP20Token is ERC20, Ownable {
    constructor() ERC20("ASPPIBRA", "ASPPBR") Ownable(msg.sender) {
        _mint(msg.sender, 21000000 * 10 ** 18);
    }
}
