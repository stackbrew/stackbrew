package googlecloud

import (
    "stackbrew.io/secret"
)

// Google Cloud Config shared by all packages
Config :: {
	region:     string
	project:    string
	serviceKey: secret.Secret
}
