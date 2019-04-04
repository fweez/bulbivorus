# Bulbivorus: A Gopher server written in Swift

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

Without a config file, `bulbivorus` uses `/var/gopherhole` as the root directory. You can copy the project's `bulbivorus-config.example.json` into `bulbivorus-config.json` in the directory you start `bulbivorus` from to modify its behavior. You might change the default route's root to a `gopherhole` directory in your home directory, for instance. See below for more information on the settings available to you.

New to gopher? See [this excellent guide](https://davebucklin.com/play/2018/03/31/how-to-gopher.html) to learn how to create a gopherhole.

### Configuration file, annotated:
```text
{
    "port": 70, // The port to run the server on. 70 is default for gopher
    
    "routes": [ // A list of configuration structures for the request handlers you'd like to use
                // Routes should be ordered in most specific to least specific, as the first match
                // will be used. So:
                // A list of routes with requestMatches in this order:
                // ["/hi.*", "/hilarious", "/.*"]
                // Will fire the first route on "/hilarious", and the last route on "/funny", and
                // never fire the second route.
     
                // A list of matches like:
                // ["/hilarious", "/hi.*", "/.*"]
                // Would fire the first route on "/hilarious", the second on "/hilarity", and the
                // last on "/funny"
        { 
            "kind": "file", // This is a basic file handler route; ie, it serves files like a normal gopher server
            "requestMatch": ".*", // All requests that get here use this configuration
            "handlerConfiguration": {
                // And the file handler will serve file requests out of this directory:
                "root": "/Users/ryan/gopherhole"
            }
        }
    ]
}
```

## Why on earth did you waste your time doing this?

I wanted to learn how hard it was to do cross-platform Swift development. Turns out, it's not hard! The open source Foundation's `FileManager` is lacking a ton of features that the closed-source version has, which can be annoying. Installing the `swift` compiler into a real linux install is also absolute garbage, I cannot figure out why there isn't an official apt repository for Ubuntu. Testing is also much more annoying than it needs to be -- copying the test names into `allTests` in each `XCTestCase` feels super clumsy.

## What the heck does "bulbivorus" mean?

> The camas pocket gopher (Thomomys bulbivorus), also known as the camas rat or Willamette Valley gopher, is a rodent, the largest member in the genus Thomomys, of the family Geomyidae. First described in 1829, it is endemic to the Willamette Valley of northwestern Oregon in the United States.

[wikipedia](https://en.wikipedia.org/wiki/Camas_pocket_gopher)
