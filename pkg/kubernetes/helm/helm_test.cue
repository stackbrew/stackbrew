package helm

import (
	"encoding/yaml"

	"blocklayer.dev/bl"
	"blocklayer.dev/aws"
	"blocklayer.dev/aws/eks"
)

TestConfig: {
	awsConfig:      aws.#Config
	eksClusterName: string
}

TestHelmRepoChart: {
	authenticate: eks.#KubeConfig & {
		config:  TestConfig.awsConfig
		cluster: TestConfig.eksClusterName
	}

	install: #Chart & {
		name:   "stackbrew-test-helm-repository"
		chart:  "redis"
		values: yaml.Marshal({
			cluster: enabled: false
		})

		namespace:  "stackbrew-test"
		kubeconfig: authenticate.kubeconfig

		// Used to speed up tests
		atomic: false
		wait:   false
	}
}

TestHelmCustomChart: {
	authenticate: eks.#KubeConfig & {
		config:  TestConfig.awsConfig
		cluster: TestConfig.eksClusterName
	}

	install: #Chart & {
		name:  "stackbrew-test-helm-local"
		chart: bl.#Directory & {
			source: "context://testdata/mychart"
		}

		namespace:  "stackbrew-test"
		kubeconfig: authenticate.kubeconfig

		// Used to speed up tests
		atomic: false
		wait:   false
	}
}
