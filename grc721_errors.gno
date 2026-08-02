package gingernft

// errors raised by the grc721 implementation
import "errors"

var (
	ErrInvalidTokenId     = errors.New("grc721: invalid token id")
	ErrInvalidAddress     = errors.New("grc721: invalid address")
	ErrCallerIsNotOwner   = errors.New("grc721: caller is not the token owner")
	ErrNotApproved        = errors.New("grc721: caller is not approved for this token")
	ErrApprovalToOwner    = errors.New("grc721: approval to current owner")
	ErrInvalidName        = errors.New("grc721: invalid collection name")
	ErrInvalidSymbol      = errors.New("grc721: invalid collection symbol")
	ErrSpoofedRealm       = errors.New("grc721: spoofed realm")
	ErrNotRealm           = errors.New("grc721: not a realm")
)

// events
const (
	TransferEvent        = "Transfer"
	ApprovalEvent        = "Approval"
	ApprovalForAllEvent  = "ApprovalForAll"
	TokenURIUpdateEvent  = "TokenURIUpdate"
)
