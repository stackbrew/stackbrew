#!/bin/bash

set -e

cd "$(dirname "$0")/.."

TEST_TARGET="${TARGET:-bl-registry:5001/stackbrew-test}"
PKGDIR="./pkg"

# FIXME: Not all packages are currently working.
# COMPONENTS="$(ls -1 ${PKGDIR})"
COMPONENTS="yarn"

case "${1}" in
    lint)
        for component in ${COMPONENTS}; do
            (
                echo "+++ LINTING ${component}"
                cd "${PKGDIR}/${component}"
                cue trim -s
            )
        done
    ;;
    test)
        for component in ${COMPONENTS}; do
            (
                echo "+++ TESTING ${component}"
                cd "${PKGDIR}/${component}"
                bl-runtime test -t "$TEST_TARGET:${component}"
            )
        done
    ;;
    *)
        echo "usage: $0 [lint|test]"
        exit 1
    ;;
esac
