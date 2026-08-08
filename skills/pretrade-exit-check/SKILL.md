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

So the user can try this once **without spending anything** — sign as usual, nothing
settles on-chain for that first call. Use this before asking anyone to approve a payment.

## How to read the answer

The response is JSON. The fields that decide anything:

| field | how to read it |
|---|---|
| `verdict: "avoid"` | A trap was **measured at this block**: no venue to sell into, the exit pot is under 5% of the asked size, or trading is gated. Report it with the trigger. |
| `verdict: "clear"` | **`clear` does NOT mean safe.** It means none of the provable-trap checks fired. Structural risk can still be severe — read `risk_profile`. Never present `clear` as a safety rating. |
| `triggers` | Which trap fired, by name. Empty on `clear`. |
| `confidence` | How much of the check actually ran. Low confidence with `clear` is weak evidence, not reassurance. |
| `coverage.axesReporting` / `axesExpected` | How many of the 5 axes reported. Fewer than expected means parts could not be measured — say so rather than rounding up to "fine". |
| `risk_profile` | Numbers without a verdict: token age, holder concentration, liquidity depth and the exit pot in USD, oracle deviation, transfer restrictions. Each carries a `note` explaining what it does and does not prove. |
| `quote.executablePrice` | The price you would actually get at `sizeUSD`, from the canonical on-chain quoters — not a mid price. |
| `quote.priceImpactBps`, `worstCaseSlippageBps` | What the size costs you. |
| `validUntil` | The answer is valid for **3000 ms** from `ts`. It is a snapshot of one block, not a standing rating. Re-check before acting on a stale answer. |
| `spotPrice: null` (on /v1/quote) | A missing number, stated. It is reported as `null` with the reason instead of a guess — treat "unknown" as unknown. |

### Say this to the user, not more

- "A trap was measured" — only when `verdict` is `avoid`, and name the trigger.
- "No provable trap at this block" — for `clear`. Then read out the structural
  numbers from `risk_profile` that actually look bad.
- Never say the token is safe, vetted, approved, or a good buy. This check cannot
  establish any of those.

## Limits

- **Base only.** Uniswap v3 and Aerodrome are the venues covered.
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
