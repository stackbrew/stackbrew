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

	conns := scanConnectors(i)
	for _, c := range(conns) {
		id, set, _ := c.ID()
		if !set {
			id="?"
		}
		fmt.Printf("Connector %s ID=%s\n", strings.Join(c.Path, "."), id)
	}

	incompletes := scanIncompletes(i)
	for _, c := range(incompletes) {
		fmt.Printf("Incomplete value: %s\n", strings.Join(c.Path, "."))
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

func scanIncompletes(root *cue.Instance) (result []Cursor) {
	scan(
		root.Value(),
		func (v cue.Value, path []string) bool {
			debug("scanning for incompletes: %v", path)
			if !v.IsConcrete() {
				result = append(result, Cursor{
					Root: root,
					Path: path,
				})
				return true
			}
			op, _:= v.Expr()
			debug("OP=%d\n", op)
			return true
		},
		nil,
	)
	return
}

type Cursor struct {
	Root *cue.Instance
	Path []string
}

func (c Cursor) Value() cue.Value {
	return c.Root.Lookup(c.Path...)
}

// A simple scan for connectors in a concrete configuration.
// A connector is any struct which has the definition `#ID: string`
// Connectors are attachment points for dynamic loading: a way to hand off
// part of a config evaluation to another evaluator.
func scanConnectors(root *cue.Instance) (conns []*Connector) {
	scan(
		root.Value(),
		func(v cue.Value, path []string) bool {
			// Is `v` a struct with a definition #ID ?
			c := NewConnector(v, path...)
			if _, _, idExists := c.ID(); idExists {
				debug("\tconnector detected")
				conns = append(conns, c)
				return false
			}
			return true
		},
		nil,
	)
	return
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


func scan(v cue.Value, get func(cue.Value, []string) bool, path []string) {
	debug("[scanning] %s", strings.Join(path, "."))
	get(v, path)
	// FIXME: make configurable
	// scanExpr(v, get, path, 0)
	switch v.Kind() {
		// Recursively check struct fields
		case cue.StructKind:
			// Only iterate over "regular" fields (not hidden, eg. definitions)
			for it, _ := v.Fields(); it.Next(); {
				scan(it.Value(), get, append(path, it.Label()))
			}
		// Recursively check list elements
		case cue.ListKind:
			for it, _ := v.List(); it.Next(); {
				scan(it.Value(), get, append(path, it.Label()))
			}
	}
}

func scanExpr(v cue.Value, get func(cue.Value, []string) bool, path []string, depth int) {
	exprOp, exprArgs:= v.Expr()
	debug("[scanExpr] %s %s@%d [ref=%v] [op=%d] [args=%d] -- %v",
		strings.Join(path, "."),
		"+" + strings.Repeat("---", depth),
		depth,
		isRef(v),
		exprOp,
		len(exprArgs),
		exprArgs,
	)
	if exprOp == cue.NoOp {
		get(v, path)
		return
	}
	refI, refP := v.Reference()
	if len(refP) > 0 {
		refTarget, err := lookup(refI.Value(), refP...)
		if err != nil {
			return
		}
		scanExpr(refTarget, get, refP, depth+1)
	}
	for _, arg := range(exprArgs) {
		scanExpr(arg, get, path, depth+1)
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

