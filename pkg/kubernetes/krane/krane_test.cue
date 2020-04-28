package krane

import (
	"b.l/bl"
	"stackbrew.io/file"
	"stackbrew.io/aws"
	"stackbrew.io/aws/eks"
)

TestConfig: {
	awsConfig:     aws.Config
    eksClusterName: string
}


TestRender: {
    kubeCfgString : #"""
        apiVersion: v1
        kind: Pod
        metadata:
            name: "kubernetes-test-<%= deployment_id %>-end"
        spec:
            restartPolicy: "Never"
            containers:
                - name: test
                  image: hello-world
        """#

    kubeCfgDirectory: file.Create & {
        filename: "/test.yaml.erb"
        contents: kubeCfgString
    }

    renderString: Render & {
        source: kubeCfgString
    }

    testString: bl.BashScript & {
        input: "/config": renderString.result
        code: #"""
        grep -q kubernetes-test- /config

        # Make sure the template was rendered
        test -z "$(grep "deployment_id" /config)"

        # Make sure that deployment_id is not empty
        test -z "$(grep "test--end" /config)"
        """#
    }

    // Render a simple config
    renderDirectory: Render & {
        source: kubeCfgDirectory.contents
    }

    testDirectory: bl.BashScript & {
        input: "/config": renderString.result
        code: #"""
        grep -q kubernetes-test- /config

        # Make sure the template was rendered
        test -z "$(grep "deployment_id" /config)"

        # Make sure that deployment_id is not empty
        test -z "$(grep "test--end" /config)"
        """#
    }
}

TestDeploy: {
	// Generate some random
	genRandom1: bl.BashScript & {
		runPolicy: "always"
		code: """
		echo -n $RANDOM > /rand
		"""
		output: "/rand": string
	}


	genRandom2: bl.BashScript & {
		runPolicy: "always"
		code: """
		echo -n $RANDOM > /rand
		"""
		output: "/rand": string
	}

	random1: genRandom1.output["/rand"]
	random2: genRandom2.output["/rand"]

    kubeCfgString : #"""
        apiVersion: v1
        kind: Pod
        metadata:
            name: "kubernetes-test-\#(random1)-end"
        spec:
            restartPolicy: "Never"
            containers:
                - name: test
                  image: hello-world
        """#

    kubeCfgDirectory: file.Create & {
        filename: "/test.yaml"
        contents : #"""
            apiVersion: v1
            kind: Pod
            metadata:
                name: "kubernetes-test-\#(random2)-end"
            spec:
                restartPolicy: "Never"
                containers:
                    - name: test
                      image: hello-world
            """#
    }

    authenticate: eks.KubeConfig & {
        config: TestConfig.awsConfig
        cluster: TestConfig.eksClusterName
    }

    deployString: Deploy & {
        kubeconfig: authenticate.kubeconfig
        namespace: "stackbrew-test"
        source: kubeCfgString
        prune: false
    }

    deployDirectory: Deploy & {
        kubeconfig: authenticate.kubeconfig
        namespace: "stackbrew-test"
        source: kubeCfgDirectory.result
        prune: false
    }
}