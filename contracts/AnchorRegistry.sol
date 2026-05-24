// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Dependant on the Governance contract
interface IGovernance {
    function isAuthorised(address submitter) external view returns (bool);
}

contract AnchorRegistry {

    // Struct that combines all metadata into one batched type
    struct BatchMetadata {
        uint256 batchId;          // sequential ID
        uint256 timestamp;        // timestamp when anchored
        address submitter;        // aggregator node 
        uint256 logCount;         // number of logs in batch
        bytes32 merkleRoot;       // stored for convenience
    }

    // State Vars
    IGovernance public governance; // Address of the gov contract

    uint256 public nextBatchId = 1; // Starts at 1 (as 0 means not found in retrieval functions)
    mapping(uint256 => BatchMetadata) public batches; // Main ledger, given a batch ID get the metadata
    mapping(bytes32 => uint256) public deviceLatest; // Reverse index of the batches ledger

    // Event for anchoring a batch, ensuring indexing occurs
    event BatchAnchored(
        uint256 indexed batchId,
        bytes32 indexed merkleRoot,
        address indexed submitter,
        uint256 timestamp,
        uint256 logCount
    );

    // Constructor for deployment
    constructor(address governanceAddress) {
        governance = IGovernance(governanceAddress);
    }

    // Submit Batch - external as cannot be called internally to function
    function submitBatch(
        bytes32 merkleRoot,
        uint256 logCount,
        bytes32[] calldata deviceIds
    ) external {

        require(governance.isAuthorised(msg.sender), "Not authorised"); // Check auth
        uint256 batchId = nextBatchId++; // Increment batchID

        // Build in memory before writing to storage
        BatchMetadata memory meta = BatchMetadata({
            batchId: batchId,
            timestamp: block.timestamp,
            submitter: msg.sender,
            logCount: logCount,
            merkleRoot: merkleRoot
        });

        batches[batchId] = meta; // ledger

        for (uint256 i = 0; i < deviceIds.length; i++) {
            deviceLatest[deviceIds[i]] = batchId;
        } // Sets the latest device for the given submission

        emit BatchAnchored(
            batchId,
            merkleRoot,
            msg.sender,
            block.timestamp,
            logCount
        );
    }
    
    //Get function 
    function getBatch(uint256 batchId)
        external
        view
        returns (BatchMetadata memory)
    {
        require(batches[batchId].batchId != 0, "Batch not found");
        return batches[batchId];
    }
    //Get for device function
    function getDeviceLatest(bytes32 deviceId)
        external
        view
        returns (BatchMetadata memory)
    {
        uint256 batchId = deviceLatest[deviceId];
        require(batchId != 0, "Device not found");
        return batches[batchId];
    }
}
