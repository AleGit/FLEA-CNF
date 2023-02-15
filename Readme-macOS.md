# Install tools and libraries for *FLEA-0*

## macOS (arm64, x86_64)

* Either install Xcode (availabe from [Apple Developer](https://developer.apple.com/xcode/) 
  or [Mac App Store](https://apps.apple.com/app/xcode/id497799835?mt=12)) 
  or the command line developer tools:

```zsh
# To install command line developer tools may be sufficient
% xcode-select install
```

* Install [Homebrew](https://brew.sh), i.e. the missing package manager for macOS.
* Install tools and libraries using hombrew:
  * [pkg-config](https://gitlab.freedesktop.org/pkg-config/pkg-config)
  * [Yices 2](https://yices.csl.sri.com)
  * [Z3](https://github.com/Z3Prover/z3/wiki)

```zsh
% brew install pkg-config
% brew install SRI-CSL/sri-csl/yices2 
% brew install z3

% pkg-config --version
% yices --version
% z3 --version
```
