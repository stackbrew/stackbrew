#!/bin/bash

set -e

cd "$(dirname "$0")/.."

TEST_TARGET="${TARGET:-localhost:5001/stackbrew-test}"
PKGDIR="./pkg"

COMPONENTS="${COMPONENTS:=$(find "${PKGDIR}" -type f -name "*.cue" | grep -v cue.mod | cut -d/ -f3- | sed -E 's=/[^/]+$==' | uniq | sort -n)}"

TEST_CONFIG="$(pwd)/testconfig.secret.json"

case "${1}" in
    fmt)
        for component in ${COMPONENTS}; do
            (
                echo "+++ FMT ${component}" >&2
                cd "${PKGDIR}/${component}"
                # FIXME: fmt is broken with _test.cue files
                #cue fmt -s
                # FIXME: trim -s is breaking list comprehensions in yarn and cloudformation
                #cue trim -s
            )
        done
    ;;
    lint)
        for component in ${COMPONENTS}; do
            (
                echo "+++ LINTING ${component}" >&2
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
                echo "+++ TESTING ${component}" >&2
                cd "${PKGDIR}/${component}"
                bl-runtime test -f "$TEST_CONFIG" -t "$TEST_TARGET:${component/\//.}"
            )
        done
    ;;
    publish)
        for component in ${COMPONENTS}; do
            (
                echo "+++ PUBLISH stackbrew.io/${component}" >&2
                cd "${PKGDIR}/${component}"
                bl-runtime publish "blocklayer.dev/${component}"
            )
        done
    ;;
    docs)
        docs="$(pwd)/docs/README.md"
        mkdir -p "$(dirname "$docs")"
        echo "# Stackbrew Packages" > "$docs"
        for component in ${COMPONENTS}; do
            (
                echo "+++ DOCUMENTING ${component}" >&2
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
