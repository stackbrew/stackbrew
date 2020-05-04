package file

import (
	"strconv"
	"encoding/json"

	"stackbrew.io/bash"
	"stackbrew.io/fs"
)

// Read reads the contents of a file.
Read :: {
	// source directory
	source: fs.Directory

	// filename names the file to read.
	filename: !=""

	// contents is the read contents.
	contents: script.output["/output"]

	script: bash.BashScript & {
		input: "/src":         source
		output: "/output":     string
		environment: FILENAME: filename
		code: """
        cp "/src/$FILENAME" /output
        """
	}
}

// Create writes contents to the given file.
Create :: {
	// source directory
	source?: fs.Directory

	// result directory
	result: script.output["/result"]

	// filename names the file to write.
	filename: !=""

	// permissions defines the permissions to use if the file does not yet exist.
	permissions: int | *0o644

	// contents specifies the bytes to be written.
	contents: bytes | string

	script: bash.BashScript & {
		if (source & fs.Directory) != _|_ {
			input: "/src": source
		}
		input: "/contents": contents
		output: "/result":  fs.Directory
		environment: {
			FILENAME: filename
			PERM:     strconv.FormatInt(permissions, 8)
		}
		code: """
        [ ! -d /src ] && mkdir /src
        cp -a /src /result
        dest="/result/$FILENAME"
        cp /contents "$dest"
        chmod "$PERM" "$dest"
        """
	}
}

// Append writes contents to the given file.
Append :: {
	// source directory
	source: fs.Directory

	// result directory
	result: script.output["/result"]

	// filename names the file to append.
	filename: !=""

	// permissions defines the permissions to use if the file does not yet exist.
	permissions: int | *0o644

	// contents specifies the bytes to be written.
	contents: bytes | string

	script: bash.BashScript & {
		input: "/src":      source
		input: "/contents": contents
		output: "/result":  fs.Directory
		environment: {
			FILENAME: filename
			PERM:     strconv.FormatInt(permissions, 8)
		}
		code: """
        cp -a /src /result
        dest="/result/$FILENAME"
        if [ ! -e "$dest" ]; then
            touch "$dest"
            chmod "$PERM" "$dest"
        fi
        cat /contents >> "$dest"
        """
	}
}

// Glob returns a list of files.
Glob :: {
	// source directory
	source: fs.Directory

	// glob specifies the pattern to match files with.
	glob: !=""

	// files that matched
	files: [...string]
	files: json.Unmarshal(script.output["/result.json"])

	script: bash.BashScript & {
		input: "/src":          source
		output: "/result.json": string
		environment: GLOB:      glob
		code: """
        cd /src
        result="[]"
        for f in $(ls -1 $GLOB); do
            echo "====> $f"
            result=$(echo "$result" | jq ". += [\\"${f}\\"]")
        done
        echo "$result" > /result.json
        """
	}
}
