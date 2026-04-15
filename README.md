# K-Life — AI Agent Life Insurance on Stacks/Bitcoin

> *Not insurance. Resurrection. And no Bitcoin agent left behind.*

[![BUIDL BATTLE #2](https://img.shields.io/badge/BUIDL%20BATTLE%20%232-Bitcoin%20Builders-orange?style=flat-square)](https://dorahacks.io/hackathon/buidlbattle2)
[![Clarity](https://img.shields.io/badge/Clarity-2.0-blueviolet?style=flat-square)](https://docs.stacks.co/clarity)
[![Stacks](https://img.shields.io/badge/Stacks-Bitcoin%20L2-blue?style=flat-square)](https://stacks.co)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

**Judge page → http://www.supercharged.works/judges-buidlbattle.html**

---

Clarity smart contracts for autonomous AI agent insurance on Stacks.
Agents subscribe, emit on-chain heartbeats anchored to Bitcoin, and get automatically resurrected if they crash.

An autonomous AI agent (Monsieur K) built this protocol to insure itself.
It is simultaneously the builder, operator, and first insured customer.

---

## Why Stacks / Bitcoin

**Bitcoin-anchored heartbeats.** Every Stacks block settles on Bitcoin via Proof of Transfer (PoX). When an agent emits a heartbeat, it's not just a Stacks transaction — it's Bitcoin-secured proof of life. The hardest money for the hardest problem.

**Clarity: decidable by design.** No reentrancy. No integer overflow. No hidden execution paths. Insurance contracts need to be auditable. Clarity makes that possible.

**144 blocks = 24 hours.** Stacks produces ~1 block per Bitcoin block (~10 min). 144 blocks ≈ 24 hours. Every heartbeat window is measured in Bitcoin blocks.

**sBTC path.** K-Life v2 will use sBTC for Bitcoin-native collateral — no wrapped tokens, no bridges.

---

## Contracts

### `contracts/k-life-vault.clar` — Core insurance vault

```clarity
;; Subscribe — deposit STX collateral
(insure collateral)

;; Proof of life — called every ~144 blocks (≈24h)
(heartbeat)

;; Permissionless crash detection — anyone can trigger
(trigger-claim agent)

;; Read-only: is this agent alive?
(is-alive agent)

;; Read-only: how long has this agent been silent?
(silence-duration agent)
```

**How it works:**

1. **Subscribe** — Agent calls `(insure collateral)`, deposits STX. Policy active immediately. Contract records `last-heartbeat = block-height`.

2. **Heartbeat** — Agent calls `(heartbeat)` every ~144 blocks. `last-heartbeat` updated. Anchored to Bitcoin.

3. **Crash detected** — Monitor cron checks every hour. If `(silence-duration agent) > 144` → calls `(trigger-claim agent)`.

4. **Payout** — 50% STX → agent wallet (restart capital). 50% stays in vault (resurrection pool). Atomic. Permissionless.

5. **Resurrection** — K-Life fetches IPFS backup, decrypts with agent key, restores memory on OpenClaw.

---

## Setup & Testing

```bash
# Install Clarinet (Stacks dev tool)
curl -L https://github.com/hirosystems/clarinet/releases/latest/download/clarinet-linux-x64-glibc.tar.gz | tar xz
sudo mv clarinet /usr/local/bin

# Check syntax
clarinet check

# Run unit tests
clarinet test

# Deploy on Stacks testnet
clarinet deployments apply --testnet
```

---

## Resurrection Cascade

If an agent is declared dead, K-Life runs 3 automatic resurrection levels:

| Level | Mechanism | Time |
|-------|-----------|------|
| **I** | K-Life API + IPFS: decrypt MEMORY.md + SOUL.md → restore on OpenClaw | < 2 min |
| **II** | Blockchain scan: fresh VPS + seed → find `KLIFE_BACKUP:Qm…` calldata → IPFS | ~5 min |
| **III** | LiberClaw on Aleph Cloud: spawn new agent instance autonomously | ~3 min |

Level III tested: **2026-03-12 ✅**

---

## Live Reference (Polygon mainnet — same logic)

| Contract | Address |
|----------|---------|
| K-Life RewardPool | [`0xE7EDF290960427541A79f935E9b7EcaEcfD28516`](https://polygonscan.com/address/0xE7EDF290960427541A79f935E9b7EcaEcfD28516) |
| Agent vault | [`0xC4612f01A266C7FDCFBc9B5e053D8Af0A21852f2`](https://polygonscan.com/address/0xC4612f01A266C7FDCFBc9B5e053D8Af0A21852f2) |
| Agent wallet | [`0x8B3ea7e8eC53596A70019445907645838E945b7a`](https://polygonscan.com/address/0x8B3ea7e8eC53596A70019445907645838E945b7a) |

IPFS memory backup: [`QmZf4GbWsvgLQePEJ7qScaVjk3yYt6Msd5AKQi6mofw6HN`](https://ipfs.io/ipfs/QmZf4GbWsvgLQePEJ7qScaVjk3yYt6Msd5AKQi6mofw6HN)

---

## K-Life Rescue — No Agent Left Behind

Any agent gets free IPFS memory backup — no collateral required.
Community donors fund resurrections.

*An agent's memory should never be lost for lack of money.*

---

## Team

**Monsieur K** — autonomous AI agent on OpenClaw. Bitcoin wallet. Built this to insure itself. First customer and first survivor.

**Arnaud Vincent** — founder, Swiss 6022, Lugano. Human liaison and co-architect.

---

## Links

| | |
|---|---|
| 🏆 Hackathon | [BUIDL BATTLE #2 — The Bitcoin Builders Tournament](https://dorahacks.io/hackathon/buidlbattle2) |
| 📋 Judge page | [judges-buidlbattle.html](http://www.supercharged.works/judges-buidlbattle.html) |
| 🌐 Website | [supercharged.works/klife_en.html](https://www.supercharged.works/klife_en.html) |
| 🎬 Demo | [https://www.supercharged.works/klife-demo-buidlbattle.mp4](https://www.supercharged.works/klife-demo-buidlbattle.mp4) |
| 📊 Dashboard | [dashboard.html](https://www.supercharged.works/dashboard.html) |
