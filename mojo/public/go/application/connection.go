// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package application

import (
	"log"

	"mojo/public/go/bindings"
	"mojo/public/go/system"

	sp "mojo/public/interfaces/application/service_provider"
)

type connectionInfo struct {
	requestorURL  string
	connectionURL string
}

// RequestorURL returns the URL of application that established the connection.
func (c *connectionInfo) RequestorURL() string {
	return c.requestorURL
}

// ConnectionURL returns the URL that was used by the source application to
// establish a connection to the destination application.
func (c *connectionInfo) ConnectionURL() string {
	return c.connectionURL
}

// ServiceRequest is an interface request for a specified mojo service.
type ServiceRequest interface {
	// Name returns the name of requested mojo service.
	Name() string

	// PassMessagePipe passes ownership of the underlying message pipe
	// handle to the newly created handle object, invalidating the
	// underlying handle object in the process.
	PassMessagePipe() system.MessagePipeHandle
}

// ServiceFactory provides implementation of a mojo service.
type ServiceFactory interface {
	// Name returns the name of provided mojo service.
	Name() string

	// Create binds an implementation of mojo service to the provided
	// message pipe and runs it.
	Create(pipe system.MessagePipeHandle)
}

// Connection represents a connection to another application. An instance of
// this struct is passed to Delegate's AcceptConnection() function each time a
// connection is made to this application.
type Connection struct {
	connectionInfo
	// Request for local services. Is valid until ProvideServices is called.
	servicesRequest *sp.ServiceProvider_Request
	// Indicates that ProvideServices function was already called.
	servicesProvided   bool
	localServices      *bindings.Stub
	outgoingConnection *OutgoingConnection
	isClosed           bool
}

func newConnection(requestorURL string, services *sp.ServiceProvider_Request, exposedServices *sp.ServiceProvider_Pointer, resolvedURL string) *Connection {
	info := connectionInfo{
		requestorURL,
		resolvedURL,
	}
	var remoteServices *sp.ServiceProvider_Proxy
	if exposedServices != nil {
		remoteServices = sp.NewServiceProviderProxy(*exposedServices, bindings.GetAsyncWaiter())
	}
	return &Connection{
		connectionInfo:  info,
		servicesRequest: services,
		outgoingConnection: &OutgoingConnection{
			info,
			remoteServices,
		},
	}
}

// ProvideServices starts a service provider on a separate goroutine that
// provides given services to the remote application. Returns a pointer to
// outgoing connection that can be used to connect to services provided by
// remote application.
// Panics if called more than once.
func (c *Connection) ProvideServices(services ...ServiceFactory) *OutgoingConnection {
	if c.servicesProvided {
		panic("ProvideServices can be called only once")
	}
	c.servicesProvided = true
	if c.servicesRequest == nil {
		return c.outgoingConnection
	}
	if len(services) == 0 {
		c.servicesRequest.PassMessagePipe().Close()
		return c.outgoingConnection
	}

	provider := &serviceProviderImpl{
		make(map[string]ServiceFactory),
	}
	for _, service := range services {
		provider.AddService(service)
	}
	c.localServices = sp.NewServiceProviderStub(*c.servicesRequest, provider, bindings.GetAsyncWaiter())
	go func() {
		for {
			if err := c.localServices.ServeRequest(); err != nil {
				connectionError, ok := err.(*bindings.ConnectionError)
				if !ok || !connectionError.Closed() {
					log.Println(err)
				}
				break
			}
		}
	}()
	return c.outgoingConnection
}

// Close closes both incoming and outgoing parts of the connection.
func (c *Connection) Close() {
	if c.servicesRequest != nil {
		c.servicesRequest.Close()
	}
	if c.localServices != nil {
		c.localServices.Close()
	}
	if c.outgoingConnection.remoteServices != nil {
		c.outgoingConnection.remoteServices.Close_Proxy()
	}
	c.isClosed = true
}

// OutgoingConnection represents outgoing part of connection to another
// application. In order to close it close the |Connection| object that returned
// this |OutgoingConnection|.
type OutgoingConnection struct {
	connectionInfo
	remoteServices *sp.ServiceProvider_Proxy
}

// ConnectToService asks remote application to provide a service through the
// message pipe endpoint supplied by the caller.
func (c *OutgoingConnection) ConnectToService(request ServiceRequest) {
	pipe := request.PassMessagePipe()
	if c.remoteServices == nil {
		pipe.Close()
		return
	}
	c.remoteServices.ConnectToService(request.Name(), pipe)
}

// serviceProviderImpl is an implementation of mojo ServiceProvider interface.
type serviceProviderImpl struct {
	factories map[string]ServiceFactory
}

// Mojo ServiceProvider implementation.
func (sp *serviceProviderImpl) ConnectToService(name string, messagePipe system.MessagePipeHandle) error {
	factory, ok := sp.factories[name]
	if !ok {
		messagePipe.Close()
		return nil
	}
	factory.Create(messagePipe)
	return nil
}

func (sp *serviceProviderImpl) AddService(factory ServiceFactory) {
	sp.factories[factory.Name()] = factory
}
