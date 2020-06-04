package googlecloud

import "blocklayer.dev/bl"

// Google Cloud Config shared by all packages

// Possible references to this location:
// aws/ecr/ecr.cue:13:14
// googlecloud/gcr/gcr.cue:13:22
#Config: {
	region:     string
	project:    string
	serviceKey: bl.Secret
}
Config: #Config @tmpNoExportNewDef(3a3f)
