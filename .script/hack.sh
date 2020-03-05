#!/bin/bash

set -e

cd "$(dirname "$0")/.."

TEST_TARGET="${TARGET:-bl-registry:5001/stackbrew-test}"
PKGDIR="./pkg"

# FIXME: Not all packages are currently working.
# COMPONENTS="$(ls -1 ${PKGDIR} | sort -n)"
COMPONENTS="yarn"

modified_files() {
    git status -s . | grep -e "^ M"  | cut -d ' ' -f3
}

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

                dirty=$(modified_files)
                [ -n "$dirty" ] && echo -e "uncommited changes\n$dirty" && exit 1

                cue fmt -s
                cue trim -s

                dirty=$(modified_files)
                [ -n "$dirty" ] && echo -e "files not properly cue fmt'ed or cue trim'ed\n$dirty" && exit 1
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
    publish)
        for component in ${COMPONENTS}; do
            (
                echo "+++ PUBLISH stackbrew.io/${component}"
                cd "${PKGDIR}/${component}"
                bl-runtime publish stackbrew.io/${component}
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
                cd "${PKGDIR}/${component}"
                echo >> "$docs"
                bl-runtime doc -o md >> "$docs"
            )
        done
    ;;
    *)
        echo "usage: $0 [lint|test]"
        exit 1
    ;;
esac
