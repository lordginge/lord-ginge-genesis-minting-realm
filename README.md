# Lord G's - Ginge Gnomie, beta mainnet minting realm (gnoland1)

This package is the **Lord G's - Ginge Gnomie** GRC721 collection (`GNOMIE`) for
gno.land beta mainnet: 111 Warhol-style gnomes with fully on-chain metadata —
image and traits live inside the chain state itself, no IPFS, no API, no server.

- **Target chain:** gnoland1 (gno.land beta mainnet), RPC `https://rpc.gno.land`
- **Target path:** `gno.land/r/g1n500fmqx8m6tgts85kmn43htegkv0eewkdm4lg/gingernft2`
- **grc721:** vendored into the package (`grc721_*.gno`, renamed to `package gingernft`)
  because gnoland1 has no on-chain grc721 library. Only external imports are
  `gno.land/p/nt/avl/v0` and `gno.land/p/nt/ufmt/v0`, both deployed on gnoland1.

## Access model

- One **owner wallet** (`g1n500fmqx8m6tgts85kmn43htegkv0eewkdm4lg`, hardcoded).
- **Public mint:** any wallet calls `Mint()` with **no arguments** while minting is
  open. The caller receives a **random** artwork from the pool. One token per wallet.
- **Owner only:** `AddArtwork(metadataURI)` (grows the pool), `EndMint()`
  (permanently closes minting, one-way), `RemoveArtwork(idx)` (deletes pool art and
  reclaims its storage deposit — the chain refunds the caller automatically, and only
  the owner can call it, so refunds can only ever go to the owner).
- Token owners control their own tokens: transfer, approve, `SetTokenURI`, `Burn`.
  Burning also removes the token's URI, releasing the **full** storage deposit
  (metadata included) to the wallet that signs the burn.
- The owner wallet has no special power over minted tokens.

## On-chain metadata and proof

Each token's `TokenURI` is a `data:application/json;base64,...` document following
the OpenSea standard — `{name, description, image, attributes}` with `Hat`, `Beard`
and `Background` colour traits — and the image itself is a data URI inside that JSON.
The realm's own `Render` pages decode this on-chain:

- `/r/.../gingernft2` lists every minted token with decoded name, traits and owner.
- `/r/.../gingernft2:3` (token id after the colon) is a per-token proof page with the
  exact `gnokey` command to read the record straight from a validator.

Anyone can verify without any website:

```
gnokey query vm/qeval -data "gno.land/r/g1n500fmqx8m6tgts85kmn43htegkv0eewkdm4lg/gingernft2.GetTokenURI(\"1\")"
```

Decode the base64 answer and the image appears.

## Randomness

`pickArtwork` hashes `sha256("height|caller|supply")`, folds the bytes into a pool
index, then walks forward to the first artwork that still exists. It is
deterministic on-chain randomness: unpredictable enough for a one-per-wallet
community drop, but not cryptographic — a validator could in theory grind it.

## Storage deposits

gnoland1 charges **100 ugnot per byte** of state growth, locked as a refundable
deposit from the transaction caller. Shrinking state (burning a token, removing
artwork) refunds the freed deposit to whoever signs that transaction. The minting
UI compresses artwork to WebP before upload (~0.5–0.7 GNOT deposit per gnome) and
shows the exact deposit estimate per file.

## Easiest deploy: the UI

Open the hosted Lord G's - Ginge Gnomie page, connect Adena with the owner wallet,
sign the one-time Contributor License Agreement, then press **Deploy collection**.
The page sends one `/vm.m_addpkg` transaction with all six files embedded
(max_deposit 6 GNOT, ~2 GNOT actually locked, 1 GNOT gas fee), polls the chain
until the realm answers, then unlocks the owner panels: single/multi artwork add,
bulk CSV upload with image matching, end-collection switch, deposit cleanup.

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
- Realms are immutable once deployed: this package cannot be altered after publish.
