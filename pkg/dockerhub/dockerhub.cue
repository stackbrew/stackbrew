package dockerhub

import (
	"blocklayer.dev/bl"
)

// Credentials retriever for Docker Hub
#Credentials: {

	// Docker Hub Config
	config: {
		username: string
		password: bl.Secret
	}

	// Target is the Docker Hub image
	target: string

	// Registry Credentials
	credentials: bl.RegistryCredentials & {
		username: config.username
		secret:   config.password
	}

	// Authentication for Docker Hub
	auth: bl.RegistryAuth
	auth: "https://index.docker.io/v1/": credentials
}
