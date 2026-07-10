package idgen

import "core:c"
import "core:encoding/uuid"
import "core:flags"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:path/filepath"
import "core:reflect"
import "core:strings"
import "core:sys/posix"

Options :: struct {
	version: bool `args:"short=V" usage:"show version number and quit"`,
	time_v7: bool `args:"name=time-v7,short=7" usage:"generate time-based v7 uuid"`,
	time_v6: bool `args:"name=time-v6,short=6" usage:"generate time-based v6 uuid"`,
	time_v1: bool `args:"name=time,short=t" usage:"generate time-based uuid"`,
}

SUBTAG_SHORT :: "short"

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

main :: proc() {
	opts: Options
	style: flags.Parsing_Style = .Unix

	parse_or_exit_with_short(&opts, os.args, style)

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
	case:
		generated_uuid := uuid.to_string(uuid.generate_v4())
		fmt.println(generated_uuid)
	}
}

generate_v1_uuid :: proc() -> uuid.Identifier {
	if id, ok := generate_v1_uuid_with_daemon(); ok {
		return id
	}

	return generate_v1_uuid_without_daemon()
}

generate_v1_uuid_without_daemon :: proc() -> uuid.Identifier {
	clock_seq := u16(rand.uint32() & 0x3FFF)
	return uuid.generate_v1(clock_seq)
}

UUIDD_SOCKET_PATH :: "/run/uuidd/request"
UUIDD_OP_TIME_UUID :: u8(2)

// reference: https://github.com/util-linux/util-linux/blob/9a6d1e94551a690a29d67dff721df593bed22195/libuuid/src/gen_uuid.c#L478
generate_v1_uuid_with_daemon :: proc() -> (id: uuid.Identifier, ok: bool) {
	fd := posix.socket(.UNIX, .STREAM)
	if fd == -1 {
		return {}, false
	}
	defer posix.close(fd)

	addr: posix.sockaddr_un
	addr.sun_family = .UNIX
	when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {
		addr.sun_len = c.uchar(size_of(addr))
	}
	path := UUIDD_SOCKET_PATH
	if len(path) + 1 > len(addr.sun_path) {
		return {}, false
	}
	for i in 0 ..< len(path) {
		addr.sun_path[i] = c.char(path[i])
	}
	addr.sun_path[len(path)] = 0

	socket_addr := (^posix.sockaddr)(&addr)
	if posix.connect(fd, socket_addr, posix.socklen_t(size_of(addr))) != .OK {
		return {}, false
	}
	op := UUIDD_OP_TIME_UUID
	bytes_sent := posix.send(fd, &op, size_of(op), {})
	if bytes_sent != 1 {
		return {}, false
	}

	reply_len: i32 // https://github.com/util-linux/util-linux/blob/9a6d1e94551a690a29d67dff721df593bed22195/libuuid/src/gen_uuid.c#L484
	bytes_read := posix.recv(fd, &reply_len, size_of(reply_len), {.WAITALL})
	if bytes_read != size_of(reply_len) {
		return {}, false
	}
	if reply_len != 16 {
		return {}, false
	}
	bytes_read = posix.recv(fd, &id, size_of(uuid.Identifier), {.WAITALL})
	if bytes_read != size_of(id) {
		return {}, false
	}

	return id, true
}
