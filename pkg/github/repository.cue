package github

import (
	"blocklayer.dev/bl"
)

// Possible references to this location:
// github/pull_request.cue:84:9
#Repository: {
	// Github repository name
	name: string

	// Github repository owner
	owner: string

	// Github API token
	token:           bl.Secret
	#GetPullRequest: #GetPullRequest & {
		"token": token
		repo: {
			"owner": owner
			"name":  name
		}
	}
}
Repository: #Repository @tmpNoExportNewDef(aff1)
