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

var verbose bool = false;

type skyHandlerRoot struct {
	root string
}

func skyHandler(root string) http.Handler {
	return &skyHandlerRoot{root}
}

func (handler *skyHandlerRoot) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if strings.HasPrefix(r.URL.Path, "/.git") {
		w.WriteHeader(http.StatusNotFound)
		return
	}
	path := path.Join(handler.root, r.URL.Path)

        // Remove this one once .sky files are gone:
	if strings.HasSuffix(path, ".sky") {
		w.Header().Set("Content-Type", "text/sky")
	}

	if strings.HasSuffix(path, ".dart") {
		w.Header().Set("Content-Type", "application/dart")
	}
	w.Header().Set("Cache-Control", "no-cache")
	http.ServeFile(w, r, path)
}

func usage() {
	fmt.Fprintf(os.Stderr, "Usage: sky_server [flags] MOJO_SRC_ROOT PACKAGE_ROOT\n")
	fmt.Fprintf(os.Stderr, "Launches a basic http server with mappings into the mojo repository for framework/service paths.\n")
	fmt.Fprintf(os.Stderr, "MOJO_SRC_ROOT must be the root of the Mojo repository.\n")
	fmt.Fprintf(os.Stderr, "PACKAGE_ROOT must be the root of your Dart packages (e.g. out/Debug/gen/dart-pkg/packages/).\n")
	flag.PrintDefaults()
	os.Exit(2)
}

func addMapping(from_path string, to_path string) {
	if (verbose) {
		fmt.Fprintf(os.Stderr, "  %s -> %s\n", from_path, to_path)
	}
	http.Handle(from_path, http.StripPrefix(from_path, skyHandler(to_path)))
}

func setupMappings(mojoRoot string, packageRoot string, port int) {
	if (verbose) {
		fmt.Fprintf(os.Stderr, "Mappings for localhost:%v:\n", port)
		fmt.Fprintf(os.Stderr, "  / -> %s\n", mojoRoot)
	}
	http.Handle("/", skyHandler(mojoRoot))

	if (verbose) {
		fmt.Fprintf(os.Stderr, "  /echo_post -> custom echo handler\n")
	}
	http.HandleFunc("/echo_post", func(w http.ResponseWriter, r *http.Request) {
		defer r.Body.Close()
		body, _ := ioutil.ReadAll(r.Body)
		w.Write(body)
	})

	addMapping("/packages/", packageRoot)
}

func main() {
	var portPtr = flag.Int("p", 8000, "The HTTP port")
	var verbosePtr = flag.Bool("v", false, "Verbose mode. Without this flag, the default behaviour only reports errors.")
	flag.Parse()
	flag.Usage = usage
	if flag.NArg() != 2 {
		usage()
	}

	var port int = *portPtr;
	verbose = *verbosePtr;

	root, _ := filepath.Abs(flag.Arg(0))
	packageRoot := flag.Arg(1)

	setupMappings(root, packageRoot, port);

	http.ListenAndServe(fmt.Sprintf(":%v", port), nil)
}
