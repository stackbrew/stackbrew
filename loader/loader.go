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
}

func (c *Connector) String() (msg string) {
	id, set, exists := c.ID()
	if !exists {
		msg = "not a connector"
		return
	}
	if set {
		msg = fmt.Sprintf("[%s]", id)
		return
	}
	if !set {
		msg = fmt.Sprintf("[disconnected]")
		return
	}
	return
}

func (c *Connector) Tasks() []*Task {
	return lookupTasks(c.Value)
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
	asString, err := field.Value.String()
	if err != nil {
		return
	}
	id = asString
	exists = true
	set = field.Value.IsConcrete()
	return
}

func NewConnector(v cue.Value) *Connector {
	return &Connector{
		Value: v,
	}
}

func scanConnectors(v cue.Value) (conns []*Connector) {
	// Is `v` a struct with a definition #ID ?
	c := NewConnector(v)
	if _, _, idExists := c.ID(); idExists {
		conns = append(conns, c)
		// FIXME: continue scanning. this allows connectors
		// to dynamically link to other connectors
		return
	}

	// Recursively check references
	refI, refP := v.Reference()
	if len(refP) > 0 {
		info, err := refI.LookupField(refP...)
		if err != nil {
			ui.Error("error looking up %v: %s", refP, err)
			return
		}
		if info.IsDefinition {
			// FIXME: LookupDef is tricky to use here
			debug("FIXME: skipping reference to %s", strings.Join(refP, "."))
		} else {
			debug("Following reference: %v", refP)
			refTarget := refI.Lookup(refP...)
			conns = append(conns, scanConnectors(refTarget)...)
		}
		return
	}

	switch v.Kind() {
		// Recursively check struct fields
		case cue.StructKind:
			// Only iterate over "regular" fields (not hidden, eg. definitions)
			for it, _ := v.Fields(); it.Next(); {
				debug("Following struct field: %s", it.Label())
				conns = append(conns, scanConnectors(it.Value())...)
			}
		// Recursively check list elements
		case cue.ListKind:
			for it, _ := v.List(); it.Next(); {
				debug("Following list element: %s", it.Label())
				conns = append(conns, scanConnectors(it.Value())...)
			}
	}

	// If `v` is an expression, break it down and recursively inspect each component
	exprOp, exprArgs:= v.Expr()
	if exprOp != cue.NoOp && exprOp != cue.SelectorOp {
		for argIdx, arg := range(exprArgs) {
			// fakeLabel is used for human-friendly path display, only
			debug("Following expression '%v/%d'", exprOp, argIdx)
			conns = append(conns, scanConnectors(arg)...)
		}
	}
	return
}

type ExecTask struct {
	Task
}

func (t *ExecTask) String() string {
	cmd, cmdExists := t.Cmd()
	if cmdExists {
		return fmt.Sprintf("exec %v", cmd)
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

// Current limitations of the task scanner:
//	- Does not follow references to definitions. Tasks in definitions will not be found, even
//		if a concrete value depends on part of the definition.
//	- @task(exec) must be set after the struct value (embedded attributes are broken ATM)
func lookupTasks(v cue.Value) (tasks []*Task) {
	// Does v have a @task attribute?
	t := &Task{Value: v}
	if _, exists := t.Verb(); exists {
		tasks = append(tasks, t)
	}
	// Check for references
	refI, refP := v.Reference()
	if len(refP) > 0 {
		info, err := refI.LookupField(refP...)
		if err != nil {
			ui.Error("error looking up %v: %s", refP, err)
			return
		}
		if info.IsDefinition {
			// FIXME: LookupDef is tricky to use here
			debug("FIXME: skipping reference to %s", strings.Join(refP, "."))
		} else {
			debug("Following reference: %v", refP)
			tasks = append(tasks, lookupTasks(refI.Lookup(refP...))...)
		}
		return
	}

	switch v.Kind() {
		// Recursively check struct fields
		case cue.StructKind:
			// Only iterate over "regular" fields (not hidden, eg. definitions)
			for it, _ := v.Fields(); it.Next(); {
				debug("Following struct field: %s", it.Label())
				tasks = append(tasks, lookupTasks(it.Value())...)
			}
		// Recursively check list elements
		case cue.ListKind:
			for it, _ := v.List(); it.Next(); {
				debug("Following list element: %s", it.Label())
				tasks = append(tasks, lookupTasks(it.Value())...)
			}
	}
	// If v is an expression, recursively inspect its component parts
	exprOp, exprArgs:= v.Expr()
	if exprOp != cue.NoOp && exprOp != cue.SelectorOp {
		for argIdx, arg := range(exprArgs) {
			// fakeLabel is used for human-friendly path display, only
			debug("Following expression '%v/%d'", exprOp, argIdx)
			tasks = append(tasks, lookupTasks(arg)...)
		}
	}
	return
}
