# Install tools and libraries for *FLEA*

## Linux (Ubuntu and others)

* Install the required dependencies for Swift and the Swift binary on your platform
  as listed on [swift.org Linux](https://www.swift.org/download/#linux).

* Install the tools to build and install the parsing library

  ```bash
  sudo apt-get install clang make bison flex
  ```

* Install the [Yices 2](http://yices.csl.sri.com) library and header files

  ```bash
  sudo add-apt-repository ppa:sri-csl/formal-methods
  sudo apt-get update
  sudo apt-get install yices2-dev
  ```

* Install the [Z3](https://github.com/Z3Prover/z3/wiki) library and header files

  ```bash
  sudo apt-get install z3lib-dev
  ```

* Download and install an [Apple Swift](https://swift.org/download/) release binary for your platform as described.

* Download and install the tptp parsing library and pkg-config files for Yices, Z3Api and TptpParsing libraries.

  The `swift build` process will be able to link the libraries if the pkg-config files are installed correctly.

  * Download the tptp parsing library sources and the pkg-config files

    ```bash
    git clone https://github.com/AleGit/CTptpParsing
    ```

  * Check if the paths in file `CTptpParsing/Linux/PkgConfig/Yices.pc`

    ```conf
    libdir=/usr/lib/x86_64-linux-gnu/
    includedir=/usr/include/
    ```

    match the actual paths for the Yices library file `libyices.so`
    and header files, e.g. `yices.h` by searching for these files.

    ```bash
    find /usr -type f -iname "libyices.so"
    find /usr -type f -iname "yices.h"
    ```

  * Check if paths in file `CTptpParsing/Linux/PkgConfig/Z3Api.pc`

    ```conf
    llibdir=/usr/lib/x86_64-linux-gnu/
    includedir=/usr/include/
    ```

    match the actual paths for the Yices library file `libz3.so`
    and header files, e.g. `z3_api.h` by searching for these files.

    ```bash
    find /usr -type f -iname "libz3.so"
    find /usr -type f -iname "z3_api.h"
    ```

  * Install the tptp parsing library and the pkg-config files
    after assigning the correct paths in the pkg-config files.

    ```bash
    cd CTptpParsing
    sudo make install
    ```

  * Check if pkg-config files were configured and installed correctly.

    ```bash
    pkg-config Yices --libs --cflags
    pkg-config Z3Api --libs --cflags
    pkg-config TptpParsing --libs --cflags
    ```
  
## Example on Ubuntu 22.4 LTS

* Installation of developer tools

  *Please notice that the list of developer tools may differ slightly between different Linux distributions.*

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

  $ clang --version
  Ubuntu clang version 14.0.0-1ubuntu1
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

* Installation of the smt headers and libraries

  ```bash
  $ sudo add-apt-repository ppa:sri-csl/formal-methods
  $ sudo apt-get update
  $ sudo apt-get install yices2-dev

  $ find /usr/ -iname "libyices.so"
  /usr/lib/x86_64-linux-gnu/libyices.so

  $ find /usr/ -iname "yices.h"
  /usr/include/yices.h

  $ sudo apt-get install libz3-dev

  $ find /usr/ -iname "libz3.so"
  /usr/lib/x86_64-linux-gnu/libz3.so

  $ find /usr/ -iname "z3_api.h"
  /usr/include/z3_api.h
  ```

* Installation of the tptp parsing library and the pkg-config files

  ```bash
  $ git clone https://github.com/AleGit/CTptpParsing
  ...
  $ cd CTptpParsing
  $ sudo make install

  $ pkg-config Yices --libs --cflags
  -I/usr/include -L/usr/lib/x86_64-linux-gnu

  $ pkg-config Z3Api --libs --cflags
  -I/usr/include -L/usr/lib/x86_64-linux-gnu

  $ pkg-config TptpParsing --libs --cflags
  -I/usr/local/include -L/usr/local/lib
  ```
