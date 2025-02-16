// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract ASPPIBRADAO is AccessControl, Pausable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Definição de papéis de controle de acesso
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");

    // Token utilizado para governança
    IERC20 public token;

    // Estrutura de uma proposta
    struct Proposal {
        address target;
        bytes data;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startTime;
        uint256 endTime;
        uint256 snapshotVotes;
        bool executed;
    }

    // Mapeamento para armazenar propostas
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    // Listas de controle (blacklist e whitelist)
    EnumerableSet.AddressSet private blacklist;
    EnumerableSet.AddressSet private whitelist;

    // Definição de quórum para votação (percentual do supply total)
    uint256 public quorumPercentage = 20;

    // Registro de votos para cada proposta
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => mapping(address => address)) public delegatedVotes;

    // Eventos
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer);
    event VoteCasted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event FundsAllocated(address indexed recipient, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event UserAddedToBlacklist(address indexed user);
    event UserRemovedFromBlacklist(address indexed user);
    event UserAddedToWhitelist(address indexed user);
    event UserRemovedFromWhitelist(address indexed user);
    event Deposited(address indexed user, uint256 amount);

    // Construtor
    constructor(address _token) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        token = IERC20(_token);
    }

    // Criar uma nova proposta (somente PROPOSER_ROLE)
    function createProposal(address target, bytes memory data, uint256 duration) external onlyRole(PROPOSER_ROLE) whenNotPaused {
        proposals[proposalCount] = Proposal(target, data, 0, 0, block.timestamp, block.timestamp + duration, token.balanceOf(msg.sender), false);
        emit ProposalCreated(proposalCount, msg.sender);
        proposalCount++;
    }

    // Votar em uma proposta (qualquer detentor de tokens)
    function vote(uint256 proposalId, bool support) external whenNotPaused {
        require(proposalId < proposalCount, "Proposta inexistente");
        require(block.timestamp >= proposals[proposalId].startTime, "Voting not started yet");
        require(block.timestamp <= proposals[proposalId].endTime, "Voting period has ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        require(!blacklist.contains(msg.sender), "User is blacklisted");

        uint256 balance = token.balanceOf(msg.sender);
        require(balance > 0, "No tokens to vote");

        Proposal storage proposal = proposals[proposalId];
        address voter = msg.sender;

        // Se o voto for delegado
        if (delegatedVotes[proposalId][msg.sender] != address(0)) {
            voter = delegatedVotes[proposalId][msg.sender];
        }

        if (support) {
            proposal.votesFor += balance;
        } else {
            proposal.votesAgainst += balance;
        }

        hasVoted[proposalId][voter] = true;
        emit VoteCasted(proposalId, voter, support);
    }

    // Delegar votos
    function delegateVote(uint256 proposalId, address to) external whenNotPaused {
        require(proposalId < proposalCount, "Proposta inexistente");
        require(block.timestamp >= proposals[proposalId].startTime, "Voting not started yet");
        require(block.timestamp <= proposals[proposalId].endTime, "Voting period has ended");
        require(to != msg.sender, "Cannot delegate vote to self");

        delegatedVotes[proposalId][msg.sender] = to;
    }

    // Executar uma proposta caso o quórum seja atingido (somente ADMIN_ROLE)
    function executeProposal(uint256 proposalId) external nonReentrant onlyRole(ADMIN_ROLE) {
        require(proposalId < proposalCount, "Proposta inexistente");

        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");

        uint256 totalSupply = token.totalSupply();
        require((proposal.votesFor + proposal.votesAgainst) >= (totalSupply * quorumPercentage) / 100, "Quorum not met");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal rejected");

        (bool success, ) = proposal.target.call(proposal.data);
        require(success, "Execution failed");

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    // Depositar tokens no contrato
    function deposit(uint256 amount) external whenNotPaused {
        token.transferFrom(msg.sender, address(this), amount);
        emit Deposited(msg.sender, amount);
    }

    // Retirar tokens do contrato (somente ADMIN_ROLE)
    function withdraw(uint256 amount, address recipient) external onlyRole(ADMIN_ROLE) {
        require(token.balanceOf(address(this)) >= amount, "Insufficient funds");
        require(!blacklist.contains(recipient), "Recipient is blacklisted");
        token.transfer(recipient, amount);
        emit FundsWithdrawn(recipient, amount);
    }

    // Alocar fundos para um endereço (somente ADMIN_ROLE)
    function allocateFunds(address recipient, uint256 amount) external onlyRole(ADMIN_ROLE) {
        require(token.balanceOf(address(this)) >= amount, "Insufficient funds");
        token.transfer(recipient, amount);
        emit FundsAllocated(recipient, amount);
    }

    // Adicionar usuário à blacklist (somente ADMIN_ROLE)
    function addToBlacklist(address user) external onlyRole(ADMIN_ROLE) {
        blacklist.add(user);
        emit UserAddedToBlacklist(user);
    }

    // Remover usuário da blacklist (somente ADMIN_ROLE)
    function removeFromBlacklist(address user) external onlyRole(ADMIN_ROLE) {
        blacklist.remove(user);
        emit UserRemovedFromBlacklist(user);
    }

    // Verificar se um usuário está na blacklist
    function isBlacklisted(address user) external view returns (bool) {
        return blacklist.contains(user);
    }

    // Adicionar usuário à whitelist (somente ADMIN_ROLE)
    function addToWhitelist(address user) external onlyRole(ADMIN_ROLE) {
        whitelist.add(user);
        emit UserAddedToWhitelist(user);
    }

    // Remover usuário da whitelist (somente ADMIN_ROLE)
    function removeFromWhitelist(address user) external onlyRole(ADMIN_ROLE) {
        whitelist.remove(user);
        emit UserRemovedFromWhitelist(user);
    }

    // Verificar se um usuário está na whitelist
    function isWhitelisted(address user) external view returns (bool) {
        return whitelist.contains(user);
    }

    // Ajustar o quórum (somente ADMIN_ROLE)
    function setQuorumPercentage(uint256 newQuorumPercentage) external onlyRole(ADMIN_ROLE) {
        quorumPercentage = newQuorumPercentage;
    }

    // Funções de pausa e retomada do contrato
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }
}
