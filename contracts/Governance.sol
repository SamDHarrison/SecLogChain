// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Governance {

    // Owner address
    address public owner;

    // Hash map of authorised
    mapping(address => bool) public authorisedSubmitters;

    // Events
    event SubmitterAdded(address indexed submitter);
    event SubmitterRemoved(address indexed submitter);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // Owner is who deployed the contract initially
    constructor() {
        owner = msg.sender;
    }

    // Add
    function addSubmitter(address submitter) external onlyOwner {
        authorisedSubmitters[submitter] = true;
        emit SubmitterAdded(submitter);
    }

    // Remove
    function removeSubmitter(address submitter) external onlyOwner {
        authorisedSubmitters[submitter] = false;
        emit SubmitterRemoved(submitter);
    }

    // Check used by anchor registry contract
    function isAuthorised(address submitter)
        external
        view
        returns (bool)
    {
        return authorisedSubmitters[submitter];
    }
}
