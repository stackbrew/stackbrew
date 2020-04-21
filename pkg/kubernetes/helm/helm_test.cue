package helm

import (
    "encoding/yaml"

    "b.l/bl"
	"stackbrew.io/aws"
	"stackbrew.io/aws/eks"
)

TestConfig: {
	awsConfig:     aws.Config
    eksClusterName: string
}


TestHelmRepoChart: {
    authenticate: eks.KubeConfig & {
        config: TestConfig.awsConfig
        cluster: TestConfig.eksClusterName
    }

    install: Chart & {
        name: "stackbrew-test-helm-repository"
        chart: "redis"
        values: yaml.Marshal({
            cluster: enabled: false
        })

        namespace: "stackbrew-test"
        kubeconfig: authenticate.kubeconfig

        // Used to speed up tests
        atomic: false
        wait: false
    }
}

TestHelmCustomChart: {
    authenticate: eks.KubeConfig & {
        config: TestConfig.awsConfig
        cluster: TestConfig.eksClusterName
    }

    install: Chart & {
        name: "stackbrew-test-helm-local"
        chart: bl.Directory & {
            local: "./testdata/mychart"
        }

        namespace: "stackbrew-test"
        kubeconfig: authenticate.kubeconfig

        // Used to speed up tests
        atomic: false
        wait: false
    }
}