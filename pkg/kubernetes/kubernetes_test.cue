package kubernetes

import (
	"blocklayer.dev/bl"
    "encoding/yaml"
	"stackbrew.io/aws"
	"stackbrew.io/aws/eks"
)

TestConfig: {
	awsConfig:     aws.Config
    eksClusterName: string
}

TestEKS: {
	// Generate some random
	genRandom: bl.BashScript & {
		runPolicy: "always"
		code: """
		echo -n $RANDOM > /rand
		"""
		output: "/rand": string
	}

	random: genRandom.output["/rand"]

    // Authenticate against EKS
    authenticate: eks.KubeConfig & {
        config: TestConfig.awsConfig
        cluster: TestConfig.eksClusterName
    }

    // Deploy a dummy inline config
    deployString: Apply & {
        kubeconfig: authenticate.kubeconfig
        namespace: "stackbrew-test"
        source: #"""
            apiVersion: v1
            kind: Pod
            metadata:
                name: "kubernetes-test-\#(random)"
            spec:
                restartPolicy: "Never"
                containers:
                    - name: test
                      image: hello-world
            """#
    }

    deployDirectory: Apply & {
        kubeconfig: authenticate.kubeconfig
        namespace: "stackbrew-test"
        source: bl.Directory & {
            source: "context://testdata"
        }
    }
}

TestKustomize: {
    kubeConfig: Kustomize & {
        source: bl.Directory & {
            source: "context://testdata"
        }
        kustomization: yaml.Marshal({
            resources: ["test.yaml"]
            images: [{
                name: "hello-world"
                newTag: "linux"
            }]
        })
    }

    changeImageName: bl.BashScript & {
		runPolicy: "always"

        input: "/kube/config.yaml": kubeConfig.out

		code: """
        grep hello-world:linux /kube/config.yaml
        """
	}
}
