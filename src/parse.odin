package idgen

import "core:flags"
import "core:fmt"
import "core:io"
import "core:os"
import "core:path/filepath"
import "core:reflect"
import "core:strings"

SUBTAG_SHORT :: "short"

write_usage_with_short :: proc(
	out: io.Writer,
	data_type: typeid,
	program: string,
	style: flags.Parsing_Style,
	shorts: map[string]string,
) {
	builder := strings.builder_make(context.temp_allocator)
	defer strings.builder_destroy(&builder)

	flags.write_usage(strings.to_writer(&builder), data_type, program, style)

	for short, long in shorts {
		usage_flag := strings.concatenate({"[", long, "]"}, context.temp_allocator)
		usage_with_short := strings.concatenate({"[", short, "|", long, "]"}, context.temp_allocator)
		strings.builder_replace_all(&builder, usage_flag, usage_with_short)

		flag_line := strings.concatenate({"\t", long, " "}, context.temp_allocator)
		flag_line_with_short := strings.concatenate({"\t", short, ", ", long, " "}, context.temp_allocator)
		strings.builder_replace_all(&builder, flag_line, flag_line_with_short)
	}

	fmt.wprint(out, strings.to_string(builder))
}

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
			write_usage_with_short(stderr, T, program, style, shorts)
			fmt.wprintln(stderr)
		}

		_, was_help_request := err.(flags.Help_Request)
		if was_help_request {
			stdout := os.to_stream(os.stdout)
			write_usage_with_short(stdout, T, program, style, shorts)
		} else {
			flags.print_errors(T, err, program, style)
		}

		os.exit(0 if was_help_request else 1)
	}
}
