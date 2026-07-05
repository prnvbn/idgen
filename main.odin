package idgen

import "core:encoding/uuid"
import "core:flags"
import "core:fmt"
import "core:os"
import "core:strings"


main :: proc() {
	Options :: struct {}

	opts: Options
	style: flags.Parsing_Style = .Unix

	flags.parse_or_exit(&opts, os.args, style)

	generated_uuid := uuid.to_string(uuid.generate_v4())
	fmt.println(generated_uuid)
}
