package idgen

import "core:flags"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:reflect"
import "core:strings"

// edited implementation of flags.parse_or_exit to add support for the short subtag (so that I can support shorthands)
// reference: https://github.com/odin-lang/Odin/blob/5b54b5df3160d6b8d63d41327f4aeb4dd8aae2d8/core/flags/util.odin#L22-L29
@(optimization_mode = "favor_size")
parse_or_exit_with_short :: proc(
	model: ^$T,
	program_args: []string,
	style: flags.Parsing_Style = .Odin,
	allocator := context.allocator,
	loc := #caller_location,
) {
	assert(len(program_args) > 0, "Program arguments slice is empty.", loc)

	program := filepath.base(program_args[0])
	args: []string

	if len(program_args) > 1 {
		args = program_args[1:]
	}

	shorts := make(map[string]string)
	for field in reflect.struct_fields_zipped(typeid_of(T)) {
		args_tag, ok := reflect.struct_tag_lookup(field.tag, flags.TAG_ARGS)
		if !ok {
			continue
		}

		short, has_short := flags.get_subtag(args_tag, SUBTAG_SHORT)
		if !has_short {
			continue
		}

		name, has_name := flags.get_subtag(args_tag, flags.SUBTAG_NAME)
		if !has_name {
			name = field.name
		}

		shorts[strings.concatenate({"-", short})] = strings.concatenate({"--", name})
	}

	expanded_args := make([]string, len(args))
	for arg, i in args {
		name, ok := shorts[arg]
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
			flags.write_usage(stderr, T, program, style) //TODO? add support for short subtag in here
			fmt.wprintln(stderr)
		}

		flags.print_errors(T, err, program, style)

		_, was_help_request := err.(flags.Help_Request)
		os.exit(0 if was_help_request else 1)
	}
}
