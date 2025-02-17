// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IGovernance {
    function vote(address proposal) external;
    function getVotingPower(address user) external view returns (uint256);
}

interface IStaking {
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
    function getStakedAmount(address user) external view returns (uint256);
}

contract Proxy is Ownable {
    address public tokenAddress;
    address public daoAddress;
    address public stakingAddress;

    constructor(address _tokenAddress, address _daoAddress, address _stakingAddress) {
        tokenAddress = _tokenAddress;
        daoAddress = _daoAddress;
        stakingAddress = _stakingAddress;
    }

    // Funções de token
    function transferTokens(address recipient, uint256 amount) external onlyOwner {
        require(IToken(tokenAddress).transfer(recipient, amount), "Falha na transferência");
    }

    function getTokenBalance(address user) external view returns (uint256) {
        return IToken(tokenAddress).balanceOf(user);
    }

    // Funções de governança (DAO)
    function voteOnProposal(address proposal) external onlyOwner {
        IGovernance(daoAddress).vote(proposal);
    }

    function getVotingPower(address user) external view returns (uint256) {
        return IGovernance(daoAddress).getVotingPower(user);
    }

    // Funções de staking
    function stakeTokens(uint256 amount) external onlyOwner {
        IStaking(stakingAddress).stake(amount);
    }

    function unstakeTokens(uint256 amount) external onlyOwner {
        IStaking(stakingAddress).unstake(amount);
    }

    function getStakedAmount(address user) external view returns (uint256) {
        return IStaking(stakingAddress).getStakedAmount(user);
    }

    // Função para alterar os contratos, se necessário
    function updateContracts(address _tokenAddress, address _daoAddress, address _stakingAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
        daoAddress = _daoAddress;
        stakingAddress = _stakingAddress;
    }
}
