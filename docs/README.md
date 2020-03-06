# Packages

## github

### Repository


#### Fields
| FIELD            | SPEC              | DOC               |
| -------------    |:-------------:    |:-------------:    |

## googlecloud

### Project


#### Fields
| FIELD            | SPEC              | DOC                                               |
| -------------    |:-------------:    |:-------------:                                    |
|*id*              |``string``         |activateUrl: string action: checkActivate: {  }    |

## kubernetes

### App


#### Fields

### Cluster


#### Fields

### Configuration


#### Fields

### YamlDirectory


#### Fields
| FIELD            | SPEC              | DOC               |
| -------------    |:-------------:    |:-------------:    |
| FIELD            | SPEC              | DOC               |
| -------------    |:-------------:    |:-------------:    |
| FIELD            | SPEC              | DOC               |
| -------------    |:-------------:    |:-------------:    |
| FIELD            | SPEC              | DOC               |
| -------------    |:-------------:    |:-------------:    |

## mysql

### Database


#### Fields

### Server


#### Fields
| FIELD            | SPEC              | DOC               |
| -------------    |:-------------:    |:-------------:    |
| FIELD            | SPEC              | DOC               |
| -------------    |:-------------:    |:-------------:    |

## netlify

### Account
A Netlify account

#### Fields

### Site
A Netlify site

#### Fields
| FIELD            | SPEC                                                               | DOC                                            |
| -------------    |:-------------:                                                     |:-------------:                                 |
|*name*            |``string``                                                          |Deploy to this Netlify site                     |
|*contents*        |``bl.Directory``                                                    |Contents of the application to deploy           |
|*url*             |``string``                                                          |Deployment url                                  |
|*account*         |``C{name: (string \| *""), token: (Secret & C{value: string})}``    |Netlify account this site is attached to        |
|*domain*          |``string``                                                          |Host the site at this address                   |
|*create*          |``(bool \| *true)``                                                 |Create the Netlify site if it doesn't exist?    |
| FIELD            | SPEC                   | DOC                                                                              |
| -------------    |:-------------:         |:-------------:                                                                   |
|*name*            |``(string \| *"")``     |Use this Netlify account name (also referred to as "team" in the Netlify docs)    |
|*token*           |``C{value: string}``    |Netlify authentication token                                                      |

## nodejs

### Container


#### Fields
| FIELD            | SPEC              | DOC               |
| -------------    |:-------------:    |:-------------:    |

## yarn

### App
A javascript application built by Yarn

#### Fields
| FIELD              | SPEC                              | DOC                                                                                   |
| -------------      |:-------------:                    |:-------------:                                                                        |
|*environment*       |``{[]: (_: string)->string, }``    |Set these environment variables during the build                                       |
|*source*            |``bl.Directory``                   |Source code of the javascript application                                              |
|*loadEnv*           |``(bool \| *true)``                |Load the contents of `environment` into the yarn process?                              |
|*yarnScript*        |``(string \| *"build")``           |Run this yarn script                                                                   |
|*writeEnvFile*      |``(string \| *"")``                |Write the contents of `environment` to this file, in the "envfile" format.             |
|*buildDirectory*    |``(string \| *"build")``           |Read build output from this directory (path must be relative to working directory).    |
|*build*             |``bl.Directory``                   |Output of yarn build                                                                   |
