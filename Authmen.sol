// contracts/Authmen.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/token/ERC20/ERC20.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.1.0/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";



contract Authmen is ERC20Burnable {
    
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address mining,
        address presale,
        address market,
        address reserved
    ) public ERC20(name, symbol)  {
        _mint(mining,   8000000 * (10**uint256(decimals)));
        _mint(presale,   600000 * (10**uint256(decimals)));
        _mint(market,    400000 * (10**uint256(decimals)));
        _mint(reserved, 1000000 * (10**uint256(decimals)));
    }
}


