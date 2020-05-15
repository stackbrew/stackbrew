package main

import (
	"io/ioutil"
	"os"
	"fmt"
	"cuelang.org/go/cue"
	"cuelang.org/go/cue/parser"
	"github.com/pkg/errors"

	"stackbrew.io/loader/ui"
)

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
	ui.Info("%d connectors detected", len(conns))
	for _, c := range(conns) {
		ui.Info("\t- %v", c)
		ui.Info("\t  %d tasks detected", len(c.tasks))
		for _, t := range(c.tasks) {
			ui.Info("\t\t- %v", t)
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
	tasks []*Task
}

func NewConnector(v cue.Value) (c *Connector) {
	c = &Connector{
		Value: v,
		tasks: lookupTasks(v),
	}
	return
}

func scanConnectors(v cue.Value) (conns []*Connector) {
	// Is `v` a struct with a definition #ID ?
	c := func (v cue.Value) (c *Connector) {
		if v.Kind() != cue.StructKind {
			return
		}
		s, err := v.Struct()
		if err != nil {
			return
		}
		_, err = s.FieldByName("#ID", true)
		if err != nil {
			return
		}
		c = NewConnector(v)
		return
	}(v)
	if c != nil {
		conns = append(conns, c)
		return
	}

	// Recursively check references
	refI, refP := v.Reference()
	if len(refP) > 0 {
		info, err := refI.LookupField(refP...)
		if err != nil {
			// FIXME: report error?
			ui.Error("ERROR LOOKUP UP REFERENCE: %v: %s", refP, err)
			return
		}
		if info.IsDefinition {
			ui.Error("CANNOT FOLLOW REFERENCE TO DEFINITION: %v", refP)
			// FIXME: LookupDef is tricky to use here
		} else {
			ui.Info("Following reference: %v", refP)
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
				ui.Info("Following struct field: %s", it.Label())
				conns = append(conns, scanConnectors(it.Value())...)
			}
		// Recursively check list elements
		case cue.ListKind:
			for it, _ := v.List(); it.Next(); {
				ui.Info("Following list element: %s", it.Label())
				conns = append(conns, scanConnectors(it.Value())...)
			}
	}

	// If `v` is an expression, break it down and recursively inspect each component
	exprOp, exprArgs:= v.Expr()
	if exprOp != cue.NoOp && exprOp != cue.SelectorOp {
		for argIdx, arg := range(exprArgs) {
			// fakeLabel is used for human-friendly path display, only
			ui.Info("Following expression '%v/%d'", exprOp, argIdx)
			conns = append(conns, scanConnectors(arg)...)
		}
	}
	return
}

type Task struct {
	Value cue.Value
	Backend string
}

// Load a task from a single value
func vLookupTask(v cue.Value) (t *Task, err error) {
	var (
		attr cue.Attribute
		backend string
	)
	attr = v.Attribute("task")
	if attr.Err() != nil {
		err = attr.Err()
		return
	}
	backend, err = attr.String(0)
	if err != nil {
		err = errors.Wrap(err, "invalid @task attribute")
		return
	}
	switch backend {
		case "exec":
			t = &Task{
				Backend: backend,
				Value: v,
			}
			ui.Info("task detected, backend=%s: %v", backend, t.Value)
		default:
			err = fmt.Errorf("unsupported task backend: %s", backend)
			ui.Error(err.Error())
	}
	return

}

// Current limitations of the task scanner:
//	- Does not follow references to definitions. Tasks in definitions will not be found, even
//		if a concrete value depends on part of the definition.
//	- @task(exec) must be set after the struct value (embedded attributes are broken ATM)
func lookupTasks(v cue.Value) (tasks []*Task) {
	// Does v have a @task attribute?
	t, err := vLookupTask(v)
	if err == nil {
		ui.Info("TASK DETECTED: %v", v)
		tasks = append(tasks, t)
	}

	// Check for references
	refI, refP := v.Reference()
	if len(refP) > 0 {
		info, err := refI.LookupField(refP...)
		if err != nil {
			// FIXME: report error?
			ui.Error("ERROR LOOKUP UP REFERENCE: %v: %s", refP, err)
			return
		}
		if info.IsDefinition {
			ui.Error("CANNOT FOLLOW REFERENCE TO DEFINITION: %v", refP)
			// FIXME: LookupDef is tricky to use here
		} else {
			ui.Info("Following reference: %v", refP)
			tasks = append(tasks, lookupTasks(refI.Lookup(refP...))...)
		}
		return
	}

	switch v.Kind() {
		// Recursively check struct fields
		case cue.StructKind:
			// Only iterate over "regular" fields (not hidden, eg. definitions)
			for it, _ := v.Fields(); it.Next(); {
				ui.Info("Following struct field: %s", it.Label())
				tasks = append(tasks, lookupTasks(it.Value())...)
			}
		// Recursively check list elements
		case cue.ListKind:
			for it, _ := v.List(); it.Next(); {
				ui.Info("Following list element: %s", it.Label())
				tasks = append(tasks, lookupTasks(it.Value())...)
			}
	}
	// If v is an expression, recursively inspect its component parts
	exprOp, exprArgs:= v.Expr()
	if exprOp != cue.NoOp && exprOp != cue.SelectorOp {
		for argIdx, arg := range(exprArgs) {
			// fakeLabel is used for human-friendly path display, only
			ui.Info("Following expression '%v/%d'", exprOp, argIdx)
			tasks = append(tasks, lookupTasks(arg)...)
		}
	}
	return
}
