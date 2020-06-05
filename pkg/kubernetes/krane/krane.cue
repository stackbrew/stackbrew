package krane

import (
	"blocklayer.dev/bl"
)

// Render a Krane template
Render :: {
	// Kubernetes config to render
	source: string | bl.Directory

	// Krane version
	version: string | *"1.1.2"

	// Rendered config
	result: run.output["/krane/result"]

	run: bl.BashScript & {
		runPolicy: "always"

		os: {
			package: curl: true

			extraCommand: [
				"curl -L https://dl.k8s.io/v1.14.7/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl",

				#"""
                apk add ruby ruby-dev g++ make \
                    && gem install krane --version \#(version) --no-document \
                    && gem install bigdecimal --no-document \
                    && apk del ruby-dev g++ make
                """#,
			]
		}

		input: "/kube/source/template.yaml.erb": source
		output: "/krane/result":                 string

		code: #"""
            # TASK_ID will be used for "<%= deployment_id %>"
            export TASK_ID="$RANDOM"

            krane render -f /kube/source > /krane/result
        """#
	}
}

// Deploy a Kubernetes configuration using Krane
Deploy :: {
	// Kubernetes config to deploy
	source: string | bl.Directory

	// Kubernetes Namespace to deploy to
	namespace: string

	// Kube config file
	kubeconfig: bl.Secret

	// Krane version
	version: string | *"1.1.2"

	// Prune resources that are no longer in your Kubernetes template set
	prune: bool | *true

	deploy: bl.BashScript & {
		runPolicy: "always"

		os: {
			package: curl: true

			extraCommand: [
				"curl -L https://dl.k8s.io/v1.14.7/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl",

				#"""
                apk add ruby ruby-dev g++ make \
                    && gem install krane --version \#(version) --no-document \
                    && gem install bigdecimal --no-document \
                    && apk del ruby-dev g++ make
                """#,
			]
		}

		input: {
			"/kube/source.yaml": source
			"/kube/config":      kubeconfig
		}

		environment: KUBE_NAMESPACE: namespace
		if !prune {
			environment: KRANE_NO_PRUNE: "true"
		}
		code: #"""
            export KUBECONFIG=/kube/config

            OPTS=""
            [ "$KRANE_NO_PRUNE" = "true" ] && OPTS="$OPTS --no-prune"

            kubectl create namespace "$KUBE_NAMESPACE" || true
            krane deploy \
                "$KUBE_NAMESPACE" "$(kubectl config current-context)" \
                -f /kube/source.yaml \
                $OPTS
        """#
	}
}
