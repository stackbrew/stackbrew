package gke

import (
	"b.l/bl"
	"stackbrew.io/googlecloud"
	"stackbrew.io/kubernetes"
)

TestConfig: {
	gcpConfig:     googlecloud.Config
    gkeClusterName: string
}

TestGKE: {
	// Generate some random
	genRandom: bl.BashScript & {
		runPolicy: "always"
		code: """
		echo -n $RANDOM > /rand
		"""
		output: "/rand": string
	}

	random: genRandom.output["/rand"]

    // Authenticate against GKE
    authenticate: KubeConfig & {
        config: TestConfig.gcpConfig
        cluster: TestConfig.gkeClusterName
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