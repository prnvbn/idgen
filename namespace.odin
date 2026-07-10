package idgen

import "base:runtime"
import "core:crypto/hash"
import "core:encoding/uuid"

UUID_Namespace :: struct {
	id:  uuid.Identifier,
	set: bool,
}

UUID_V8_Hash :: struct {
	algorithm: hash.Algorithm,
	set:       bool,
}

idgen_type_setter :: proc(
	data: rawptr,
	data_type: typeid,
	unparsed_value: string,
	args_tag: string,
) -> (
	err: string,
	handled: bool,
	allocator_err: runtime.Allocator_Error,
) {
	switch data_type {
	case UUID_Namespace:
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
	case UUID_V8_Hash:
		handled = true
		algorithm, ok := parse_v8_hash_algorithm(unparsed_value)
		if !ok {
			err = "unsupported UUIDv8 hash algorithm"
			return
		}

		v8_hash := cast(^UUID_V8_Hash)data
		v8_hash.algorithm = algorithm
		v8_hash.set = true
	case:
		return "", false, nil
	}

	return
}

parse_v8_hash_algorithm :: proc(value: string) -> (hash.Algorithm, bool) {
	switch value {
	case "blake2b":
		return .BLAKE2B, true
	case "blake2s":
		return .BLAKE2S, true
	case "sha224":
		return .SHA224, true
	case "sha256":
		return .SHA256, true
	case "sha384":
		return .SHA384, true
	case "sha512":
		return .SHA512, true
	case "sha512-256":
		return .SHA512_256, true
	case "sha3-224":
		return .SHA3_224, true
	case "sha3-256":
		return .SHA3_256, true
	case "sha3-384":
		return .SHA3_384, true
	case "sha3-512":
		return .SHA3_512, true
	case "sm3":
		return .SM3, true
	case "keccak-224":
		return .Legacy_KECCAK_224, true
	case "keccak-256":
		return .Legacy_KECCAK_256, true
	case "keccak-384":
		return .Legacy_KECCAK_384, true
	case "keccak-512":
		return .Legacy_KECCAK_512, true
	}

	return .Invalid, false
}
