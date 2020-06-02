// Deployment infrastructure for acme clothing
package infra

// Platform connector: how to use this environment as a platform for other environments
#Tenant: {
	env: [ID=string]: {
		shortname: string
		web: {
			source: fs.#Directory
			url: deploy.web[shortname].url
		}
		api: {
			source: fs.#Directory
			url: deploy.api[shortname].url
		}
	}

	#Settings: {
		// Human-friendly name for this deployment
		appName: string
	
		// Path to WEB frontend source code (relative to context)
		webPath: string | *"./crate/code/web"
	
		// Path to API source code (relative to context)
		apiPath: string | *"./crate/code/api"
	}
}

#Settings: {
	webDomain: string
	apiDomain: string

	netlify: {
		token: secret.#Secret
		team: string | *""
	}
	
	aws: {
		region: string | *"us-east-1"
		accessKey: secret.#Secret
		secretKey: secret.#Secret
	}

	kubernetes: {
		auth: secret.#Secret
	}

	db: {
		username: secret.#Secret
		password: secret.#Secret
	}
}

deploy: {
	for id, env in #Platform.env {
		web: "\(env.shortname)": acme.#Frontend & {
			hostname: "\(env.shortname).\(#Settings.webDomain)"
			source: env.web.source
			netlifyAccount: {
				name: #Settings.netlify.team
				token: #Settings.netlify.token
			}
		}
		api: "\(env.shortname)": acme.#API & {
			hostname: "\(env.shortname).\(#Settings.apiDomain)"
			aws: #Settings.aws
			kub: auth: #Settings.kubernetes.auth
			db: adminAuth: #Settings.db
		}
	}
}

sharedAPI: acme.#API & {
			hostname: "staging.\(#Settings.apiDomain)"
			aws: #Settings.aws
			kub: auth: #Settings.kubernetes.auth
			db: adminAuth: #Settings.db
		}
