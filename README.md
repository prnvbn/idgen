# idgen

`idgen` is a drop in replacement for [uuidgen](https://www.man7.org/linux/man-pages/man1/uuidgen.1.html) implemented in [Odin](https://odin-lang.org/). Additionally, it also supports [UUIDv8](https://www.rfc-editor.org/rfc/rfc9562.html#name-uuid-version-8) and [TypeIDs](https://github.com/jetify-com/typeid).

## Usage

```shell
# generate UUIDv4
$ idgen
c1c792d8-8656-4c32-b245-55acf9b6e376

# generate UUIDv7
$ idgen -7
019f9a54-6594-708b-b624-15436b2053ca

# generate TypeID with prefix
$ idgen -T user
user_01kyd58y3afjyr6nvw05khz4wz

```

```
$ idgen --help
Usage:
	idgen [-C|--count] [-8|--hash-v8] [-x|--hex] [-m|--md5] [-N|--name] [-n|--namespace] [-r|--random] [-s|--sha1] [-t|--time] [-6|--time-v6] [-7|--time-v7] [-T|--type-id] [-V|--version]
Flags:
	-C, --count <uint>                | generate more uuids in loop
	-8, --hash-v8 <UUID_V8_Hash>      | generate hash-based UUIDv8 using this algorithm
	-x, --hex                         | interpret name as hex string
	-m, --md5                         | generate md5 hash (UUIDv3)
	-N, --name <string>               | generate hash-based uuid from this name
	-n, --namespace <UUID_Namespace>  | generate hash-based uuid in this namespace. available namespaces: @dns @url @oid @x500
	-r, --random                      | generate random-based UUIDv4
	-s, --sha1                        | generate sha1 hash (UUIDv5)
	-t, --time                        | generate time-based UUIDv1
	-6, --time-v6                     | generate time-based UUIDv6
	-7, --time-v7                     | generate time-based UUIDv7
	-T, --type-id <string>            | generate a TypeID with this prefix
	-V, --version                     | show version number and quit
```

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
