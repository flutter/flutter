// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package tests

import (
	"fmt"
	"sync"
	"testing"

	"mojo/public/go/application"
	"mojo/public/go/bindings"

	"examples/echo/echo"
	mojoApp "mojo/public/interfaces/application/application"
	sp "mojo/public/interfaces/application/service_provider"
	"mojo/public/interfaces/application/shell"
)

var urls = [2]string{"first.example.com", "second.example.com"}

func pairedURL(url string) string {
	switch url {
	case urls[0]:
		return urls[1]
	case urls[1]:
		return urls[0]
	default:
		panic(fmt.Sprintf("unexpected URL %v", url))
	}
}

func checkEcho(echoPointer echo.Echo_Pointer) {
	echo := echo.NewEchoProxy(echoPointer, bindings.GetAsyncWaiter())
	str := fmt.Sprintf("Hello, world")
	response, err := echo.EchoString(&str)
	if err != nil {
		panic(err)
	}
	if *response != str {
		panic(fmt.Sprintf("invalid response: want %v, got %v", str, *response))
	}
	echo.Close_Proxy()
}

type EchoImpl struct{}

func (echo *EchoImpl) EchoString(inValue *string) (outValue *string, err error) {
	return inValue, nil
}

// EchoDelegate implements mojo application. In this test configuration we
// have two instances of this implementation that talk to each other.
type EchoDelegate struct {
	Wg       *sync.WaitGroup
	localURL string
}

func (delegate *EchoDelegate) Create(request echo.Echo_Request) {
	stub := echo.NewEchoStub(request, &EchoImpl{}, bindings.GetAsyncWaiter())
	go func() {
		if err := stub.ServeRequest(); err != nil {
			panic(err)
		}
		stub.Close()
		delegate.Wg.Done()
	}()
}

// Initialize connects to other instance, providing and asking for echo service.
func (delegate *EchoDelegate) Initialize(ctx application.Context) {
	if ctx.URL() != delegate.localURL {
		panic(fmt.Sprintf("invalid URL: want %v, got %v", delegate.localURL, ctx.URL()))
	}
	if len(ctx.Args()) != 1 || ctx.Args()[0] != delegate.localURL {
		panic(fmt.Sprintf("invalid args: want %v, got %v", []string{delegate.localURL}, ctx.Args()))
	}
	go func() {
		echoRequest, echoPointer := echo.CreateMessagePipeForEcho()
		conn := ctx.ConnectToApplication(pairedURL(delegate.localURL), &echo.Echo_ServiceFactory{delegate})
		if conn.RequestorURL() != delegate.localURL {
			panic(fmt.Sprintf("invalid requestor URL: want %v, got %v", delegate.localURL, conn.RequestorURL()))
		}
		if conn.ConnectionURL() != pairedURL(delegate.localURL) {
			panic(fmt.Sprintf("invalid connection URL: want %v, got %v", pairedURL(delegate.localURL), conn.ConnectionURL()))
		}
		conn.ConnectToService(&echoRequest)
		checkEcho(echoPointer)
	}()
}

// AcceptConnection accepts incoming connection, providing and asking for echo
// service.
func (delegate *EchoDelegate) AcceptConnection(conn *application.Connection) {
	if conn.RequestorURL() != pairedURL(delegate.localURL) {
		panic(fmt.Sprintf("invalid requestor URL: want %v, got %v", pairedURL(delegate.localURL), conn.RequestorURL()))
	}
	if conn.ConnectionURL() != delegate.localURL {
		panic(fmt.Sprintf("invalid connection URL: want %v, got %v", delegate.localURL, conn.ConnectionURL()))
	}
	echoRequest, echoPointer := echo.CreateMessagePipeForEcho()
	conn.ProvideServices(&echo.Echo_ServiceFactory{delegate}).ConnectToService(&echoRequest)
	checkEcho(echoPointer)
}

func (delegate *EchoDelegate) Quit() {}

// shellImpl forward connection from local EchoDelegate instance to remote.
type shellImpl struct {
	remoteApp *mojoApp.Application_Proxy
	localURL  string
}

func (s *shellImpl) ConnectToApplication(URL string, services *sp.ServiceProvider_Request, exposedServices *sp.ServiceProvider_Pointer) error {
	if URL != pairedURL(s.localURL) {
		return fmt.Errorf("invalid URL: want %v, got %v", pairedURL(s.localURL), URL)
	}
	s.remoteApp.AcceptConnection(s.localURL, services, exposedServices, pairedURL(s.localURL))
	return nil
}

func TestApplication(t *testing.T) {
	var apps []*mojoApp.Application_Proxy
	var responsesSent, appsTerminated sync.WaitGroup
	// Create and run applications.
	for i := 0; i < 2; i++ {
		request, pointer := mojoApp.CreateMessagePipeForApplication()
		apps = append(apps, mojoApp.NewApplicationProxy(pointer, bindings.GetAsyncWaiter()))
		// Each app instance provides echo service once when it creates
		// a connection and once other instance creates a connection.
		responsesSent.Add(2)
		appsTerminated.Add(1)
		delegate := &EchoDelegate{&responsesSent, urls[i]}
		go func() {
			application.Run(delegate, request.PassMessagePipe().ReleaseNativeHandle())
			appsTerminated.Done()
		}()
	}
	// Provide a shell for each application.
	for i := 0; i < 2; i++ {
		shellRequest, shellPointer := shell.CreateMessagePipeForShell()
		shellStub := shell.NewShellStub(shellRequest, &shellImpl{apps[i^1], urls[i]}, bindings.GetAsyncWaiter())
		go func() {
			if err := shellStub.ServeRequest(); err != nil {
				panic(err)
			}
			shellStub.Close()
		}()
		apps[i].Initialize(shellPointer, &[]string{urls[i]}, urls[i])
	}
	// Wait and then close pipes.
	responsesSent.Wait()
	for i := 0; i < 2; i++ {
		apps[i].RequestQuit()
	}
	appsTerminated.Wait()
	for i := 0; i < 2; i++ {
		apps[i].Close_Proxy()
	}
}
