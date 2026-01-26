# Blockchain Training Projects

This repository contains Solidity smart contracts and related scripts developed as part of my blockchain development learning journey.  
The projects are built, tested, and deployed using **Foundry**, following structured lessons and real-world dApp examples.

---

## 📂 Projects

### 1. FundMe.sol
A decentralized crowdfunding contract that allows users to fund in ETH, with the contract owner able to withdraw the total balance.

**Key Features:**
- Accepts ETH contributions from multiple funders.
- Uses Chainlink Price Feeds to enforce a minimum funding amount in USD.
- Maintains a record of each funder’s contribution.
- Only the owner (deployer) can withdraw the funds.
- Integrated with mock price feed (`MockV3Aggregator`) for local testing.

**Technologies & Tools:**
- Solidity ^0.8.18
- Foundry (Forge & Cast)
- Chainlink Price Feeds
- Sepolia Testnet deployment
- Keystore-based secure deployments (ERC-2335 format)

**Deployment & Verification Example:**
```bash
make deploy SEPOLIA_RPC_URL=<url> \
            KEYSTORE=<keystore-file> \
            --verify \
            --etherscan-api-key <api-key>

Tests Included:

    Minimum funding amount enforcement.

    Funding and withdrawal logic.

    Ownership restrictions.

    Mock price feed integration for local testing.

2. SimpleStorage.sol

A basic contract for storing and retrieving a single unsigned integer.

Key Features:

    Store a number on-chain.

    Retrieve the stored number.

    Demonstrates Solidity basics for state variables and functions.

Technologies & Tools:

    Solidity ^0.8.18

    Foundry for compiling, deploying, and testing.

Tests Included:

    Setting a value and retrieving it.

    Default value checks.

🛠 Project Structure

.
├── src/
│   ├── FundMe.sol
│   ├── PriceConverter.sol
│   ├── SimpleStorage.sol
├── script/
│   ├── DeployFundMe.s.sol
│   ├── DeploySimpleStorage.s.sol
├── test/
│   ├── FundMeTest.t.sol
│   ├── mocks/
│   │   └── MockV3Aggregator.sol
│   └── SimpleStorageTest.t.sol
├── Makefile
└── README.md

🚀 Getting Started
Prerequisites

    Foundry

    Node.js (for package management if needed)

    Git

Installation

# Clone the repository
git clone <repo-url>

# Enter the project directory
cd blockchain-training

# Install dependencies (if any)
forge install

Running Tests

forge test -vv

Deployment

make deploy

📚 Learning Source

These projects were built as part of the Cyfrin Updraft Solidity & Foundry training program, with additional practice and experimentation for real-world readiness.
📜 License

This project is licensed under the MIT License.