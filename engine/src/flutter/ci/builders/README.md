## SUMMARY

Flutter Engine Build Definition Language uses json to describe a complex build using a combination of sub-builds, archives, generators and dependencies. It simplifies sharding by mapping build inputs to workflows listing explicitly the generated artifacts. The build definition language along with the Engine Recipes V2 and the generation of artifacts using GN+Ninja set the groundwork for efficient builds with dependency reusability.  

**Author: Godofredo Contreras (godofredoc)**

**Go Link: flutter.dev/go/engine-build-definition-language**

**Created:** 01/2023   /  **Last updated: **01/2023


## WHAT PROBLEM IS THIS SOLVING?

Engine builds are a complex combination of recipe source code, gn+ninja commands, fuzzy dependencies hidden by running everything in a single builder, and multiple helper scripts using bash and python to generate artifacts combining build system outputs. This complexity is error prone and impacts the velocity of the whole team as adding|removing|updating artifacts require multiple coordinated pull requests and an in-depth knowledge of the engine source code, build system, recipes and infrastructure.

The build definition language targets the following goals: 

 



*   Remove complexity of the engine build system describing the builds in a single place and using a common language.
*   Remove the requirement for engine developers to learn recipes and python.
*   Make slow builds faster with automated and efficient sharding.
*   Add clarity about what a build is doing by clearly defining its components.
*   Simplify builds by separating build, test, generate and archive steps.
*   Get early feedback through presubmit on changes adding/deleting/updating engine artifacts. 


## BACKGROUND

Engine builds use LUCI recipes to build, test and archive artifacts. The workflow requires to checkout the engine repository, run gn, run ninja, create artifacts and upload them to GCS. These steps are implemented differently for different platforms usually by copy/pasting blocks of recipe code. This copy/paste process generated a large and complex [engine.py](https://cs.opensource.google/flutter/recipes/+/main:recipes/engine/engine.py) recipe (2K+ lines of code) which is difficult to update/maintain without breaking the builds.

Having the build logic as a sequence of build steps in a monolithic recipe makes it very difficult to identify dependencies in between sub-builds, sometimes duplicating logic in multiple places and making it very difficult for engineers to add/remove logic. 


#### Audience

Flutter Engine contributors that add/update/remove builds, platforms and artifacts from the build system.


#### Glossary



*   **[recipes](https://github.com/luci/recipes-py)** - domain specific language for specifying sequences of subprocess calls in a cross-platform and testable way.
*   **Generator **- scripts in dart, python or bash that generates artifacts combining the output of sub-builds.
*   **Builder** - a combination of configuration and recipes used with a given commit to build artifacts and test them.
*   **Build** - a builder running with specific properties, repository and commit.
*   **[Gn](https://gn.googlesource.com/gn/)**, a meta-build system that generates build files for [Ninja](https://ninja-build.org/).
*   **[Ninja](https://ninja-build.org)**, Ninja is a small build system with a focus on speed.
*   **CAS**, a service that stores arbitrary binary blobs addressed by (hash of) their content. It is specialized for low latency, high volume query/read/write operations.


## OVERVIEW

To describe engine builds in a generic and scalable way we are creating a build definition language that supports all the current build use cases. The definition language is using json to describe builds, tests, archives, and dependency relations.

This definition language will be used by generic recipes to trigger independent build units in different machines using cas for intermediate storage and an orchestrator recipe that collects and integrates the multiple pieces.

On top of the current use cases the definition language also supports configurations for code signing and describing the artifacts explicitly. These two new use cases are required for the implementation of SLSA requirements and the implementation of a single command Flutter SDK release.

The definition language makes heavy use of GN and Ninja to move most of the build/test/archive logic to the flutter/engine repository. This will help us remove most of the logic from recipes and make the recipes implementation generic and reusable by Dart & Flutter teams.


#### Non-goals

Using a format different from json to describe the engine builds.


## USAGE EXAMPLES

Engine builds will be translated one to one using the build definition language with one file per build. The build definition files will be stored in the [flutter/engine/ci/builders](https://cs.opensource.google/flutter/engine/+/main:ci/builders/) directory.

The [engine orchestrator recipe](https://cs.opensource.google/flutter/recipes/+/main:recipes/engine_v2/) will read the file, shard builds, collect artifacts and upload them to the Google Cloud Storage bucket where they are downloaded by the Flutter Tool.

Ci\_yaml file is the glue sticking all the components together. A new build will be added to the [.ci.yaml](https://cs.opensource.google/flutter/engine/+/main:.ci.yaml) file with a property pointing to the build definition file to be used by engine\_v2 recipes. The following is an example of a build configuration referencing [android\_aot\_engine.json](https://cs.opensource.google/flutter/engine/+/main:ci/builders/mac_android_aot_engine.json):


```
  - name: Mac mac_android_aot_engine
    recipe: engine_v2/engine_v2
    timeout: 60
    properties:
      config_name: mac_android_aot_engine
      $flutter/osx_sdk : >-
        { "sdk_version": "14a5294e" }

```



## DETAILED DESIGN/DISCUSSION

Flutter's LUCI Infrastructure uses the engine build configuration language to build, test and archive the engine artifacts. The goal of the configurations using the build definition language is to move all the build, test and archive logic out of recipes and bring it to the engine repository. 

The following is a non-exhaustive list of the benefits of moving to build configurations files:



*   No need to coordinate changes to recipes, engine and build configurations when adding new builds or artifacts.
*   Adding new artifacts can be tested on presubmit.
*   Having the archive logic in GN ensures the artifacts are created correctly, the expected dependencies are built, and the archives contain only what is generated by the build targets and their dependencies.
*   The builds are simplified to a GN command followed by a ninja command.
*   Artifacts are explicitly described in the configuration allowing post processing tasks like code signing.
*   Scripts used as generators either local or global follow a very simple interface to ensure they can be plugged out of the box in the build system.


### Assumptions

To keep the build definition language simple the following assumptions were made during its design:



*   A build can be expressed as a set of independent sub-builds.
*   A sub-build can be defined as a sequence of gn, ninja, self contained test scripts, self contained generator scripts.
*   All the sub-builds required by a global generator are defined within the same configuration file.


### Build configuration language


#### Build configuration file

The build configuration is a  json file containing a list of builds, tests, generators and archives. The following is an example of an empty configuration file:


```
{
   "builds": [],
   "tests": [],
   "generators": {
       "tasks": []
   },
   "archives": [
   ]
}
```


Build configuration files have to be checked into the engine[/ci/builder](https://github.com/flutter/engine/tree/main/ci/builders) directory where engine v2 recipes will be reading them from.  

A configuration file defines a top level builder that will show up as a column in the [Flutter Dashboard](https://flutter-dashboard.appspot.com/#/build?repo=engine&branch=master).


#### Build

A build is a dictionary with a gn command, a ninja command, zero or more generator commands, zero or more local tests, zero or more local generators and zero or more output artifacts.

The following is the high level structure of the build component:


```
{
           "archives": [],
           "drone_dimensions": [],
           "gclient_variables": {},
           "gn": [],
           "name": "host_debug",
           "ninja": {},
           "tests": []
}
```


Each build element will be translated to an independent sub-build and its entire out directory will be uploaded to CAS. 


##### Archive

An archive component is used to tell the recipes which artifacts are generated by the build and where to upload them.

 


```
{
  "name": "host_debug",
  "base_path": "out/host_debug/zip_archives/",
  "type": "gcs",
  "include_paths": [
     "out/host_debug/zip_archives/linux-x64/artifacts.zip"
  ]
}
```


Description of the fields:



*   **Name:** Used to identify the archive inside CAS.
*   **Base\_path:** The portion of the path to remove before uploading to its destination. In the example the base\_path **“out/host\_debug/zip\_archives”** will be extracted from the include path **"out/host\_debug/zip\_archives/linux-x64/artifacts.zip"** before uploading to GCS, e.g. &lt;bucket>/flutter/&lt;commit>/linux-x64/artifacts.zip.
*   **Type:** The type of storage to use. Currently only **“GCS”** and **“CAS”** are supported. 
*   **Include\_paths:** A list of strings representing paths to artifacts generated by the build that need to be uploaded to a given destination. 


##### Drone\_dimensions

A list of strings with key value pairs separated by an equal sign. These dimensions are used to select the bot where the sub-build will be running.


```
"drone_dimensions": [          "device_type=none",
  "os=Linux"
]
```


In the previous example, the build containing this drone\_dimensions component will run on a bot with a Linux OS that does not have any devices attached to it.


##### Gclient\_variables

A dictionary with the gclient variable as key and its content as value. This dictionary is passed to gclient during a gclient sync operation to add/remove gclient dependencies.


```
"gclient_variables": {
   "download_android_deps": false
}
```


The example above is used to avoid downloading the [android sdk dependencies](https://cs.opensource.google/flutter/engine/+/main:DEPS;l=80) in builders that do not need it.


##### Gn

A list of strings representing flags passed to the [tools/gn](https://cs.opensource.google/flutter/engine/+/master:tools/gn?q=gn&ss=flutter%2Fengine) script. The strings can be in the form of “--flag=value” or “--flag” followed by “value”.


```
"gn": [
               "--runtime-mode",
               "debug",
               "--prebuilt-dart-sdk",
               "--build-embedder-examples"
           ],
```


The previous example will prepare the configurations to build a host debug version using a prebuilt dart sdk and also build the embedder examples. 


##### Ninja

A dictionary with two keys: “config” which references the configs created by gn and “target” which is a list of strings with the Ninja targets to build.


```
"ninja": {
               "config": "host_debug",
               "targets": [
                   "flutter/build/archives:artifacts",
                   "flutter/build/archives:embedder",
               ]
           },
```


In the example above the ninja command will use the configuration for host\_debug and will build artifacts and embedder targets as described by the [flutter/build/archives/BUILD.gn](https://cs.opensource.google/flutter/engine/+/master:build/archives/BUILD.gn) file.

 


##### Tests

This section of the build configuration will be referred to as the local tests. This section contains a list of dictionaries with configurations for the scripts and parameters used to run tests inside the current build unit. These tests should not reference or use anything outside of the commit checkout or the outputs generated by running the gn and ninja sections of the build config. 


```
          "tests": [
            {
                "language": "python3",
                "name": "Host Tests for host_debug_impeller_vulkan",
                "parameters": [
                    "--variant",
                    "host_debug_impeller_vulkan",
                    "--type",
                    "impeller-vulkan",
                    "--engine-capture-core-dump"
                ],
                "script": "flutter/testing/run_tests.py",
                "type": "local"
            }
        ]
```


Description of the fields:



*   **Language,** the executable used to run the script, e.g. python3. 
*   **Name,** the name of the step running the script.
*   **Parameters**, flags or parameters passed to the script.
*   **Script**, the path to the script to execute relative to the checkout directory.
*   **Type**, the test type. (Deprecate? Test on the build config will be always local)

The test scripts will run in a deferred context (failing the step only after logs have been uploaded). The tester and builder recipes provide an environment variable called FLUTTER\_LOGS\_DIR pointing a temporary directory where the test runner can place any logs|artifacts needed to debug issues. At the end of the test execution the content of FLUTTER\_LOGS\_DIR will be uploaded to Google Cloud Storage before signaling the pass | fail test state.

Note that to keep the recipes generic they don’t know anything about what the test script is doing and it is the responsibility of the test script to copy the relevant files to the FLUTTER\_LOGS\_DIR directory.


#### Generators

Generators are scripts used to generate artifacts combining the output of two or more sub-builds. The most common use case is to generate FAT binaries for Mac/iOS artifacts.

Generators can be written in any language but they require to follow some guidance to make them compatible with the engine build system.

The guidelines are as follows:



*   Flags receiving paths to resources from multiple sub-builds need to use paths relative to the checkout directory. If there are global generators in a build configuration, the engine\_v2 recipes will download the full archives of the sub-builds to the checkout/out/&lt;sub-build name> directory.
*   Flags receiving paths to output directories must use paths relative to the out folder. This is to be able to reference the artifacts in the global archives section.
*   The script is in charge of generating the final artifact, e.g. if the script generates multiple files that will be zipped later then it is the script responsibility to generate the final zip.
*   If the generator is producing a Mac/iOS artifact then it is the script responsibility to embed the signing metadata.   

Generators contain a single property “tasks” which is a list of tasks to be performed.


```
"generators": {
        "tasks": []
 }
```


The example above represents a generator configuration with an empty list of tasks.


##### Task

Task is a dictionary describing the scripts to be executed. 

The properties description is as follows:



*   **Name**, the name of the step running the script.
*   **Parameters**, flags passed to the script. Both input and output paths must be relative to the checkout directory.
*   **Script**, the script path relative to the checkout repository.
*   **Language**, the script language executable to run the script. If empty it is assumed to be bash.

    ```
      {
                "name": "Debug-FlutterMacOS.framework",
                "parameters": [
                    "--dst",
                    "out/debug",
                    "--arm64-out-dir",
                    "out/ios_debug",
                    "--simulator-x64-out-dir",
                    "out/ios_debug_sim",
                    "--simulator-arm64-out-dir",
                    "out/ios_debug_sim_arm64"
                ],
                "script": "flutter/sky/tools/create_full_ios_framework.py",
                "language": "python3"
            }
```




#### Archives 

The archives component provides instructions to upload the artifacts generated by the global generators. Is a list of dictionaries with two keys: source and destination. Source is a path relative to the checkout repository and destination is a relative path to &lt;bucket>/flutter/&lt;commit>.


```
    "archives": [
        {
            "source": "out/debug/artifacts.zip",
            "destination": "ios/artifacts.zip"
        },
        {
            "source": "out/debug/ios-objcdoc.zip",
            "destination": "ios-objcdoc.zip"
        }
    ]
```


The example above will cause the file &lt;checkout>/out/debug/artifacts.zip to be uploaded &lt;bucket>/flutter/&lt;commit>/ios/artifacts.zip.


### ACCESSIBILITY

N/A


### INTERNATIONALIZATION

N/A.


### INTEGRATION WITH EXISTING FEATURES

The build definition language will force all the artifacts to be generated with GN+Ninja. This will require a carefully designed strategy to replace the artifacts with minimal disruption.

A migration to simpler and more scalable recipes will be required to achieve all the goals of the build definition language. A deprecation of the old recipes will be also necessary to remove all the technical debt.

From the developers point of view we can expect some disruption with multiple land -> revert -> re-land cycles. For Flutter users there will be no difference as they will receive the same files with the same content even though they are generated differently. 


## OPEN QUESTIONS



*   Once the build definition language is feature complete should it use protos rather than json? Is the effort worthy?


## TESTING PLAN

Configuration files will be created and used with builders running in parallel to the production ones. The builders using the new build configuration files will run on the staging environment for several weeks before moving them to production.

The artifacts generated by GN+Ninja will be released  with the old recipes to ensure their content is correct and complete.

Artifacts generated by builders using the configuration language will be using GN+Ninja artifacts exclusively. Once all those artifacts are validated with the old recipes the builds using the configuration language will be moved to production and the old recipes deprecated and removed.


## DOCUMENTATION PLAN

The main purpose of this document is to describe the build definition language. Once it has been reviewed most of the content of this document will be adapted to markup and will be merged along the build configuration files in the engine repository.

This document, the document describing [GN+Ninja artifacts](https://flutter.dev/go/gn-ninja-engine-artifacts), the document describing the engine v2 recipes and the document with the plan to speed up engine builds will be added to the flutter wiki page.


## MIGRATION PLAN

The migration to use the build definition language depends on the release | validation of the GN + Ninja artifacts. Once that part is complete two changes will need to be coordinated:



*   A change in the engine repository to remove the old build configurations from .ci.yaml file and updating the artifact destination in the builds using the build definition language will be landed.
*   A change to remove old recipes will be landed in the recipes repository. 
