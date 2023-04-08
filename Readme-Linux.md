# Install tools and libraries for *FLEA*

## Linux (Ubuntu 22.04 and others)

* Download an [Apple Swift](https://swift.org/download/) release binary for your platform.

* Install the required dependencies for Swift and the Swift binary on your platform
  as listed on [swift.org](https://www.swift.org/download/#linux).

* Install the tools to build and install the parsing library

  ```bash
  % sudo apt-get install clang make bison flex
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
  
## Example

### Install developer tools

Please notice that the to be installe developer tools differs slightly differren distributions of Linux. 

```bash 
$ sudo apt-get install \
    binutils \
    git \
    gnupg2 \
    libc6-dev \
    libcurl4-openssl-dev \
    libedit2 \
    libgcc-9-dev \
    libpython3.8 \
    libsqlite3-0 \
    libstdc++-9-dev \
    libxml2-dev \
    libz3-dev \
    pkg-config \
    tzdata \
    unzip \
    zlib1g-dev
  
$ sudo apt-get install clang make bison flex
```

### Install smt libraries


```bash
$ sudo add-apt-repository ppa:sri-csl/formal-methods
$ sudo apt-get update
$ sudo apt-get install yices2
$ sudo apt-get install yices2-dev

$ yices --version
Yices 2.6.4
Copyright SRI International.
Linked with GMP 6.2.1
Copyright Free Software Foundation, Inc.
Build date: 2021-12-20
Platform: x86_64-linux-gnu (release)

$ which yices
/usr/bin/yices

$ find /usr -iname "*yices*"
/usr/include/yices.h
/usr/include/yices_limits.h
/usr/include/yices_types.h
/usr/include/yices_exit_codes.h

/usr/bin/yices-smt
/usr/bin/yices-sat
/usr/bin/yices-smt2
/usr/bin/yices

/usr/lib/x86_64-linux-gnu/libyices.so.2.6
/usr/lib/x86_64-linux-gnu/libyices.so.2.6.4
/usr/lib/x86_64-linux-gnu/libyices.so



$ sudo apt-get install libz3-dev

$ $ z3 --version
Z3 version 4.8.12 - 64 bit
alexander@ThinkPad-X240:~/z3/build$ which z3
/usr/bin/z3
alexander@ThinkPad-X240:~/z3/build$ find /usr/ -iname "*z3*"

/usr/include/z3_fixedpoint.h
/usr/include/z3_spacer.h
/usr/include/z3_rcf.h
/usr/include/z3_macros.h
/usr/include/z3_algebraic.h
/usr/include/z3_fpa.h
/usr/include/z3_v1.h
/usr/include/z3_api.h
/usr/include/z3.h
/usr/include/z3_optimization.h
/usr/include/z3++.h
/usr/include/z3_version.h
/usr/include/z3_polynomial.h
/usr/include/z3_ast_containers.h

/usr/bin/z3

/usr/lib/x86_64-linux-gnu/libz3.so.4
/usr/lib/x86_64-linux-gnu/libz3.so
/usr/lib/x86_64-linux-gnu/pkgconfig/z3.pc
```
