package dockerhub

import (
	"b.l/bl"
)

TestConfig : {
	dockerHubConfig:     Credentials.config
	dockerHubRepository: string
}

TestDockerHub: {
	// Generate some random
	random: bl.BashScript & {
		runPolicy: "always"
		code: """
		echo -n $RANDOM > /rand
		"""
		output: "/rand": string
	}

	rand: random.output["/rand"]

	// Target GCR image for our tests (with a random tag)
	image: "\(TestConfig.dockerHubRepository):test-dh-\(rand)"

	// Build a test image
	build: bl.Build & {
		dockerfile: #"""
			FROM alpine:latest@sha256:ab00606a42621fb68f2ed6ad3c88be54397f981a7b70a79db3d1172b11c4367d
			RUN echo "\#(rand)" > /test
			"""#
	}

	// Get the GCR credentials
	login: Credentials & {
		config: TestConfig.dockerHubConfig
		target: image
	}

	// Push the image
	export: bl.Push & {
		source:      build.image
		target:      image
		auth:        login.auth
	}

	// Pull the image and verify
	test: bl.Build & {
		dockerfile:  #"""
			FROM \#(image)
			# create a dependency between this task and export
			RUN echo \#(export.ref)
			RUN cat /test
			RUN test "$(cat /test)" = "\#(rand)"
		"""#
		auth: login.auth
	}
}
