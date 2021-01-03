// contracts/Authmen.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

//import '@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol';
//import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts-ethereum-package/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155BurnableUpgradeable.sol";

/*******************************
 ***   Queue implementation  ***
 *******************************/
library QueueLib {
    struct Queue {
        uint256[] _array;
        uint256 _read;
    }
    function push(Queue storage queue, uint256 timestamp) internal {
        queue._array.push(timestamp);
    }
    function pop(Queue storage queue) internal returns (uint256)  {
        require(queue._read < queue._array.length, "pop: Out of index.");

        uint256 value = queue._array[queue._read];
        delete(queue._array[queue._read]);
        queue._read += 1;

        return value;
    }
    function get(Queue storage queue, uint256 index) internal view returns (uint256) {
        require(queue._read + index < queue._array.length, "get: Out of index.");
        
        return queue._array[index + queue._read];
    }
    function length(Queue storage queue) internal view returns (uint256) {
        return queue._array.length - queue._read;
    }
    /************* End of Queue implementation *********************/
    
}

contract AuthmenNFT is ERC1155BurnableUpgradeable  {
    using QueueLib for QueueLib.Queue;
    
    uint256 constant AUTH1 = 0;
    uint256 constant AUTH2 = 1;
    uint256 constant AUTH3 = 2;
    uint256 constant AUTH4 = 3;
    uint256 constant AUTH5 = 4;
    uint256 constant AUTH6 = 5;
    bytes  constant strAUTH1 = "Orc";
    bytes  constant strAUTH2 = "Werewolf";
    bytes  constant strAUTH3 = "Villager";
    bytes  constant strAUTH4 = "Viking";
    bytes  constant strAUTH5 = "Knight";
    bytes  constant strAUTH6 = "King";
    
    uint256 constant TRY_LOCK_TIME = 10 minutes; //30 days;
    
    address _authmen;
    address _trytoken;
    address constant _burned = address(0x000000000000000000000000000000000000dEaD);
    
    
    // address => queue
    mapping(address => QueueLib.Queue) private stakeTime;
    

    function initialize(address authmen, address trytoken) public initializer {
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
        
         require((stakeTime[msg.sender].length() == 0) 
              || (stakeTime[msg.sender].length() != 0 && now.sub(stakeTime[msg.sender].get(stakeTime[msg.sender].length() - 1)) > TRY_LOCK_TIME), 
              "TRY is locking");
        /*uint256 length = stakeTime[msg.sender].length();
        if (length != 0 && now.sub(stakeTime[msg.sender].get(length - 1)) < TRY_LOCK_TIME) {
            return;
        }*/
        
        IERC20(_trytoken).transferFrom(msg.sender, address(this), 2000000 ether);
        _mint(msg.sender, AUTH1, 1, strAUTH1);
        stakeTime[msg.sender].push(now);
    }
    
    // get all TRY tokens exceed 30days out.
    function unstakeTRY() external {
        uint256 length = stakeTime[msg.sender].length();
        if (length <= 0) return;
        
        // delete elements
        uint256 count = 0;
        for (uint256 i = 0; i < length; i++) {
            if (now.sub(stakeTime[msg.sender].get(i)) >= TRY_LOCK_TIME) {
                count = count.add(1);
            } else {
                break;
            }
        }

        for (uint256 i = 0; i < count; i++) {
            stakeTime[msg.sender].pop();
        }
        
        IERC20(_trytoken).transfer(msg.sender, count.mul(2000000 ether));
    }
    
    function latestTRYStakeTime() external view returns (uint256) {
        if (stakeTime[msg.sender].length() == 0) {
            return 0;
        } else {
            return stakeTime[msg.sender].get(stakeTime[msg.sender].length() - 1);
        }
        
    }
}
