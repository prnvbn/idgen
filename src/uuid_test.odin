package idgen

import "core:testing"

@(test)
test_parse_uuid :: proc(t: ^testing.T) {
	test :: struct {
		s:  string,
		ok: bool,
	}

	tests :: []test {
		{"f47ac10b-58cc-0372-8567-0e02b2c3d479", true},
		{"urn:uuid:f47ac10b-58cc-4372-0567-0e02b2c3d479", true},
		{"URN:UUID:f47ac10b-58cc-4372-0567-0e02b2c3d479", true},
		{"aRN:UUID:f47ac10b-58cc-4372-0567-0e02b2c3d479", false},
		{"{f47ac10b-58cc-0372-8567-0e02b2c3d479}", true},
		{"{f47ac10b-58cc-0372-8567-0e02b2c3d479", false},
		{"f47ac10b-58cc-0372-8567-0e02b2c3d479}", false},
		{"f47ac10b58cc037285670e02b2c3d479", true},
		{"f47ac10b58cc037285670e02b2c3d4790", false},
	}

	for test in tests {
		_, ok := parse_uuid(test.s)
		testing.expect(t, ok == test.ok, "testcase failed")

	}
}
