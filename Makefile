.PHONY: vet dist windows darwin-amd64 darwin-arm64 linux-arm64 linux-amd64 clean

DIST_DIR := dist
BUILD_FLAGS := -o:speed -vet
SRC := .

define build-target
	odin build $(SRC) $(BUILD_FLAGS) -target:$(1) -out:$(DIST_DIR)/idgen-$(2)
endef

vet:
	odin build $(SRC) -vet

dist:
	mkdir -p $(DIST_DIR)
	$(MAKE) windows darwin-arm64 darwin-amd64 linux-arm64 linux-amd64

windows:
	$(call build-target,windows_amd64,windows.exe)

darwin-amd64:
	$(call build-target,darwin_amd64,darwin-amd64)

darwin-arm64:
	$(call build-target,darwin_arm64,darwin-arm64)

linux-arm64:
	$(call build-target,linux_arm64,linux-arm64)

linux-amd64:
	$(call build-target,linux_amd64,linux-amd64)

clean:
	rm -rf $(DIST_DIR)/
