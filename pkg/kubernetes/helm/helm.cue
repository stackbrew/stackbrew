package helm

import (
	"strconv"

	"blocklayer.dev/bl"
)

// Install a Helm chart
#Chart: {
	// Helm deployment name
	name: string

	// Helm chart to install
	chart: string | bl.#Directory

	// Helm chart repository (defaults to stable)
	repository: *"https://kubernetes-charts.storage.googleapis.com/" | string

	// Helm values (either a YAML string or a Cue structure)
	values?: string

	// Kubernetes Namespace to deploy to
	namespace: string

	// Helm action to apply
	action: *"installOrUpgrade" | "install" | "upgrade"

	// time to wait for any individual Kubernetes operation (like Jobs for hooks)
	timeout: string | *"5m"

	// if set, will wait until all Pods, PVCs, Services, and minimum number of
	// Pods of a Deployment, StatefulSet, or ReplicaSet are in a ready state
	// before marking the release as successful.
	// It will wait for as long as timeout
	wait: *true | bool

	// if set, installation process purges chart on fail.
	// The wait option will be set automatically if atomic is used
	atomic: *true | bool

	// Kube config file
	kubeconfig: bl.#Secret

	// Helm version
	version: string | *"3.1.2"

	run: bl.#BashScript & {
		runPolicy: "always"

		os: {
			package: curl: true

			extraCommand: [
				"curl -L https://dl.k8s.io/v1.14.7/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl",

				#"""
                curl -L -S https://get.helm.sh/helm-v\#(version)-linux-amd64.tar.gz | \
                    tar -zx -C /tmp && \
                    mv /tmp/linux-amd64/helm /usr/local/bin && \
                    chmod +x /usr/local/bin/helm
                """#,
			]
		}

		input: "/kube/config": kubeconfig
		if (values & string) != _|_ {
			input: "/helm/values.yaml": values
		}
		input: "/helm/chart": chart

		environment: {
			KUBE_NAMESPACE: namespace

			HELM_REPO:   repository
			HELM_NAME:   name
			HELM_ACTION: action

			HELM_TIMEOUT: timeout
			HELM_WAIT:    strconv.FormatBool(wait)
			HELM_ATOMIC:  strconv.FormatBool(atomic)
		}

		code: #"""
            export KUBECONFIG=/kube/config

            # Add the repository
            helm repo add repository "${HELM_REPO}"
            helm repo update

            # If the chart is a file, then it's the chart name
            # If it's a directly, then it's the contents of the cart
            if [ -f "/helm/chart" ]; then
                HELM_CHART="repository/$(cat /helm/chart)"
            else
                HELM_CHART="/helm/chart"
            fi

            OPTS=""
            OPTS="$OPTS --timeout "$HELM_TIMEOUT""
            OPTS="$OPTS --namespace "$KUBE_NAMESPACE""
            [ "$HELM_WAIT" = "true" ] && OPTS="$OPTS --wait"
            [ "$HELM_ATOMIC" = "true" ] && OPTS="$OPTS --atomic"
            [ -f "/helm/values.yaml" ] && OPTS="$OPTS -f /helm/values.yaml"

            # Select the namespace
            kubectl create namespace "$KUBE_NAMESPACE" || true

            case "$HELM_ACTION" in
                install)
                    helm install $OPTS "$HELM_NAME" "$HELM_CHART"
                ;;
                upgrade)
                    helm upgrade $OPTS "$HELM_NAME" "$HELM_CHART"
                ;;
                installOrUpgrade)
                    helm upgrade $OPTS --install "$HELM_NAME" "$HELM_CHART"
                ;;
                *)
                    echo unsupported helm action "$HELM_ACTION"
                    exit 1
                ;;
            esac
            """#
	}
}
