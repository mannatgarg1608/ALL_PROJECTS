# Compiler
CXX = g++

# Compiler flags
CXXFLAGS =  -std=c++11

# Targets
all: forward no_forward

forward: forward.cpp
		$(CXX) $(CXXFLAGS) -o forward processor.cpp forward.cpp 

no_forward: no_forward.cpp
		$(CXX) $(CXXFLAGS) -o no_forward  processor.cpp no_forward.cpp



clean:
	rm -f forward no_forward 
