package idgen

import "core:encoding/uuid"
import "core:flags"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:reflect"
import "core:strings"

Options :: struct {
	version: bool `args:"alias=V" usage:"show version number and quit"`,
	time_v7: bool `args:"name=time-v7,alias=7" usage:"generate time-based v7 uuid"`,
}


// wrapper around flags.parse_or_exit to add support for alias subtag (so that I can support shorthands)
// used the following as a reference: https://github.com/odin-lang/Odin/blob/5b54b5df3160d6b8d63d41327f4aeb4dd8aae2d8/core/flags/util.odin#L22-L29
parse_or_exit_with_aliases :: proc(
	model: ^$T,
	program_args: []string,
	style: flags.Parsing_Style = .Odin,
	allocator := context.allocator,
	loc := #caller_location,
) {
	// TODO: add compile time check for args subtag using #assert
	assert(len(program_args) > 0, "Program arguments slice is empty.", loc)

	program := filepath.base(program_args[0])
	args: []string

	if len(program_args) > 1 {
		args = program_args[1:]
	}

	aliases := make(map[string]string)
	for field in reflect.struct_fields_zipped(typeid_of(T)) {
		args_tag, ok := reflect.struct_tag_lookup(field.tag, "args")
		if !ok {
			continue
		}

		alias, has_alias := flags.get_subtag(args_tag, "alias")
		if !has_alias {
			continue
		}

		name, has_name := flags.get_subtag(args_tag, "name")
		if !has_name {
			name = field.name
		}

		aliases[strings.concatenate({"-", alias})] = strings.concatenate({"--", name})
	}

	expanded_args := make([]string, len(args))
	for arg, i in args {
		name, ok := aliases[arg]
		if ok {
			expanded_args[i] = name
		} else {
			expanded_args[i] = arg
		}
	}

	err := flags.parse(model, expanded_args[:], style, true, true, allocator, loc)
	if err != nil {
		stderr := os.to_stream(os.stderr)

		if len(args) == 0 {
			// No arguments entered, and there was an error; show the usage,
			// specifically on STDERR.
			flags.write_usage(stderr, T, program, style) //TODO: add support for alias subtag in here
			fmt.wprintln(stderr)
		}

		flags.print_errors(T, err, program, style)

		_, was_help_request := err.(flags.Help_Request)
		os.exit(0 if was_help_request else 1)
	}
}

main :: proc() {
	opts: Options
	style: flags.Parsing_Style = .Unix

	parse_or_exit_with_aliases(&opts, os.args, style)

	switch {
	case opts.version:
		version := #load("version.txt")
		fmt.println(string(version))
	case opts.time_v7:
		generated_uuid := uuid.to_string(uuid.generate_v7())
		fmt.println(generated_uuid)
	case:
		generated_uuid := uuid.to_string(uuid.generate_v4())
		fmt.println(generated_uuid)
	}
}
