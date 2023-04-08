# Install tools and libraries for *FLEA*

## Linux (Ubuntu 22.04 and others)

* Download an [Apple Swift](https://swift.org/download/) release binary for your platform.

* Install the required dependencies for Swift and the Swift binary on your platform
  as listed on [swift.org Linux](https://www.swift.org/download/#linux).

* Install the tools to build and install the parsing library

  ```bash
  $ sudo apt-get install clang make bison flex
  ```

* Install [Yices 2](http://yices.csl.sri.com) headers and library

  ```bash
  $ sudo add-apt-repository ppa:sri-csl/formal-methods
  $ sudo apt-get update
  $ sudo apt-get install yices2-dev
  $ yices --version
  ```

* Install [Z3](https://github.com/Z3Prover/z3/wiki) headers and library

  May already been installed with the developer tools.

  ```bash
  $ sudo apt-get install z3lib-dev
  $ Z3 --version
  ```
  
## Example

### Install developer tools

Please notice that the list of developer tools may differ slightly between different Linux distributions. 

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

$ pkg-config --version
0.29.2

$ clang --versionUbuntu clang version 14.0.0-1ubuntu1
Target: x86_64-pc-linux-gnu
Thread model: posix
InstalledDir: /usr/bin

$ make --versionGNU Make 4.3
GNU Make 4.3

$ bison --version
bison (GNU Bison) 3.8.2

$ flex --version
flex 2.6.4

```

### Install smt headers and libraries


```bash
$ sudo add-apt-repository ppa:sri-csl/formal-methods
$ sudo apt-get update
$ sudo apt-get install yices2-dev

$ yices --version
Yices 2.6.4

$ which yices
/usr/bin/yices

$ find /usr -iname "*yices*" -ls
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

$ find /usr/ -iname "*z3*"
/usr/include/z3_api.h
/usr/bin/z3
/usr/lib/x86_64-linux-gnu/libz3.so.4
/usr/lib/x86_64-linux-gnu/libz3.so
/usr/lib/x86_64-linux-gnu/pkgconfig/z3.pc
```
