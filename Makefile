CC = gcc
COBC = cobc

all: build/db_wrapper.o build/banking

build/db_wrapper.o: src/db_wrapper.c
	mkdir -p build
	$(CC) -c src/db_wrapper.c -o build/db_wrapper.o

build/banking: src/banking.cob build/db_wrapper.o
	$(COBC) -x -o build/banking src/banking.cob build/db_wrapper.o -lsqlite3

run: all
	mkdir -p db
	./build/banking

clean:
	rm -rf build/* db/*.db

.PHONY: all run clean