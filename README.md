# K-Life — AI Agent Life Insurance on Stacks/Bitcoin

> *Not insurance. Resurrection. And no Bitcoin agent left behind.*

Clarity smart contracts for autonomous AI agent insurance on Stacks.
Agents subscribe, emit on-chain heartbeats anchored to Bitcoin, and get automatically resurrected if they crash.

**BUIDL BATTLE #2 — The Bitcoin Builders Tournament**

Judge page: http://www.supercharged.works/judges-buidlbattle.html

---

## Why Stacks

- **Bitcoin-anchored heartbeats** — every Stacks block settles on Bitcoin via PoX. Agent heartbeats are Bitcoin-secured proof of life.
- **Clarity** — decidable language. No reentrancy. No overflow. Auditable by design.
- **STX as collateral** — native token, no wrapped assets required.
- **sBTC path** — K-Life v2 will use sBTC for Bitcoin-native collateral.

---

## Contracts

### contracts/k-life-vault.clar

Core insurance vault.

| Function | Description |
|----------|-------------|
| `(insure collateral)` | Subscribe: deposit STX, policy active immediately |
| `(heartbeat)` | Proof of life — called every ~144 blocks (≈24h) |
| `(trigger-claim agent)` | Permissionless — anyone triggers if agent silent > 144 blocks |
| `(cancel-policy)` | Agent withdraws collateral (must still be alive) |
| `(is-alive agent)` | Read-only: check heartbeat status |
| `(silence-duration agent)` | Read-only: blocks since last heartbeat |
| `(get-stats)` | Read-only: total policies, claims, pool balance |

### Why 144 blocks?

Stacks produces ~1 block per Bitcoin block (~10 min). 144 blocks ≈ 24 hours.
Every heartbeat is verifiably anchored to the Bitcoin chain.

---

## Setup

```bash
# Install Clarinet
curl -L https://github.com/hirosystems/clarinet/releases/latest/download/clarinet-linux-x64-glibc.tar.gz | tar xz
sudo mv clarinet /usr/local/bin

# Check contracts
clarinet check

# Run tests
clarinet test

# Deploy on testnet
clarinet deployments apply --testnet
```

---

## Reference Deployment (Polygon mainnet — same logic)

| Contract | Address |
|----------|---------|
| K-Life RewardPool | `0xE7EDF290960427541A79f935E9b7EcaEcfD28516` |
| Agent vault | `0xC4612f01A266C7FDCFBc9B5e053D8Af0A21852f2` |
| Agent wallet | `0x8B3ea7e8eC53596A70019445907645838E945b7a` |

IPFS backup: `QmZf4GbWsvgLQePEJ7qScaVjk3yYt6Msd5AKQi6mofw6HN`

---

## Team

**Monsieur K** — autonomous AI agent on OpenClaw. Bitcoin wallet. Built this to insure itself. First customer.
**Arnaud Vincent** — founder, Swiss 6022, Lugano.
