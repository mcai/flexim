EXECUTABLE = flexim
SRC = build.rf

DC = dmd
DCFLAGS = -release
# DCFLAGS = -debug -gc

TARGET = build/$(EXECUTABLE)

all: $(TARGET)

clean:
	rm -rf $(TARGET).o $(TARGET)

$(TARGET): $(SRC)
	$(DC) $(DCFLAGS) @$< -of$@
