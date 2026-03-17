package wallet

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"go-tps/tx"
	"sync"
	"time"

	"github.com/ethereum/go-ethereum/accounts"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	hdwallet "github.com/miguelmota/go-ethereum-hdwallet"
	"github.com/tyler-smith/go-bip39"
)

type Wallet struct {
	Address        common.Address
	PrivateKey     *ecdsa.PrivateKey
	DerivationPath string
	Nonce          uint64
	sync.Mutex
}

// GenerateMnemonic generates a new mnemonic phrase
func GenerateMnemonic() (string, error) {
	entropy, err := bip39.NewEntropy(128)
	if err != nil {
		return "", fmt.Errorf("failed to generate entropy: %w", err)
	}

	mnemonic, err := bip39.NewMnemonic(entropy)
	if err != nil {
		return "", fmt.Errorf("failed to generate mnemonic: %w", err)
	}

	return mnemonic, nil
}

// DeriveWalletsFromMnemonic derives multiple wallets from a single mnemonic.
func DeriveWalletsFromMnemonic(mnemonic string, count int, txSender *tx.TransactionSender) ([]*Wallet, error) {
	w, err := hdwallet.NewFromMnemonic(mnemonic)
	if err != nil {
		return nil, fmt.Errorf("failed to create HD wallet: %w", err)
	}

	wallets := make([]*Wallet, 0, count)

	for i := 0; i < count; i++ {
		// Standard Ethereum derivation path: m/44'/60'/0'/0/i
		path := hdwallet.MustParseDerivationPath(fmt.Sprintf("m/44'/60'/0'/0/%d", i))

		account, err := w.Derive(path, false)
		if err != nil {
			return nil, fmt.Errorf("failed to derive account %d: %w", i, err)
		}

		privateKey, err := w.PrivateKey(account)
		if err != nil {
			return nil, fmt.Errorf("failed to get private key for account %d: %w", i, err)
		}
		// context with 30 timeout
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)

		nonce, err := txSender.GetNonce(ctx, account.Address)
		cancel() // Call cancel immediately instead of deferring
		if err != nil {
			return nil, fmt.Errorf("failed to get nonce for wallet %d: %w", i, err)
		}

		wallets = append(wallets, &Wallet{
			Address:        account.Address,
			PrivateKey:     privateKey,
			DerivationPath: path.String(),
			Nonce:          nonce,
		})
	}

	return wallets, nil
}

// GetPublicAddress returns the Ethereum address from a private key
func GetPublicAddress(privateKey *ecdsa.PrivateKey) common.Address {
	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		return common.Address{}
	}

	return crypto.PubkeyToAddress(*publicKeyECDSA)
}

// ParseDerivationPath parses a derivation path string
func ParseDerivationPath(path string) (accounts.DerivationPath, error) {
	return hdwallet.ParseDerivationPath(path)
}
