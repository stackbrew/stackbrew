package dockerhub

import (
    "stackbrew.io/container"
    "stackbrew.io/secret"
)

// Credentials retriever for Docker Hub
Credentials :: {

	// Docker Hub Config
	config: {
		username: string
		password: secret.Secret
	}

	// Target is the Docker Hub image
	target: string

	// Registry Credentials
	credentials: container.RegistryCredentials & {
		username: config.username
		secret:   config.password
	}

	// Authentication for Docker Hub
	auth: container.RegistryAuth
	auth: "https://index.docker.io/v1/": credentials
}
