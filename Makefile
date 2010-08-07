EXECUTABLE = flexim
SRC = build.rf

DC = dmd
# DCFLAGS = 
DCFLAGS = -debug -gc

TARGET = bin/$(EXECUTABLE)

all: $(TARGET)

clean:
	rm -rf $(TARGET).o $(TARGET)

$(TARGET): $(SRC)
	$(DC) $(DCFLAGS) @$< -of$@
