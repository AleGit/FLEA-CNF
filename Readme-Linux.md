# Install tools and libraries for *FLEA*

## Linux (Ubuntu 22.04 and others)

* Download an [Apple Swift](https://swift.org/download/) release binary for your platform.

* Install the required dependencies for Swift and the Swift binary on your platform
  as listed on [swift.org](https://www.swift.org/download/#linux).

* Install the tools to build and install the parsing library

  ```bash
  % apt-get install clang make bison flex
  ```

* Install [Yices 2](http://yices.csl.sri.com)

  ```bash
  % sudo add-apt-repository ppa:sri-csl/formal-methods
  % sudo apt-get update
  % sudo apt-get install yices2
  % yices --version
  ```

* Install [Z3](https://github.com/Z3Prover/z3/wiki), i.e.

  * either build it from the [source code](https://github.com/Z3Prover/z3),

  * or install one the [release binaries](https://github.com/Z3Prover/z3/releases).

  ```bash
  % Z3 --version
  ```
