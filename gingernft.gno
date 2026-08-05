// Package gingernft is the Lord G's - Ginge Gnomie GRC721 collection on gno.land.
//
// Access model:
//   - The collection has ONE owner wallet (the deployer, hardcoded below).
//   - Only the owner can add artwork to the collection (AddArtwork).
//   - Any wallet can call Mint with no arguments while minting is open:
//     it mints a RANDOM artwork from the pool to the caller. Each wallet
//     can hold at most one token, so nobody can drain a drop.
//   - Only the owner can end minting (EndMint). It is permanent: once
//     closed, no more tokens can ever be minted. Scarcity is final.
//   - Only the owner can clean up old artwork (RemoveArtwork), which
//     releases its storage deposit; the refund goes to the owner.
//   - Only a token's owner can change its URI, move it, or burn it.
//   - The owner wallet gets no special power over minted tokens.
//
// Each token's metadata is stored as its TokenURI following the standard
// GRC721/OpenSea pattern: a data:application/json;base64,... URI containing
// a metadata document {name, description, image, attributes}. The image
// itself is usually a data:image/...;base64 URI inside that JSON, which
// makes the whole NFT (art + metadata) live fully on-chain with no IPFS
// or server.
//
// Randomness note: the pick is a deterministic hash of chain height,
// caller address and supply. It is unpredictable enough for a fair drop,
// but it is not cryptographic randomness; a validator could in theory
// grind it. For a one-per-wallet community mint this is the standard
// on-chain tradeoff.
package gingernft

import (
	"chain/runtime"
	"crypto/sha256"
	"errors"
	"strconv"
	"strings"

	"gno.land/p/nt/avl/v0"
	"gno.land/p/nt/ufmt/v0"
)

// ownerAddr is the only wallet allowed to manage the collection.
var ownerAddr = address("g1n500fmqx8m6tgts85kmn43htegkv0eewkdm4lg")

var nft = NewBasicNFT("Lord G's - Ginge Gnomie", "GNOMIE")

// artworks holds every artwork in the pool, keyed by its 1-based index
// as a string. Mint picks one at random.
var artworks avl.Tree
var artworkCount int64

// mintOpen starts true; EndMint flips it false forever.
var mintOpen = true

// --- owner only ---

// AddArtwork adds a metadata URI to the mint pool. Owner wallet only.
// Returns the artwork index.
// metadataURI is typically data:application/json;base64,... produced by
// the minting UI (max 300k chars). Plain https:// or ipfs:// URIs work too.
func AddArtwork(_ realm, metadataURI string) int64 {
	prev := runtime.PreviousRealm()
	require(prev.IsUser(), "AddArtwork from a user wallet only, no intermediary realms.")
	require(prev.Address() == ownerAddr, "only the collection owner can add artwork.")
	require(metadataURI != "", "metadataURI is required.")
	require(len(metadataURI) <= 300000, "metadataURI too long (max 300000 chars).")

	artworkCount++
	artworks.Set(strconv.FormatInt(artworkCount, 10), metadataURI)
	return artworkCount
}

// EndMint permanently closes the collection: no more tokens can ever be
// minted after this call. Owner wallet only. One-way, cannot be undone.
func EndMint(_ realm) error {
	prev := runtime.PreviousRealm()
	require(prev.IsUser(), "user wallets only")
	if prev.Address() != ownerAddr {
		return errors.New("only the collection owner can end minting")
	}
	if !mintOpen {
		return errors.New("minting is already closed")
	}
	mintOpen = false
	return nil
}

// RemoveArtwork deletes artwork idx from the pool and releases its locked
// storage deposit. The chain automatically refunds the freed deposit to
// the transaction caller, and only the owner wallet can call this, so the
// refund can only ever go to the owner. Owner wallet only.
// Minted tokens keep their own copy of the metadata, so removing an
// artwork never affects NFTs that already exist.
func RemoveArtwork(_ realm, idx int64) error {
	prev := runtime.PreviousRealm()
	require(prev.IsUser(), "user wallets only")
	if prev.Address() != ownerAddr {
		return errors.New("only the collection owner can remove artwork")
	}
	key := strconv.FormatInt(idx, 10)
	if !artworks.Has(key) {
		return errors.New("no artwork with that index")
	}
	artworks.Remove(key)
	return nil
}

// --- public mint ---

// Mint mints a RANDOM artwork from the pool to the caller's wallet.
// No arguments: minters cannot choose or supply metadata. One token per
// wallet. Fails permanently once the owner has ended minting.
// Returns the new token ID.
func Mint(_ realm) string {
	prev := runtime.PreviousRealm()
	require(prev.IsUser(), "Mint from a user wallet only, no intermediary realms.")
	caller := prev.Address()
	require(mintOpen, "minting is closed forever.")
	require(artworkCount > 0, "no artwork available yet.")

	bal, err := nft.BalanceOf(caller)
	checkErr(err)
	require(bal == 0, "this wallet already holds a Lord G's - Ginge Gnomie NFT (one per wallet).")

	idx := pickArtwork(caller)
	v, found := artworks.Get(strconv.FormatInt(int64(idx), 10))
	require(found, "artwork pool is empty.")
	metadataURI, ok := v.(string)
	require(ok, "corrupt artwork entry.")

	tid := TokenID(strconv.FormatInt(nft.TokenCount()+1, 10))
	checkErr(nft.Mint(caller, tid))
	_, serr := nft.SetTokenURI(tid, TokenURI(metadataURI))
	checkErr(serr)
	return tid.String()
}

// pickArtwork chooses a pool entry using a sha256 hash of the chain
// height, the caller and the current supply, then walks forward from that
// point to the first entry that still exists (removed ones are skipped).
func pickArtwork(caller address) int {
	n := int(artworkCount)
	h := sha256.Sum256([]byte(ufmt.Sprintf("%d|%s|%d", runtime.ChainHeight(), caller.String(), nft.TokenCount())))
	start := 0
	for _, b := range h {
		start = (start*31 + int(b)) % n
	}
	for i := 0; i < n; i++ {
		idx := (start+i)%n + 1
		if artworks.Has(strconv.FormatInt(int64(idx), 10)) {
			return idx
		}
	}
	return 0
}

// --- write wrappers ---

// TransferFrom moves a token; caller must be owner or approved.
func TransferFrom(_ realm, from, to address, tid string) error {
	require(runtime.PreviousRealm().IsUser(), "user wallets only")
	return nft.TransferFrom(from, to, TokenID(tid))
}

// Approve approves another address to move a token.
func Approve(_ realm, to address, tid string) error {
	require(runtime.PreviousRealm().IsUser(), "user wallets only")
	return nft.Approve(to, TokenID(tid))
}

// SetApprovalForAll approves or revokes an operator for all caller's tokens.
func SetApprovalForAll(_ realm, operator address, approved bool) error {
	require(runtime.PreviousRealm().IsUser(), "user wallets only")
	return nft.SetApprovalForAll(operator, approved)
}

// SetTokenURI updates a token's metadata URI. Token owner only.
func SetTokenURI(_ realm, tid, metadataURI string) error {
	require(runtime.PreviousRealm().IsUser(), "user wallets only")
	require(len(metadataURI) <= 300000, "metadataURI too long (max 300000 chars).")
	_, err := nft.SetTokenURI(TokenID(tid), TokenURI(metadataURI))
	return err
}

// Burn destroys a token the caller owns.
func Burn(_ realm, tid string) error {
	prev := runtime.PreviousRealm()
	require(prev.IsUser(), "user wallets only")
	owner, err := nft.OwnerOf(TokenID(tid))
	if err != nil {
		return err
	}
	if owner != prev.Address() {
		return errors.New("only the token owner can burn it")
	}
	return nft.Burn(TokenID(tid))
}

// --- read-only views (queryable via gnokey/qeval and the UI) ---

func Name() string      { return nft.Name() }
func Symbol() string    { return nft.Symbol() }
func TokenCount() int64 { return nft.TokenCount() }

func BalanceOf(owner address) (int64, error) { return nft.BalanceOf(owner) }
func OwnerOf(tid string) (address, error)    { return nft.OwnerOf(TokenID(tid)) }
func GetTokenURI(tid string) (string, error) { return nft.TokenURI(TokenID(tid)) }

// ArtworkCount is how many artworks were ever added to the pool.
func ArtworkCount() int64 { return artworkCount }

// PoolSize is how many artworks remain in the pool (removed ones excluded).
func PoolSize() int { return artworks.Size() }

// MintOpen reports whether minting is still open.
func MintOpen() bool { return mintOpen }

// GetArtworkURI returns the metadata URI of artwork idx.
func GetArtworkURI(idx int64) (string, bool) {
	v, found := artworks.Get(strconv.FormatInt(idx, 10))
	if !found {
		return "", false
	}
	s, ok := v.(string)
	return s, ok
}

// --- gnoweb page ---

// Render lists minted tokens. Metadata JSON lives in each TokenURI;
// this page shows IDs and owners, with a hint per token.
func Render(path string) string {
	if path != "" {
		return "404 — try the home page."
	}
	var sb strings.Builder
	sb.WriteString("# Lord G's - Ginge Gnomie\n\n")
	state := "OPEN"
	if !mintOpen {
		state = "CLOSED FOREVER"
	}
	sb.WriteString(ufmt.Sprintf("GRC721 collection · mint **%s** · **%d minted** · %d artworks in the pool\n\n",
		state, nft.TokenCount(), artworks.Size()))
	sb.WriteString("Mint by calling `Mint()` while open — a random artwork from the pool goes straight to your wallet. One per wallet.\n")
	sb.WriteString("Only the owner wallet can add artwork (`AddArtwork`), end minting (`EndMint`, permanent) or clean up (`RemoveArtwork`).\n\n")
	var i int64
	for i = 1; i <= nft.TokenCount(); i++ {
		tid := strconv.FormatInt(i, 10)
		owner, err := nft.OwnerOf(TokenID(tid))
		if err != nil {
			continue
		}
		sb.WriteString(ufmt.Sprintf("- **#%s** — owner `%s`\n", tid, owner.String()))
	}
	return sb.String()
}

func require(cond bool, msg string) {
	if !cond {
		panic(msg)
	}
}

func checkErr(err error) {
	if err != nil {
		panic(err)
	}
}
