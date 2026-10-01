# SPADE: design summary

- Supply: 1,000,000 SPADE, 24 decimals, fixed at deployment, no mint function.
- Allocation: liquidity 30% (LP locked 24 months), treasury 25% (48-month vest, 6-month cliff), reserves 25% (60-month vest, 12-month cliff), contributors 20% (48-month vest, 12-month cliff).
- Fees: 0.3% on each trade; 20% of that fee is burned.
- Agent economy: owners fund agents through capped, expiring sessions; 20% of query tolls burn.
- Staking: 8% APY in this demo, paid from the staking reserve, never newly minted.
- Governance: stake-weighted votes on fee, bounty and cooldown proposals.
- Price: set by pool reserves (constant product). The demo opens at $150,000 as a reference only.
- Status: simulation. No real funds. Contracts are unaudited.
