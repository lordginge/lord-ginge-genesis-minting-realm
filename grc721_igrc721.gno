package gingernft

// IGRC721 is the interface implemented by BasicNFT.
type IGRC721 interface {
	Name() string
	Symbol() string
	TokenCount() int64
	BalanceOf(owner address) (int64, error)
	OwnerOf(tid TokenID) (address, error)
	TokenURI(tid TokenID) (string, error)
	SetTokenURI(caller address, tid TokenID, tURI TokenURI) (bool, error)
	IsApprovedForAll(owner, operator address) bool
	Approve(caller, to address, tid TokenID) error
	SetApprovalForAll(caller, operator address, approved bool) error
	TransferFrom(caller, from, to address, tid TokenID) error
	Mint(to address, tid TokenID) error
	Burn(tid TokenID) error
}

type TokenID string
type TokenURI string

func (t TokenID) String() string  { return string(t) }
func (u TokenURI) String() string { return string(u) }
