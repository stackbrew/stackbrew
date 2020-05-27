// -> Netlify setup
// -> Github setup
// -> S3 setup
package infra

import (
	"blocklayer.dev/github"
	"blocklayer.dev/unix"
)

// Note: capitalized definitions are standardized actions reserved by Blocklayer.
// lowercase definitions are configuration-specific.

// Build this configuration from source
// 	Q. how to update dependencies?
#Build: {

}

// Host capabilities required to run this configuration
// All side effects go here.

#Up: {
	
}

#Down: {
	monorepo: github.#Repository & {
		owner: #Settings.monorepo.owner
		name: #Settings.monorepo.name
		
		subscribe: {
			pullRequest: true
		}
	}
}

// Control panel for this configuration. Accessible only to config admin.
#Control: {
	monorepo: {
		owner: string
		name: string
	}
}	

// Synchronize: fetch all inputs, re-compute all outputs
#Sync: {

	

}

monorepo: github.#Repository & {
	owner: "blocklayerhq"
	name: "acme-clothing"
}

frontend: {
	ntlfy: netlify.#Site
	S:
}
