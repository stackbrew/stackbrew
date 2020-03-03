package github

import (
	"b.l/bl"
)

Repository :: {
	token: bl.Secret & {value: string}
	name:  string
	owner: string

	pr: [prId=string]: {
		id:     prId
		status: "open" | "closed"
		comments: [commentId=string]: {
			author: string
			text:   string
		}
		branch: {
			name: string
			tip: {
				commitId: string
				checkout: bl.Directory
			}
		}
	}
}
