package kubernetes

import (
	"b.l/bl"
)

App :: {
	cluster:          Cluster
	namespace:        string
	config:           Configuration
	unknownResources: "error" | "ignore" | "remove"
}

// TODO: portable kubernetes cluster interface
Cluster :: {
	namespace: [ns=string]: config: Configuration
	...
}

// FIXME: native kubernetes config schema
Configuration :: {
	deployment: [string]: spec:   _
	ingress: [string]: spec:      _
	secret: [string]: stringData: _
}

YamlDirectory :: {
	config: Configuration
	dir:    bl.Directory
}
