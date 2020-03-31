package aws

import "b.l/bl"

// AWS Config shared by all AWS packages
Config :: {
	region:    string
	accessKey: bl.Secret
	secretKey: bl.Secret
}
