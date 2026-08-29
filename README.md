# pretrade-exit-check

Agent skill: **pre-trade economic check for ERC-20 tokens on Base, Polygon and
Arbitrum** — can this be sold again, and at what price at your size.

A wallet-security scanner answers "is this transaction malicious". This answers
"is there anything to exit into". Different questions.

## Install

```bash
npx skills add plexa-xyz/skills
```

## What it costs

$0.05 per call, paid by the agent's wallet over x402 (`exact`, EIP-3009, Base).
**The first call from a new wallet is free** — full response, same engine.

## Scope

Base, Polygon and Arbitrum only. Not a safety rating, not a prediction. See [SKILL.md](skills/pretrade-exit-check/SKILL.md).

---
Generated from the Plexa sources by `scripts/p26_skill_build.ts` — do not edit by hand.
