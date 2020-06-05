package github

// GitHub Event
// https://developer.github.com/v3/activity/events
Event :: {
	name: string

	sender: {...}
	repository?: {...}
	organization?: {...}

	// FIXME: handle other events
	{
		name: "pull_request"
		PullRequestEvent
	}
}

// PullRequestEvent
// https://developer.github.com/v3/activity/events/types/#pullrequestevent
PullRequestEvent :: {
	action:
		"assigned" |
		"unassigned" |
		"review_requested" |
		"review_request_removed" |
		"labeled" |
		"unlabeled" |
		"opened" |
		"edited" |
		"closed" |
		"ready_for_review" |
		"locked" |
		"unlocked" |
		"reopened" |
		"synchronize"

	after?:  string
	before?: string

	// The pull request number.
	number: int

	// The changes to the comment if the action was edited.
	changes: {...}

	// The previous version of the title if the action was edited.
	"changes[title][from]"?: string

	// The previous version of the body if the action was edited.
	"changes[body][from]"?: string

	// The pull request itself.
	pull_request: {...}
}
