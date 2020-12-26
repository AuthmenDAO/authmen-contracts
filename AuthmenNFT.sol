// contracts/Authmen.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.1.0/contracts/token/ERC1155/ERC1155Burnable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.1.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.1.0/contracts/math/SafeMath.sol";

contract AuthmenNFT is ERC1155Burnable {
    using SafeMath for uint256;
    
    uint256 constant AUTH1 = 0;
    uint256 constant AUTH2 = 1;
    uint256 constant AUTH3 = 2;
    uint256 constant AUTH4 = 3;
    uint256 constant AUTH5 = 4;
    uint256 constant AUTH6 = 5;
    bytes  strAUTH1 = "Orc";
    bytes  strAUTH2 = "Werewolf";
    bytes  strAUTH3 = "Villager";
    bytes  strAUTH4 = "Viking";
    bytes  strAUTH5 = "Knight";
    bytes  strAUTH6 = "King";

    
    address _authmen;
    address _trytoken;
    address _burned = address(0x000000000000000000000000000000000000dEaD);
    
    mapping(address => uint256[]) public stakeTime;
    

    constructor(address authmen, address trytoken) public ERC1155("AuthmenNFT") {
        _authmen  = authmen;
        _trytoken = trytoken;
    }
    
    // approve before transferFrom
    function mintAUTH1() external {
        IERC20(_authmen).transferFrom(msg.sender, _burned, 60 ether);
        _mint(msg.sender, AUTH1, 1, strAUTH1);
    }
    
    
    function mintAUTH2() external {
        IERC20(_authmen).transferFrom(msg.sender, _burned, 70 ether);
        burn(msg.sender, AUTH1, 1);
        _mint(msg.sender, AUTH2, 1, strAUTH2);
    }
    
    function mintAUTH3() external {
        IERC20(_authmen).transferFrom(msg.sender, _burned, 80 ether);
        burn(msg.sender, AUTH2, 1);
        _mint(msg.sender, AUTH3, 1, strAUTH3);
    }
    
    function mintAUTH4() external {
        IERC20(_authmen).transferFrom(msg.sender, _burned, 90 ether);
        burn(msg.sender, AUTH3, 1);
        _mint(msg.sender, AUTH4, 1, strAUTH4);
    }
    
    function mintAUTH5() external {
        IERC20(_authmen).transferFrom(msg.sender, _burned, 100 ether);
        burn(msg.sender, AUTH4, 1);
        _mint(msg.sender, AUTH5, 1, strAUTH5);
    }
    
    function mintAUTH6() external {
        IERC20(_authmen).transferFrom(msg.sender, _burned, 120 ether);
        burn(msg.sender, AUTH5, 1);
        _mint(msg.sender, AUTH6, 1, strAUTH6);
    }
    
    function stakeTRY() external {
        IERC20(_trytoken).transferFrom(msg.sender, address(this), 2000000 ether);
        _mint(msg.sender, AUTH1, 1, strAUTH1);
        stakeTime[msg.sender].push(now);
    }
    
    function unstakeTRY() external {
        uint256[] memory array = stakeTime[msg.sender];
        if (array.length <= 0) return;
        
        if (now - stakeTime[msg.sender][0] >= 30 days) {
            // delete first element
            for (uint256 i = 0; i < array.length - 1; i++){
                stakeTime[msg.sender][i] = stakeTime[msg.sender][i + 1];
            }
            stakeTime[msg.sender].pop();
            
            IERC20(_trytoken).transfer(msg.sender, 2000000 ether);
        } else {
            return;
        }
    }
}

