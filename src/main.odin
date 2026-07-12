package idgen

import "core:encoding/uuid"
import "core:encoding/uuid/legacy"
import "core:flags"
import "core:fmt"
import "core:os"
import "core:strings"

Options :: struct {
	version:   bool `args:"short=V" usage:"show version number and quit"`,
	time_v7:   bool `args:"name=time-v7,short=7" usage:"generate time-based UUIDv7"`,
	time_v6:   bool `args:"name=time-v6,short=6" usage:"generate time-based UUIDv6"`,
	time_v1:   bool `args:"name=time,short=t" usage:"generate time-based UUIDv1"`,
	random:    bool `args:"name=random,short=r" usage:"generate random-based UUIDv4"`,
	count:     uint `args:"name=count,short=C" usage:"generate more uuids in loop"`,
	namespace: UUID_Namespace `args:"name=namespace,short=n" usage:"generate hash-based uuid in this namespace. available namespaces: @dns @url @oid @x500"`,
	name:      string `args:"name=name,short=N" usage:"generate hash-based uuid from this name"`,
	md5:       bool `args:"name=md5,short=m" usage:"generate md5 hash (UUIDv3)"`,
	sha1:      bool `args:"name=sha1,short=s" usage:"generate sha1 hash (UUIDv5)"`,
	hash_v8:   UUID_V8_Hash `args:"name=hash-v8,short=8" usage:"generate hash-based UUIDv8 using this algorithm"`,
	hex:       bool `args:"name=hex,short=x" usage:"interpret name as hex string"`,
}


validate_options_or_exit :: proc(opts: Options) {
	has_namespace := opts.namespace.set
	has_name := len(opts.name) > 0
	has_hash_v8 := opts.hash_v8.set

	if has_name && !has_namespace do exit_with_error("--name requires --namespace argument")
	if !has_name && has_namespace do exit_with_error("--namespace requires --name argument")
	if (opts.md5 && opts.sha1) || ((opts.md5 || opts.sha1) && has_hash_v8) do exit_with_error("--md5, --sha1, and --hash-v8 cannot be combined")
	if opts.md5 && (!has_name || !has_namespace) do exit_with_error("--md5 requires --namespace  and --name arguments")
	if opts.sha1 && (!has_name || !has_namespace) do exit_with_error("--sha1 requires --namespace  and --name arguments")
	if has_hash_v8 && (!has_name || !has_namespace) do exit_with_error("--hash-v8 requires --namespace and --name arguments")
}

main :: proc() {
	opts: Options
	style: flags.Parsing_Style = .Unix

	flags.register_type_setter(idgen_type_setter)
	parse_or_exit_with_short(&opts, os.args, style)
	validate_options_or_exit(opts)

	num_uuids := max(1, opts.count)

	for _ in 0 ..< num_uuids {
		switch {
		case opts.version:
			version := #load("../version.txt")
			fmt.println(strings.trim_space(string(version)))
		case opts.time_v7:
			generated_uuid := uuid.to_string(uuid.generate_v7())
			fmt.println(generated_uuid)
		case opts.time_v6:
			generated_uuid := uuid.to_string(uuid.generate_v6())
			fmt.println(generated_uuid)
		case opts.time_v1:
			generated_uuid := uuid.to_string(generate_v1_uuid())
			fmt.println(generated_uuid)
		case opts.md5:
			name, ok := name_bytes(opts.name, opts.hex)
			if !ok do exit_with_error("`%s` is not a valid hex string", opts.name)
			generated_uuid := uuid.to_string(legacy.generate_v3(opts.namespace.id, name))
			fmt.println(generated_uuid)
		case opts.sha1:
			name, ok := name_bytes(opts.name, opts.hex)
			if !ok do exit_with_error("`%s` is not a valid hex string", opts.name)
			generated_uuid := uuid.to_string(legacy.generate_v5(opts.namespace.id, name))
			fmt.println(generated_uuid)
		case opts.hash_v8.set:
			name, ok := name_bytes(opts.name, opts.hex)
			if !ok do exit_with_error("`%s` is not a valid hex string", opts.name)
			generated_uuid := uuid.to_string(
				uuid.generate_v8_hash(opts.namespace.id, name, opts.hash_v8.algorithm),
			)
			fmt.println(generated_uuid)
		case opts.random:
			fallthrough
		case:
			generated_uuid := uuid.to_string(uuid.generate_v4())
			fmt.println(generated_uuid)
		}
	}
}

exit_with_error :: proc(format: string, args: ..any, flush := true) {
	stderr := os.to_stream(os.stderr)
	fmt.wprintfln(stderr, format, ..args, flush = flush)
	os.exit(1)
}

name_bytes :: proc(name: string, hex: bool, allocator := context.allocator) -> ([]byte, bool) {
	if hex {
		if len(name) % 2 != 0 {
			return nil, false
		}

		decoded := make([]byte, len(name) / 2, allocator)
		for i in 0 ..< len(decoded) {
			ok: bool
			decoded[i], ok = xtob(name[i * 2], name[i * 2 + 1])
			if !ok {
				delete(decoded, allocator)
				return nil, false
			}
		}

		return decoded, true

	}
	return transmute([]byte)name, true
}
