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

    event TokensTransferred(address indexed recipient, uint256 amount);
    event ProposalVoted(address indexed proposal);
    event TokensStaked(uint256 amount);
    event TokensUnstaked(uint256 amount);
    event ContractsUpdated(address newToken, address newDao, address newStaking);

    constructor(address _tokenAddress, address _daoAddress, address _stakingAddress) Ownable(msg.sender) {
        require(_tokenAddress != address(0) && _daoAddress != address(0) && _stakingAddress != address(0), "Endereco invalido");
        tokenAddress = _tokenAddress;
        daoAddress = _daoAddress;
        stakingAddress = _stakingAddress;
    }

    // Funções de token
    function transferTokens(address recipient, uint256 amount) external onlyOwner {
        require(IToken(tokenAddress).transfer(recipient, amount), "Falha na transferencia");
        emit TokensTransferred(recipient, amount);
    }

    function getTokenBalance(address user) external view returns (uint256) {
        return IToken(tokenAddress).balanceOf(user);
    }

    // Funções de governança (DAO)
    function voteOnProposal(address proposal) external onlyOwner {
        require(proposal != address(0), "Proposta invalida");
        IGovernance(daoAddress).vote(proposal);
        emit ProposalVoted(proposal);
    }

    function getVotingPower(address user) external view returns (uint256) {
        return IGovernance(daoAddress).getVotingPower(user);
    }

    // Funções de staking
    function stakeTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "Valor invalido");
        IStaking(stakingAddress).stake(amount);
        emit TokensStaked(amount);
    }

    function unstakeTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "Valor invalido");
        IStaking(stakingAddress).unstake(amount);
        emit TokensUnstaked(amount);
    }

    function getStakedAmount(address user) external view returns (uint256) {
        return IStaking(stakingAddress).getStakedAmount(user);
    }

    // Atualizar contratos
    function updateContracts(address _tokenAddress, address _daoAddress, address _stakingAddress) external onlyOwner {
        require(_tokenAddress != address(0) && _daoAddress != address(0) && _stakingAddress != address(0), "Endereco invalido");
        tokenAddress = _tokenAddress;
        daoAddress = _daoAddress;
        stakingAddress = _stakingAddress;
        emit ContractsUpdated(_tokenAddress, _daoAddress, _stakingAddress);
    }
}
