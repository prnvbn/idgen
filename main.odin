package idgen

import "core:encoding/uuid"
import "core:flags"
import "core:fmt"
import "core:os"

main :: proc() {
	Options :: struct {
		version: bool `usage:"Show version number and quit"`,
	}

	opts: Options
	style: flags.Parsing_Style = .Unix

	flags.parse_or_exit(&opts, os.args, style)


	switch {
	case opts.version:
		version := #load("version.txt")
		fmt.println(string(version))
	case:
		generated_uuid := uuid.to_string(uuid.generate_v4())
		fmt.println(generated_uuid)
	}
}
