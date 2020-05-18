package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"strings"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/parser"
	"stackbrew.io/loader/ui"
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
	inputCue, err := ioutil.ReadAll(os.Stdin)
	if err != nil {
		panic(err)
	}
	f, err := parser.ParseFile("stdin", string(inputCue))
	if err != nil {
		panic(err)
	}
	r := new(cue.Runtime)
	i, err := r.CompileFile(f)
	if err != nil {
		panic(err)
	}

	conns := scanConnectors(i.Value())
	for _, c := range(conns) {
		tasks := c.Tasks()
		ui.Info("Connector: %s (%d tasks)", c.String(), len(tasks))
		for _, t := range(tasks) {
			et := &ExecTask{ Task: *t }
			ui.Info("\tTask %s", et.String())
		}
	}

	// Match contents of input with connector(s)
		// Q. match algorithm?
		// Q. support more than one connector?
		// Q. can connectors be nested?

	// Write cue output to stdout
}

type Connector struct {
	cue.Value
	Path []string
}

func (c *Connector) String() (msg string) {
	id, set, exists := c.ID()
	if !exists {
		msg = "not a connector"
		return
	}
	if set {
		msg = fmt.Sprintf("%s [%s]", strings.Join(c.Path, "."), id)
		return
	}
	if !set {
		msg = fmt.Sprintf("%s [-]", strings.Join(c.Path, "."))
		return
	}
	return
}

func (c *Connector) Tasks() []*Task {
	return scanTasks(c.Value)
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
	scanExpr(v, get, path, 0)
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


func scanConnectors(v cue.Value) (conns []*Connector) {
	scan(
		v,
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


func scanTasks(v cue.Value) (tasks []*Task) {
	scan(
		v,
		func(v cue.Value, path []string) bool {
			// Is `v` a struct with a definition #ID ?
			t := NewTask(v, path...)
			if _, exists := t.Verb(); exists {
				debug("\ttask detected")
				tasks = append(tasks, t)
				return false
			}
			return true
		},
		nil,
	)
	return
}

type ExecTask struct {
	Task
}

func (t *ExecTask) String() string {
	cmd, cmdExists := t.Cmd()
	if cmdExists {
		return fmt.Sprintf("%s [exec %v]", strings.Join(t.Path, "."), cmd)
	}
	return "exec <malformed>"
}

func (t *ExecTask) Cmd() (cmd []string, exists bool) {
	cmdValue := t.Value.Lookup("cmd")
	if !cmdValue.Exists() {
		return
	}
	cmdJson, err := cmdValue.MarshalJSON()
	if err != nil {
		return
	}
	err = json.Unmarshal(cmdJson, &cmd)
	if err != nil {
		return
	}
	exists = true
	return
}

type Task struct {
	cue.Value
	Path []string
}

func NewTask(v cue.Value, path ...string) *Task {
	return &Task{
		Value: v,
		Path: path,
	}
}

func (t *Task) Verb() (verb string, exists bool) {
	var (
		err error
	)
	attr := t.Value.Attribute("task")
	if attr.Err() != nil {
		return
	}
	verb, err = attr.String(0)
	if err != nil {
		return
	}
	exists = true
	return
}
