package eks

import (
	"b.l/bl"
	"stackbrew.io/aws"
)

TestConfig: {
	awsConfig:     aws.Config
    eksClusterName: string
}

TestAuthConfig: {
    authenticate: AuthConfig & {
        config: TestConfig.awsConfig
        eksClusterName: TestConfig.eksClusterName
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

    // Authenticate against EKS
    authenticate: AuthConfig & {
        config: TestConfig.awsConfig
        eksClusterName: TestConfig.eksClusterName
    }

    // Deploy a dummy config
    deploy: Deployment & {
        config: TestConfig.awsConfig
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