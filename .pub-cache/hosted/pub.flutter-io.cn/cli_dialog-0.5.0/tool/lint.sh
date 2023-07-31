#!/bin/bash

cd  "$( dirname ${BASH_SOURCE[0]} )"/..
dartfmt -w . | grep Formatted
dartanalyzer .