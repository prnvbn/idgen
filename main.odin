package idgen

import "core:encoding/uuid"
import "core:flags"
import "core:fmt"
import "core:os"

Options :: struct {
	version: bool `args:"short=V" usage:"show version number and quit"`,
	time_v7: bool `args:"name=time-v7,short=7" usage:"generate time-based v7 uuid"`,
	time_v6: bool `args:"name=time-v6,short=6" usage:"generate time-based v6 uuid"`,
	time_v1: bool `args:"name=time,short=t" usage:"generate time-based uuid"`,
	random:  bool `args:"name=random,short=r" usage:"generate random-based uuid"`,
	count:   uint `args:"name=count,short=C" usage:"generate more uuids in loop"`,
}

main :: proc() {
	opts: Options
	style: flags.Parsing_Style = .Unix

	parse_or_exit_with_short(&opts, os.args, style)

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
		case opts.random:
			fallthrough
		case:
			generated_uuid := uuid.to_string(uuid.generate_v4())
			fmt.println(generated_uuid)
		}
	}
}
