## Fork of MaciASL for command line 'patchmatic' by RehabMan

After SJ_Underwater released his ACPI IDE, MaciASL, I immediately wanted to prepare a version of the embedded DSDT patching code into a command line application which could be used for automated DSDT patching from scripts or PKG installers, such as the ProBook Installer.

Since I had no experience writing Objective-C code, I was a bit hesitant to take on the task.  But given that it seemed no one else was interested in taking it on, I eventually decided to learn enough Objective-C and OS X "Foundation" framework to give it a try.  The result is 'patchmatic' a command line version of MaciASL's patching functionality.

Mostly the changes to MaciASL source code are minimal, as the patchmatic has its own PCH (pre-compiled header).  Mostly a few #ifdefs and changes to the project file to allow for the additional 'patchmatic' target, plus main.m which is the command line driver to the patch classes.

Because I wanted it to work on ML, Lion, and SL, there is a NSRegularExpression shim which utilizes open-source RegexKitLite.  If you build to target OS X 10.6, it uses this shim.  If you build to target OS X 10.7 or greater it uses the built-in NSRegularExpression provided by the OS (the code for RegexKitLite is still compiled in unless you remove those files from the patchmatic target). Please note the shim is incomplete, as I only implemented the NSRegularExpression features that MaciASL is using (well, there is a few 'easy' extras implemented, but the more involved methods that are not being used are not implemented).

A note about changes to MaciASL itself: You can also build the MaciASL.app from this repo.  It contains a few changes to SJ's MaciASL.  In particular: autosaves are disabled (I find that feature incredibly annoying/buggy), syntax color highlighting is turned off (I find it too slow), and there are some improvements to the algorithm used for automatic indenting of patch output.

Forked from the following repo: git://git.code.sf.net/p/maciasl/code


### How to Install:

This is a command line binary, so you can run it directly or copy to your /usr/local/bin:

```
cp patchmatic /usr/local/bin/patchmatic
```

Usage can be displayed by running the program with no arguments.


### Downloads:

Downloads are available on Bitbucket:

https://bitbucket.org/RehabMan/os-x-maciasl-patchmatic/downloads/

Note: Archived (old) downloads are available on Google Code:

https://code.google.com/p/os-x-maciasl-patchmatic/downloads/list


### Feedback

You can use the following thread for questions and to find out more about MaciASL or patchmatic:

http://www.tonymacx86.com/dsdt/83565-native-dsdt-aml-ide-compiler-maciasl-open-beta.html


### Build Environment

My build environment is currently Xcode 6.1, using SDK 10.8, targeting OS X 10.6.

No other build environment is supported.

There is a 'makefile' provided if you wish to do command line builds.  The 'makefile' will build both patchmatic and MaciASL.app.   You can install it to the standard places using 'make install'


### 32-bit Builds

Because this project uses ARC, 32-bit builds are not supported.


### Source Code:

The source code is maintained at the following sites:

https://code.google.com/p/os-x-maciasl-patchmatic/

https://github.com/RehabMan/OS-X-MaciASL-patchmatic


### Change Log:

2016-03-12

- Switched ACPI 5.1 -> ACPI 6.1


2014-10-14

- Merged with latest MaciASL from SJ...

- Includes latest iasl build from Intel in iasl5

- Added "-extract" feature to patchmatic


2013-04-07

- Initial publication.


### Credits:

RehabMan for patchmatic
SJ_Underwater for coding MaciASL in the first place.
John Engelhart the author of RegexKit.
