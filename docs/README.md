# Packages

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
|*source*          |``bl.Directory``                |source directory                                                              |
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

## github

### Repository

#### Fields

| FIELD            | SPEC                                                                                                                                                                                                     | DOC               |
| -------------    |:-------------:                                                                                                                                                                                           |:-------------:    |
|*name*            |``string``                                                                                                                                                                                                |N/A                |
|*token*           |``bl.Secret``                                                                                                                                                                                             |N/A                |
|*owner*           |``string``                                                                                                                                                                                                |N/A                |
|*pr*              |``{ [prId=string]: { id: prId status: "open" \| "closed" comments: [commentId=string]: { author: string text: string } branch: { name: string tip: { commitId: string checkout: bl.Directory } } } }``    |N/A                |

## googlecloud

### Project

#### Fields

| FIELD            | SPEC                                                                                                                                                                 | DOC                                               |
| -------------    |:-------------:                                                                                                                                                       |:-------------:                                    |
|*id*              |``string``                                                                                                                                                            |activateUrl: string action: checkActivate: {  }    |
|*account*         |``{ key: { // FIXME: google cloud service key schema ... } }``                                                                                                        |N/A                                                |
|*GCR*             |``{ // A GCR container repository Repository: { name: string tag: [string]: bl.Directory unknownTags: "remove" \| *"ignore" \| "error" ref: "gcr.io/\(name)" } }``    |N/A                                                |
|*GKE*             |``{ // A GKE cluster Cluster: kubernetes.Cluster & { name: string zone: *"us-west1" \| string create: *true \| bool } }``                                             |N/A                                                |
|*SQL*             |``{}``                                                                                                                                                                |N/A                                                |

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
|*deployment*      |``{ [string]: spec: _ }``          |N/A                |
|*ingress*         |``{ [string]: spec: _ }``          |N/A                |
|*secret*          |``{ [string]: stringData: _ }``    |N/A                |

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
|*token*           |``bl.Secret``        |Netlify authentication token                                                      |

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
|*environment*     |``{ [string]: string }``    |N/A                |
|*buildScript*     |``string``                  |N/A                |
|*runScript*       |``string``                  |N/A                |
|*source*          |``bl.Directory``            |N/A                |
|*image*           |``bl.Directory``            |N/A                |

## yarn

### App

A javascript application built by Yarn

#### Fields

| FIELD              | SPEC                                    | DOC                                                                                   |
| -------------      |:-------------:                          |:-------------:                                                                        |
|*environment*       |``{ [string]: string }``                 |Set these environment variables during the build                                       |
|*source*            |``bl.Directory``                         |Source code of the javascript application                                              |
|*loadEnv*           |``bool \| *true``                        |Load the contents of `environment` into the yarn process?                              |
|*yarnScript*        |``string \| *"build"``                   |Run this yarn script                                                                   |
|*writeEnvFile*      |``string \| *""``                        |Write the contents of `environment` to this file, in the "envfile" format.             |
|*buildDirectory*    |``string \| *"build"``                   |Read build output from this directory (path must be relative to working directory).    |
|*build*             |``action.build.output["/app/build"]``    |Output of yarn build                                                                   |
