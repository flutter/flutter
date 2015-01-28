// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package main

import (
    "flag"
    "fmt"
    "io/ioutil"
    "net/http"
    "os"
    "path"
    "path/filepath"
    "strings"
)

type skyHandlerRoot struct {
    root string
}

func skyHandler(root string) http.Handler {
    return &skyHandlerRoot{root}
}

func (handler *skyHandlerRoot) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    path := path.Join(handler.root, r.URL.Path)
    if strings.HasSuffix(path, ".sky") {
        w.Header().Set("Content-Type", "text/sky")
    }
    http.ServeFile(w, r, path)
}

func usage() {
    fmt.Fprintf(os.Stderr, "Usage: sky_server [flags] MOJO_SRC_ROOT PORT\n\n")
    fmt.Fprintf(os.Stderr, "launches a basic http server with mappings into the\n")
    fmt.Fprintf(os.Stderr, "mojo repository for framework/service paths.\n")
    fmt.Fprintf(os.Stderr, "[flags] MUST be before arguments, because go:flag.\n\n")
    flag.PrintDefaults()
    os.Exit(2)
}

func addMapping(from_path string, to_path string) {
    // Print to stderr to it's more obvious what this binary does.
    fmt.Fprintf(os.Stderr, "  %s -> %s\n", from_path, to_path)
    http.Handle(from_path, http.StripPrefix(from_path, skyHandler(to_path)))
}

func main() {
    var configuration = flag.String("t", "Release", "The target configuration (i.e. Release or Debug)")

    flag.Parse()
    flag.Usage = usage
    // The built-in go:flag is awful.  It only allows short-name arguments
    // and they *must* be before any unnamed arguments.  There are better ones:
    // https://godoc.org/github.com/jessevdk/go-flags
    // but for now we're using raw-go.
    if flag.NArg() != 2 {
        usage()
    }

    root, _ := filepath.Abs(flag.Arg(0))
    port := flag.Arg(1)

    genRoot := path.Join(root, "out", *configuration, "gen")

    fmt.Fprintf(os.Stderr, "Mappings for localhost:%s:\n", port)

    fmt.Fprintf(os.Stderr, "  / -> %s\n", root)
    http.Handle("/", skyHandler(root))

    fmt.Fprintf(os.Stderr, "  /echo_post -> custom echo handler\n")
    http.HandleFunc("/echo_post", func(w http.ResponseWriter, r *http.Request) {
        defer r.Body.Close()
        body, _ := ioutil.ReadAll(r.Body)
        w.Write(body)
    })

    addMapping("/gen/", genRoot)

    http.ListenAndServe(":" + port, nil)
}
