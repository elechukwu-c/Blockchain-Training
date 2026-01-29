## Required dependencies

Each Foundry project requires installing its own dependencies.

Example (run inside project folder):

forge install foundry-rs/forge-std
forge install Cyfrin/foundry-devops
forge install smartcontractkit/chainlink

## Remapping  
@chainlink/contracts/ = lib/chainlink/contracts/
   
# then use:
#   import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
