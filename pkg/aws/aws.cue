package aws

import (
    "stackbrew.io/secret"
)

// AWS Config shared by all AWS packages
Config :: {
	region:    string
	accessKey: secret.Secret
	secretKey: secret.Secret
}
