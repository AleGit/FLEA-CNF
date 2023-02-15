# *FLEA* – First Order Prover with Equality

Author: Alexander Maringele

## Installation

*FLEA* is written in the Apple [Swift](https://swift.org) programming language.
It relies heavily on the power of the sat and smt solver libraries 
of [Yices2](https://yices.csl.sri.com) and [Z3](https://github.com/Z3Prover/z3)
and uses a basic [parsing library](https://github.com/AleGit/CTptpParsing) implemented in C by the author.

### Required Tools and Libraries

You find detailed installation hints for required developer tools and libraries
in [Readme-macOS.md](Readme-macOS.md) for macOS 
and [Readme-Linux.md](Readme-Linux.md) for Ubuntu Linux.
You can easily check if the tools and libraries are installed correctly, e.g. the minimal versions on macOS are as follows:

```zsh
% git --version             # git version 2.37.1 (Apple Git-137.1)
% clang --version           # Apple clang version 14.0.0 (clang-1400.0.29.202)
% swift --version           # swift-driver version: 1.62.15 Apple Swift version 5.7.2 (swiftlang-5.7.2.135.5 clang-1400.0.29.51)
% yices --verison           # Yices 2.6.4
% z3 --version              # Z3 version 4.11.2 - 64 bit
% pkg-config --version      # 0.29.2
% flex --version            # flex 2.6.4 Apple(flex-34)
% bison --version           # bison (GNU Bison) 2.3
```

### Thousand Problems for Theorem Provers

We use this collection of first order problems for testing and experimenting with *FLEA*.

- [The TPTP Library for Automated Theorem Proving](http://www.tptp.org)

Download (in your web-browser or with curl) and unpack TPTP v8.0.0 or newer.
Rename the unpacked folder into your home directory.

```zsh
% curl http://www.tptp.org/TPTP/Distribution/TPTP-v8.0.0.tgz --output TPTP-v8.0.0.tgz
% tar -xf TPTP-v8.0.0.tgz
% mv TPTP-v8.0.0 ~/TPTP
% rm TPTP-v8.0.0.tgz
% ls ~/TPTP/
Axioms          Documents       Generators      Problems        Scripts         TPTP2X
```

By default *FLEA* will search for files in the following order

- `~/TPTP/Axioms` `~/Downloads/TPTP/Axioms` (`*.ax` axiom files)
- `~/TPTP/Problems` `~/Downloads/TPTP/Problems` (`*.p` problem files)

### The Basic TPTP Parsing Library 

The simple [tptp parsing library](https://github.com/AleGit/CTptpParsing) 
-- written in C with Bison and Flex and provided by the author of *FLEA* -- 
can be installed easily on macOS or Ubuntu.

```zsh
% git clone https://github.com/AleGit/CTptpParsing.git
% cd CTptpParsing
% sudo make install
```

This will install header files and library binaries of the tptp parsing library.
Additionally three pkg-config files `Yices.pc`, `Z3Api.pc`, and `TptpParsing.pc`
are copied into

```zsh
/usr/local/lib/pkgconfig    # macOS 11 (arm64,x86_64)
/usr/lib/pkgconfig          # Ubuntu Linux
```

such that [pkg-config](https://www.freedesktop.org/wiki/Software/pkg-config/) 
can find these config files.

- Expected configuration files

```zsh
# macOS arm64 + x86_64
/usr/local/lib/pkgconfig/Yices.pc
/usr/local/lib/pkgconfig/Z3API.pc 
/usr/local/lib/pkgconfig/TptpParsing.pc 

# Ubuntu Linux
/usr/lib/pkgconfig/Yices.pc 
/usr/lib/pkgconfig/Z3API.pc
/usr/lib/pkgconfig/TptpParsing.pc
```

- Check the configuration

```zsh
% pkg-config Yices Z3Api TptpParsing --cflags --libs
# macOS arm64
-I/opt/homebrew/include -I/usr/local/include -L/opt/homebrew/lib -L/usr/local/lib 
# macOS 11 x86_64, Ubuntu Linux
-I/usr/local/include -L/usr/local/lib
```

The pkg-config must yield correct paths to header and library directories 
of Yices2, Z3, and tptp parsing. 

- Required header files in `include` directory from configuration above

```zsh
# Yices
yices.h             
yices_limits.h      
yices_types.h       
yices_exit_codes.h 

# Z3API
z3_rcf.h
z3_macros.h
z3_polynomial.h
z3++.h
z3_algebraic.h
z3_fpa.h
z3_optimization.h
z3.h
z3_ast_containers.h
z3_v1.h
z3_api.h
z3_version.h
z3_fixedpoint.h
z3_spacer.h

# TptpParsing
PrlcMacros.h     
PrlcData.h
PrlcCore.h
PrlcParser.h
```

- Required library files in `lib` directory from configuration above 

```zsh
# Yices 2
libyices.a                 # macOS 11 
libyices.dylib             # macOS 11
libyices.2.dylib           # macOS 11
libyices.so                # Ubunto Linux

# Z3
libz3.a                # macOS (static)
libz3.dylib           # macOS only

# TptpParsing
libTptpParsing.dylib           # macOS 12 (arm64 and x86_64)
libTptpParsing.a               # TODO: Ubuntu Linux
```

### Download, run and test *FLEA*.

```zsh
% git clone https://github.com/AleGit/FLEA5.git
Cloning into FLEA5 ...
% cd FLEA5
% git checkout develop
% swift run
FLEA - First order Logic with Equality Attester (FLEA)
...
% swift test
...
Executed ... tests, with 0 failures (0 unexpected) in ... (...) seconds.
```
