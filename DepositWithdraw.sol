// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IVerifier {
    struct G1Point {
        uint X;
        uint Y;
    }

    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }

    struct Proof {
        G1Point a;
        G2Point b;
        G1Point c;
    }

    function verifyTx(Proof memory proof, uint[8] memory input) external view returns (bool r);
}

contract DepositWithdraw {
    IVerifier public immutable verifier;

    mapping(address => uint256) public balances;
    mapping(address => uint256[8]) private commitments;

    event Deposited(address indexed sender, uint256 amount);
    event Withdrawn(address indexed recipient, uint256 amount);

    constructor(address verifierAddress) {
        verifier = IVerifier(verifierAddress);
    }

    function deposit(uint256[8] calldata hash) external payable {
        require(msg.value > 0, "Deposit must be greater than zero");
        balances[msg.sender] += msg.value;
        commitments[msg.sender] = hash;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(
        IVerifier.Proof calldata proof,
        uint256[8] calldata input
    ) external {
        require(balances[msg.sender] > 0, "No balance to withdraw");

        uint256[8] memory stored = commitments[msg.sender];
        for (uint256 i = 0; i < 8; i++) {
            require(stored[i] == input[i], "Input does not match stored hash");
        }

        bool valid = verifier.verifyTx(proof, input);
        require(valid, "Invalid zero-knowledge proof");

        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        delete commitments[msg.sender];

        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getCommitment(address account) external view returns (uint256[8] memory) {
        return commitments[account];
    }
}
