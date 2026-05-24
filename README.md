# SecLogChain

## Overview

AnchorRegistry is a smart contract system for anchoring device log data to a private blockchain. Rather than storing raw log data on-chain (which would be prohibitively expensive), aggregator nodes batch logs off-chain, build a Merkle tree from them, and anchor just the Merkle root to the chain. This gives a tamper-evident, auditable record of device activity without bloating the ledger.

The system is designed to run on a private, permissioned blockchain network — access to the node is restricted to internal infrastructure, with on-chain governance providing an additional layer of write control.

---

## Contracts

### `Governance`

A bare-bones governance implementation which adds submitter addresses, removes them and verifies them.

**State:**
- `authorisedSubmitters` - A list of the authorised addresses

**Functions:**
- `isAuthorised(address submitter)` — returns whether an address is authorised

- `addSubmitter(address submitter)` — adds a submitter address

- `removeSubmitter(address submitter)` — removes a submitter address

**Deploy this first**, then input the address into the `AnchorRegistry` constructor for full project deployment.

---

### `AnchorRegistry`

The core contract. Maintains an on-chain ledger of anchored batches and a reverse index mapping device IDs to their most recent batch.

**State:**
- `governance` — reference to the governance contract
- `nextBatchId` — auto-incrementing batch counter
- `batches` — mapping of batch ID → `BatchMetadata`
- `deviceLatest` — mapping of device ID → most recent batch ID

**Functions:**

- `anchorBatch(bytes32 merkleRoot, uint256 logCount, bytes32[] calldata deviceIds)` — anchors a new batch. Caller must be an authorised submitter. Updates `deviceLatest` for all device IDs in the batch and emits a `BatchAnchored` event.

- `getBatch(uint256 batchId)` — returns the full `BatchMetadata` for a given batch ID. Reverts with `"Batch not found"` if the ID has not been anchored.

- `getLatestBatchForDevice(bytes32 deviceId)` — convenience function that returns the most recent batch metadata for a given device. Reverts with `"Device not found"` if the device has never been anchored.

---

## Deployment Order

1. Deploy `Governance` 
2. Call `authorise(yourAddress)` on the governance contract
3. Deploy `AnchorRegistry`, passing the governance contract address as the constructor argument

---

## Verifying a Log Entry

To verify that a specific log belongs to a specific batch:

1. Call `getLatestBatchForDevice(deviceId)` to retrieve the batch metadata including the Merkle root
2. Obtain the Merkle proof for the log from the aggregator node (stored off-chain)
3. Verify the proof against the on-chain Merkle root using standard Merkle verification

The contract stores the root; proof verification can be done off-chain or via a separate verifier contract.


## Example Data for Testing

### 1  
merkleRoot: 0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef  
logCount: 10  
deviceIds: ["0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA","0xBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"]  

### 2  
merkleRoot: 0xcafebabecafebabecafebabecafebabecafebabecafebabecafebabecafebabe  
logCount: 5  
deviceIds: ["0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"]  

### 3  
merkleRoot: 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef  
logCount: 100  
["0xDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD","0xEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE","0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"]
### 4  
merkleRoot: 0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef  
logCount: 10  
deviceIds: ["0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA","0xBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"]  

### 5  
merkleRoot: 0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890  
logCount: 77  
deviceIds: ["0x0202020202020202020202020202020202020202020202020202020202020202","0x0303030303030303030303030303030303030303030303030303030303030303","0x0404040404040404040404040404040404040404040404040404040404040404","0x0505050505050505050505050505050505050505050505050505050505050505"]  