# Response fields

Live capture from the production engine — **not a hand-written example** (nothing
here is invented; this is what the endpoint returned).

- captured: **2026-08-10T18:10:02.501Z**
- Base block (liquidity axis): **49798027**
- token: `0xcbb7c0000ab88b473b1f5afd9ef808440eed33bf` (cbBTC), `sizeUSD: "1000"`
- all 5 axes reported on this capture, and the exit check reached a conclusion —
  the fields below are shown doing their job, not sitting empty
- validity window: **3000 ms** (`validUntil - ts`)

## What decides the verdict

`avoid` fires only on a trap that can be proven from on-chain state at that block:

| trigger | meaning |
|---|---|
| `NO_EXIT_VENUE` | no pool on the covered DEXes to sell back into |
| `EXIT_LIQUIDITY_DRAINED` | the exit pot is below **5%** of the size asked about |
| `TRADING_DISABLED` | the trading gate on the contract reads false at this block |

Anything else is `clear`: the proven-trap checks ran and none of them fired. That is the scope of the word — proven traps, and nothing beyond them.

## The 5 axes

`coverage.axesReporting` counts these, and `risk_profile` carries one section per axis.
An axis that could not be computed reports `null` fields and says so in its `note`; it
is **not** silently dropped and **not** counted as a pass. The field lists below are the
ones present in the live capture at the bottom of this page.

| axis | what it measures | fields |
|---|---|---|
| `age` | how long since the first transfer | `ageDays`, `genesisBlock` |
| `concentration` | what share of supply the top-1 and top-10 holders hold | `top1SharePct`, `top10SharePct`, `holders`, `holdersExact`, `source`, `asOfBlock`, `ageSec`, `stale` |
| `liquidity` | how many pools and venues, and the exit pot in USD a sell can actually reach — across up to TWO hops (pairs against WETH/USDC, plus pairs against any other counter asset whose own exit was confirmed) | `poolCount`, `venueCount`, `largestPoolSharePct`, `exitLiquidityUsd` |
| `oracle` | whether an independent price cross-check exists, and how far it disagrees | `source`, `deviationBps`, `stalenessSec` |
| `transferability` | tax, blacklist, max-size and trading-gate fingerprints on the contract | `sellTaxRaw`, `buyTaxRaw`, `hasBlacklist`, `hasMaxLimit`, `tradingEnabled`, `fingerprints` |

## Full response

```json
{
 "chain": "base",
 "token": "0xcbb7c0000ab88b473b1f5afd9ef808440eed33bf",
 "verdict": "clear",
 "triggers": [],
 "confidence": "high",
 "reasons": [
  "no provable trap detected. This is NOT a safety rating: it means none of the checks that can PROVE a trap (NO_EXIT_VENUE, EXIT_LIQUIDITY_DRAINED, TRADING_DISABLED) fired at this block. Structural risk — age, holder concentration, liquidity depth, transfer restrictions — is reported in risk_profile and can still be severe"
 ],
 "risk_profile": {
  "age": {
   "ageDays": 710.56,
   "genesisBlock": 19101898,
   "note": "710.56 days since the first transfer — an established history, which says nothing about today's liquidity"
  },
  "concentration": {
   "top1SharePct": 82.2985,
   "top10SharePct": 90.2837,
   "holders": null,
   "holdersExact": false,
   "source": "graph",
   "asOfBlock": 49797953,
   "ageSec": 140,
   "stale": false,
   "note": "top-1 holder holds 82.2985% of supply, top-10 hold 90.2837%. A single holder that large can move the price alone. Read it with care: pool and treasury CONTRACTS are counted as holders here, so a mature token whose supply sits in its own pool looks identical to one wallet holding everything"
  },
  "liquidity": {
   "poolCount": 45,
   "venueCount": 13,
   "largestPoolSharePct": 16.08,
   "exitLiquidityUsd": 40275191.6,
   "note": "45 pool(s) found across 13 venue(s), holding $40275191.6 of counter asset (WETH+USDC) — that is the pot your sell would be paid from"
  },
  "oracle": {
   "source": "chainlink:BTC / USD",
   "deviationBps": 2,
   "stalenessSec": 72,
   "note": "cross-checked against chainlink:BTC / USD; the pool mid differs from the feed by 2 bps"
  },
  "transferability": {
   "sellTaxRaw": null,
   "buyTaxRaw": null,
   "hasBlacklist": true,
   "hasMaxLimit": false,
   "tradingEnabled": null,
   "fingerprints": "isBlacklisted",
   "note": "a blacklist function exists. On its own this is not a trap: USDC and cbBTC have one too. It means the issuer CAN freeze an address, which is a governance fact, not a measurement of today's behaviour"
  }
 },
 "flags": {
  "F_LIQ": {
   "severity": "low",
   "confidence": "high",
   "metrics": {
    "poolsWithLiquidity": 45,
    "largestPoolSharePct": 16.08,
    "totalTokenInPoolsHuman": 665.14870788,
    "venueCount": 13,
    "exitLiquidityUsd": 40275191.6,
    "exitLiquiditySource": "usdc+weth@chainlink",
    "lpConcentrationPct": null,
    "unmeasuredVenues": 0,
    "unmeasuredVenueNames": null,
    "factoriesChecked": 13,
    "venuesUnread": 0,
    "singletonPoolsSeen": 10,
    "singletonPoolsCounted": 1,
    "singletonPoolsRejected": 8,
    "singletonPoolsHooked": 7,
    "singletonScanTruncated": true,
    "asOfBlockFirst": 49798026,
    "asOfBlock": 49798027
   }
  },
  "F_CONC": {
   "severity": "high",
   "confidence": "medium",
   "metrics": {
    "holders": null,
    "top1SharePct": 82.2985,
    "top10SharePct": 90.2837,
    "decimals": 8,
    "source": "graph",
    "asOfBlock": 49797953,
    "fromCache": true,
    "cachedAgeSec": 140,
    "stale": false,
    "staleMaxSec": 86400,
    "holdersExact": false
   }
  },
  "F_AGE": {
   "severity": "low",
   "confidence": "high",
   "metrics": {
    "genesisBlock": 19101898,
    "ageSeconds": 61392256,
    "ageDays": 710.56,
    "firstTransferHash": "0x2b0bbc609005d30e11a0152cc1e552538ebba225cd194961fb3780e47bcd2a90"
   }
  },
  "F_FOT": {
   "severity": "high",
   "confidence": "high",
   "metrics": {
    "fingerprints": "isBlacklisted",
    "sellTaxRaw": null,
    "buyTaxRaw": null,
    "tradingEnabled": null,
    "hasBlacklist": true,
    "hasMaxLimit": false,
    "probesUnread": 0
   }
  },
  "O_SANITY": {
   "severity": "low",
   "confidence": "high",
   "metrics": {
    "source": "chainlink:BTC / USD",
    "stalenessSec": 72,
    "deviationBps": 2,
    "feedPriceUsd": 63902.54,
    "poolMidUsd": 63890.9953043413,
    "feedStableHeartbeat": false
   }
  }
 },
 "quote": {
  "direction": "buy",
  "tokenIn": "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
  "tokenOut": "0xcbb7c0000ab88b473b1f5afd9ef808440eed33bf",
  "executablePrice": 0.00001564358,
  "priceImpactBps": 5.1610367691268255,
  "depthAtSize": 0.01564358,
  "worstCaseSlippageBps": 5.1610367691268255,
  "confidence": "high",
  "route": {
   "dex": "univ3",
   "path": [
    "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
    "0xcbb7c0000ab88b473b1f5afd9ef808440eed33bf"
   ],
   "pools": [
    "0xfBB6Eed8e7aa03B138556eeDaF5D271A5E1e43ef"
   ]
  }
 },
 "sizeUSD": "1000",
 "disclaimer": "Informational economic-safety signal, not financial advice. verdict \"clear\" means NO PROVABLE TRAP was detected at this block — it is not a safety rating and not a prediction; read risk_profile for structural risk. verdict \"avoid\" means a listed trap was conclusive. Checks are heuristics over on-chain state and can miss novel traps.",
 "ts": 1786385402501,
 "validUntil": 1786385405501,
 "coverage": {
  "axesExpected": 5,
  "axesReporting": 5
 },
 "liquidityCoverage": {
  "conclusive": true,
  "poolsFound": 45,
  "factoriesChecked": 13,
  "unmeasuredVenues": 0,
  "unmeasuredVenueNames": [],
  "venuesUnread": 0,
  "singletonPoolsSeen": 10,
  "singletonPoolsCounted": 1,
  "singletonPoolsRejected": 8,
  "singletonPoolsHooked": 7,
  "singletonScanTruncated": true,
  "asOfBlockFirst": 49798026,
  "asOfBlock": 49798027
 }
}
```

## Beyond the verdict: the six context blocks

Added by later versions of the engine, so they are shown from a SECOND live
capture — token `0x4200000000000000000000000000000000000006` (WETH), captured **2026-08-27T14:00:51.213Z**. Two
measurements, kept apart on purpose: the capture above has all 5 axes
reporting, this one has the market vendor answering in full. Neither is edited.

**Fragment — only these six blocks, the rest of the body is the same as above:**

```json
{
 "identity": {
  "name": "Wrapped Ether",
  "symbol": "WETH",
  "decimals": 18,
  "totalSupplyRaw": "226130074043909151045427",
  "totalSupply": 226130.07404390915,
  "note": "name, symbol, decimals and totalSupply read straight from the token contract at this block"
 },
 "valuation": {
  "fdvExecutableUsd": 564516515.2017463,
  "basis": "totalSupply(this chain) x executablePrice(at sizeUSD)",
  "note": "fully-diluted value at the price your size can actually execute at, not at spot. Two reasons it may differ from a market-data site: the executable price is worse than spot on thin books, and totalSupply is THIS chain's supply — for a bridged token the global figure is larger. The vendor's global figure travels in this same response as market.marketCapUsd: the two are DIFFERENT quantities, and a large gap between them is the bridged supply plus the spot-vs-executable spread, not a contradiction"
 },
 "ownership": {
  "ownerAddress": null,
  "ownerRenounced": null,
  "isMintable": false,
  "creatorAddress": "0xe8a3ecea7d6a688ee903173024225357ddf29e93",
  "creatorBalance": 0.000289172466091074,
  "creatorSharePct": 1.2787881811550793e-7,
  "note": "no owner()/getOwner() answered — ownership is unknown, which is NOT the same as renounced; no known mint selector in the bytecode (heuristic: proxies and assembly dispatchers can hide one); creator inferred from the sender of the first transfer — a candidate, not a proven deployer"
 },
 "dormancy": {
  "topHolderIdleDays": null,
  "lastTopHolderMoveBlock": null,
  "headBlock": null,
  "note": "not computed: it rests on the holder axis, and that axis produced no block for this token (concentration source: none)"
 },
 "market": {
  "priceUsdSpot": 2490.85,
  "volume24hUsd": 263860126.61999997,
  "marketCapUsd": 559276105,
  "holderCount": 5232994,
  "note": "third-party market data, republished as-is and signed as theirs in `sources` — we did not measure any of it. priceUsdSpot is DexScreener's SPOT print from the deepest Base pool for this token, NOT the price your order gets: that one is quote.executablePrice, it depends on sizeUSD, and on a thin book it is worse than spot. marketCapUsd is the vendor's GLOBAL figure — every chain, their supply source. Our valuation.fdvExecutableUsd is a DIFFERENT quantity: THIS chain's totalSupply times the price your size can execute at. For a bridged token ours is legitimately the smaller number, and the gap is the bridged supply plus the spot-vs-executable spread. Compare them, do not equate them. volume24hUsd sums DexScreener's 24h volume over the 30 Base pair(s) where this token is the BASE asset; pairs where it is the quote asset are not counted. holderCount is GoPlus's count of addresses on this chain — read it with the same caution as concentration: pool, bridge and treasury CONTRACTS are addresses too"
 },
 "sources": {
  "*": "measured",
  "risk_profile.concentration": "unavailable:holder-axis-produced-nothing",
  "flags.F_CONC": "unavailable:holder-axis-produced-nothing",
  "valuation": "derived:identity.totalSupply*quote.executablePrice",
  "dormancy": "unavailable:holder-axis-produced-no-block",
  "ownership.creatorAddress": "derived:sender-of-first-transfer",
  "ownership.isMintable": "derived:mint-selector-in-bytecode",
  "market": "vendor:dexscreener+goplus",
  "market.priceUsdSpot": "vendor:dexscreener",
  "market.volume24hUsd": "vendor:dexscreener",
  "market.marketCapUsd": "vendor:dexscreener",
  "market.holderCount": "vendor:goplus"
 }
}
```

### The source map

`sources` answers "who said this" for every field. `*` is the default for
everything not listed.

| field | attribution |
|---|---|
| `*` | `measured` |
| `risk_profile.concentration` | `unavailable:holder-axis-produced-nothing` |
| `flags.F_CONC` | `unavailable:holder-axis-produced-nothing` |
| `valuation` | `derived:identity.totalSupply*quote.executablePrice` |
| `dormancy` | `unavailable:holder-axis-produced-no-block` |
| `ownership.creatorAddress` | `derived:sender-of-first-transfer` |
| `ownership.isMintable` | `derived:mint-selector-in-bytecode` |
| `market` | `vendor:dexscreener+goplus` |
| `market.priceUsdSpot` | `vendor:dexscreener` |
| `market.volume24hUsd` | `vendor:dexscreener` |
| `market.marketCapUsd` | `vendor:dexscreener` |
| `market.holderCount` | `vendor:goplus` |

Prefixes seen in this capture: `measured`, `unavailable`, `derived`, `vendor`.

- `measured` — ours, read off the chain on this call;
- `derived:<formula>` — ours, computed from other fields of this same response;
- `vendor:<name>` — somebody else's number, republished as-is and signed as theirs;
- `unavailable:<reason>` — no value, **and the reason why**. This is the whole
  point of the map: a missing number that names its own gap cannot be mistaken for
  a clean result.

## When an axis has no data at all

The capture above has every axis reporting. This one does not, and it is included
because the shape of a MISSING answer is part of the contract.

Same endpoint, a different token, captured earlier — WETH
(`0x4200000000000000000000000000000000000006`), captured
**2026-08-27T14:00:51.213Z**:

```json
{ "coverage": {"axesExpected":5,"axesReporting":4},
  "confidence": "medium",
  "risk_profile": { "concentration": {
    "top1SharePct": null,
    "top10SharePct": null,
    "holders": null,
    "holdersExact": null,
    "source": null,
    "asOfBlock": null,
    "ageSec": null,
    "stale": null,
    "note": "holder concentration could not be computed for this token — not a clean result, an absent one"
  } } }
```

Holder data for this token comes from one source, and that source did not answer.
The reply says so in fields rather than in prose: every number is `null`,
`ageSec` is `null` because there is no value to date, and `stale` is `null`
because there is nothing for a freshness flag to describe — not `false`, which
would assert that a non-existent value is fresh. `coverage` drops to 4/5 and `confidence` falls with it. The other four axes are unaffected and still carry
their numbers.
