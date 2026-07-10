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
		namespace.id = uuid.Namespace_DNS
		namespace.set = true
	case "@url", "url":
		namespace.id = uuid.Namespace_URL
		namespace.set = true
	case "@oid", "oid":
		namespace.id = uuid.Namespace_OID
		namespace.set = true
	case "@x500", "@x.500":
		namespace.id = uuid.Namespace_X500
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
