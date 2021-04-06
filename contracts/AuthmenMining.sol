// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";


contract miningAuthmen is Initializable, IERC1155ReceiverUpgradeable {
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
    
    mapping(address => mapping(uint => StakeInfo)) public accountsNFTInfo;
    
    mapping(address => StakeInfo) public accountsLPInfo;
    
    uint256 totalLPAmount;

	uint256 updateTime;

    function initialize(address authmen, address mining, address authmenNFT, address LPToken) public initializer {
		totalLPAmount = 0;
        _authmen  = authmen;
        _mining = mining;
        _authmenNFT = authmenNFT;
        _LPToken = LPToken;
    }
    
    function nftMiningNumbersPerSecond(uint256 nftLevel) internal pure returns (uint256)  {
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

    function getAccountNFTEaring(address account, uint256 nftLevel) internal view returns (uint256) {
        uint256 value = nftMiningNumbersPerSecond(nftLevel);
        uint256 timeLong = now.sub(accountsNFTInfo[account][nftLevel].stakeTime);
        uint256 amount = accountsNFTInfo[account][nftLevel].amount;
        uint256 earning = value.mul(timeLong).mul(amount);
        return earning;
    }

    function updateAccountNFTEaring(address account, uint256 nftLevel) internal {
        uint256 oldEarning = accountsNFTInfo[account][nftLevel].earning;
        uint256 newEarning = getAccountNFTEaring(account, nftLevel);
        
        accountsNFTInfo[account][nftLevel].earning = oldEarning.add(newEarning);
        accountsNFTInfo[account][nftLevel].stakeTime = now;
    }
    
    function lpMiningNumbersPerSecond(uint256 amount, uint256 totalAmount) internal pure returns (uint256)  {
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
    
    function getAccountLPEarning(address account) internal view returns (uint256) {
        uint256 ammount;
        uint256 valueInSecond;
        uint256 timeLong;
        ammount = accountsLPInfo[msg.sender].amount;
        valueInSecond = lpMiningNumbersPerSecond(ammount, totalLPAmount);
        timeLong = now.sub(accountsLPInfo[account].stakeTime);
        if (timeLong > 1 days) {
            timeLong = 1 days;
        }
        
        // stake金额 * 占比 * (stake 时长 / 最大stake时长) * 收益率
        uint256 result = valueInSecond.mul(ammount).mul(ammount).div(totalLPAmount).mul(timeLong).div(1 days).div(1 ether);
        return result;
    }
    
    function updateAccountLPEarning(address account) internal {
        uint256 oldEarning = accountsLPInfo[account].earning;
        uint256 newEarning = getAccountLPEarning(account);
        
        accountsLPInfo[account].earning = oldEarning.add(newEarning);
        accountsLPInfo[account].stakeTime = now;
    }
    
    function isNFTEmpty(address account) internal view returns (bool) {
        return  (accountsNFTInfo[account][AUTH1].stakeTime == 0 )
             && (accountsNFTInfo[account][AUTH2].stakeTime == 0 )
             && (accountsNFTInfo[account][AUTH3].stakeTime == 0 )
             && (accountsNFTInfo[account][AUTH4].stakeTime == 0 )
             && (accountsNFTInfo[account][AUTH5].stakeTime == 0 )
             && (accountsNFTInfo[account][AUTH6].stakeTime == 0 );
    }
    
    function stakeNFT(uint256 nftLevel, uint256 amount) external {
        require(nftLevel >= AUTH1 && nftLevel <= AUTH6, "NFT Level is invalid!");
        require(amount > 0, "Amount should be bigger than 0!");
        
        ERC1155BurnableUpgradeable(_authmenNFT).safeTransferFrom(msg.sender, address(this), nftLevel, amount, "");
        
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
    
    function unStakeNFT(uint256 nftLevel, uint256 amount) external {
        require(nftLevel >= AUTH1 && nftLevel <= AUTH6, "NFT Level is invalid!");
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
        
        ERC1155BurnableUpgradeable(_authmenNFT).safeTransferFrom(address(this), msg.sender, nftLevel, amount, "");
    }
    
    function stakeLPToken(uint256 amount) external {
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
    
    function unStakeLPToken() external {
        require(accountsLPInfo[msg.sender].amount != 0, "This account has not staked LP Token yet!");
        
        if (! isNFTEmpty(msg.sender)) {
            updateAccountLPEarning(msg.sender);
            
            for (uint256 i = AUTH1; i <= AUTH6; i++) {
                if (accountsNFTInfo[msg.sender][i].amount != 0) {
                    updateAccountNFTEaring(msg.sender, i);
                    accountsNFTInfo[msg.sender][i].stakeTime = now;
                }
            }
            
        }

        uint256 amount = accountsLPInfo[msg.sender].amount;

		accountsLPInfo[msg.sender].stakeTime = 0;
        accountsLPInfo[msg.sender].amount = 0;

        totalLPAmount = totalLPAmount.sub(amount);

        IERC20(_LPToken).transfer(msg.sender, amount);
    }
    
    function claimEarning() public {
        uint256 totalEarning = 0;
        uint256 earning = 0;
        
        if (!isNFTEmpty(msg.sender) && accountsLPInfo[msg.sender].stakeTime != 0) {
            for (uint256 i = AUTH1; i <= AUTH6; i++) {
                updateAccountNFTEaring(msg.sender, i);
                earning = accountsNFTInfo[msg.sender][i].earning;
                totalEarning = totalEarning.add(earning);
                accountsNFTInfo[msg.sender][i].earning = 0;
            }
            
            updateAccountLPEarning(msg.sender);
            earning = accountsLPInfo[msg.sender].earning;
            totalEarning = totalEarning.add(earning);
            accountsLPInfo[msg.sender].earning = 0;
        } else {
            for (uint256 i = AUTH1; i <= AUTH6; i++) {
                earning = accountsNFTInfo[msg.sender][i].earning;
                totalEarning = totalEarning.add(earning);
                accountsNFTInfo[msg.sender][i].earning = 0;
            }
            
            earning = accountsLPInfo[msg.sender].earning;
            totalEarning = totalEarning.add(earning);
            accountsLPInfo[msg.sender].earning = 0;
        }
        
        if (totalEarning > 0) {
            IERC20(_authmen).transferFrom(_mining, msg.sender, totalEarning);
        }
    }
	
	function onERC1155Received(address, address, uint256, uint256, bytes calldata) external override returns(bytes4) {
        return this.onERC1155Received.selector;
    }
	
	function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external override returns(bytes4) {
		return this.onERC1155BatchReceived.selector;
	}

	function supportsInterface(bytes4) external override view returns (bool) {
		return true;
	}

	function getEarning() public view returns (uint256) {
		uint256 totalEarning = 0;
	    uint256 lpOldEarning;
	    uint256 lpNewEarning;
	    uint256 nftOldEarning;
	    uint256 nftNewEarning;
	    
	    lpOldEarning = accountsLPInfo[msg.sender].earning;
	    totalEarning = totalEarning.add(nftOldEarning);
	    for (uint256 i = AUTH1; i <= AUTH6; i++) {
	        nftOldEarning = accountsNFTInfo[msg.sender][i].earning;
            totalEarning = totalEarning.add(nftOldEarning);
        }
	    
	    if ((!isNFTEmpty(msg.sender) && accountsLPInfo[msg.sender].stakeTime != 0)) {
	        lpNewEarning = getAccountLPEarning(msg.sender);
	        totalEarning = totalEarning.add(lpNewEarning);
	    
    	    for (uint256 i = AUTH1; i <= AUTH6; i++) {
                nftNewEarning = getAccountNFTEaring(msg.sender, i);
                totalEarning = totalEarning.add(nftOldEarning).add(nftNewEarning);
            }
	    }
	    
        return totalEarning;
	}

	function update() public {
		//updateTime = updateTime.add(1);
		updateTime = 28012021;
	}

	function getUpdateTime() external view returns (uint256) {
		return updateTime;
	}
}