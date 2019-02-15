SET CIRRUS_TAG 2>Nul | Findstr/I "."
IF ERRORLEVEL 1 SET TAG=latest ELSE TAG=%CIRRUS_TAG%

# pull to make sure we are not rebuilding for nothing
docker pull "gcr.io/flutter-cirrus/win-android-image:%TAG%"

docker build --tag "gcr.io/flutter-cirrus/win-android-image:%TAG%" .
