# Install tools and libraries for *FLEA*

## Linux (Ubuntu 20.04 LTS, x86_64)

* Install a of list development tools 

```bash
$ apt-get install \
          binutils \
          git \
          gnupg2 \
          libc6-dev \
          libcurl4 \
          libedit2 \
          libgcc-9-dev \
          libpython2.7 \
          libsqlite3-0 \
          libstdc++-9-dev \
          libxml2 \
          libz3-dev \
          pkg-config \
          tzdata \
          uuid-dev \
          zlib1g-dev
```
as listed under https://www.swift.org/getting-started/#installing-swift

* Install [Apple Swift](https://swift.org/download/ )

Follow the instructions on https://www.swift.org/download/#using-downloads 
(scroll down to Linux below Apple Platforms)
and do not forget to put the swift directory into the path variable.

```bash
$ swift --version
Swift version 5.3.2 (swift-5.3.2-RELEASE)
Target: x86_64-unkonwn-linux.gnu
```

* Install additonal tools to build the parsing library
```
% apt-get install clang make bison flex
```

* Install [Yices 2](http://yices.csl.sri.com)

```bash
% sudo add-apt-repository ppa:sri-csl/formal-methods
% sudo apt-get update
% sudo apt-get install yices2
% yices --version
```


* Install [Z3](https://github.com/Z3Prover/z3/wiki), i.e. build from source or download and install binaries

  - [Source Code](https://github.com/Z3Prover/z3)

  - [Releases](https://github.com/Z3Prover/z3/releases)


