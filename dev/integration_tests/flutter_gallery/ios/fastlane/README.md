FastLane documentation
================
This folder contains hermetic scripts to re-build the app using a distribution
profile and then deploy to TestFlight.

This is done using the [FastLane](https://fastlane.tools) tool suite.

Deployment can be done manually by Googlers by following
go/flutter-gallery-publish (internal doc).

Deployment is automatically done by Cirrus on tagged branch commits.

## How to renew the Apple distribution certificate

In case the distribution certifcate expires, for example, this error message
occured: "Your certificate ... is not valid, please check end date and
renew it if necessary", a Googler can renew it by following the instructions at
http://go/googler-flutter-signing#how-to-renew.
