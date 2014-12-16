// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package main

import (
    "flag"
    "io/ioutil"
    "net/http"
    "path"
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

func main() {
    var configuration = flag.String("t", "Release", "The target configuration (i.e. Release or Debug)")
    flag.Parse()

    args := flag.Args()
    root := args[0]
    port := args[1]

    genRoot := path.Join(root, "out", *configuration, "gen")

    http.Handle("/", skyHandler(root))
    http.HandleFunc("/echo_post", func(w http.ResponseWriter, r *http.Request) {
        defer r.Body.Close()
        body, _ := ioutil.ReadAll(r.Body)
        w.Write(body)
    })
    http.Handle("/mojo/public/", http.StripPrefix("/mojo/public/", skyHandler(path.Join(genRoot, "mojo", "public"))))
    http.Handle("/mojo/services/", http.StripPrefix("/mojo/services/", skyHandler(path.Join(genRoot, "mojo", "services"))))
    http.Handle("/sky/services/", http.StripPrefix("/sky/services/", skyHandler(path.Join(genRoot, "sky", "services"))))

    http.ListenAndServe(":" + port, nil)
}
