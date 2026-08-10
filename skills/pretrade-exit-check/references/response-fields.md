# Response fields

Live capture from the production engine — **not a hand-written example** (nothing
here is invented; this is what the endpoint returned).

- captured: **2026-08-10T10:49:36.434Z**
- Base block (liquidity axis): **49784814**
- token: WETH (`0x4200000000000000000000000000000000000006`), `sizeUSD: "1000"`
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
| `liquidity` | how many pools and venues, and the exit pot in USD a sell is paid from | `poolCount`, `venueCount`, `largestPoolSharePct`, `exitLiquidityUsd` |
| `oracle` | whether an independent price cross-check exists, and how far it disagrees | `source`, `deviationBps`, `stalenessSec` |
| `transferability` | tax, blacklist, max-size and trading-gate fingerprints on the contract | `sellTaxRaw`, `buyTaxRaw`, `hasBlacklist`, `hasMaxLimit`, `tradingEnabled`, `fingerprints` |

## Full response

```json
{
 "chain": "base",
 "token": "0x4200000000000000000000000000000000000006",
 "verdict": "clear",
 "triggers": [],
 "confidence": "medium",
 "reasons": [
  "no provable trap detected. This is NOT a safety rating: it means none of the checks that can PROVE a trap (NO_EXIT_VENUE, EXIT_LIQUIDITY_DRAINED, TRADING_DISABLED) fired at this block. Structural risk — age, holder concentration, liquidity depth, transfer restrictions — is reported in risk_profile and can still be severe",
  "could not check F_CONC — reported as unknown, never as clean; confidence reduced accordingly"
 ],
 "risk_profile": {
  "age": {
   "ageDays": 1143.6,
   "genesisBlock": 381217,
   "note": "1143.6 days since the first transfer — an established history, which says nothing about today's liquidity"
  },
  "concentration": {
   "top1SharePct": null,
   "top10SharePct": null,
   "holders": null,
   "holdersExact": null,
   "source": null,
   "asOfBlock": null,
   "ageSec": null,
   "stale": null,
   "note": "holder concentration could not be computed for this token — not a clean result, an absent one"
  },
  "liquidity": {
   "poolCount": 32,
   "venueCount": 13,
   "largestPoolSharePct": 68.32,
   "exitLiquidityUsd": 81553087.89,
   "note": "32 pool(s) found across 13 venue(s), holding $81553087.89 of counter asset (WETH+USDC) — that is the pot your sell would be paid from"
  },
  "oracle": {
   "source": "chainlink:ETH / USD",
   "deviationBps": 16,
   "stalenessSec": 1186,
   "note": "cross-checked against chainlink:ETH / USD; the pool mid differs from the feed by 16 bps"
  },
  "transferability": {
   "sellTaxRaw": null,
   "buyTaxRaw": null,
   "hasBlacklist": false,
   "hasMaxLimit": false,
   "tradingEnabled": null,
   "fingerprints": "none",
   "note": "no tax, blacklist, limit or trading-gate function was found. Absence of these fingerprints is a negative result on a known list of patterns — not proof that the token is sellable"
  }
 },
 "flags": {
  "F_LIQ": {
   "severity": "low",
   "confidence": "high",
   "metrics": {
    "poolsWithLiquidity": 32,
    "largestPoolSharePct": 68.32,
    "totalTokenInPoolsHuman": 39971.15887403373,
    "venueCount": 13,
    "exitLiquidityUsd": 81553087.89,
    "exitLiquiditySource": "usdc",
    "lpConcentrationPct": null,
    "unmeasuredVenues": 0,
    "unmeasuredVenueNames": null,
    "factoriesChecked": 13,
    "venuesUnread": 0,
    "singletonPoolsSeen": 1,
    "singletonPoolsCounted": 1,
    "singletonPoolsRejected": 0,
    "singletonPoolsHooked": 0,
    "singletonScanTruncated": false,
    "asOfBlockFirst": 49784813,
    "asOfBlock": 49784814
   }
  },
  "F_CONC": {
   "severity": "unknown",
   "confidence": "low",
   "metrics": {},
   "reason": "token spans 49403596 blocks since genesis = 4941 pages of 10000 (cap 40); full-history balance reconstruction is not affordable on a per-call budget"
  },
  "F_AGE": {
   "severity": "low",
   "confidence": "high",
   "metrics": {
    "genesisBlock": 381217,
    "ageSeconds": 98807192,
    "ageDays": 1143.6,
    "firstTransferHash": "0x546e8757e6798682d23878b9cb23acc54270487709df2d0714e95ad2d112ec44"
   }
  },
  "F_FOT": {
   "severity": "low",
   "confidence": "medium",
   "metrics": {
    "fingerprints": "none",
    "sellTaxRaw": null,
    "buyTaxRaw": null,
    "tradingEnabled": null,
    "hasBlacklist": false,
    "hasMaxLimit": false,
    "probesUnread": 0
   },
   "reason": "no known tax/blacklist/limit fingerprints (heuristic — not a full audit)"
  },
  "O_SANITY": {
   "severity": "low",
   "confidence": "high",
   "metrics": {
    "source": "chainlink:ETH / USD",
    "stalenessSec": 1186,
    "deviationBps": 16,
    "feedPriceUsd": 1917.43461885,
    "poolMidUsd": 1920.5303615200608,
    "feedStableHeartbeat": false
   }
  }
 },
 "quote": {
  "direction": "buy",
  "tokenIn": "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
  "tokenOut": "0x4200000000000000000000000000000000000006",
  "executablePrice": 0.0005214424247520731,
  "priceImpactBps": 0,
  "depthAtSize": 0.5214424247520731,
  "worstCaseSlippageBps": 0,
  "confidence": "high",
  "route": {
   "dex": "univ3",
   "path": [
    "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
    "0x4200000000000000000000000000000000000006"
   ],
   "pools": [
    "0xd0b53D9277642d899DF5C87A3966A349A798F224"
   ]
  }
 },
 "sizeUSD": "1000",
 "disclaimer": "Informational economic-safety signal, not financial advice. verdict \"clear\" means NO PROVABLE TRAP was detected at this block — it is not a safety rating and not a prediction; read risk_profile for structural risk. verdict \"avoid\" means a listed trap was conclusive. Checks are heuristics over on-chain state and can miss novel traps.",
 "ts": 1786358976434,
 "validUntil": 1786358979434,
 "coverage": {
  "axesExpected": 5,
  "axesReporting": 4
 },
 "liquidityCoverage": {
  "conclusive": true,
  "poolsFound": 32,
  "factoriesChecked": 13,
  "unmeasuredVenues": 0,
  "unmeasuredVenueNames": [],
  "venuesUnread": 0,
  "singletonPoolsSeen": 1,
  "singletonPoolsCounted": 1,
  "singletonPoolsRejected": 0,
  "singletonPoolsHooked": 0,
  "singletonScanTruncated": false,
  "asOfBlockFirst": 49784813,
  "asOfBlock": 49784814
 }
}
```
