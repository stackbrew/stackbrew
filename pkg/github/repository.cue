package github

import (
	"blocklayer.dev/bl"
)


// FIXME: weird behavior, talk to Marcel
let tlGetPullRequest=#GetPullRequest

#Repository: {
	// Github repository name
	name: string

	// Github repository owner
	owner: string

	// Github API token
	token:           bl.#Secret
	#GetPullRequest: tlGetPullRequest & {
		"token": token
		repo: {
			"owner": owner
			"name":  name
		}
	}
}
