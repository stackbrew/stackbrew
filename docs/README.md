# Packages

## yarn

### App
A javascript application built by Yarn

#### Fields
| FIELD              | SPEC                            | DOC                                                                                   |
| -------------      |:-------------:                  |:-------------:                                                                        |
|*environment*       |`{[]: (_: string)->string, }`    |Set these environment variables during the build                                       |
|*source*            |`bl.Directory`                   |Source code of the javascript application                                              |
|*loadEnv*           |`(bool | *true)`                 |Load the contents of `environment` into the yarn process?                              |
|*yarnScript*        |`(string | *"build")`            |Run this yarn script                                                                   |
|*writeEnvFile*      |`(string | *"")`                 |Write the contents of `environment` to this file, in the "envfile" format.             |
|*buildDirectory*    |`(string | *"build")`            |Read build output from this directory (path must be relative to working directory).    |
|*build*             |`bl.Directory`                   |Output of yarn build                                                                   |
