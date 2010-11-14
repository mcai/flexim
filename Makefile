EXECUTABLE = flexim
SRC = build.rf

DC = dmd
# DCFLAGS = -w -wi
# DCFLAGS = -O
DCFLAGS = -debug -gc -w -wi
LDFLAGS = -L-ldl

TARGET = build/$(EXECUTABLE)

all: $(TARGET)

clean:
	rm -rf $(TARGET).o $(TARGET)

$(TARGET): $(SRC)
	$(DC) $(DCFLAGS) $(LDFLAGS) @$< -of$@
	rm -rf $(TARGET).o
