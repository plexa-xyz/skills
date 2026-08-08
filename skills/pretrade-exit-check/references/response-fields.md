# Response fields

Live capture from the production engine — **not a hand-written example** (nothing
here is invented; this is what the endpoint returned).

- captured: **2026-08-06T13:15:27.255Z**
- Base block (concentration axis): **49616303**
- token: WETH (`0x4200000000000000000000000000000000000006`), `sizeUSD: "1000"`
- validity window: **3000 ms** (`validUntil - ts`)

## What decides the verdict

`avoid` fires only on a trap that can be proven from on-chain state at that block:

| trigger | meaning |
|---|---|
| `NO_EXIT_VENUE` | no pool on the covered DEXes to sell back into |
| `EXIT_LIQUIDITY_DRAINED` | the exit pot is below **5%** of the size asked about |
| `TRADING_DISABLED` | the trading gate on the contract reads false at this block |

Anything else is `clear`, and `clear` is not a safety rating.

## Full response

```json
{
 "chain": "base",
 "token": "0x4200000000000000000000000000000000000006",
 "verdict": "clear",
 "triggers": [],
 "confidence": "high",
 "reasons": [
  "no provable trap detected. This is NOT a safety rating: it means none of the checks that can PROVE a trap (NO_EXIT_VENUE, EXIT_LIQUIDITY_DRAINED, TRADING_DISABLED) fired at this block. Structural risk — age, holder concentration, liquidity depth, transfer restrictions — is reported in risk_profile and can still be severe"
 ],
 "risk_profile": {
  "age": {
   "ageDays": 1139.7,
   "genesisBlock": 381217,
   "note": "1139.7 days since the first transfer — an established history, which says nothing about today's liquidity"
  },
  "concentration": {
   "top1SharePct": 29.2572,
   "top10SharePct": 56.9671,
   "holders": null,
   "holdersExact": false,
   "source": "graph",
   "asOfBlock": 49616303,
   "note": "top-1 holder holds 29.2572% of supply, top-10 hold 56.9671%. A single holder that large can move the price alone. Read it with care: pool and treasury CONTRACTS are counted as holders here, so a mature token whose supply sits in its own pool looks identical to one wallet holding everything"
  },
  "liquidity": {
   "poolCount": 6,
   "venueCount": 2,
   "largestPoolSharePct": 83.83,
   "exitLiquidityUsd": 61985229.39,
   "note": "6 pool(s) found across 2 venue(s), holding $61985229.39 of counter asset (WETH+USDC) — that is the pot your sell would be paid from"
  },
  "oracle": {
   "source": "chainlink:ETH / USD",
   "deviationBps": 29,
   "stalenessSec": 356,
   "note": "cross-checked against chainlink:ETH / USD; the pool mid differs from the feed by 29 bps"
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
   "severity": "medium",
   "confidence": "high",
   "metrics": {
    "poolsWithLiquidity": 6,
    "largestPoolSharePct": 83.83,
    "totalTokenInPoolsHuman": 37644.928776293345,
    "venueCount": 2,
    "exitLiquidityUsd": 61985229.39,
    "exitLiquiditySource": "usdc",
    "lpConcentrationPct": null
   }
  },
  "F_CONC": {
   "severity": "medium",
   "confidence": "medium",
   "metrics": {
    "holders": null,
    "top1SharePct": 29.2572,
    "top10SharePct": 56.9671,
    "decimals": 18,
    "source": "graph",
    "asOfBlock": 49616303,
    "cachedAgeSec": 35,
    "holdersExact": false
   }
  },
  "F_AGE": {
   "severity": "low",
   "confidence": "high",
   "metrics": {
    "genesisBlock": 381217,
    "ageSeconds": 98470344,
    "ageDays": 1139.7,
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
    "hasMaxLimit": false
   },
   "reason": "no known tax/blacklist/limit fingerprints (heuristic — not a full audit)"
  },
  "O_SANITY": {
   "severity": "low",
   "confidence": "high",
   "metrics": {
    "source": "chainlink:ETH / USD",
    "stalenessSec": 356,
    "deviationBps": 29,
    "feedPriceUsd": 1891.20457577,
    "poolMidUsd": 1896.7476003341283,
    "feedStableHeartbeat": false
   }
  }
 },
 "quote": {
  "direction": "buy",
  "tokenIn": "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
  "tokenOut": "0x4200000000000000000000000000000000000006",
  "executablePrice": 0.0005277836784854826,
  "priceImpactBps": 0,
  "depthAtSize": 0.5277836784854826,
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
 "disclaimer": "Informational economic-safety signal, not financial advice. verdict \"clear\" means NO PROVABLE TRAP was detected at this block — it is not a safety rating and not a prediction; read risk_profile for structural risk. verdict \"avoid\" means a listed trap was measured. Checks are heuristics over on-chain state and can miss novel traps.",
 "ts": 1786022127255,
 "validUntil": 1786022130255,
 "coverage": {
  "axesExpected": 5,
  "axesReporting": 5
 }
}
```
