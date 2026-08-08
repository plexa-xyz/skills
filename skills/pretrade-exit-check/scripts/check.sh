#!/usr/bin/env bash
# Minimal example. Requires an x402-capable client with a funded wallet.
# The FIRST call from a new wallet is free — nothing settles on-chain for it.
set -euo pipefail

TOKEN="${1:?usage: check.sh <erc20-address-on-base> [sizeUSD]}"
SIZE="${2:-1000}"

# With MetaMask Agent Wallet (skill bundles the helper):
#   python3 "$SKILL_DIR/scripts/x402_pay.py" inspect https://api.getplexa.com/v1/pretrade/check
#   python3 "$SKILL_DIR/scripts/x402_pay.py" pay     https://api.getplexa.com/v1/pretrade/check --confirm \
#     --method POST --data "{\"token\":\"$TOKEN\",\"sizeUSD\":\"$SIZE\"}"
#
# Without a wallet: this shows the payment requirement and costs nothing.
curl -sS -i -X POST "https://api.getplexa.com/v1/pretrade/check" \
  -H 'content-type: application/json' \
  -d "{\"token\":\"$TOKEN\",\"sizeUSD\":\"$SIZE\"}"
