package github

import (
	"blocklayer.dev/bl"
	"encoding/json"
	"strings"
)

#CommentFields: {
	id:   string
	body: string
}

// Possible references to this location:
// github/comment.cue:43:11
// github/comment.cue:70:11
// github/comment.cue:104:15
#CommentFragment: """
    fragment CommentParts on IssueComment {
        id
        body
    }
    """

// Possible references to this location:
// github/comment.cue:125:16
#AddComment: {
	subjectId: string
	body:      string

	data:    _

	comment: #CommentFields
	comment: data.addComment.commentEdge.node

	#Query & {
		query: """
        mutation ($input: AddCommentInput!) {
            addComment(input: $input) {
                subject {
                    id
                }
                commentEdge {
                    node {
                        ...CommentParts
                    }
                }
            }
        }
        \(#CommentFragment)
        """

		variable: input: {
			"subjectId": subjectId
			"body":      body
		}
	}
}

// Possible references to this location:
// github/comment.cue:115:16
#UpdateComment: {
	commentId: string
	body:      string

	data:    _

	comment: #CommentFields
	comment: data.updateIssueComment.issueComment

	#Query & {
		query: """
        mutation ($input: UpdateIssueCommentInput!) {
            updateIssueComment(input: $input) {
                issueComment {
                    ...CommentParts
                }
            }
        }
        \(#CommentFragment)
        """

		variable: input: {
			id:     commentId
			"body": body
		}
	}
}


#Comment: {
	subjectId: string
	marker:    *"<!-- bl-marker-do-not-remove -->" | string
	token:     bl.Secret
	body:      string

	listComments: #Query & {
		"token": token

		query:
			"""
            query($nodeId: ID!) {
                node(id: $nodeId) {
                    ...PullRequestParts
                }
            }
            fragment PullRequestParts on PullRequest {
                id
                comments(first: 100) {
                    nodes {
                        ...CommentParts
                    }
                }
            }
            \(#CommentFragment)
            """
		variable: {
			nodeId: subjectId
		}
	}

	// Contains a list of comment ID matching the marker
	commentId: [ for n in listComments.data.node.comments.nodes if strings.Contains(n.body, "\(marker)") {n.id}]

	updateCommentQuery: json.Marshal({
		query: #UpdateComment.query
		variables: input: {
			if len(commentId) > 0 {
				id: commentId[0]
			}
			"body": "\(body)\n\(marker)"
		}
	})

	addCommentQuery: json.Marshal({
		query: #AddComment.query
		variables: input: {
			"subjectId": subjectId
			"body":      "\(body)\n\(marker)"
		}
	})

	editComment: bl.BashScript & {
		os: package: curl: true
		input: {
			"/token": token
			if len(commentId) > 0 {
				"/updateComment": commentId[0]
			}
			"/addCommentQuery":    addCommentQuery
			"/updateCommentQuery": updateCommentQuery
			"/commentsData":       listComments.response.body
		}
		output: {
			"/response": string
			"/status":   string
		}
		code:
			#"""
            curlArgs=(
                https://api.github.com/graphql
                -L --fail --silent --show-error
                --write-out "%{http_code}"
                -H "Authorization: bearer $(cat /token)"
                -H "Content-Type: application/json"
                -X POST
                -o /response
            )

            if [ -e /updateComment ]; then
                curlArgs+=("-d" "$(cat /updateCommentQuery)")
            else
                curlArgs+=("-d" "$(cat /addCommentQuery)")
            fi

            curl "${curlArgs[@]}" > /status
            """#
	}

	response: editComment.output["/response"]
	status:   editComment.output["/status"]
}
