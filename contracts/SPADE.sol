// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// SPADE - testnet reference implementation (unaudited)
// Requires OpenZeppelin Contracts v5.x. Audit before any mainnet use.
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {VestingWalletCliff} from "@openzeppelin/contracts/finance/VestingWalletCliff.sol";
import {VestingWallet} from "@openzeppelin/contracts/finance/VestingWallet.sol";

/// @notice 1,000,000 SPADE, 24 decimals, fixed at deployment. No mint function exists.
contract SPADE is ERC20, ERC20Burnable {
    uint256 public constant TOTAL_SUPPLY = 1_000_000 * 1e24;

    // Allocation (bps): treasury 25%, contributors 20%, liquidity 30%, reserves 25%
    constructor(address treasuryVest, address teamVest, address liquidity, address reserveVest)
        ERC20("SPADE", "SPADE")
    {
        _mint(treasuryVest, (TOTAL_SUPPLY * 2500) / 10_000);
        _mint(teamVest,     (TOTAL_SUPPLY * 2000) / 10_000);
        _mint(liquidity,    (TOTAL_SUPPLY * 3000) / 10_000);
        _mint(reserveVest,  (TOTAL_SUPPLY * 2500) / 10_000);
    }

    function decimals() public pure override returns (uint8) { return 24; }
}

/// @notice Linear vesting with cliff. Team: 12-month cliff, 48-month total.
contract SpadeVesting is VestingWalletCliff {
    constructor(address beneficiary, uint64 start, uint64 duration, uint64 cliff)
        VestingWallet(beneficiary, start, duration)
        VestingWalletCliff(cliff)
    {}
}

/// @notice Agent escrow: owners fund an agent via capped, expiring sessions.
/// RAG query tolls are split between the node operator and a permanent burn.
contract AgentEscrow is Ownable, Pausable, ReentrancyGuard {
    SPADE public immutable spade;
    uint16 public burnBps = 2000; // 20% of every toll burned; hard ceiling 50%

    struct Session { uint128 cap; uint128 spent; uint64 expiry; }
    mapping(address => uint256) public balanceOf;                         // owner => escrowed
    mapping(address => mapping(address => Session)) public sessions;      // owner => agent => session

    event Deposited(address indexed owner, uint256 amt);
    event Withdrawn(address indexed owner, uint256 amt);
    event SessionOpened(address indexed owner, address indexed agent, uint128 cap, uint64 expiry);
    event SessionRevoked(address indexed owner, address indexed agent);
    event QueryPaid(address indexed owner, address indexed agent, address indexed node, uint256 toNode, uint256 burned);

    error NoSession(); error Expired(); error OverCap(); error Insufficient(); error BadParam();

    constructor(SPADE _spade) Ownable(msg.sender) { spade = _spade; }

    function deposit(uint256 amt) external nonReentrant whenNotPaused {
        balanceOf[msg.sender] += amt;
        require(spade.transferFrom(msg.sender, address(this), amt), "transfer");
        emit Deposited(msg.sender, amt);
    }

    function withdraw(uint256 amt) external nonReentrant {
        if (balanceOf[msg.sender] < amt) revert Insufficient();
        balanceOf[msg.sender] -= amt;
        require(spade.transfer(msg.sender, amt), "transfer");
        emit Withdrawn(msg.sender, amt);
    }

    function openSession(address agent, uint128 cap, uint64 expiry) external {
        if (expiry <= block.timestamp || expiry > block.timestamp + 30 days) revert BadParam();
        sessions[msg.sender][agent] = Session(cap, 0, expiry);
        emit SessionOpened(msg.sender, agent, cap, expiry);
    }

    function revokeSession(address agent) external {
        delete sessions[msg.sender][agent];
        emit SessionRevoked(msg.sender, agent);
    }

    /// @dev Called by the agent. Enforces cap + expiry, then splits toll and burns the sink share.
    function payQuery(address owner_, address node, uint128 amt) external nonReentrant whenNotPaused {
        Session storage s = sessions[owner_][msg.sender];
        if (s.expiry == 0) revert NoSession();
        if (block.timestamp > s.expiry) revert Expired();
        if (s.spent + amt > s.cap) revert OverCap();
        if (balanceOf[owner_] < amt) revert Insufficient();
        s.spent += amt;
        balanceOf[owner_] -= amt;
        uint256 burned = (uint256(amt) * burnBps) / 10_000;
        uint256 toNode = amt - burned;
        spade.burn(burned);
        require(spade.transfer(node, toNode), "transfer");
        emit QueryPaid(owner_, msg.sender, node, toNode, burned);
    }

    function setBurnBps(uint16 bps) external onlyOwner { if (bps > 5000) revert BadParam(); burnBps = bps; }
    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }
}
