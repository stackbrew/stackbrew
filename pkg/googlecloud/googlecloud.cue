package googlecloud

import (
	"b.l/bl"

	"stackbrew.io/kubernetes"
)

Project :: {

	// activateUrl: string
	// action: checkActivate: {
	//
	// }

	id: string
	account: key: {
		// FIXME: google cloud service key schema
		...
	}

	GCR: {

		// A GCR container repository
		Repository: {
			name: string
			tag: [string]: bl.Directory
			unknownTags: "remove" | *"ignore" | "error"
			ref:         "gcr.io/\(name)"
		}

	}

	GKE: {

		// A GKE cluster
		Cluster: kubernetes.Cluster & {
			name:   string
			zone:   *"us-west1" | string
			create: *true | bool
		}
	}

	// TODO: Google Cloud SQL controller
	SQL: {}
}
