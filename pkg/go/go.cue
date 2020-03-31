package go

import "b.l/bl"

// Go application built with `go build`
App :: {

    // Source Directory to build
    source: bl.Directory

    // Go version to use
    version: *"1.14.1" | string

    // Run `go generate` before building
    generate: *false | true

    // Target architecture
    arch: *"amd64" | string

    // Target OS
    osInput=os: *"linux" | string

    // Build tags to use for building
    tags: *"netgo" | string

    // LDFLAGS to use for linking
    ldflags: *"-w -extldflags \"-static\"" | string

    // Specify targetted binary name
    binaryName: *"app" | string

    // Binary file output of the Go build
    binary: bl.Directory & {
        from: build.output["/outputs/out"]
        path: binaryName
    }

    build: bl.BashScript & {
        input: {
            "/inputs/source": source
            "/inputs/version": version
            if generate {
                "/inputs/go-generate": "true"
            }
            "/inputs/binaryName": binaryName
            "/inputs/arch": arch
            "/inputs/os": osInput
            "/inputs/tags": tags
            "/inputs/ldflags": ldflags
            "/cache/go": bl.Cache
        }

        output: {
            "/outputs/out": bl.Directory
        }

        os: package: {
			"libc6-compat": true
		}

        code: #"""
            goVersion="$(cat /inputs/version)"

            export GOROOT="/cache/go/$goVersion"
            if [ ! -d ${GOROOT} ]; then
                wget -q -O - https://raw.githubusercontent.com/blocklayerhq/golang-tools-install-script/master/goinstall.sh \
                | bash -s -- --version "$goVersion"
            fi

            export PATH="$PATH:${GOROOT}/bin"
            export GOOS="$(cat /inputs/os)"
            export GOARCH="$(cat /inputs/arch)"
            export GO111MODULE=on
            mkdir -p /cache/go_path
            export GOPATH="/cache/go_path"

            cp -a /inputs/source/ /tmp
            out="/outputs/out/$(cat /inputs/binaryName)"
            tags="$(cat /inputs/tags)"
            ldflags="$(cat /inputs/ldflags)"
            (
                cd /tmp/source

                if [ -d /inputs/go-generate ]; then
                    go generate .
                fi

                go build -a -v -tags "$tags" -ldflags "$ldflags" -o "$out"
            )
        """#
    }
}
