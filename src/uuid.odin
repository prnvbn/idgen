package idgen

import "core:c"
import "core:encoding/uuid"
import "core:math/rand"
import "core:strings"
import "core:sys/posix"

UUIDD_SOCKET_PATH :: "/run/uuidd/request"
UUIDD_OP_TIME_UUID :: u8(2)

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

// reference: https://github.com/google/uuid/blob/2d3c2a9cc518326daf99a383f07c4d3c44317e4d/uuid.go#L95
// todo: look into better error handling in Odin
// todo: add tests for this
parse_uuid :: proc(s: string) -> (id: uuid.Identifier, ok: bool) {
	s := s
	switch len(s) {
	case 36:
	// xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
	case 36 + 9:
		// urn:uuid:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
		if !strings.equal_fold(s[:9], "urn:uuid:") {
			return {}, false
		}
		s = s[9:]
	case 36 + 2: // {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
			s = s[1:len(s)]
	case 32:
		// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
		for i in id {
			id[i], ok = xtob(s[i * 2], s[i * 2 + 1])
			if !ok {
				return {}, false
			}
		}
		return id, true
	case: // invalid length
			return {}, false
	}

	// s is now at least 36 bytes long
	// it must be of the form xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
	if s[8] != '-' || s[13] != '-' || s[18] != '-' || s[23] != '-' {
		return {}, false
	}

	hex_pair_offsets := [16]int{0, 2, 4, 6, 9, 11, 14, 16, 19, 21, 24, 26, 28, 30, 32, 34}
	for x, i in hex_pair_offsets {
		id[i], ok = xtob(s[x], s[x + 1])
		if !ok {
			return id, false
		}
	}

	return
}

// hex pair offsets for uuid of the form xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
STANDARD_UUID_HEX_PAIR_OFFSETS :: [16]int {
	0,
	2,
	4,
	6,
	9,
	11,
	14,
	16,
	19,
	21,
	24,
	26,
	28,
	30,
	32,
	34,
}

// xtob converts hex characters x1 and x2 into a byte.
// reference: https://github.com/google/uuid/blob/master/util.go#L40
xtob :: proc(x1, x2: byte) -> (byte, bool) {
	xvalues := XVALUES
	b1 := xvalues[x1]
	b2 := xvalues[x2]
	return (b1 << 4) | b2, b1 != 255 && b2 != 255
}

// xvalues returns the value of a byte as a hexadecimal digit or 255.
// todo: (nit) fix ols config to not expand this
XVALUES :: [256]byte {
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	0,
	1,
	2,
	3,
	4,
	5,
	6,
	7,
	8,
	9,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	10,
	11,
	12,
	13,
	14,
	15,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	10,
	11,
	12,
	13,
	14,
	15,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	255,
}
