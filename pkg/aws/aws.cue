package aws

import "blocklayer.dev/bl"

// AWS Config shared by all AWS packages

// Possible references to this location:
// aws/ecr/ecr.cue:13:14
// googlecloud/gcr/gcr.cue:13:22
#Config: {
	region:    string
	accessKey: bl.Secret
	secretKey: bl.Secret
}
Config: #Config @tmpNoExportNewDef(3a3f)
