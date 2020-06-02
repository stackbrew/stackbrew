package main

import (
	"io"
	"path/filepath"
	"encoding/json"
	"fmt"
	"os"
	"bytes"
	"strings"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/format"
	"cuelang.org/go/cue/load"
	"cuelang.org/go/cue/ast"
	"cuelang.org/go/cue/build"
	"stackbrew.io/loader/ui"
	"github.com/pkg/errors"
)

func debug(fmt string, args ...interface{}) {
	if os.Getenv("DEBUG") != "" {
		ui.Info(fmt, args...)
	}
}

func main() {
	// Load connectors
		// Q. connector list in commandline args?

	// Read cue input from stdin
	i, err := cueCompile(os.Stdin, ".")
	if err != nil {
		panic(err)
	}

	var conns []*Connector
	scanDown(
		i.Value(),
		func(v cue.Value, path []string) bool {
			scanUp(
				v,
				func(v cue.Value, path []string) bool {
					c := NewConnector(v, path...)
					if _, _, idExists := c.ID(); idExists {
						debug("connector detected")
						conns = append(conns, c)
						return false
					}
					return true
				},
				path,
				0,
			)
			return true
		},
		nil,
	)
	for _, c := range(conns) {
		id, set, _ := c.ID()
		if !set {
			id="?"
		}
		fmt.Printf("Connector %s ID=%s\n", strings.Join(c.Path, "."), id)
	}

	if len(os.Args) > 1 {
		var queryPath []string
		if os.Args[1] != "." {
			queryPath = strings.Split(os.Args[1], ".")
		}
		out := i.Lookup(queryPath...)
		outJson, err := JsonIndent(out.MarshalJSON())
		if err != nil {
			panic(err)
		}
		os.Stdout.Write(append(outJson, '\n'))
	}

	// Match contents of input with connector(s)
		// Q. match algorithm?
		// Q. support more than one connector?
		// Q. can connectors be nested?

	// Write cue output to stdout
}


type Cursor struct {
	Root *cue.Instance
	Path []string
}

func (c Cursor) Value() cue.Value {
	return c.Root.Lookup(c.Path...)
}

type Connector struct {
	cue.Value
	Path []string
}

func (c *Connector) ID() (id string, set, exists bool) {
	if c.Kind() != cue.StructKind {
		return
	}
	s, err := c.Struct()
	if err != nil {
		return
	}
	field, err := s.FieldByName("#ID", true)
	if err != nil {
		return
	}
	exists = true
	if !field.Value.IsConcrete() {
		return
	}
	set = true
	asString, err := field.Value.String()
	if err != nil {
		return
	}
	id = asString
	return
}

func NewConnector(v cue.Value, path ...string) *Connector {
	return &Connector{
		Value: v,
		Path: path,
	}
}

func lookup(v cue.Value, path...string) (result cue.Value, err error) {
	var field cue.FieldInfo
	result = v
	for _, name := range(path) {
		field, err = result.LookupField(name)
		if err != nil {
			return
		}
		result = field.Value
	}
	return
}


// Recursively scan a value and all struct fields and list elements.
// Hidden fields and definitions are ignored.
func scanDown(v cue.Value, get func(cue.Value, []string) bool, path []string) {
	debug("[scan down] %s", strings.Join(path, "."))
	get(v, path)
	switch v.Kind() {
		// Recursively check struct fields
		case cue.StructKind:
			// Only iterate over "regular" fields (not hidden, eg. definitions)
			for it, _ := v.Fields(); it.Next(); {
				scanDown(it.Value(), get, append(path, it.Label()))
			}
		// Recursively check list elements
		case cue.ListKind:
			for it, _ := v.List(); it.Next(); {
				scanDown(it.Value(), get, append(path, it.Label()))
			}
	}
}

// Recursively scan a value and the individual components of its cue expression.
func scanUp(v cue.Value, get func(cue.Value, []string) bool, path []string, depth int) {
	exprOp, exprArgs:= v.Expr()
	// Reference information
	refInst, refPath := v.Reference()
	debug("Reference -> %v, %v", refInst, refPath)
	var refTarget cue.Value
	if refInst != nil && len(refPath) > 0 {
		var err error
		refTarget, err = lookup(refInst.Value(), refPath...)
		if err != nil {
			return
		}
	}

	// Display
	if len(refPath) > 0 {
		debug("[%s] %sref -> %s (",
			strings.Join(path, "."),
			strings.Repeat("   ", depth),
			strings.Join(refPath, "."),
		)
		defer debug("[%s] %s) // pop ref",
			strings.Join(path, "."),
			strings.Repeat("   ", depth),
		)
	} else {
		switch exprOp {
			// Leaf: show value details
			case cue.NoOp:
				debug("[%s] %s%s",
					strings.Join(path, "."),
					strings.Repeat("   ", depth),
					v,
				)
			// Node: show indented "stack"
			default:
				debug("[%s] %s%s ( %d args:",
					strings.Join(path, "."),
					strings.Repeat("   ", depth),
					exprOp.String(),
					len(exprArgs),
				)
				defer debug("[%s] %s)",
					strings.Join(path, "."),
					strings.Repeat("   ", depth),
				)
		}
	}
	// New values to check?
	switch exprOp {
		case cue.NoOp, cue.SelectorOp: get(v, path)
	}
	// Recursively follow expr components (except noop)
	if exprOp == cue.NoOp {
		return
	}
	if len(refPath) > 0 {
		scanUp(refTarget, get, refPath, depth + 1)
		return
	}
	for _, arg := range(exprArgs) {
		scanUp(arg, get, path, depth+1)
	}
}

func isRef(v cue.Value) bool {
	_, p := v.Reference()
	return len(p) > 0
}


func cueCompile(src io.Reader, rootDir string) (result *cue.Instance, err error) {
	rootDir, err = filepath.Abs(rootDir)
	if err != nil {
		return
	}
	cfg := &load.Config{
		Stdin: src,
		Dir: rootDir,
		ModuleRoot: rootDir,
		Overlay: make(map[string]load.Source),
	}

	var pkgOverlay = map[string]string {
		//FIXME
	}
	for fName, fContents := range(pkgOverlay) {
		absPath := fmt.Sprintf("%s/cue.mod/pkg/blocklayer.dev/%s", rootDir, fName)
		cfg.Overlay[absPath] = load.FromString(fContents)
	}
	buildInstances := load.Instances([]string{"-"}, cfg)
	if len(buildInstances) != 1 {
		return nil, errors.New("only one package is supported at a time")
	}
	buildInstance := buildInstances[0]

	// 2. Create and merge cue instances (not the same as build instances)
	instances := cue.Build([]*build.Instance{buildInstance})
	root := cue.Merge(instances...)
	if root.Err != nil {
		return nil, errors.Wrap(root.Err, "cue merge")
	}
	if err := root.Value().Validate(); err != nil {
		return nil, errors.Wrap(err, "cue validate")
	}
	// return the root instance
	return root, nil
}

func CueQueryInstance(i *cue.Instance, exportJson, concrete bool, path ...string) (result string, err error) {
	var (
		v cue.Value
		n ast.Node
		b []byte
	)
	// FIXME: separate read lock
	if i == nil {
		result = "{}"
		return
	}
	v = i.Lookup(path...)

	if exportJson {
		// Json export
		b, err = JsonIndent(v.MarshalJSON())
		if err != nil {
			return
		}
	} else {
		// Regular cue result
		synOpts := []cue.Option{}
		if concrete {
			ui.Info("Query: setting Concrete opts to true")
			synOpts = append(synOpts, cue.Concrete(true))
		}
		n = v.Syntax(synOpts...)
		if n == nil {
			err = fmt.Errorf("failed to extract cue AST")
			return
		}
		b, err = format.Node(n, format.Simplify())
		if err != nil {
			return
		}
	}
	result = string(b)
	return
}

func JsonIndent(rawJson []byte, e error) (indentedJson []byte, err error) {
	if e != nil {
		err = e
		return
	}
	var buf = new(bytes.Buffer)
	err = json.Indent(buf, rawJson, "", "  ")
	if err != nil {
		return
	}
	indentedJson = buf.Bytes()
	return
}

