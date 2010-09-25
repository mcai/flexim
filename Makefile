EXECUTABLE = flexim
SRC = build.rf

DC = dmd
# DCFLAGS = -w -wi
# DCFLAGS = -release -O
DCFLAGS = -debug -gc -w -wi

DCFLAGS += -I/home/itecgo/Flexim2/refs/gtkD_trunk/src -L-Llib -L-ldl -L-lgtkd -L-lgtkdgl -L-lgtkdsv

TARGET = build/$(EXECUTABLE)

all: $(TARGET)

clean:
	rm -rf $(TARGET).o $(TARGET)

$(TARGET): $(SRC)
	$(DC) $(DCFLAGS) @$< -of$@
	rm -rf $(TARGET).o
