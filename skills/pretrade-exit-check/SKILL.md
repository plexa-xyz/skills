---
name: pretrade-exit-check
description: Use when the user is about to buy, sell, or size a position in an unfamiliar ERC-20 token on Base, Polygon or Arbitrum and asks whether it can be sold again, how much can be sold without moving the price, what the realizable fill price is, whether the pool is deep enough to exit, whether a token looks like a honeypot or a rug, or how bad slippage would be at a given size; also when a wallet-security check has already said a transaction is not malicious and the remaining question is economic — is there anything to exit into. Base, Polygon and Arbitrum only. Not for BTC/ETH-only wallets and not for tokens outside those networks.
license: MIT
metadata:
  author: plexa
  homepage: https://api.getplexa.com
  network: base, polygon, arbitrum
---

# Pre-trade exit check (Base · Polygon · Arbitrum)

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

- The token is on a network this does not cover. Served on: base, polygon, arbitrum. Per network — base (13 liquidity factories + uniswap-v4/pancakeswap-infinity, priced on uniswap-v3/aerodrome/aerodrome-cl-1/aerodrome-cl-2/aerodrome-cl-3/sushiswap-v3/uniswap-v2/sushiswap-v2/pancakeswap-v2/baseswap/alienbase/swapbased/uniswap-v4); polygon (15 liquidity factories + uniswap-v4, priced on uniswap-v3/sushiswap-v3/quickswap-v3/quickswap-v2/uniswap-v2/sushiswap-v2/apeswap/uniswap-v4); arbitrum (10 liquidity factories + uniswap-v4, priced on uniswap-v3/sushiswap-v3/ramses-v3/camelot-v3/sushiswap-v2/camelot-v2/uniswap-v2/uniswap-v4). The exit pot and the quote are measured on DIFFERENT venue lists by design: the pot only needs pool discovery and balances, a quote needs a quoter we have confirmed against the live market. Venues that count toward the exit pot but are NOT in the price: base — pancakeswap-v3, pancakeswap-infinity; polygon — retro, ramses-v3, w-dex, dooar, vulcandex, fraxswap, wault, polycat; arbitrum — pancakeswap-v3, ramses-v2, solidly-v3. On those the quote can be worse than the market while the safety verdict still sees that liquidity. A network that is not listed answers 422 — we do not publish a verdict where we have not measured the exit.
- The wallet holds only majors (BTC, ETH, stablecoins) — there is no long-tail risk to measure.
- The user wants a price prediction or an investment opinion. This does not do that.

## How to call

POST to `https://api.getplexa.com/v1/pretrade/check` (aliases: `/v1/token-safety`, `/v1/rug-check`).

```json
{ "token": "0x<erc20 address>", "sizeUSD": "1000", "chain": "base" }
```

The endpoint is paid per call over **x402** (`exact` scheme, EIP-3009, Base).
If your agent has a wallet with x402 support, the payment is handled by the wallet:
inspect the 402 first, show the user the amount, pay only after approval.

**Price: $0.05 per call.**

### The first call is free

First call from a new wallet is FREE — the full response, every field, same engine as a paid call. No trial tier, no reduced answer: only the COUNT is limited (one per wallet, across BOTH endpoints). Sign the x402 payment as usual; nothing is settled on-chain for that first call. P82 — you do not have to take that on trust: every 200 response carries `freeTrialApplied` — true when THAT call was served free, false when it was billed.

Use this before asking anyone to approve a payment.

## How to read the answer

The response is JSON. The fields that decide anything:

| field | how to read it |
|---|---|
| `verdict: "avoid"` | A trap was **measured at this block**: no venue to sell into, the exit pot is under 5% of the asked size, or trading is gated. `triggers` names which one. |
| `verdict: "clear"` | **Scope: none of the checks that can PROVE a trap fired, AND the exit check reached a conclusion.** That is the whole claim — it covers proven traps and nothing else. Structural risk lives in `risk_profile`, and how completely the checks ran lives in `coverage` and `liquidityCoverage`. |
| `verdict: "unknown"` | No trap fired **and the exit check did not reach a conclusion** (`liquidityCoverage.conclusive: false`) — so this call establishes neither a trap nor its absence. `reasons` carries `exit-coverage-incomplete:<what>`. Do not read it as `clear`: it is "not checked", not "checked, fine". |
| `triggers` | Which trap fired, by name. Empty unless the verdict is `avoid`. |
| `confidence` | How complete the evidence behind the verdict was. Read it together with `coverage` and `liquidityCoverage`. |
| `coverage.axesReporting` / `axesExpected` | How many of the 5 axes reported. The axes are `age` (how long since the first transfer), `concentration` (what share of supply the top-1 and top-10 holders hold), `liquidity` (how many pools and venues, and the exit pot in USD — since 20.09.2026 that pot is what SELLING THE POSITION returns, measured by quoting the sale, with the best road taken against the second-hop roads and never their sum. `exitPotBasis` says which number you got (position-sale = measured proceeds, second-hop = a counter-asset road, pool-inventory = the sale could not be quoted this call), and what the pools HOLD is published beside it as `exitPoolInventoryUsd` — an upper bound, not a promise), `oracle` (whether an independent price cross-check exists, and how far it disagrees), `transferability` (tax, blacklist, max-size and trading-gate fingerprints on the contract). Fewer than expected means parts of the check could not be conclusive. |
| `liquidityCoverage.conclusive` | Whether the exit check reached a conclusion. `true` — every covered factory was queried and the result stands. `false` — an AMM that cannot be measured pool-by-pool holds this token, and the exit triggers are not raised on this call. |
| `liquidityCoverage.poolsFound` / `factoriesChecked` | `poolsFound: 0` with `factoriesChecked: 13` is a measurement: every covered factory was asked and no pool exists. `poolsFound: null` with `factoriesChecked: 0` means discovery did not run at all — a different state, and the two are distinguishable without reading any text. |
| `liquidityCoverage.unmeasuredVenues` | How many AMMs hold this token but cannot be measured pool-by-pool (singleton AMMs such as Uniswap v4 keep every pool inside one contract). Their names are in `unmeasuredVenueNames`. |
| `liquidityCoverage.venuesUnread` | Of the unmeasured venues, how many simply did not answer on THIS call, as opposed to AMMs that cannot be measured by design. A non-zero value is about the call, not about the token. |
| `liquidityCoverage.singletonPoolsCounted` / `singletonPoolsRejected` / `singletonPoolsSeen` | Singleton AMMs (Uniswap v4) keep every pool inside one contract, so a sale is SIMULATED per pool through the canonical V4Quoter — hooks execute during that simulation. `singletonPoolsSeen` is how many pools of the pair were found, `singletonPoolsCounted` how many simulations succeeded (their proceeds are inside `exitLiquidityUsd`), `singletonPoolsRejected` how many the chain refused: a refusal is a measurement about that pool, not a gap in the data. |
| `liquidityCoverage.secondHopAssetsSeen` / `secondHopAssetsCounted` / `secondHopAssetsRejected` | 🔴 A token can be perfectly sellable against some asset that is NOT WETH or USDC (measured on Base: HALO trades against VIRTUAL, three tokens of one family against ADS, SOGNI against USDT). Until 2026-08-27 the pot did not look there and answered "no exit". `secondHopAssetsSeen` is how many such counter assets the factories list a pool for with this token — enumerated from the factories' own pool-creation events, so no list of "good" assets is involved. `secondHopAssetsCounted` is how many of those roads were CONFIRMED: the counter asset has its own exit to USDC that the engine itself quoted. `secondHopAssetsRejected` is how many could not be confirmed — they add nothing to the pot AND make the exit inconclusive, never a silent zero. |
| `liquidityCoverage.secondHopUsd` / `secondHopAssets` / `secondHopTruncated` | How many dollars of `exitLiquidityUsd` came from those confirmed roads, which assets carry them (`SYMBOL:usd`), and whether more roads existed than the per-call cap. The pot takes the BOTTLENECK of the two hops — the counter asset sitting in the token's pair valued at its own mid, against what that asset's market actually pays for it — never their sum. The search runs only when the WETH/USDC pot is below the drain floor: above it another road cannot change the answer. |
| `liquidityCoverage.singletonPoolsHooked` | Of the pools seen, how many carry a hook with swap permissions. Derived from the hook address bits, no extra call. A hook is arbitrary code in the swap path; the simulation runs through it rather than around it. |
| `liquidityCoverage.singletonPoolsHookRefused` | Of the pools the chain REFUSED to quote, how many carried such a hook. Separates "the hook forbade this sale" from "the pool is empty" — both used to arrive as one refusal counter. |
| `liquidityCoverage.singletonHookFlags` | Which swap permissions those hooks hold (BEFORE_SWAP, AFTER_SWAP, BEFORE_SWAP_RETURNS_DELTA, AFTER_SWAP_RETURNS_DELTA), comma-separated. null when no hooked pool refused. |
| `liquidityCoverage.exitPotBound` / `exitPotBoundReason` / `exitVenuesCounted` | 🔴 What the pot NUMBER means. `"measured"` — the sweep walked every source it knows about. `"lower"` — it stopped once the drain question was already answered (or hit a work cap, or priced through a venue whose pools are not in the count), so the pot is a FLOOR: at least this much, and how much more is not claimed. Dividing a `lower` pot by your position size gives a floor, not a coverage ratio. `exitPotBoundReason` says why and names the venues; `exitVenuesCounted` lists the venues whose pools actually contributed counter asset. This is a DIFFERENT question from `conclusive`: unasked pools can only RAISE the pot, so a `lower` pot next to `conclusive: true` is consistent — and a pot that is fully `measured` is what a trap verdict rests on. |
| `liquidityCoverage.exitLadderTopUsd` / `exitLadderBrokeAtUsd` / `exitLadderPoolsProbed` | 🔴 The v4 part of `exitLiquidityUsd` is no longer a sale of YOUR size. A singleton pool shows no reserves, so until 01.09.2026 its contribution was what a sale of the size you asked about returned — capped at about your size, which made `pot / my position` unable to exceed ~1 no matter how deep the pool was. Now we walk a ladder of ABSOLUTE dollar sizes ($5 / $25 / $100 / $500 / $2k / $10k / $50k, plus one refinement between the last size that worked and the first that did not) and report the largest size that actually sold at a loss no worse than the drain floor (5% of the size sold): `exitLadderTopUsd`. `exitLadderBrokeAtUsd` is where the pool stops being an exit; `null` there with a non-null top means the ladder ran out of rungs or work budget first, and `exitPotBoundReason` then carries `ladder-capped`. `exitLadderPoolsProbed` is how many extra pools the ladder asked — in discovery order, hooked pools on equal terms, because on measured tokens the deepest pool was a hooked one. All three `null` = the ladder did not run: the pot already answered the question. |
| `liquidityCoverage.exitLadderStatus` / `secondHopStatus` | 🔴 What each of those numbers MEANS — a zero used to carry three different facts (measured 2026-09-09 on the 27 watch pairs: `exitLadderTopUsd: 0` was "cannot sell even $5" on KOTAEMON, "no direct road, exit elsewhere" on HALO/SOGNI/KUMA, and "no exit" on the traps). Closed list: `measured` (the number is a measurement), `not_measured` (nobody measured it — the ladder did not run, or the second hop was not searched, or its token→asset leg is not quoted yet), `no_route` (enumeration ran, nothing to ask), `refused` (the chain reverted the sale — hook/quoter), `unsellable` (the chain answered with a number and every answer lost more than the drain floor at the $5 rung), `vendor_silent` (the node did not answer after retries). Two of them change the verdict: `exitLadderStatus: "unsellable"` and a pot that clears the drain floor only through a `secondHopStatus: "not_measured"` second hop both make the verdict `unknown`, never `clear` — `reasons` then carries an `exit-pot-status:…` line. A `not_measured` `secondHopUsd` is the counter assets' inventory, not what your sale would fetch. |
| `liquidityCoverage.exitPotUnquotedUsd` / `exitVenuesUnquoted` | 🔴 Since 19.09.2026 the price and the exit pot share ONE venue registry: a pot factory whose quoter is confirmed against the market (factory binding + aggregator ≤1 % or a reserve-formula/mid check) is quoted; the rest are `unquoted` by name. `exitPotUnquotedUsd` is the counter-asset inventory sitting on those unquoted venues: in the first hop it is inside `exitLiquidityUsd` (real reserve of a direct pool), in the second hop it is NOT — the token→asset leg cannot be quoted there, so the road stays unconfirmed and the pot excludes it. The second hop itself is now a measured leg: `secondHopUsd` is the bottleneck of what a sale of YOUR position fetches on the pool's own venue and what that asset's exit pays — never their sum (`secondHopStatus: measured`). |
| `liquidityCoverage.exitPotBasis` / `exitReachUsd` / `exitReachStatus` / `exitPoolInventoryUsd` | 🔴 Since 20.09.2026 `exitLiquidityUsd` is WHAT SELLING THE POSITION RETURNS, not what the pools hold. We quote the sale of the very position the answer prices and take the best road against the second-hop roads — never their sum. `exitPotBasis` says which number you got: `position-sale` (measured proceeds of the direct road), `second-hop` (the number came from a counter-asset road measured by the second hop) or `pool-inventory` (the sale could not be quoted this call — no entry quote or a silent node — so the number fell back to inventory, the pre-20.09 meaning). `exitReachUsd` is that measured sale and `exitReachStatus` is what it means (`measured` / `no_route` — a measured absence of a buyer at your size / `vendor_silent` / `not_measured`). `exitPoolInventoryUsd` keeps the old number: counter asset held by the direct pools, an upper bound on any sale, never a promise. Measured 20.09.2026 on SOGNI: inventory $113 968 against a sale that returns $4 571 for a $5 000 position — the promise `min(pot, size)` used to overstate the exit by 8.6 % of size. |
| `liquidityCoverage.exitLadderScope` / `exitReachRoad` | 🔴 Since 22.09.2026 each exit number names the ROAD it describes, because two of them were read wider than they were measured. `exitLadderScope` (today always `uniswap-v4-direct`) is the scope of `exitLadderStatus`: the ladder walks DIRECT Uniswap v4 pools and nothing else, so `unsellable` means THOSE pools refused your size — it never means the token cannot be sold. `exitReachRoad` names the road the pot itself was measured on: `direct` (straight into the dollar) or `via <asset>` — the asset's symbol when it is in our chain registry, its ADDRESS otherwise (we do not spend a node call on a label). Both are derived from work already done, so they cost nothing. Measured 22.09.2026 on Base: `exitLadderStatus: unsellable` across 31 v4 pools while selling the position returned $4 735.82 through Aerodrome into VIRTUAL — a real swap simulated on the same block agreed to 0.0000 %. Read them together with `exitPoolInventoryUsd`: when the ladder ran, the v4 share of that "upper bound" is the ladder's REACH, not inventory, and it never counts the second leg of a two-leg sale — measured on HOME the same day, inventory $4 472.00 against a sale returning $4 642.40. |
| `liquidityCoverage.singletonPoolsDiscovered` / `singletonPoolsUnasked` | The denominator and the remainder of the singleton scan: how many pools of this token exist and how many were never quoted because the sweep stopped early. Measured case (BASELINE, 2026-08-30): 238 found, 2 asked, 236 unasked once the pot cleared the floor — without these two numbers "we asked 2" and "2 exist" looked identical from outside. |
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

### What else comes back besides the verdict

The verdict and the 5 axes are the decision. These six blocks are the
CONTEXT around it — added after this skill was first written, and they are what a
market-data lookup cannot give you next to an executable price.

| block | what it is |
|---|---|
| `identity` | `name`, `symbol`, `decimals`, `totalSupply` read straight from the token contract at this block — not from a listing database that can be stale or wrong about a fork. |
| `valuation.fdvExecutableUsd` | Fully-diluted value at the price YOUR size can actually execute at. Deliberately different from a market-data site's market cap: the executable price is worse than spot on a thin book, and `totalSupply` is THIS chain's supply. The vendor's global figure travels in the same response as `market.marketCapUsd` — compare them, do not equate them. |
| `ownership` | `ownerRenounced`, `isMintable`, the creator address and the creator's remaining share. `ownerRenounced: null` means no `owner()` answered — **unknown, which is not the same as renounced**. |
| `dormancy` | How long the top holder has sat still. Rests on the holder axis: when that axis produces nothing, this block is `null` and says why. |
| `market` | Third-party market data (spot price, 24h volume, market cap, holder count), republished as-is and signed as theirs in `sources`. We did not measure any of it. `market.priceUsdSpot` is a SPOT print — the price your order gets is `quote.executablePrice`. |
| `sources` | **The map of who said what.** Every field of the response is attributable: `measured`, `unavailable`, `derived`, `vendor`. `unavailable:<reason>` names the gap instead of hiding it — that is how "we could not check" stays distinguishable from "we checked and it is fine". |

🔴 **Read `sources` before you trust a number.** `measured` is ours, off the chain,
this call. `derived` is ours, computed from other fields — the formula is in the
value. `vendor:<name>` is somebody else's number that we republish without
re-measuring. `unavailable:<reason>` is a hole with a name. A response where half
the map says `vendor` is a different product from one where it says `measured`,
and the map is the only way to tell them apart.

### Two answers side by side

Two states that look alike from the outside and are not the same claim. Until
2026-08-27 both answered `clear`, and the difference lived only in the numbers
below; now the verdict word itself separates them.

```json
{ "verdict": "avoid", "triggers": ["NO_EXIT_VENUE"],
  "liquidityCoverage": { "conclusive": true, "poolsFound": 0, "factoriesChecked": 13, "unmeasuredVenues": 0 } }
```
Every covered factory was queried, no pool exists. The exit check reached a conclusion.

```json
{ "verdict": "unknown", "triggers": [],
  "reasons": ["exit-coverage-incomplete:uniswap-v4,singleton-scan-truncated — ..."],
  "liquidityCoverage": { "conclusive": false, "poolsFound": 0, "factoriesChecked": 13,
                         "unmeasuredVenues": 1, "unmeasuredVenueNames": ["uniswap-v4"] } }
```
No proven trap fired, and the exit check did not reach a conclusion: an AMM holding
this token could not be measured pool-by-pool, or the sweep hit its work cap. The
absence of a trap is NOT established — treat it as unchecked, not as clean.

## Limits

- **Coverage is per network, and it differs.** Served on: base, polygon, arbitrum. Per network — base (13 liquidity factories + uniswap-v4/pancakeswap-infinity, priced on uniswap-v3/aerodrome/aerodrome-cl-1/aerodrome-cl-2/aerodrome-cl-3/sushiswap-v3/uniswap-v2/sushiswap-v2/pancakeswap-v2/baseswap/alienbase/swapbased/uniswap-v4); polygon (15 liquidity factories + uniswap-v4, priced on uniswap-v3/sushiswap-v3/quickswap-v3/quickswap-v2/uniswap-v2/sushiswap-v2/apeswap/uniswap-v4); arbitrum (10 liquidity factories + uniswap-v4, priced on uniswap-v3/sushiswap-v3/ramses-v3/camelot-v3/sushiswap-v2/camelot-v2/uniswap-v2/uniswap-v4). The exit pot and the quote are measured on DIFFERENT venue lists by design: the pot only needs pool discovery and balances, a quote needs a quoter we have confirmed against the live market. Venues that count toward the exit pot but are NOT in the price: base — pancakeswap-v3, pancakeswap-infinity; polygon — retro, ramses-v3, w-dex, dooar, vulcandex, fraxswap, wault, polycat; arbitrum — pancakeswap-v3, ramses-v2, solidly-v3. On those the quote can be worse than the market while the safety verdict still sees that liquidity. A network that is not listed answers 422 — we do not publish a verdict where we have not measured the exit.
- On **Base** the exit pot is measured across 13 liquidity factories
  (Uniswap v3, Aerodrome AMM and Slipstream, PancakeSwap v3, SushiSwap v3 and the
  v2 family), plus Uniswap v4 by per-pool simulation. Prices come from Uniswap v3,
  Aerodrome, Aerodrome Slipstream and Uniswap v4 — the venues whose quoter we have
  confirmed against the live market; the rest count toward the exit pot only.
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
