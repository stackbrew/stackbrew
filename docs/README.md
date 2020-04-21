# Stackbrew Packages

## aws

#### Config

AWS Config shared by all AWS packages

##### Fields

| FIELD            | SPEC              | DOC               |
| -------------    |:-------------:    |:-------------:    |
|*region*          |``string``         |N/A                |

### cloudformation

#### Stack

AWS CloudFormation Stack

##### Fields

| FIELD            | SPEC                                      | DOC                                                                                |
| -------------    |:-------------:                            |:-------------:                                                                     |
|*source*          |``string``                                 |Source is the Cloudformation template, either a Cue struct or a JSON/YAML string    |
|*config*          |``aws.Config``                             |AWS Config                                                                          |
|*stackName*       |``string``                                 |Stackname is the cloudformation stack                                               |
|*parameters*      |``{ [string]: string }``                   |Stack parameters                                                                    |
|*stackOutput*     |``run.output["/outputs/stack_output"]``    |Output of the stack apply                                                           |

### ecr

#### Credentials

Credentials retriever for ECR

##### Fields

| FIELD            | SPEC                                                                                                                                                                                                                      | DOC                                        |
| -------------    |:-------------:                                                                                                                                                                                                            |:-------------:                             |
|*auth*            |``C{[]: (host: string)-\>RegistryCredentials, registry: credentials}``                                                                                                                                                     |Authentication for ECR Registries           |
|*target*          |``string``                                                                                                                                                                                                                 |Target is the ECR image                     |
|*config*          |``aws.Config``                                                                                                                                                                                                             |AWS Config                                  |
|*credentials*     |``bl.RegistryCredentials & { username: run.output["/outputs/username"] secret: bl.Secret & { // FIXME: we should be able to output a bl.Secret directly value: base64.Encode(null, run.output["/outputs/secret"]) } }``    |ECR credentials                             |
|*registry*        |``run.output["/outputs/registry"]``                                                                                                                                                                                        |ECR registry name associated with target    |
|*helperUrl*       |``"https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/0.4.0/linux-amd64/docker-credential-ecr-login"``                                                                                               |N/A                                         |

### ecs

#### Task

##### Fields

| FIELD            | SPEC                                                                                                                                                                                                                                                                            | DOC               |
| -------------    |:-------------:                                                                                                                                                                                                                                                                  |:-------------:    |
|*cpu*             |``*256 \| uint``                                                                                                                                                                                                                                                                 |N/A                |
|*memory*          |``*512 \| uint``                                                                                                                                                                                                                                                                 |N/A                |
|*networkMode*     |``*"bridge" \| string``                                                                                                                                                                                                                                                          |N/A                |
|*containers*      |``[Container, ...]``                                                                                                                                                                                                                                                             |N/A                |
|*resources*       |``{ ECSTaskDefinition: { Type: "AWS::ECS::TaskDefinition" Properties: { Cpu: strconv.FormatUint(cpu, 10) Memory: strconv.FormatUint(memory, 10) if (roleArn & string) != _\|_ { ExecutionRoleArn: roleArn } NetworkMode: networkMode ContainerDefinitions: containers } } }``    |N/A                |

#### Container

##### Fields

| FIELD            | SPEC                | DOC               |
| -------------    |:-------------:      |:-------------:    |
|*Command*         |``[string, ...]``    |N/A                |
|*Name*            |``string``           |N/A                |
|*Image*           |``string``           |N/A                |

#### Service

##### Fields

| FIELD              | SPEC                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | DOC                                           |
| -------------      |:-------------:                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |:-------------:                                |
|*resources*         |``{ ECSListenerRule: { Type: "AWS::ElasticLoadBalancingV2::ListenerRule" Properties: { ListenerArn: elbListenerArn Priority: 100 Conditions: [{ Field: "host-header" Values: [hostName] }] Actions: [{ Type: "forward" TargetGroupArn: Ref: "ECSTargetGroup" }] } } ECSTargetGroup: { Type: "AWS::ElasticLoadBalancingV2::TargetGroup" Properties: { VpcId: vpcID Port: 80 Protocol: "HTTP" } } ECSService: { Type: "AWS::ECS::Service" Properties: { Cluster: cluster DesiredCount: desiredCount LaunchType: launchType LoadBalancers: [{ TargetGroupArn: Ref: "ECSTargetGroup" ContainerName: containerName ContainerPort: containerPort }] ServiceName: serviceName TaskDefinition: Ref: "ECSTaskDefinition" DeploymentConfiguration: { MaximumPercent: 100 MinimumHealthyPercent: 50 } } DependsOn: "ECSListenerRule" } }``    |N/A                                            |
|*cluster*           |``string``                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |ECS cluster name or ARN                        |
|*containerPort*     |``int & \>=0``                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |Container port                                 |
|*containerName*     |``string``                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |Container name                                 |
|*launchType*        |``"FARGATE" \| "EC2"``                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |Service launch type                            |
|*vpcID*             |``string``                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |VPC id of the cluster                          |
|*elbListenerArn*    |``string``                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |ARN of the ELB listener                        |
|*hostName*          |``string``                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |Hostname of the publicly accessible service    |
|*serviceName*       |``string``                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |Name of the service                            |

#### SimpleECSApp

SimpleECSApp is a simplified interface for ECS

##### Fields

| FIELD              | SPEC                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | DOC               |
| -------------      |:-------------:                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |:-------------:    |
|*config*            |``aws.Config``                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |N/A                |
|*resources*         |``C{ECSTaskDefinition: C{Type: "AWS::ECS::TaskDefinition", Properties: C{Cpu: FormatUint (cpu,10), Memory: FormatUint (memory,10), NetworkMode: networkMode, ContainerDefinitions: containers if ((roleArn & string) != _\|_(from source)) yield C{ExecutionRoleArn: roleArn}}}, ECSListenerRule: C{Type: "AWS::ElasticLoadBalancingV2::ListenerRule", Properties: C{ListenerArn: elbListenerArn, Priority: 100, Conditions: [C{Field: "host-header", Values: [hostName]}], Actions: [C{Type: "forward", TargetGroupArn: C{Ref: "ECSTargetGroup"}}]}}, ECSTargetGroup: C{Type: "AWS::ElasticLoadBalancingV2::TargetGroup", Properties: C{Protocol: "HTTP", VpcId: vpcID, Port: 80}}, ECSService: C{Type: "AWS::ECS::Service", Properties: C{Cluster: cluster, DesiredCount: desiredCount, LaunchType: launchType, LoadBalancers: [C{ContainerPort: containerPort, TargetGroupArn: C{Ref: "ECSTargetGroup"}, ContainerName: containerName}], ServiceName: serviceName, TaskDefinition: C{Ref: "ECSTaskDefinition"}, DeploymentConfiguration: C{MaximumPercent: 100, MinimumHealthyPercent: 50}}, DependsOn: "ECSListenerRule"}}``    |N/A                |
|*containerPort*     |``*80 \| uint``                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |N/A                |
|*hostname*          |``string``                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |N/A                |
|*containerImage*    |``string``                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |N/A                |
|*infra*             |``{ cluster: string vpcID: string elbListenerArn: string }``                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |N/A                |
|*subDomain*         |``strings.Split(hostname, ".")[0]``                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |N/A                |
|*out*               |``cfn.stackOutput``                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |N/A                |
|*cfn*               |``cloudformation.Stack & { config: inputConfig source: json.Marshal({ AWSTemplateFormatVersion: "2010-09-09" Description: "ECS App deployed with Blocklayer" Resources: resources }) stackName: "bl-ecs-\(subDomain)" }``                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |N/A                |

### eks

#### KubeConfig

KubeConfig config outputs a valid kube-auth-config for kubectl client

##### Fields

| FIELD            | SPEC              | DOC                |
| -------------    |:-------------:    |:-------------:     |
|*config*          |``aws.Config``     |AWS Config          |
|*cluster*         |``string``         |EKS cluster name    |

### elasticbeanstalk

#### Application

Elastic Beanstalk Application

##### Fields

| FIELD               | SPEC                             | DOC                          |
| -------------       |:-------------:                   |:-------------:               |
|*config*             |``aws.Config``                    |AWS Config                    |
|*applicationName*    |``string``                        |Beanstalk application name    |
|*out*                |``run.output["/outputs/out"]``    |N/A                           |

#### Environment

Elastic Beanstalk Environment

##### Fields

| FIELD               | SPEC                                                                                                                                                            | DOC                                                    |
| -------------       |:-------------:                                                                                                                                                  |:-------------:                                         |
|*platform*           |``string``                                                                                                                                                       |Elastic Beanstalk platform to use                       |
|*source*             |``bl.Directory``                                                                                                                                                 |Source code to deploy                                   |
|*config*             |``aws.Config``                                                                                                                                                   |AWS Config                                              |
|*applicationName*    |``string``                                                                                                                                                       |Application name                                        |
|*out*                |``run.output["/outputs/out"]``                                                                                                                                   |N/A                                                     |
|*environmentName*    |``string``                                                                                                                                                       |Beanstalk environment name                              |
|*createOptions*      |``{ cname?: string tier?: string instance_type?: string instance_profile?: string service_role?: string keyname?: string scale?: string elb_type?: string }``    |Environment create options; check `eb create --help`    |
|*cname*              |``run.output["/outputs/cname"]``                                                                                                                                 |N/A                                                     |

#### Deployment

Elastic Beanstalk Deployment

##### Fields

| FIELD               | SPEC                               | DOC                          |
| -------------       |:-------------:                     |:-------------:               |
|*source*             |``bl.Directory``                    |Source code to deploy         |
|*config*             |``aws.Config``                      |AWS Config                    |
|*applicationName*    |``string``                          |Application name              |
|*environmentName*    |``string``                          |Beanstalk environment name    |
|*cname*              |``run.output["/outputs/cname"]``    |N/A                           |

### s3

#### Put

S3 file or Directory upload

##### Fields

| FIELD            | SPEC                             | DOC                                                              |
| -------------    |:-------------:                   |:-------------:                                                   |
|*url*             |``run.output["/outputs/url"]``    |URL of the uploaded S3 object                                     |
|*source*          |``string \| bl.Directory``        |Source Directory, File or String to Upload to S3                  |
|*target*          |``string``                        |Target S3 URL (eg. s3://\<bucket-name\>/\<path\>/\<sub-path\>)    |
|*config*          |``aws.Config``                    |AWS Config                                                        |

## dockerhub

#### Credentials

Credentials retriever for Docker Hub

##### Fields

| FIELD            | SPEC                                                                                          | DOC                              |
| -------------    |:-------------:                                                                                |:-------------:                   |
|*auth*            |``C{[]: (host: string)-\>RegistryCredentials, "https://index.docker.io/v1/": credentials}``    |Authentication for Docker Hub     |
|*target*          |``string``                                                                                     |Target is the Docker Hub image    |
|*config*          |``{ username: string password: bl.Secret }``                                                   |Docker Hub Config                 |
|*credentials*     |``bl.RegistryCredentials & { username: config.username secret: config.password }``             |Registry Credentials              |

### nodejs

#### Container

##### Fields

| FIELD            | SPEC                       | DOC               |
| -------------    |:-------------:             |:-------------:    |
|*image*           |``bl.Directory``            |N/A                |
|*environment*     |``{ [string]: string }``    |N/A                |
|*source*          |``bl.Directory``            |N/A                |
|*buildScript*     |``string``                  |N/A                |
|*runScript*       |``string``                  |N/A                |

## file

#### Read

Read reads the contents of a file.

##### Fields

| FIELD            | SPEC                           | DOC                                |
| -------------    |:-------------:                 |:-------------:                     |
|*filename*        |``!=""``                        |filename names the file to read.    |
|*contents*        |``script.output["/output"]``    |contents is the read contents.      |
|*source*          |``bl.Directory``                |source directory                    |

#### Create

Create writes contents to the given file.

##### Fields

| FIELD            | SPEC                           | DOC                                                                          |
| -------------    |:-------------:                 |:-------------:                                                               |
|*filename*        |``!=""``                        |filename names the file to write.                                             |
|*contents*        |``bytes \| string``             |contents specifies the bytes to be written.                                   |
|*permissions*     |``int \| *0o644``               |permissions defines the permissions to use if the file does not yet exist.    |
|*result*          |``script.output["/result"]``    |result directory                                                              |

#### Append

Append writes contents to the given file.

##### Fields

| FIELD            | SPEC                           | DOC                                                                          |
| -------------    |:-------------:                 |:-------------:                                                               |
|*filename*        |``!=""``                        |filename names the file to append.                                            |
|*contents*        |``bytes \| string``             |contents specifies the bytes to be written.                                   |
|*permissions*     |``int \| *0o644``               |permissions defines the permissions to use if the file does not yet exist.    |
|*source*          |``bl.Directory``                |source directory                                                              |
|*result*          |``script.output["/result"]``    |result directory                                                              |

#### Glob

Glob returns a list of files.

##### Fields

| FIELD            | SPEC                                                                                                                     | DOC                                               |
| -------------    |:-------------:                                                                                                           |:-------------:                                    |
|*glob*            |``!=""``                                                                                                                  |glob specifies the pattern to match files with.    |
|*files*           |``_\|_(cannot use string (type string) as bytes in argument 0 to encoding/json.Unmarshal: non-concrete value string)``    |files that matched                                 |
|*source*          |``bl.Directory``                                                                                                          |source directory                                   |

## git

#### Repository

Git repository

##### Fields

| FIELD            | SPEC                                                                 | DOC                                        |
| -------------    |:-------------:                                                       |:-------------:                             |
|*url*             |``string``                                                            |URL of the Repository                       |
|*ref*             |``*"master" \| string``                                               |Git Ref to checkout                         |
|*keepGitDir*      |``*false \| bool``                                                    |Keep .git directory after clone             |
|*out*             |``clone.output["/outputs/out"]``                                      |Output directory of the `git clone`         |
|*commit*          |``strings.TrimRight(clone.output["/outputs/commit"], "\n")``          |Output commit ID of the Repository          |
|*shortCommit*     |``strings.TrimRight(clone.output["/outputs/short-commit"], "\n")``    |Output short-commit ID of the Repository    |

#### PathCommit

Retrieve commit IDs from a git working copy (ie. cloned repository)

##### Fields

| FIELD            | SPEC                                                                      | DOC                                             |
| -------------    |:-------------:                                                            |:-------------:                                  |
|*path*            |``*"./" \| string``                                                        |Optional path to retrieve git commit IDs from    |
|*from*            |``bl.Directory``                                                           |Source Directory (git working copy)              |
|*commit*          |``strings.TrimRight(pathCommit.output["/outputs/commit"], "\n")``          |Output commit ID of the Repository               |
|*shortCommit*     |``strings.TrimRight(pathCommit.output["/outputs/short-commit"], "\n")``    |Output short-commit ID of the Repository         |

## github

#### Repository

##### Fields

| FIELD            | SPEC                                                                                                                                                                                                     | DOC               |
| -------------    |:-------------:                                                                                                                                                                                           |:-------------:    |
|*name*            |``string``                                                                                                                                                                                                |N/A                |
|*owner*           |``string``                                                                                                                                                                                                |N/A                |
|*pr*              |``{ [prId=string]: { id: prId status: "open" \| "closed" comments: [commentId=string]: { author: string text: string } branch: { name: string tip: { commitId: string checkout: bl.Directory } } } }``    |N/A                |

## go

#### App

Go application built with `go build`

##### Fields

| FIELD            | SPEC                                          | DOC                                 |
| -------------    |:-------------:                                |:-------------:                      |
|*os*              |``*"linux" \| string``                         |Target OS                            |
|*source*          |``bl.Directory``                               |Source Directory to build            |
|*version*         |``*"1.14.1" \| string``                        |Go version to use                    |
|*generate*        |``*false \| true``                             |Run `go generate` before building    |
|*arch*            |``*"amd64" \| string``                         |Target architecture                  |
|*tags*            |``*"netgo" \| string``                         |Build tags to use for building       |
|*ldflags*         |``*"-w -extldflags \"-static\"" \| string``    |LDFLAGS to use for linking           |
|*binaryName*      |``"app"``                                      |Specify the targeted binary name     |

## googlecloud

#### Config

Google Cloud Config shared by all packages

##### Fields

| FIELD            | SPEC              | DOC               |
| -------------    |:-------------:    |:-------------:    |
|*region*          |``string``         |N/A                |
|*project*         |``string``         |N/A                |

### gcr

#### Credentials

Credentials retriever for GCR

##### Fields

| FIELD            | SPEC                                                                                                                                                                                                                           | DOC                                                                                                                                                                                             |
| -------------    |:-------------:                                                                                                                                                                                                                 |:-------------:                                                                                                                                                                                  |
|*auth*            |``C{[]: (host: string)-\>RegistryCredentials, "gcr.io": credentials, "asia.gcr.io": credentials, "eu.gcr.io": credentials, "marketplace.gcr.io": credentials, "staging-k8s.gcr.io": credentials, "us.gcr.io": credentials}``    |Authentication for GCR Registries This list is hardcoded from: https://github.com/GoogleCloudPlatform/docker-credential-gcr/blob/be7633a109f04f19953c4d830ec5788709c16df4/config/const.go#L50    |
|*target*          |``string``                                                                                                                                                                                                                      |Target is the GCR image                                                                                                                                                                          |
|*config*          |``googlecloud.Config``                                                                                                                                                                                                          |GCP Config                                                                                                                                                                                       |
|*credentials*     |``bl.RegistryCredentials & { username: run.output["/outputs/username"] secret: bl.Secret & { // FIXME: we should be able to output a bl.Secret directly value: base64.Encode(null, run.output["/outputs/secret"]) } }``         |Registry Credentials                                                                                                                                                                             |
|*helperUrl*       |``"https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v2.0.1/docker-credential-gcr_linux_amd64-2.0.1.tar.gz"``                                                                                      |N/A                                                                                                                                                                                              |

### gke

#### KubeConfig

KubeConfig config outputs a valid kube-auth-config for kubectl client

##### Fields

| FIELD            | SPEC                     | DOC                |
| -------------    |:-------------:           |:-------------:     |
|*config*          |``googlecloud.Config``    |GCP Config          |
|*cluster*         |``string``                |GKE cluster name    |

## helm

#### Chart

Install a Helm chart

##### Fields

| FIELD            | SPEC                                                                 | DOC                                                                                                                                                                                                                           |
| -------------    |:-------------:                                                       |:-------------:                                                                                                                                                                                                                |
|*name*            |``string``                                                            |Helm deployment name                                                                                                                                                                                                           |
|*chart*           |``string \| bl.Directory``                                            |Helm chart to install                                                                                                                                                                                                          |
|*repository*      |``*"https://kubernetes-charts.storage.googleapis.com/" \| string``    |Helm chart repository (defaults to stable)                                                                                                                                                                                     |
|*namespace*       |``string``                                                            |Kubernetes Namespace to deploy to                                                                                                                                                                                              |
|*action*          |``*"installOrUpgrade" \| "install" \| "upgrade"``                     |Helm action to apply                                                                                                                                                                                                           |
|*timeout*         |``string \| *"5m"``                                                   |time to wait for any individual Kubernetes operation (like Jobs for hooks)                                                                                                                                                     |
|*wait*            |``*true \| bool``                                                     |if set, will wait until all Pods, PVCs, Services, and minimum number of Pods of a Deployment, StatefulSet, or ReplicaSet are in a ready state before marking the release as successful. It will wait for as long as timeout    |
|*atomic*          |``*true \| bool``                                                     |if set, installation process purges chart on fail. The wait option will be set automatically if atomic is used                                                                                                                 |
|*version*         |``string \| *"3.1.2"``                                                |Helm version                                                                                                                                                                                                                   |

## krane

#### Render

Render a Krane template

##### Fields

| FIELD            | SPEC                              | DOC                           |
| -------------    |:-------------:                    |:-------------:                |
|*source*          |``string \| bl.Directory``         |Kubernetes config to render    |
|*version*         |``string \| *"1.1.2"``             |Krane version                  |
|*result*          |``run.output["/krane/result"]``    |Rendered config                |

#### Deploy

Deploy a Kubernetes configuration using Krane

##### Fields

| FIELD            | SPEC                         | DOC                                                                  |
| -------------    |:-------------:               |:-------------:                                                       |
|*source*          |``string \| bl.Directory``    |Kubernetes config to deploy                                           |
|*version*         |``string \| *"1.1.2"``        |Krane version                                                         |
|*namespace*       |``string``                    |Kubernetes Namespace to deploy to                                     |
|*prune*           |``bool \| *true``             |Prune resources that are no longer in your Kubernetes template set    |

## kubernetes

#### Kustomize

Exposes `kubectl kustomize`

##### Fields

| FIELD            | SPEC                                | DOC                                  |
| -------------    |:-------------:                      |:-------------:                       |
|*source*          |``string \| bl.Directory``           |Kubernetes config to take as input    |
|*version*         |``*"v1.14.7" \| string``             |Version of kubectl client             |
|*out*             |``kustomize.output["/kube/out"]``    |Output of kustomize                   |

#### Apply

Apply a Kubernetes configuration

##### Fields

| FIELD            | SPEC                         | DOC                                 |
| -------------    |:-------------:               |:-------------:                      |
|*source*          |``string \| bl.Directory``    |Kubernetes config to deploy          |
|*version*         |``*"v1.14.7" \| string``      |Version of kubectl client            |
|*namespace*       |``string``                    |Kubernetes Namespace to deploy to    |

## mysql

#### Database

##### Fields

| FIELD            | SPEC                | DOC               |
| -------------    |:-------------:      |:-------------:    |
|*name*            |``string``           |N/A                |
|*create*          |``*true \| bool``    |N/A                |
|*server*          |``Server``           |N/A                |

#### Server

##### Fields

| FIELD             | SPEC               | DOC               |
| -------------     |:-------------:     |:-------------:    |
|*host*             |``string``          |N/A                |
|*port*             |``*3306 \| int``    |N/A                |
|*adminUser*        |``string``          |N/A                |
|*adminPassword*    |``string``          |N/A                |

## netlify

#### Account

A Netlify account

##### Fields

| FIELD            | SPEC                | DOC                                                                              |
| -------------    |:-------------:      |:-------------:                                                                   |
|*name*            |``string \| *""``    |Use this Netlify account name (also referred to as "team" in the Netlify docs)    |

#### Site

A Netlify site

##### Fields

| FIELD            | SPEC                                                      | DOC                                            |
| -------------    |:-------------:                                            |:-------------:                                 |
|*name*            |``string``                                                 |Deploy to this Netlify site                     |
|*contents*        |``bl.Directory``                                           |Contents of the application to deploy           |
|*url*             |``strings.TrimRight(deploy.output["/info/url"], "\n")``    |Deployment url                                  |
|*account*         |``Account``                                                |Netlify account this site is attached to        |
|*domain*          |``string``                                                 |Host the site at this address                   |
|*create*          |``bool \| *true``                                          |Create the Netlify site if it doesn't exist?    |

## yarn

#### App

A javascript application built by Yarn

##### Fields

| FIELD              | SPEC                                    | DOC                                                                                   |
| -------------      |:-------------:                          |:-------------:                                                                        |
|*build*             |``action.build.output["/app/build"]``    |Output of yarn build                                                                   |
|*environment*       |``{ [string]: string }``                 |Set these environment variables during the build                                       |
|*source*            |``bl.Directory``                         |Source code of the javascript application                                              |
|*loadEnv*           |``bool \| *true``                        |Load the contents of `environment` into the yarn process?                              |
|*yarnScript*        |``string \| *"build"``                   |Run this yarn script                                                                   |
|*writeEnvFile*      |``string \| *""``                        |Write the contents of `environment` to this file, in the "envfile" format.             |
|*buildDirectory*    |``string \| *"build"``                   |Read build output from this directory (path must be relative to working directory).    |

## zip

#### Archive

Zip archive

##### Fields

| FIELD            | SPEC                                                        | DOC                                            |
| -------------    |:-------------:                                              |:-------------:                                 |
|*source*          |``bl.Directory \| string``                                   |Source Directory, File or String to Zip from    |
|*archive*         |``{ from: run.output["/outputs/out"] path: "file.zip" }``    |Archive file output                             |
