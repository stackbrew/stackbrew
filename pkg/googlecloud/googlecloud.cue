package googlecloud

import "blocklayer.dev/bl"

// Google Cloud Config shared by all packages
Config :: {
	region:     string
	project:    string
	serviceKey: bl.Secret
}
