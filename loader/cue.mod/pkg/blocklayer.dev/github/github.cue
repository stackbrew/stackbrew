package github

import (
	"blocklayer.dev/graphql"
	"blocklayer.dev/secret"
)

#Repository: {
	#ID: string

	token: secret.#Secret
	owner: string
	name: string

	#endpoint: graphql.#Endpoint & {
		header: Authorization: "Bearer \(token.#decrypt.result)"
		url: "https://api.github.com/graphql"
	}

	#listPullRequests: #endpoint.#Query & {
		#query:
			"""
			repository(owner:\(owner), name:\(name)) {
				pullRequests(states=OPEN) {
					nodes {
						number
						title
					}
				}
			}
			"""
		result: repository: pullRequests: nodes: [...#PullRequest]
	}

	pr: {
		for _, pr in #listPullRequests.result.repository.pullRequests.nodes {
			"\(pr.number)": {
				number: pr.number
				title: pr.title
			}
		}
	}
}

#PullRequest: {
	number: int
	title: string
}
