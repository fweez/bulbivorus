# Bulbivorus: A high-performance Gopher server written in Swift

## Building bulbivorus

### macOS with Xcode 10.2 or better

Just open the `bulbivorus.xcodeproj` and build the `bulbivorus` target. Move the built product anywhere you'd like, and run it.

### macOS or Linux with Swift 5.0 command line tools

`swift build`

Copy the built product (which is probably in `./.build/x86_64-apple-macosx/debug/bulbivorus`) somewhere and run it.

### Building and running in a Docker instance

At the root project directory, and assuming it's shareable to docker images:
```
$ docker run --privileged -i -t \
-v ./bulbivorus:/bulbivorus --name bulbivorus swift:5.0 /bin/bash
root@f5b46befff98:/# cd /bulbivorus/
root@f5b46befff98:/bulbivorus# ls
1                 Sources                         bulbivorus.xcodeproj  linuxtests.sh~
LICENSE           Tests                           dockertests.sh        linuxtests_results.txt
Package.resolved  bulbivorus-config.example.json  dockertests.sh~       out.txt
Package.swift     bulbivorus.playground           linuxtests.sh
root@f5b46befff98:/bulbivorus# swift build
[5/5] Linking ./.build/x86_64-unknown-linux/debug/bulbivorus
root@f5b46befff98:/bulbivorus# ./.build/x86_64-unknown-linux/debug/bulbivorus
```

_TODO: An actual real live Dockerfile_

## Using bulbivorus

Without a config file, `bulbivorus` uses `/var/gopherhole` as the root directory. You can copy the project's `bulbivorus-config.example.json` into `bulbivorus-config.json` in the directory you start bulbivorus from to modify its behavior. You might change the default route's root to a `gopherhole` directory in your home directory, for instance. See that file for more information on the settings available to you.

New to gopher? See [this excellent guide](https://davebucklin.com/play/2018/03/31/how-to-gopher.html) to learn how to create a gopherhole.
