// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package application

import (
	"log"
	"sync"

	"mojo/public/go/bindings"
	"mojo/public/go/system"

	"mojo/public/interfaces/application/application"
	sp "mojo/public/interfaces/application/service_provider"
	"mojo/public/interfaces/application/shell"
)

// Delegate is an interface that your mojo application should implement.
// All methods are called from the same goroutine to make sure that order of
// calls matches the order of messages sent to underlying message pipe.
type Delegate interface {
	// Initialize is called exactly once before any other method.
	Initialize(ctx Context)

	// AcceptConnection is called when another application attempts to open
	// a connection to this application. Close the connection if you no
	// longer need it.
	AcceptConnection(connection *Connection)

	// Quit is called to request the application shut itself down
	// gracefully.
	Quit()
}

// Context is an interface to information about mojo application environment.
type Context interface {
	// URL returns the URL the application was found at, after all mappings,
	// resolution, and redirects.
	URL() string

	// Args returns a list of initial configuration arguments, passed by the
	// Shell.
	Args() []string

	// ConnectToApplication requests a new connection to an application. You
	// should pass a list of services you want to provide to the requested
	// application.
	ConnectToApplication(remoteURL string, providedServices ...ServiceFactory) *OutgoingConnection

	// Close closes the main run loop for this application.
	Close()
}

// ApplicationImpl is an utility class for communicating with the Shell, and
// providing Services to clients.
type ApplicationImpl struct {
	shell *shell.Shell_Proxy
	args  []string
	url   string
	// Pointer to the stub that runs this instance of ApplicationImpl.
	runner   *bindings.Stub
	quitOnce sync.Once

	delegate Delegate
	// Protects connections, that can be modified concurrently because of
	// ConnectToApplication calls.
	mu          sync.Mutex
	connections []*Connection
}

// Run binds your mojo application to provided message pipe handle and runs it
// until the application is terminated.
func Run(delegate Delegate, applicationRequest system.MojoHandle) {
	messagePipe := system.GetCore().AcquireNativeHandle(applicationRequest).ToMessagePipeHandle()
	appRequest := application.Application_Request{bindings.NewMessagePipeHandleOwner(messagePipe)}
	impl := &ApplicationImpl{
		delegate: delegate,
	}
	stub := application.NewApplicationStub(appRequest, impl, bindings.GetAsyncWaiter())
	impl.runner = stub
	for {
		if err := stub.ServeRequest(); err != nil {
			connectionError, ok := err.(*bindings.ConnectionError)
			if !ok || !connectionError.Closed() {
				log.Println(err)
			}
			impl.RequestQuit()
			break
		}
	}
}

// Mojo application implementation.
func (impl *ApplicationImpl) Initialize(shellPointer shell.Shell_Pointer, args *[]string, url string) error {
	impl.shell = shell.NewShellProxy(shellPointer, bindings.GetAsyncWaiter())
	if args != nil {
		impl.args = *args
	}
	impl.url = url
	impl.delegate.Initialize(impl)
	return nil
}

// Mojo application implementation.
func (impl *ApplicationImpl) AcceptConnection(requestorURL string, services *sp.ServiceProvider_Request, exposedServices *sp.ServiceProvider_Pointer, resolvedURL string) error {
	connection := newConnection(requestorURL, services, exposedServices, resolvedURL)
	impl.delegate.AcceptConnection(connection)
	impl.addConnection(connection)
	return nil
}

// Mojo application implementation.
func (impl *ApplicationImpl) RequestQuit() error {
	impl.quitOnce.Do(func() {
		impl.delegate.Quit()
		impl.mu.Lock()
		for _, c := range impl.connections {
			c.Close()
		}
		impl.mu.Unlock()
		impl.shell.Close_Proxy()
		impl.runner.Close()
	})
	return nil
}

// Context implementaion.
func (impl *ApplicationImpl) URL() string {
	return impl.url
}

// Context implementaion.
func (impl *ApplicationImpl) Args() []string {
	return impl.args
}

// Context implementaion.
func (impl *ApplicationImpl) ConnectToApplication(remoteURL string, providedServices ...ServiceFactory) *OutgoingConnection {
	servicesRequest, servicesPointer := sp.CreateMessagePipeForServiceProvider()
	exposedServicesRequest, exposedServicesPointer := sp.CreateMessagePipeForServiceProvider()
	if err := impl.shell.ConnectToApplication(remoteURL, &servicesRequest, &exposedServicesPointer); err != nil {
		log.Printf("can't connect to %v: %v", remoteURL, err)
		// In case of error message pipes sent through Shell are closed and
		// the connection will work as if the remote application closed
		// both ServiceProvider's pipes.
	}
	connection := newConnection(impl.url, &exposedServicesRequest, &servicesPointer, remoteURL)
	impl.addConnection(connection)
	return connection.ProvideServices(providedServices...)
}

func (impl *ApplicationImpl) Close() {
	impl.RequestQuit()
}

// addConnection appends connections slice by a provided connection, removing
// connections that have been closed.
func (impl *ApplicationImpl) addConnection(c *Connection) {
	impl.mu.Lock()
	i := 0
	for i < len(impl.connections) {
		if impl.connections[i].isClosed {
			last := len(impl.connections) - 1
			impl.connections[i] = impl.connections[last]
			impl.connections[last] = nil
			impl.connections = impl.connections[:last]
		} else {
			i++
		}
	}
	if !c.isClosed {
		impl.connections = append(impl.connections, c)
	}
	impl.mu.Unlock()
}
