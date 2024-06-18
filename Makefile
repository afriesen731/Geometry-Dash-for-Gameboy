# General Purpose Makefile for RGBDS

# Compiler settings
RGBASM := rgbasm
RGBLINK := rgblink
RGBFIX := rgbfix

# directories
BUILD_DIR = obj

INCDIRS = src/ src/include/ src/music/ src/bin/ 
ASFLAGS = $(addprefix -I,$(INCDIRS))

EMULATOR := C:\Users\afrie\OneDrive\Desktop\Emulicious-with-Java64\Emulicious.exe

# Source files (add your own)
SRCS := $(wildcard src/*.asm wildcard src/music/*.asm)
OBJS := $(patsubst src/%.asm,obj/%.o,$(SRCS))

# Output ROM name
ROM := geometry-dash.gb

.PHONY: all clean run


# Targets
all: $(ROM)

run: 
	$(EMULATOR) $(ROM)

clean:
	rm -rf $(BUILD_DIR) $(ROM)



$(BUILD_DIR):
	mkdir -p $@

$(ROM): $(OBJS)
	$(RGBLINK) -o $@ $^
	$(RGBFIX) -v -p 0 $@

$(BUILD_DIR)/%.o: src/%.asm | $(BUILD_DIR)
	$(RGBASM) $(ASFLAGS) -o $@ $<



