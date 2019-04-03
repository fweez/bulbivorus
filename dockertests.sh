#!/bin/sh

docker run --privileged -i -t -v /Users/ryan/projects/bulbivorus:/bulbivorus --rm --name swifttest swift:5.0 /bulbivorus/linuxtests.sh
