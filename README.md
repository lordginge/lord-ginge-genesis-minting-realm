# Lord Ginge Genesis, beta mainnet minting realm (gnoland1)

This package is the beta-mainnet deployment of the GRC721 collection. The code is
identical to the live topaz version; only the network and namespace differ.

- **Target chain:** gnoland1 (gno.land beta mainnet), RPC `https://rpc.gno.land`
- **Target path:** `gno.land/r/g1n500fmqx8m6tgts85kmn43htegkv0eewkdm4lg/gingernft`
- **grc721:** vendored into the package (`grc721_*.gno`, renamed to `package gingernft`)
  because gnoland1, like topaz, has no on-chain grc721 library. Only external imports
  are `gno.land/p/nt/avl/v0` and `gno.land/p/nt/ufmt/v0`, both deployed on gnoland1.

## Easiest deploy: the UI

Open the hosted Lord Ginge Genesis beta mainnet page, connect Adena, and press
**Deploy collection to beta mainnet**. The page sends one `/vm.m_addpkg` transaction
with all six files embedded, a 6 GNOT storage deposit, and a 1 GNOT gas fee. It then
polls the chain until the realm answers and unlocks minting.

The deploy must come from wallet `g1n500fmqx8m6tgts85kmn43htegkv0eewkdm4lg`, because
namespaces are permissioned: only that address can publish under `r/g1n500…/`.

## Deploying from your own UI: two Adena traps

Verified against Adena's encoder and the production deploy flow of
[samouraiworld/memba](https://github.com/samouraiworld/memba):

1. **`/vm.m_addpkg` has no `deposit` field.** Its proto fields are `creator`,
   `package`, `send`, `max_deposit`. If you send a `deposit` field, Adena's
   `encodeMessageValue` silently drops it, the VM falls back to the chain's tiny
   default deposit, and simulation fails with "not enough deposit to cover the
   storage usage", which Adena surfaces only as a generic **"Failed to estimate
   gas"** with fee `0` and gas `2200000000`. Always use
   `send: ""` + `max_deposit: "6000000ugnot"` for a package of this size.

2. **Pass explicit gas, never rely on estimation.** Call
   `adena.DoContract({ messages, gasFee: 1000000, gasWanted: 40000000, memo })`.
   With `gasWanted` set, the wallet skips the `.app/simulate` estimation path, so
   the zero-fee failure state cannot occur. Mint calls on this realm are fine at
   `gasWanted: 10000000` with `max_deposit: "3000000ugnot"`.

## CLI alternative (gnokey)

```
gnokey add deployer --recover          # import the wallet seed
gnokey maketx addpkg \
  -pkgdir . \
  -gas-fee 1000000ugnot -gas-wanted 40000000 \
  -max-deposit 6000000ugnot \
  -remote https://rpc.gno.land -chain-id gnoland1 \
  -broadcast deployer
```

## Beta mainnet caveats

- GNOT transfers between accounts are disabled during beta (gas usage works fine).
- The gno.land team may reset chain data during beta; treat mints as not yet permanent.
- Minting, transferring and burning NFTs are realm state changes and work normally.
