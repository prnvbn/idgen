PROG = idgen

SRC = src

ODIN = odin
BUILD_DIR = dist
COMMON_FLAGS = -collection:lib=./lib -strict-style -vet-semicolon -vet-cast -vet-using-param
RELEASE_FLAGS = -vet-unused -o:speed
DEBUG_FLAGS = -debug -o:none

all: release

release: $(BUILD_DIR)
	$(ODIN) build $(SRC) $(COMMON_FLAGS) $(RELEASE_FLAGS) -microarch:native -out:$(BUILD_DIR)/$(PROG)

debug: $(BUILD_DIR)
	$(ODIN) build $(SRC) $(COMMON_FLAGS) $(DEBUG_FLAGS) -out:$(BUILD_DIR)/$(PROG)

run: debug
	./$(BUILD_DIR)/$(PROG) $(ARGS)

test: $(BUILD_DIR)
	$(ODIN) test $(SRC) $(COMMON_FLAGS) $(DEBUG_FLAGS) \
		-define:ODIN_TEST_LOG_LEVEL=warning \
		-define:ODIN_TEST_FANCY=false \
		-define:ODIN_TEST_SHORT_LOGS=true \
		-keep-executable -out:$(BUILD_DIR)/$(PROG)-tests

check:
	$(ODIN) check $(SRC) $(COMMON_FLAGS) -vet-unused -debug

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

clean:
	-@rm -r $(BUILD_DIR)

.PHONY: all release debug run test check clean
