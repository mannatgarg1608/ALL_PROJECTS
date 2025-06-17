import time

# Define a class to represent a Gate with name, dimensions, coordinates, pins, and connections
class Gate:
    def __init__(self, name, width, height):
        self.name = name
        self.width = width
        self.height = height
        self.x = 0  # Initial x position of the gate
        self.y = 0  # Initial y position of the gate
        self.pins = {}  # Dictionary to store pins and their relative positions
        self.connections = []  # List of connections to other gates

# Function to read the input file and parse gate definitions and connections
def read_input(filename):
    gates = {}
    
    with open(filename, "r") as file:
        number_of_connections=0
        for line in file:
                   
            parts = line.split()
            # If line describes a gate (gX width height)
            if len(parts) == 3 and parts[0].startswith('g'):
                name, width, height = parts
                gates[name] = Gate(name, int(width), int(height))
            # If line describes pins for a gate (pins gate_name x1 y1 x2 y2 ...)
            elif parts[0] == 'pins':
                gate_name = parts[1]
                for i in range(2, len(parts), 2):
                    pin_num = f"p{(i-2)//2 + 1}"
                    x, y = int(parts[i]), int(parts[i+1])
                    gates[gate_name].pins[pin_num] = (x, y)
            # If line describes a wire connection (wire gate1.pin gate2.pin)
            elif parts[0] == 'wire':
                number_of_connections=number_of_connections+1
                g1, p1 = parts[1].split('.')
                g2, p2 = parts[2].split('.')
                gates[g1].connections.append((g2, p1, p2))
                gates[g2].connections.append((g1, p2, p1))
    return list(gates.values()),number_of_connections  # Return list of all gates




# Calculate total wire length based on placed gates and their connections
def calculate_wire_length(placed_gates, all_gates):
    
    total_wire_length = 0
    processed_pins = set()

    # Create a dictionary of all gates by name for easy lookup
    gates_dict = {gate.name: gate for gate in all_gates}

    for gate in placed_gates:
        for pin in gate.pins:
            # Skip if we've already processed this pin
            if (gate.name, pin) in processed_pins:
                continue

            # connected_pins = [(gate.name, pin)]
            connected_coordinates = []

            # Get the absolute coordinates of the current pin
            x = gate.x + gate.pins[pin][0]
            y = gate.y + gate.pins[pin][1]
            connected_coordinates.append((x, y))

            # Find all connected pins
            for connected_gate_name, pin1, pin2 in gate.connections:
                if pin1 == pin:
                    connected_gate = gates_dict[connected_gate_name]
                    # If pin2 is already processed ,don't add to connected_coordinates
                    if (connected_gate_name, pin2) in processed_pins:
                        continue
                    else:
                    # Get the absolute coordinates of the connected pin
                        x = connected_gate.x + connected_gate.pins[pin2][0]
                        y = connected_gate.y + connected_gate.pins[pin2][1]
                        connected_coordinates.append((x, y))

            # Calculate the semiperimeter of the bounding box for all connected pins
            if connected_coordinates:
                min_x = min(coord[0] for coord in connected_coordinates)
                max_x = max(coord[0] for coord in connected_coordinates)
                min_y = min(coord[1] for coord in connected_coordinates)
                max_y = max(coord[1] for coord in connected_coordinates)
                
                semiperimeter = (max_x - min_x) + (max_y - min_y)
                total_wire_length += semiperimeter

            # Mark this pin as processed
            processed_pins.add((gate.name, pin))

    return total_wire_length

# Calculate wire length for a specific gate in relation to placed gates
def calculate_wire_length_gates(new_gate, placed_gates, all_gates):
    total_wire_length = 0
    gate_dict = {gate.name: gate for gate in all_gates}

    for connected_gate_name, pin1, pin2 in new_gate.connections:
        connected_gate = gate_dict[connected_gate_name]
        
        # Only consider connections to already placed gates
        if connected_gate in placed_gates:
            # Calculate absolute positions of the pins
            x1 = new_gate.x + new_gate.pins[pin1][0]
            y1 = new_gate.y + new_gate.pins[pin1][1]
            x2 = connected_gate.x + connected_gate.pins[pin2][0]
            y2 = connected_gate.y + connected_gate.pins[pin2][1]
            
            # Calculate distance between the pins
            wire_length = abs(x2 - x1) + abs(y2 - y1)
            total_wire_length += wire_length

    return total_wire_length
    

# Calculate the bounding box size for all placed gates
def calculate_bounding_box(gates):    
    
    min_x = min(gate.x for gate in gates)
    max_x = max(gate.x + gate.width for gate in gates)
    min_y = min(gate.y for gate in gates) 
    max_y = max(gate.y + gate.height for gate in gates)
    return max_x - min_x, max_y - min_y  # Return width and height of the bounding box

# Check if a new gate overlaps with any already placed gates
def is_overlapping(new_gate, placed_gates):
    for gate in placed_gates:
        if not (new_gate.x + new_gate.width <= gate.x or
                new_gate.x >= gate.x + gate.width or
                new_gate.y + new_gate.height <= gate.y or
                new_gate.y >= gate.y + gate.height):
            return True  # Overlapping detected
    return False

# Greedy gate placement algorithm
def greedy_placement(gates,connection_number):
    # Sort gates by number of connections (in descending order)
    sorted_gates_list = sorted(gates, key=lambda t: len(t.connections), reverse=True)
    n = len(gates)
    

    # Place the gate with the most connections at the center (origin)
    center_gate = sorted_gates_list[0]
    center_gate.x = 0
    center_gate.y = 0
    placed_gates = [center_gate]
    remaining_gates = sorted_gates_list[1:]
    
    # Directions for placement (right, top, left, bottom)
    
    while remaining_gates:
        best_gate = None
        best_position = None
        best_wire_length = float('inf')
        
        for gate in remaining_gates[:4]:  # Consider top 4 gates with most connections
            
            for placed_gate in placed_gates:
                
                for i in range(4):  # Try four different placements (right, top, left, bottom)
                    if i == 0:  # Place on the right of the current gate
                        x = placed_gate.x + placed_gate.width
                        y = placed_gate.y
                    elif i == 1:  # Place above the current gate
                        x = placed_gate.x
                        y = placed_gate.y + placed_gate.height
                    elif i == 2:  # Place below the current gate
                        x = placed_gate.x
                        y = placed_gate.y - gate.height
                    else:  # Place on the left of the current gate
                        x = placed_gate.x - gate.width
                        y = placed_gate.y
                    
                    # Temporarily place the gate at this position
                    gate.x, gate.y = x, y
                    
                    # Check for overlaps
                    if not is_overlapping(gate, placed_gates):
                        placed_gates.append(gate)  # Temporarily place the gate
                        
                        
                        # Calculate wire length for the placement
                        
                        if n*connection_number<250*3000:                      
                        
                            
                            wire_length = calculate_wire_length(placed_gates, gates)
                        else:
                            wire_length = calculate_wire_length_gates(gate,placed_gates, gates)
                        
                        # Update best placement if this one is better
                        if wire_length < best_wire_length:
                            best_gate = gate
                            best_position = (x, y)
                            best_wire_length = wire_length
                        
                        placed_gates.pop()  # Remove temporary placement
        
        # Place the best gate permanently
        if best_gate:
            best_gate.x, best_gate.y = best_position
            placed_gates.append(best_gate)
            remaining_gates.remove(best_gate)
    
    return placed_gates

# Main function to read input, perform greedy placement, and output results
def main():
    start_time = time.time()  # Start time measurement
    
    gates,connection_number = read_input("input.txt")
    placed_gates = greedy_placement(gates,connection_number)
    wire_length = calculate_wire_length(placed_gates, gates)
    bounding_width, bounding_height = calculate_bounding_box(placed_gates)
    
    with open("output.txt", "w") as file:
        file.write(f"Total Wire Length: {wire_length}\n")
        file.write(f"bounding_box {bounding_width} {bounding_height}\n")
        
        # Shift the coordinates so that the bounding box starts at (0, 0)
        a = float('inf')
        b = float('inf')
        for gate in placed_gates:
            a = min(a, gate.x)
            b = min(b, gate.y)
        for gate in placed_gates:
            file.write(f"{gate.name} {gate.x - a} {gate.y - b}\n")
    
    end_time = time.time()  # End time measurement
    execution_time = end_time - start_time
    print(f"Execution time: {execution_time:.4f} seconds")  # Print execution time

if __name__ == "__main__":
    main()