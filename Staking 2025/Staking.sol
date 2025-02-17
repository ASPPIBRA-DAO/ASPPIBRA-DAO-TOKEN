// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract ASPPBRStakeUpgradeable is Initializable, ReentrancyGuard, Ownable {
    struct Stake {
        uint256 amount;
        uint256 timestamp;
        uint256 rewards;
    }

    IERC20 public asppbrToken;
    uint256 public apy;
    uint256 public minimumStakeDuration;
    mapping(address => Stake) public stakes;

    event Staked(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 amount, uint256 rewards, uint256 timestamp);
    event APYUpdated(uint256 newAPY);
    event MinimumStakeDurationUpdated(uint256 newDuration);
    event TokensRecovered(address token, uint256 amount);

    function initialize(address _tokenAddress, uint256 _minimumStakeDuration) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        asppbrToken = IERC20(_tokenAddress);
        apy = 500;
        minimumStakeDuration = _minimumStakeDuration;
    }

    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Stake amount must be greater than zero");
        asppbrToken.transferFrom(msg.sender, address(this), amount);
        
        Stake storage userStake = stakes[msg.sender];
        userStake.amount += amount;
        userStake.timestamp = block.timestamp;
        
        emit Staked(msg.sender, amount, block.timestamp);
    }

    function withdraw() external nonReentrant {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No active stake found");
        
        uint256 rewards = calculateRewards(msg.sender);
        uint256 totalAmount = userStake.amount + rewards;
        
        if (block.timestamp - userStake.timestamp < minimumStakeDuration) {
            totalAmount = (userStake.amount * 1) / 3;
        }
        
        uint256 amountToWithdraw = totalAmount;
        userStake.amount = 0;
        userStake.rewards = 0;
        
        asppbrToken.transfer(msg.sender, amountToWithdraw);
        emit Withdrawn(msg.sender, amountToWithdraw, rewards, block.timestamp);
    }

    function calculateRewards(address user) public view returns (uint256) {
        Stake storage userStake = stakes[user];
        if (userStake.amount == 0) return 0;
        
        uint256 stakingDuration = block.timestamp - userStake.timestamp;
        uint256 reward = (userStake.amount * apy * stakingDuration) / (365 days * 100);
        
        return reward;
    }

    function setAPY(uint256 newAPY) external onlyOwner {
        apy = newAPY;
        emit APYUpdated(newAPY);
    }

    function getStake(address user) external view returns (uint256, uint256) {
        return (stakes[user].amount, stakes[user].rewards);
    }

    function setMinimumStakeDuration(uint256 newDuration) external onlyOwner {
        minimumStakeDuration = newDuration;
        emit MinimumStakeDurationUpdated(newDuration);
    }

    function recoverTokens(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(asppbrToken), "Cannot withdraw staking tokens");
        IERC20(tokenAddress).transfer(owner(), amount);
        emit TokensRecovered(tokenAddress, amount);
    }
}
