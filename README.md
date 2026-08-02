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
