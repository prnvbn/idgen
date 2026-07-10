package idgen

import "core:encoding/uuid"
import "core:flags"
import "core:fmt"
import "core:os"

Options :: struct {
	version:   bool `args:"short=V" usage:"show version number and quit"`,
	time_v7:   bool `args:"name=time-v7,short=7" usage:"generate time-based v7 uuid"`,
	time_v6:   bool `args:"name=time-v6,short=6" usage:"generate time-based v6 uuid"`,
	time_v1:   bool `args:"name=time,short=t" usage:"generate time-based uuid"`,
	random:    bool `args:"name=random,short=r" usage:"generate random-based uuid"`,
	count:     uint `args:"name=count,short=C" usage:"generate more uuids in loop"`,
	namespace: UUID_Namespace `args:"name=namespace,short=n" usage:"generate hash-based uuid in this namespace. available namespaces: @dns @url @oid @x500"`,
	name:      string `args:"name=name,short=N" usage:"generate hash-based uuid from this name"`,
	md5:       bool `args:"name=md5,short=m" usage:"generate md5 hash"`,
	sha1:      bool `args:"name=sha1,short=s" usage:"generate sha1 hash"`,
	hex:       bool `args:"name=hex,short=x" usage:"interpret name as hex string"`,
}


validate_options_or_exit :: proc(opts: Options) {
	has_namespace := opts.namespace.set
	has_name := len(opts.name) > 0

	if has_name && !has_namespace do exit_with_error("--namespace requires --name argument")
	if !has_name && has_namespace do exit_with_error("--name requires --namespace argument")
	if opts.md5 && opts.sha1 do exit_with_error("--md5 and --sha1 can not combined")
	if opts.md5 && (!has_name || !has_namespace) do exit_with_error("--md5 requires --namespace  and --name arguments")
	if opts.sha1 && (!has_name || !has_namespace) do exit_with_error("--sha1 requires --namespace  and --name arguments")
}

main :: proc() {
	opts: Options
	style: flags.Parsing_Style = .Unix

	flags.register_type_setter(uuid_namespace_type_setter)
	parse_or_exit_with_short(&opts, os.args, style)
	validate_options_or_exit(opts)

	num_uuids := max(1, opts.count)

	for _ in 0 ..< num_uuids {
		switch {
		case opts.version:
			version := #load("version.txt")
			fmt.println(string(version))
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
			name: []byte
			if opts.hex {
				ok: bool
				name, ok = decode_hex(opts.name)
				if !ok do exit_with_error("`%s` is not a valid hex string", opts.name)
			} else {
				name = transmute([]byte)opts.name
			}

			generated_uuid := uuid.to_string(generate_v3_uuid(opts.namespace.id, name))
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

decode_hex :: proc(value: string) -> (result: []byte, ok: bool) {
	if len(value) % 2 != 0 {
		return
	}

	result = make([]byte, len(value) / 2)

	for i in 0 ..< len(result) {
		result[i], ok = xtob(value[i * 2], value[i * 2 + 1])
		if !ok {
			delete(result)
			result = nil
			return
		}
	}

	ok = true
	return
}
