// Deployment infrastructure for acme clothing
package infra

import (
	"acme.infralabs.io/acme"
	"blocklayer.dev/linux"
	"blocklayer.dev/fs"
	"blocklayer.dev/netlify"
	"blocklayer.dev/bash"
	"blocklayer.dev/secret"
	"blocklayer.dev/container"

	"blocklayer.dev/website"
	"blocklayer.dev/webapp"
)

// Connector to upper layers
#App: {
	// Q. segregate per user/identity for multi-tenancy?

	env: {
		[name=string]: {
			// One app deployment as seen by the upper layer
			web: {
				source: fs.#Directory
				url: fullEnv.web.url
			}
			api: {
				source: fs.#Directory
				url: fullEnv.api.url
			}
		}
	}
}

// Connector to lower layers.
// Here we only need a linux runtime to execute tasks
// (specific cloud service integrations are statically linked)
//		Q. how to benefit from resource tracking / ID with static linking?
//			example: web domain changed; redeploy everything; how to garbage collect?
#Platform: {

	run: container.#Run

	build: container.#Build

	vault: secret.#Vault

	// Platform requirement: standard webapp deployment
	webapp.#Deployer

	// Required to decrypt API tokens
	secret.#Vault
}


#Settings: {
	webDomain: string
	apiDomain: string

	netlify: {
		token: #Platform.#Secret
		team: string | *""
	}
	
	aws: {
		region: string | *"us-east-1"
		accessKey: #Down.#Secret
		secretKey: #Down.#Secret
	}

	kubernetes: {
		auth: #Down.#Secret
	}

	db: {
		username: #Down.#Secret
		password: #Down.#Secret
	}
}


// Anything not explicitly in a connector, is private.

fullEnv: {
	for name, userConfig in #App.env {
		web: acme.#Frontend & {
			#deploy: #Platform

			hostname: "\(name).\(#Settings.webDomain)"
			source: userConfig.web.source
			netlifyAccount: {
				name: #Settings.netlify.team
				token: #Settings.netlify.token
			}
		}


		api: acme.#API & {
			hostname: "\(envName).\(#Settings.apiDomain)"
			aws: #Settings.aws
			kub: auth: #Settings.kubernetes.auth
			db: adminAuth: #Settings.db
		}
	}
}

//////// move to separate packages

pkg: acme: #Frontend: {
	site: netlify.#Site & {
		...
	}
}

pkg: netlify: #Site: {
	#run: bash.#Run
	#build: container.#Build

	contents: fs.#Directory
	name: string

	ctr: #build & {
		dockerfile: "..."
	}

	#deploy: #run & {
		fs: ctr.rootfs
		script:
		}.rootfs
		cmd: ["/entrypoint.sh"]
		input: "/app/contents": contents
		environment: {
			NETLIFY_SITE_NAME: name
		}
	}
}

pkg: secret: #Vault: {

	// Public key for this vault
	pubKey: string

	#Secret: {
		#schema: _ | *string
		encrypted: string

		"pubKey": pubKey

		#decrypt: {
			#result: #schema
		}
	}

}

pkg: acme: #Frontend: {
	source: fs.#Directory
	
}

pkg: linux: #Host: {
}
