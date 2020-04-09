package gke

import (
	"b.l/bl"
	"stackbrew.io/googlecloud"
)

TestConfig: {
	gcpConfig:     googlecloud.Config
    gkeClusterName: string
}

TestAuthConfig: {
    authenticate: AuthConfig & {
        config: TestConfig.gcpConfig
        gkeClusterName: TestConfig.gkeClusterName
    }

    test: bl.BashScript & {
        input: "/auth": authenticate.out
        code: """
        test -n /auth
        """
    }
}

TestDeployment: {
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
    authenticate: AuthConfig & {
        config: TestConfig.gcpConfig
        gkeClusterName: TestConfig.gkeClusterName
    }

    // Deploy a dummy config
    deploy: Deployment & {
        config: TestConfig.gcpConfig
        kubeAuthConfig: authenticate.out
        namespace: "stackbrew-test"
        kubeConfigYAML: #"""
            apiVersion: v1
            kind: Pod
            metadata:
                name: "kubernetes-test-\#(random)"
            spec:
                containers:
                    - name: test
                      image: hello-world
            """#
    }
}