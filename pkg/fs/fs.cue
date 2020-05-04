package fs

// Directory is a core type representing a directory.
//
// There are multiple implementations of directory, a directory can map to a
// registry, to the local filesystem, and so on.
Directory :: {
	$bl: "bl.Directory"
	{
		// Directory from another directory (e.g. subdirectory)
		from: Directory
	} | {
		// Reference to remote directory
		ref: string
	} | {
		// Use a local directory
		local: string
	}
	path: string | *"/"
}

// Cache is a core type. It behaves like a directory but it's content is
// persistenly cached between runs
Cache :: {
	$bl: "bl.Cache"
	key: string | *""
}
