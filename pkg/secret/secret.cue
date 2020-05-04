package secret

// Secret is a core type holding a secret value.
//
// Secrets are encrypted at rest and only decrypted on demand when passed as an
// input to a Run
Secret :: {
	$bl:   "bl.Secret"
	value: string
}
