package idgen

import "base:runtime"
import "core:encoding/uuid"

UUID_Namespace :: struct {
	id:  uuid.Identifier,
	set: bool,
}

uuid_namespace_type_setter :: proc(
	data: rawptr,
	data_type: typeid,
	unparsed_value: string,
	args_tag: string,
) -> (
	err: string,
	handled: bool,
	allocator_err: runtime.Allocator_Error,
) {
	if data_type != UUID_Namespace {
		return "", false, nil
	}

	handled = true
	namespace := cast(^UUID_Namespace)data

	switch unparsed_value {
	case "@dns", "dns":
		namespace.id = UUID_NAMESPACE_DNS
		namespace.set = true
	case "@url", "url":
		namespace.id = UUID_NAMESPACE_URL
		namespace.set = true
	case "@oid", "oid":
		namespace.id = UUID_NAMESPACE_OID
		namespace.set = true
	case "@x500", "@x.500":
		namespace.id = UUID_NAMESPACE_X500
		namespace.set = true
	case:
		parsed, ok := parse_uuid(unparsed_value)
		if !ok {
			err = "namespace must be @dns, @url, @oid, @x500, or a valid UUID"
			return
		}
		namespace.id = parsed
		namespace.set = true
	}

	return
}

// reference: https://github.com/util-linux/util-linux/blob/9a6d1e94551a690a29d67dff721df593bed22195/libuuid/src/predefined.c#L48-L63
UUID_NAMESPACE_DNS :: uuid.Identifier {
	0x6b,
	0xa7,
	0xb8,
	0x10,
	0x9d,
	0xad,
	0x11,
	0xd1,
	0x80,
	0xb4,
	0x00,
	0xc0,
	0x4f,
	0xd4,
	0x30,
	0xc8,
}
UUID_NAMESPACE_URL :: uuid.Identifier {
	0x6b,
	0xa7,
	0xb8,
	0x11,
	0x9d,
	0xad,
	0x11,
	0xd1,
	0x80,
	0xb4,
	0x00,
	0xc0,
	0x4f,
	0xd4,
	0x30,
	0xc8,
}
UUID_NAMESPACE_OID :: uuid.Identifier {
	0x6b,
	0xa7,
	0xb8,
	0x12,
	0x9d,
	0xad,
	0x11,
	0xd1,
	0x80,
	0xb4,
	0x00,
	0xc0,
	0x4f,
	0xd4,
	0x30,
	0xc8,
}
UUID_NAMESPACE_X500 :: uuid.Identifier {
	0x6b,
	0xa7,
	0xb8,
	0x14,
	0x9d,
	0xad,
	0x11,
	0xd1,
	0x80,
	0xb4,
	0x00,
	0xc0,
	0x4f,
	0xd4,
	0x30,
	0xc8,
}
