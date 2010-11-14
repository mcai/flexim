EXECUTABLE = flexim
SRC = build.rf

DC = dmd
# DCFLAGS = -w -wi
# DCFLAGS = -O
DCFLAGS = -debug -gc -w -wi

DCOLLECTION_DCFLAGS = -I/home/itecgo/Flexim2/refs/dcollections-2.0c
DCOLLECTION_LDFLAGS = -L-L/home/itecgo/Flexim2/refs/dcollections-2.0c -L-ldcollections

DCFLAGS += $(DCOLLECTION_DCFLAGS) -L-ldl $(DCOLLECTION_LDFLAGS)

TARGET = build/$(EXECUTABLE)

all: $(TARGET)

clean:
	rm -rf $(TARGET).o $(TARGET)

$(TARGET): $(SRC)
	$(DC) $(DCFLAGS) @$< -of$@
	rm -rf $(TARGET).o
