CC = g++
CFLAGS = -std=c++17 -O3

all: L1simulate

L1simulate: simulator.cpp
	$(CC) $(CFLAGS) -o L1simulate simulator.cpp

clean:
	rm -f L1simulate *.o