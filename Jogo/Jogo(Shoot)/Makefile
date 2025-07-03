# Makefile para compilar o jogo shoot.nasm (Assembly 64 bits)

# Nome dos arquivos
SRC = shoot.nasm
OBJ = shoot.o
BIN = shoot

# Montador e Linkador
ASM = nasm
LD  = ld

# Flags
ASMFLAGS = -f elf64
LDFLAGS  =

all: $(BIN)

$(BIN): $(OBJ)
	$(LD) $(LDFLAGS) -o $@ $^

$(OBJ): $(SRC)
	$(ASM) $(ASMFLAGS) -o $@ $<

run: $(BIN)
	./$(BIN)

clean:
	rm -f $(OBJ) $(BIN)
