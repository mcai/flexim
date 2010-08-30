EXECUTABLE = flexim
SRC = build.rf

DC = dmd
# DCFLAGS = -w -wi
# DCFLAGS = -release -O
DCFLAGS = -debug -gc -w -wi
TARGET = build/$(EXECUTABLE)

all: $(TARGET)

clean:
	rm -rf $(TARGET).o $(TARGET)

$(TARGET): $(SRC)
	$(DC) $(DCFLAGS) @$< -of$@
	rm -rf $(TARGET).o
