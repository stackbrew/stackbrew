#!/bin/bash

set -e

cd "$(dirname "$0")/.."

TEST_TARGET="${TARGET:-bl-registry:5001/stackbrew-test}"
PKGDIR="./pkg"

COMPONENTS="${COMPONENTS:=$(find "${PKGDIR}" -type f -name "*.cue" | grep -v cue.mod | cut -d/ -f3- | sed -E 's=/[^/]+$==' | uniq | sort -n)}"

TEST_CONFIG="$(pwd)/testconfig.secret.json"

case "${1}" in
    fmt)
        for component in ${COMPONENTS}; do
            (
                echo "+++ FMT ${component}"
                cd "${PKGDIR}/${component}"
                cue fmt -s
                cue trim -s
            )
        done
    ;;
    lint)
        for component in ${COMPONENTS}; do
            (
                echo "+++ LINTING ${component}"
                cd "${PKGDIR}/${component}"
                cue fmt -s
                cue trim -s
                test -z "$(git status -s . | grep -e "^ M"  | cut -d ' ' -f3 | tee /dev/stderr)"
            )
        done
    ;;
    test)
        for component in ${COMPONENTS}; do
            (
                echo "+++ TESTING ${component}"
                cd "${PKGDIR}/${component}"
                bl-runtime test -f "$TEST_CONFIG" -t "$TEST_TARGET:${component/\//.}"
            )
        done
    ;;
    publish)
        for component in ${COMPONENTS}; do
            (
                echo "+++ PUBLISH stackbrew.io/${component}"
                cd "${PKGDIR}/${component}"
                bl-runtime publish "stackbrew.io/${component}"
            )
        done
    ;;
    docs)
        docs="$(pwd)/docs/README.md"
        mkdir -p "$(dirname "$docs")"
        echo "# Packages" > "$docs"
        for component in ${COMPONENTS}; do
            (
                echo "+++ DOCUMENTING ${component}"
                cd "${PKGDIR}"
                echo >> "$docs"
                bl-runtime doc -c "${component}" -o md >> "$docs"
            )
        done
    ;;
    *)
        echo "usage: $0 [lint|test]"
        exit 1
    ;;
esac
