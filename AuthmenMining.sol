
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v3.3.0/contracts/token/ERC1155/IERC1155Upgradeable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/proxy/Initializable.sol";


contract miningAuthmen is Initializable {
    using SafeMath for uint256;
    
    struct StakeInfo {
        uint256 amount;
        uint256 stakeTime;
        //uint256 miningTime;
        uint256 earning;
    }
    
    uint256 constant AUTH1 = 0;
    uint256 constant AUTH2 = 1;
    uint256 constant AUTH3 = 2;
    uint256 constant AUTH4 = 3;
    uint256 constant AUTH5 = 4;
    uint256 constant AUTH6 = 5;
    
    address _authmen;
    address _mining;
    address _authmenNFT;
    address _LPToken;
    
    mapping(address => mapping(uint => StakeInfo)) accountsNFTInfo;
    
    mapping(address => StakeInfo) accountsLPInfo;
    
    uint256 totalLPAmount = 0;
    
    function initialize(address authmen, address mining, address authmenNFT, address LPToken) public initializer {
        _authmen  = authmen;
        _mining = mining;
        _authmenNFT = authmenNFT;
        _LPToken = LPToken;
    }
    
    function getNFTMiningNumbersPerSecond(uint256 nftLevel) internal pure returns (uint256)  {
        uint price;
        if (nftLevel == AUTH1) {
            price = 4 ether;
            return price.div(10).div(1 hours);
        } else if (nftLevel == AUTH2) {
            price = 6 ether;
            return price.div(10).div(1 hours);
        } else if (nftLevel == AUTH3) {
            price = 1 ether;
            return price.div(1 hours);
        } else if (nftLevel == AUTH4) {
            price = 15 ether;
            return price.div(10).div(1 hours);
        } else if (nftLevel == AUTH5) {
            price = 2 ether;
            return price.div(1 hours);
        } else {
            price = 3 ether;
            return price.div(1 hours);
        }
    }
    
    function updateAccountNFTEaring(address account, uint256 nftLevel) internal {
        accountsNFTInfo[account][nftLevel].earning = accountsNFTInfo[account][nftLevel].earning.add(
            getNFTMiningNumbersPerSecond(nftLevel)
            .mul(accountsNFTInfo[account][nftLevel].amount)
            .mul(now.sub(accountsNFTInfo[account][nftLevel].stakeTime)));
    }
    
    function getLPMiningNumbersPerSecond(uint256 amount, uint256 totalAmount) internal pure returns (uint256)  {
        uint price;
        
        if (totalAmount.div(amount) > 200)  { // < 0.5%
            price = 1 ether;
            return price.div(10).div(1 hours);
        } else if (totalAmount.div(amount) > 100) {
            price = 2 ether;
            return price.div(10).div(1 hours);
        } else if (totalAmount.div(amount) > 20) {
            price = 4 ether;
            return price.div(10).div(1 hours);
        } else if (totalAmount.div(amount) > 10) {
            price = 2 ether;
            return price.div(10).div(1 hours);
        } else {
            price = 1 ether;
            return price.div(10).div(1 hours);
        }
    }
    
    function updateAccountLPEarning(address account) internal {
        uint256 amount = accountsLPInfo[msg.sender].amount;
        
        // stake金额 * 占比 * (stake 时长 / 最大stake时长) * 收益率
        accountsLPInfo[account].earning = accountsLPInfo[account].earning.add(
            getLPMiningNumbersPerSecond(amount, totalLPAmount)
            .mul(amount)
            .mul(amount)
            .div(totalLPAmount)
            .mul(now.sub(accountsLPInfo[account].stakeTime))
            .div(1 days));
    }
    
    function isNFTEmpty(address account) internal view returns (bool) {
        return  (accountsNFTInfo[account][AUTH1].stakeTime == 0 )
             && (accountsNFTInfo[account][AUTH2].stakeTime == 0 )
             && (accountsNFTInfo[account][AUTH3].stakeTime == 0 )
             && (accountsNFTInfo[account][AUTH4].stakeTime == 0 )
             && (accountsNFTInfo[account][AUTH5].stakeTime == 0 )
             && (accountsNFTInfo[account][AUTH6].stakeTime == 0 );
    }
    
    function stakeNFT(uint256 nftLevel, uint256 amount) public {
        require(nftLevel >= AUTH1 && nftLevel <= AUTH5, "NFT Level is invalid!");
        require(amount > 0, "Amount should be bigger than 0!");
        
        IERC1155Upgradeable(_authmenNFT).safeTransferFrom(msg.sender, address(this), nftLevel, amount, "");
        
        if (accountsLPInfo[msg.sender].stakeTime != 0) {
            if (isNFTEmpty(msg.sender)) {
                // begin earning.
                accountsLPInfo[msg.sender].stakeTime = now;
            } else if (accountsNFTInfo[msg.sender][nftLevel].stakeTime != 0) {
                updateAccountNFTEaring(msg.sender, nftLevel);
            }
        }
        accountsNFTInfo[msg.sender][nftLevel].stakeTime = now;
        accountsNFTInfo[msg.sender][nftLevel].amount = accountsNFTInfo[msg.sender][nftLevel].amount.add(amount);
    }
    
    function unStakeNFT(uint256 nftLevel, uint256 amount) public {
        require(nftLevel >= AUTH1 && nftLevel <= AUTH5, "NFT Level is invalid!");
        require(amount > 0 && amount <= accountsNFTInfo[msg.sender][nftLevel].amount, "Amount should be bigger than 0 and not bigger than owned!");

        if (accountsLPInfo[msg.sender].stakeTime != 0) {
            updateAccountNFTEaring(msg.sender, nftLevel);
        }
        
        accountsNFTInfo[msg.sender][nftLevel].amount = accountsNFTInfo[msg.sender][nftLevel].amount.sub(amount);
        
        if (accountsNFTInfo[msg.sender][nftLevel].amount > 0) {
            accountsNFTInfo[msg.sender][nftLevel].stakeTime = now;
        } else {
            // reset stake time of this nftlevel.
            accountsNFTInfo[msg.sender][nftLevel].stakeTime = 0;
        }

        if (isNFTEmpty(msg.sender)) {
             if  (accountsLPInfo[msg.sender].stakeTime != 0) {
                 // stop mining
                 updateAccountLPEarning(msg.sender);
                 accountsLPInfo[msg.sender].stakeTime = now;
             }
        }
        
        IERC1155Upgradeable(_authmenNFT).safeTransferFrom(address(this), msg.sender, nftLevel, amount, "");
    }
    
    function stakeLPToken(uint256 amount) public {
        require(amount > 0, "Amount should be bigger than 0!");
        
        IERC20(_LPToken).transferFrom(msg.sender, address(this), amount);
        
        if (! isNFTEmpty(msg.sender)) {
            if (accountsLPInfo[msg.sender].stakeTime == 0) {
                // begin mining
                for (uint256 i = AUTH1; i <= AUTH6; i++) {
                    if (accountsNFTInfo[msg.sender][i].stakeTime != 0) {
                        accountsNFTInfo[msg.sender][i].stakeTime = now;
                    }
                }
            } else {
                updateAccountLPEarning(msg.sender);
            }
        }
        accountsLPInfo[msg.sender].stakeTime = now;
        accountsLPInfo[msg.sender].amount = accountsLPInfo[msg.sender].amount.add(amount);
        
        totalLPAmount = totalLPAmount.add(amount);
    }
    
    function unStakeLPToken(uint256 amount) public {
        require(amount > 0 && amount <= accountsLPInfo[msg.sender].amount, "Amount should be bigger than 0 and not bigger than owned!");
        require(accountsLPInfo[msg.sender].stakeTime != 0, "This account has not staked LP Token yet!");
        
        if (! isNFTEmpty(msg.sender)) {
            updateAccountLPEarning(msg.sender);
        }

        accountsLPInfo[msg.sender].amount = accountsLPInfo[msg.sender].amount.sub(amount);
        
        if (accountsLPInfo[msg.sender].amount > 0) {
            accountsLPInfo[msg.sender].stakeTime = now;
        } else {
            accountsLPInfo[msg.sender].stakeTime = 0;
            
            for (uint256 i = AUTH1; i <= AUTH6; i++) {
                if (accountsNFTInfo[msg.sender][i].amount != 0) {
                    updateAccountNFTEaring(msg.sender, i);
                    accountsNFTInfo[msg.sender][i].stakeTime = now;
                }
            }
            
        }

        totalLPAmount = totalLPAmount.sub(amount);

        IERC20(_LPToken).transferFrom(address(this), msg.sender, amount);
    }
    
    function claimEarning() public {
        uint256 totalEarning = 0;
        
        if (!isNFTEmpty(msg.sender) && accountsLPInfo[msg.sender].stakeTime != 0) {
            for (uint256 i = AUTH1; i <= AUTH6; i++) {
                updateAccountNFTEaring(msg.sender, i);
                totalEarning = totalEarning.add(accountsNFTInfo[msg.sender][i].earning);
                accountsNFTInfo[msg.sender][i].earning = 0;
            }
            
            updateAccountLPEarning(msg.sender);
            totalEarning = totalEarning.add(accountsLPInfo[msg.sender].earning);
            accountsLPInfo[msg.sender].earning = 0;
        } else {
            for (uint256 i = AUTH1; i <= AUTH6; i++) {
                totalEarning = totalEarning.add(accountsNFTInfo[msg.sender][i].earning);
                accountsNFTInfo[msg.sender][i].earning = 0;
            }
            
            totalEarning = totalEarning.add(accountsLPInfo[msg.sender].earning);
            accountsLPInfo[msg.sender].earning = 0;
        }
        
        if (totalEarning > 0) {
            IERC20(_authmen).transferFrom(_mining, msg.sender, totalEarning);
        }
    }
    
    
}
