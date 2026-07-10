package idgen

import "core:c"
import "core:encoding/uuid"
import "core:math/rand"
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
