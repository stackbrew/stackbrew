package eks

import (
	"blocklayer.dev/bl"
	"stackbrew.io/aws"
	"stackbrew.io/kubernetes"
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
    authenticate: KubeConfig & {
        config: TestConfig.awsConfig
        cluster: TestConfig.eksClusterName
    }

    // Deploy a dummy config
    deploy: kubernetes.Apply & {
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
}
