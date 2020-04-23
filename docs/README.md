# Stackbrew Packages

## kubernetes

#### Kustomize

Exposes `kubectl kustomize`

##### Fields

| FIELD             | SPEC                                | DOC                                  |
| -------------     |:-------------:                      |:-------------:                       |
|*source*           |``string \| bl.Directory``           |Kubernetes config to take as input    |
|*kustomization*    |``*"" \| string``                    |Optionnal kustomization.yaml          |
|*version*          |``*"v1.14.7" \| string``             |Version of kubectl client             |
|*out*              |``kustomize.output["/kube/out"]``    |Output of kustomize                   |

#### Apply

Apply a Kubernetes configuration

##### Fields

| FIELD            | SPEC                         | DOC                                 |
| -------------    |:-------------:               |:-------------:                      |
|*source*          |``string \| bl.Directory``    |Kubernetes config to deploy          |
|*version*         |``*"v1.14.7" \| string``      |Version of kubectl client            |
|*namespace*       |``string``                    |Kubernetes Namespace to deploy to    |
