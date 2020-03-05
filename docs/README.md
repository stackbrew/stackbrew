# Packages

## file

### Read
Read reads the contents of a file.

#### Fields
| FIELD            | SPEC               | DOC                                |
| -------------    |:-------------:     |:-------------:                     |
|*filename*        |``!=""``            |filename names the file to read.    |
|*contents*        |``string``          |contents is the read contents.      |
|*source*          |``bl.Directory``    |source directory                    |

### Create
Create writes contents to the given file.

#### Fields
| FIELD            | SPEC                    | DOC                                                                          |
| -------------    |:-------------:          |:-------------:                                                               |
|*filename*        |``!=""``                 |filename names the file to write.                                             |
|*contents*        |``(bytes \| string)``    |contents specifies the bytes to be written.                                   |
|*permissions*     |``(int \| *420)``        |permissions defines the permissions to use if the file does not yet exist.    |
|*source*          |``bl.Directory``         |source directory                                                              |
|*result*          |``bl.Directory``         |result directory                                                              |

### Append
Append writes contents to the given file.

#### Fields
| FIELD            | SPEC                    | DOC                                                                          |
| -------------    |:-------------:          |:-------------:                                                               |
|*filename*        |``!=""``                 |filename names the file to append.                                            |
|*contents*        |``(bytes \| string)``    |contents specifies the bytes to be written.                                   |
|*permissions*     |``(int \| *420)``        |permissions defines the permissions to use if the file does not yet exist.    |
|*source*          |``bl.Directory``         |source directory                                                              |
|*result*          |``bl.Directory``         |result directory                                                              |

### Glob
Glob returns a list of files.

#### Fields
| FIELD            | SPEC               | DOC                                               |
| -------------    |:-------------:     |:-------------:                                    |
|*glob*            |``!=""``            |glob specifies the pattern to match files with.    |
|*files*           |``_\|_``            |files that matched                                 |
|*source*          |``bl.Directory``    |source directory                                   |

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
| FIELD            | SPEC              | DOC               |
| -------------    |:-------------:    |:-------------:    |

### Cluster


#### Fields
| FIELD            | SPEC              | DOC               |
| -------------    |:-------------:    |:-------------:    |

### Configuration


#### Fields
| FIELD            | SPEC              | DOC               |
| -------------    |:-------------:    |:-------------:    |

### YamlDirectory


#### Fields
| FIELD            | SPEC              | DOC               |
| -------------    |:-------------:    |:-------------:    |

## mysql

### Database


#### Fields
| FIELD            | SPEC              | DOC               |
| -------------    |:-------------:    |:-------------:    |

### Server


#### Fields
| FIELD            | SPEC              | DOC               |
| -------------    |:-------------:    |:-------------:    |

## netlify

### Account
A Netlify account

#### Fields
| FIELD            | SPEC                  | DOC                                                                              |
| -------------    |:-------------:        |:-------------:                                                                   |
|*name*            |``(string \| *"")``    |Use this Netlify account name (also referred to as "team" in the Netlify docs)    |
|*token*           |``bl.Secret``          |Netlify authentication token                                                      |

### Site
A Netlify site

#### Fields
| FIELD            | SPEC                                          | DOC                                            |
| -------------    |:-------------:                                |:-------------:                                 |
|*name*            |``string``                                     |Deploy to this Netlify site                     |
|*contents*        |``bl.Directory``                               |Contents of the application to deploy           |
|*url*             |``string``                                     |Deployment url                                  |
|*account*         |``C{name: (string \| *""), token: Secret}``    |Netlify account this site is attached to        |
|*domain*          |``string``                                     |Host the site at this address                   |
|*create*          |``(bool \| *true)``                            |Create the Netlify site if it doesn't exist?    |

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
