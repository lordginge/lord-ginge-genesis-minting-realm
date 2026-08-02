package gingernft

import "strings"

func isValidAddress(addr address) error {
	s := addr.String()
	if !strings.HasPrefix(s, "g1") || len(s) != 40 {
		return ErrInvalidAddress
	}
	return nil
}

func validName(name string) bool {
	return len(name) >= 1 && len(name) <= 64
}

func validSymbol(symbol string) bool {
	if len(symbol) < 1 || len(symbol) > 8 {
		return false
	}
	for _, c := range symbol {
		if c < 'A' || c > 'Z' {
			return false
		}
	}
	return true
}
