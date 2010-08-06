DC = dmd
DFLAGS = 
#DFLAGS = -debug -gc


BIN=bin
D_FILES = build.rf
TARGET = $(BIN)/flexim

all: $(TARGET)

$(TARGET): $(D_FILES)
	$(DC) $(DFLAGS) @$< -of$@

clean:
	rm -rf $(TARGET).o $(TARGET)
