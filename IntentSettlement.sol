// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IntentSettlement {
    using ECDSA for bytes32;

    struct Intent {
        address user;
        address tokenIn;
        uint256 amountIn;
        address tokenOut;
        uint256 minAmountOut;
        uint256 nonce;
        uint256 deadline;
    }

    mapping(address => uint256) public nonces;

    /**
     * @dev Settles a user's intent. Solvers call this and must provide 
     * enough output tokens to satisfy the user's constraints.
     */
    function settle(
        Intent calldata intent,
        bytes calldata signature,
        bytes calldata solverData
    ) external {
        require(block.timestamp <= intent.deadline, "Intent expired");
        require(nonces[intent.user] == intent.nonce, "Invalid nonce");
        
        // Verification logic for intent signature would go here...
        nonces[intent.user]++;

        // 1. Pull user's tokens
        IERC20(intent.tokenIn).transferFrom(intent.user, address(this), intent.amountIn);
        
        // 2. Execute solver's specialized route (e.g., an AMM swap)
        (bool success, ) = msg.sender.call(solverData);
        require(success, "Solver execution failed");

        // 3. Ensure user received their requested output
        uint256 balanceOut = IERC20(intent.tokenOut).balanceOf(address(this));
        require(balanceOut >= intent.minAmountOut, "Slippage too high");
        IERC20(intent.tokenOut).transfer(intent.user, balanceOut);
    }
}
