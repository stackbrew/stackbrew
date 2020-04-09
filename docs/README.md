# Packages

## aws

### Config

AWS Config shared by all AWS packages

#### Fields

| FIELD            | SPEC              | DOC               |
| -------------    |:-------------:    |:-------------:    |
|*region*          |``string``         |N/A                |

## cloudformation

### Stack

AWS CloudFormation Stack

#### Fields

| FIELD            | SPEC                                      | DOC                                     |
| -------------    |:-------------:                            |:-------------:                          |
|*source*          |``{...}``                                  |N/A                                      |
|*config*          |``aws.Config``                             |AWS Config                               |
|*sourceRaw*       |``"{}"``                                   |N/A                                      |
|*stackName*       |``string``                                 |Stackname is the cloudformation stack    |
|*parameters*      |``{ [string]: string }``                   |Stack parameters                         |
|*stackOutput*     |``run.output["/outputs/stack_output"]``    |Output of the stack apply                |

## ecr

### Credentials

Credentials retriever for ECR

#### Fields

| FIELD            | SPEC                                                                                                                                                                                                                      | DOC                             |
| -------------    |:-------------:                                                                                                                                                                                                            |:-------------:                  |
|*credentials*     |``bl.RegistryCredentials & { username: run.output["/outputs/username"] secret: bl.Secret & { // FIXME: we should be able to output a bl.Secret directly value: base64.Encode(null, run.output["/outputs/secret"]) } }``    |URL of the uploaded S3 object    |
|*target*          |``string``                                                                                                                                                                                                                 |Target is the ECR image          |
|*config*          |``aws.Config``                                                                                                                                                                                                             |AWS Config                       |
|*helperUrl*       |``"https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/0.4.0/linux-amd64/docker-credential-ecr-login"``                                                                                               |N/A                              |

## eks

### AuthConfig

AuthConfig config outputs a valid kube-auth-config for kubectl client

#### Fields

| FIELD              | SPEC                              | DOC                |
| -------------      |:-------------:                    |:-------------:     |
|*config*            |``aws.Config``                     |AWS Config          |
|*eksClusterName*    |``string``                         |EKS cluster name    |
|*out*               |``run.output["/outputs/auth"]``    |N/A                 |

### Deployment

Deployment of a kubernetes configuration on an AWS EKS cluster

#### Fields

| FIELD              | SPEC                       | DOC                                 |
| -------------      |:-------------:             |:-------------:                      |
|*config*            |``aws.Config``              |AWS Config                           |
|*kubeConfigYAML*    |``string``                  |Kubernetes config to deploy          |
|*namespace*         |``string``                  |Kubernetes Namespace to deploy to    |
|*version*           |``*"v1.14.7" \| string``    |Version of kubectl client            |
|*kubeAuthConfig*    |``string``                  |Kube auth config file                |

## s3

### Put

S3 file or Directory upload

#### Fields

| FIELD            | SPEC                             | DOC                                                        |
| -------------    |:-------------:                   |:-------------:                                             |
|*url*             |``run.output["/outputs/url"]``    |URL of the uploaded S3 object                               |
|*source*          |``string \| bl.Directory``        |Source Directory, File or String to Upload to S3            |
|*target*          |``string``                        |Target S3 URL (eg. s3://<bucket-name>/<path>/<sub-path>)    |
|*config*          |``aws.Config``                    |AWS Config                                                  |

## file

### Read

Read reads the contents of a file.

#### Fields

| FIELD            | SPEC                           | DOC                                |
| -------------    |:-------------:                 |:-------------:                     |
|*filename*        |``!=""``                        |filename names the file to read.    |
|*contents*        |``script.output["/output"]``    |contents is the read contents.      |
|*source*          |``bl.Directory``                |source directory                    |

### Create

Create writes contents to the given file.

#### Fields

| FIELD            | SPEC                           | DOC                                                                          |
| -------------    |:-------------:                 |:-------------:                                                               |
|*filename*        |``!=""``                        |filename names the file to write.                                             |
|*contents*        |``bytes \| string``             |contents specifies the bytes to be written.                                   |
|*permissions*     |``int \| *0o644``               |permissions defines the permissions to use if the file does not yet exist.    |
|*result*          |``script.output["/result"]``    |result directory                                                              |

### Append

Append writes contents to the given file.

#### Fields

| FIELD            | SPEC                           | DOC                                                                          |
| -------------    |:-------------:                 |:-------------:                                                               |
|*filename*        |``!=""``                        |filename names the file to append.                                            |
|*contents*        |``bytes \| string``             |contents specifies the bytes to be written.                                   |
|*permissions*     |``int \| *0o644``               |permissions defines the permissions to use if the file does not yet exist.    |
|*source*          |``bl.Directory``                |source directory                                                              |
|*result*          |``script.output["/result"]``    |result directory                                                              |

### Glob

Glob returns a list of files.

#### Fields

| FIELD            | SPEC                                                                                                                     | DOC                                               |
| -------------    |:-------------:                                                                                                           |:-------------:                                    |
|*glob*            |``!=""``                                                                                                                  |glob specifies the pattern to match files with.    |
|*files*           |``_\|_(cannot use string (type string) as bytes in argument 0 to encoding/json.Unmarshal: non-concrete value string)``    |files that matched                                 |
|*source*          |``bl.Directory``                                                                                                          |source directory                                   |

## git

### Repository

Git repository

#### Fields

| FIELD            | SPEC                                                                 | DOC                                        |
| -------------    |:-------------:                                                       |:-------------:                             |
|*url*             |``string``                                                            |URL of the Repository                       |
|*ref*             |``*"master" \| string``                                               |Git Ref to checkout                         |
|*keepGitDir*      |``*false \| bool``                                                    |Keep .git directory after clone             |
|*out*             |``clone.output["/outputs/out"]``                                      |Output directory of the `git clone`         |
|*commit*          |``strings.TrimRight(clone.output["/outputs/commit"], "\n")``          |Output commit ID of the Repository          |
|*shortCommit*     |``strings.TrimRight(clone.output["/outputs/short-commit"], "\n")``    |Output short-commit ID of the Repository    |

### PathCommit

Retrieve commit IDs from a git working copy (ie. cloned repository)

#### Fields

| FIELD            | SPEC                                                                      | DOC                                             |
| -------------    |:-------------:                                                            |:-------------:                                  |
|*path*            |``*"./" \| string``                                                        |Optional path to retrieve git commit IDs from    |
|*from*            |``bl.Directory``                                                           |Source Directory (git working copy)              |
|*commit*          |``strings.TrimRight(pathCommit.output["/outputs/commit"], "\n")``          |Output commit ID of the Repository               |
|*shortCommit*     |``strings.TrimRight(pathCommit.output["/outputs/short-commit"], "\n")``    |Output short-commit ID of the Repository         |

## github

### Repository

#### Fields

| FIELD            | SPEC                                                                                                                                                                                                     | DOC               |
| -------------    |:-------------:                                                                                                                                                                                           |:-------------:    |
|*name*            |``string``                                                                                                                                                                                                |N/A                |
|*owner*           |``string``                                                                                                                                                                                                |N/A                |
|*pr*              |``{ [prId=string]: { id: prId status: "open" \| "closed" comments: [commentId=string]: { author: string text: string } branch: { name: string tip: { commitId: string checkout: bl.Directory } } } }``    |N/A                |

## go

### App

Go application built with `go build`

#### Fields

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

### Config

Google Cloud Config shared by all packages

#### Fields

| FIELD            | SPEC              | DOC               |
| -------------    |:-------------:    |:-------------:    |
|*region*          |``string``         |N/A                |
|*project*         |``string``         |N/A                |

## gke

### AuthConfig

AuthConfig config outputs a valid kube-auth-config for kubectl client

#### Fields

| FIELD              | SPEC                              | DOC                |
| -------------      |:-------------:                    |:-------------:     |
|*config*            |``googlecloud.Config``             |GCP Config          |
|*gkeClusterName*    |``string``                         |GKE cluster name    |
|*out*               |``run.output["/outputs/auth"]``    |N/A                 |

### Deployment

Deployment of a kubernetes configuration on an GKE cluster

#### Fields

| FIELD              | SPEC                       | DOC                                 |
| -------------      |:-------------:             |:-------------:                      |
|*config*            |``googlecloud.Config``      |GCP Config                           |
|*kubeConfigYAML*    |``string``                  |Kubernetes config to deploy          |
|*namespace*         |``string``                  |Kubernetes Namespace to deploy to    |
|*version*           |``*"v1.14.7" \| string``    |Version of kubectl client            |
|*kubeAuthConfig*    |``string``                  |Kube auth config file                |

## kubernetes

### App

#### Fields

| FIELD                | SPEC                                  | DOC               |
| -------------        |:-------------:                        |:-------------:    |
|*cluster*             |``Cluster``                            |N/A                |
|*namespace*           |``string``                             |N/A                |
|*config*              |``Configuration``                      |N/A                |
|*unknownResources*    |``"error" \| "ignore" \| "remove"``    |N/A                |

### Cluster

#### Fields

| FIELD            | SPEC                                         | DOC               |
| -------------    |:-------------:                               |:-------------:    |
|*namespace*       |``{ [ns=string]: config: Configuration }``    |N/A                |

### Configuration

#### Fields

| FIELD            | SPEC                              | DOC               |
| -------------    |:-------------:                    |:-------------:    |
|*secret*          |``{ [string]: stringData: _ }``    |N/A                |
|*deployment*      |``{ [string]: spec: _ }``          |N/A                |
|*ingress*         |``{ [string]: spec: _ }``          |N/A                |

### YamlDirectory

#### Fields

| FIELD            | SPEC                | DOC               |
| -------------    |:-------------:      |:-------------:    |
|*config*          |``Configuration``    |N/A                |
|*dir*             |``bl.Directory``     |N/A                |

## mysql

### Database

#### Fields

| FIELD            | SPEC                | DOC               |
| -------------    |:-------------:      |:-------------:    |
|*name*            |``string``           |N/A                |
|*create*          |``*true \| bool``    |N/A                |
|*server*          |``Server``           |N/A                |

### Server

#### Fields

| FIELD             | SPEC               | DOC               |
| -------------     |:-------------:     |:-------------:    |
|*host*             |``string``          |N/A                |
|*port*             |``*3306 \| int``    |N/A                |
|*adminUser*        |``string``          |N/A                |
|*adminPassword*    |``string``          |N/A                |

## netlify

### Account

A Netlify account

#### Fields

| FIELD            | SPEC                | DOC                                                                              |
| -------------    |:-------------:      |:-------------:                                                                   |
|*name*            |``string \| *""``    |Use this Netlify account name (also referred to as "team" in the Netlify docs)    |

### Site

A Netlify site

#### Fields

| FIELD            | SPEC                             | DOC                                            |
| -------------    |:-------------:                   |:-------------:                                 |
|*name*            |``string``                        |Deploy to this Netlify site                     |
|*contents*        |``bl.Directory``                  |Contents of the application to deploy           |
|*url*             |``deploy.output["/info/url"]``    |Deployment url                                  |
|*account*         |``Account``                       |Netlify account this site is attached to        |
|*domain*          |``string``                        |Host the site at this address                   |
|*create*          |``bool \| *true``                 |Create the Netlify site if it doesn't exist?    |

## nodejs

### Container

#### Fields

| FIELD            | SPEC                       | DOC               |
| -------------    |:-------------:             |:-------------:    |
|*image*           |``bl.Directory``            |N/A                |
|*environment*     |``{ [string]: string }``    |N/A                |
|*source*          |``bl.Directory``            |N/A                |
|*buildScript*     |``string``                  |N/A                |
|*runScript*       |``string``                  |N/A                |

## yarn

### App

A javascript application built by Yarn

#### Fields

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

### Archive

Zip archive

#### Fields

| FIELD            | SPEC                                                        | DOC                                            |
| -------------    |:-------------:                                              |:-------------:                                 |
|*source*          |``bl.Directory \| string``                                   |Source Directory, File or String to Zip from    |
|*archive*         |``{ from: run.output["/outputs/out"] path: "file.zip" }``    |Archive file output                             |
