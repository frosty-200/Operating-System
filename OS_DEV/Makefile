QEMU      := qemu-system-x86_64
CPU       := qemu64,pdpe1gb=on
MEM       := 16384
DISK      := boot.img
FORMAT    := raw

.PHONY: run

run:
	$(QEMU) -cpu $(CPU) -m $(MEM) -drive file=$(DISK),format=$(FORMAT)   
