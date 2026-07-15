# idgen

`idgen` is a drop in replacement for [uuidgen](https://www.man7.org/linux/man-pages/man1/uuidgen.1.html) implemented in [Odin](https://odin-lang.org/). Additionally, it also supports [UUIDv8](https://www.rfc-editor.org/rfc/rfc9562.html#name-uuid-version-8) and [TypeIDs](https://github.com/jetify-com/typeid).

## Installation

### Linux or MacOS

You can install the latest version of `idgen` by running the following command in your terminal.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/prnvbn/idgen/main/installer.sh)"
```

Move the binary to a directory in your PATH. For e.g. `/usr/local/bin` on linux.

### via `homebrew`

You can install `idgen` from [prnvbn/homebrew-tap](https://github.com/prnvbn/homebrew-tap).

```bash
brew install prnvbn/tap/idgen
```
