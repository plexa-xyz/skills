---
name: pretrade-exit-check
description: Use when the user is about to buy, sell, or size a position in an unfamiliar ERC-20 token on Base and asks whether it can be sold again, how much can be sold without moving the price, what the realizable fill price is, whether the pool is deep enough to exit, whether a token looks like a honeypot or a rug, or how bad slippage would be at a given size; also when a wallet-security check has already said a transaction is not malicious and the remaining question is economic — is there anything to exit into. Base chain only. Not for BTC/ETH-only wallets and not for tokens outside Base.
license: MIT
metadata:
  author: plexa
  homepage: https://api.getplexa.com
  network: base
---

# Pre-trade exit check (Base)

Answers one question a wallet-security check does not: **if you buy this token, is
there anything to sell it back into?**

A transaction-security scanner tells you whether signing is dangerous — malicious
contract, drainer approval, phishing site. This tells you whether the *trade* is
survivable: how deep the exit pot is, what the realizable fill price is at your
size, and whether a trap can be **proven** on-chain right now.

Both questions matter. They are different questions.

## When to call

- The user is about to buy, sell, or size a position in a token they do not know.
- The user asks "can I sell this again", "how much can I move without wrecking the
  price", "is this a honeypot", "what will I actually get".
- A security scanner returned "not malicious" and the economic question is still open.

## When NOT to call

- The token is not on **Base**. This checks Base only; other chains return nothing useful.
- The wallet holds only majors (BTC, ETH, stablecoins) — there is no long-tail risk to measure.
- The user wants a price prediction or an investment opinion. This does not do that.

## How to call

POST to `https://api.getplexa.com/v1/pretrade/check` (aliases: `/v1/token-safety`, `/v1/rug-check`).

```json
{ "token": "0x<erc20 address on Base>", "sizeUSD": "1000" }
```

The endpoint is paid per call over **x402** (`exact` scheme, EIP-3009, Base).
If your agent has a wallet with x402 support, the payment is handled by the wallet:
inspect the 402 first, show the user the amount, pay only after approval.

**Price: $0.05 per call.**

### The first call is free

First call from a new wallet is FREE — the full response, every field, same engine as a paid call. No trial tier, no reduced answer: only the COUNT is limited (one per wallet). Sign the x402 payment as usual; nothing is settled on-chain for that first call.

Use this before asking anyone to approve a payment.

## How to read the answer

The response is JSON. The fields that decide anything:

| field | how to read it |
|---|---|
| `verdict: "avoid"` | A trap was **measured at this block**: no venue to sell into, the exit pot is under 5% of the asked size, or trading is gated. `triggers` names which one. |
| `verdict: "clear"` | **Scope: none of the checks that can PROVE a trap fired.** That is the whole claim — it covers proven traps and nothing else. Structural risk lives in `risk_profile`, and how completely the checks ran lives in `coverage` and `liquidityCoverage`. |
| `triggers` | Which trap fired, by name. Empty on `clear`. |
| `confidence` | How complete the evidence behind the verdict was. Read it together with `coverage` and `liquidityCoverage`. |
| `coverage.axesReporting` / `axesExpected` | How many of the 5 axes reported. The axes are `age` (how long since the first transfer), `concentration` (what share of supply the top-1 and top-10 holders hold), `liquidity` (how many pools and venues, and the exit pot in USD a sell is paid from), `oracle` (whether an independent price cross-check exists, and how far it disagrees), `transferability` (tax, blacklist, max-size and trading-gate fingerprints on the contract). Fewer than expected means parts of the check could not be conclusive. |
| `liquidityCoverage.conclusive` | Whether the exit check reached a conclusion. `true` — every covered factory was queried and the result stands. `false` — an AMM that cannot be measured pool-by-pool holds this token, and the exit triggers are not raised on this call. |
| `liquidityCoverage.poolsFound` / `factoriesChecked` | `poolsFound: 0` with `factoriesChecked: 13` is a measurement: every covered factory was asked and no pool exists. `poolsFound: null` with `factoriesChecked: 0` means discovery did not run at all — a different state, and the two are distinguishable without reading any text. |
| `liquidityCoverage.unmeasuredVenues` | How many AMMs hold this token but cannot be measured pool-by-pool (singleton AMMs such as Uniswap v4 keep every pool inside one contract). Their names are in `unmeasuredVenueNames`. |
| `liquidityCoverage.venuesUnread` | Of the unmeasured venues, how many simply did not answer on THIS call, as opposed to AMMs that cannot be measured by design. A non-zero value is about the call, not about the token. |
| `liquidityCoverage.singletonPoolsCounted` / `singletonPoolsRejected` / `singletonPoolsSeen` | Singleton AMMs (Uniswap v4) keep every pool inside one contract, so a sale is SIMULATED per pool through the canonical V4Quoter — hooks execute during that simulation. `singletonPoolsSeen` is how many pools of the pair were found, `singletonPoolsCounted` how many simulations succeeded (their proceeds are inside `exitLiquidityUsd`), `singletonPoolsRejected` how many the chain refused: a refusal is a measurement about that pool, not a gap in the data. |
| `liquidityCoverage.singletonPoolsHooked` | Of the pools seen, how many carry a hook with swap permissions. Derived from the hook address bits, no extra call. A hook is arbitrary code in the swap path; the simulation runs through it rather than around it. |
| `liquidityCoverage.singletonScanTruncated` | `true` — the singleton scan hit its work cap and some pools were left unqueried. Reported whether or not it changed the answer. |
| `liquidityCoverage.asOfBlockFirst` / `asOfBlock` | The Base blocks at the start and the end of the liquidity reads. Equal — the axis was read inside one block and is reproducible at that block. Different — no single block describes it, and the gap between them is the size of that uncertainty. |
| `risk_profile.concentration.ageSec` / `stale` | How old the holder numbers are. `ageSec: null` with `stale: false` — read on this call. A number — measured that many seconds ago. `stale: true` — the holder source was unreachable, so the last known measurement is reported instead of nothing. `stale: null` — there is no holder value at all, so there is nothing for the freshness flag to describe. |
| `risk_profile.concentration.holdersExact` | `false` means the TOTAL number of holders is unknown — a limit on our side, not a property of the token. The top-10 shares themselves are complete. |
| `risk_profile` | Those same 5 axes as numbers without a verdict, one section each: `age`, `concentration`, `liquidity`, `oracle`, `transferability`. Each carries a `note` explaining what it does and does not prove. |
| `quote` | The pre-trade answer **embeds a quote sub-result** — the same engine that serves /v1/quote, run at your `sizeUSD`. You do not call that endpoint separately for this. `null` if the token cannot be priced at all. |
| `quote.executablePrice` | The price you would actually get at `sizeUSD`, from the canonical on-chain quoters — not a mid price. |
| `quote.priceImpactBps`, `worstCaseSlippageBps` | What the size costs you. |
| `validUntil` | The answer is valid for **3000 ms** from `ts`. It is a snapshot of one block, not a standing rating. Re-check before acting on a stale answer. |
| `spotPrice: null` | Not a field of the embedded `quote` above: `spotPrice` belongs to the standalone /v1/quote response — the other endpoint on this same engine — and is named here because it is the clearest case of a rule that holds for every number in both. A value that could not be measured comes back as `null` **with the reason**, never as a guess and never as `0`. Treat "unknown" as unknown. |

### Two answers side by side

The same `verdict` word covers two different states. The difference is in the numbers.

```json
{ "verdict": "avoid", "triggers": ["NO_EXIT_VENUE"],
  "liquidityCoverage": { "conclusive": true, "poolsFound": 0, "factoriesChecked": 13, "unmeasuredVenues": 0 } }
```
Every covered factory was queried, no pool exists. The exit check reached a conclusion.

```json
{ "verdict": "clear", "triggers": [],
  "liquidityCoverage": { "conclusive": false, "poolsFound": 0, "factoriesChecked": 13,
                         "unmeasuredVenues": 1, "unmeasuredVenueNames": ["uniswap-v4"] } }
```
No proven trap fired, and the exit check did not reach a conclusion: an AMM holding
this token cannot be measured pool-by-pool.

## Limits

- **Base only.** The exit pot is measured across 13 liquidity factories
  (Uniswap v3, Aerodrome AMM and Slipstream, PancakeSwap v3, SushiSwap v3 and the
  v2 family), plus Uniswap v4 by per-pool simulation. Prices come from two of them.
- **Not a prediction.** It describes the state of one block; the next block can differ.
- **Absence of a trap is not proof of safety.** Novel traps that are not on the
  checked list will not fire.
- **On thin, new tokens some axes return `unknown`** — that is visible in
  `coverage` and in the per-axis notes. Unknown is reported as unknown, not
  rounded to a pass.
- Informational signal, not financial advice.

## Reference

- [Response fields](references/response-fields.md) — every field, with a live example.
- Example call: [`scripts/check.sh`](scripts/check.sh).
