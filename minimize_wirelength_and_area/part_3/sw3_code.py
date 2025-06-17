import time

class Gate:
    def __init__(self, name, width, height, delay):
        self.name = name
        self.width = width
        self.height = height
        self.x1 = 0  # Initial x position of the gate for greedy_placement
        self.y1 = 0  # Initial y position of the gate for greedy_placement
        self.delay = delay
        self.pins = {}  #  stores pins and their relative positions
        self.connections = []  # List of connections to other gates


class Circuit:
    def __init__(self):
        self.gates= {}
        self.connections = []  # List of (source_pin, dest_pin)
        self.primary_inputs = set() #stores primary inputs (1 for each gate)
        self.primary_outputs = set() #stores primary outputs (1 for each gate)
        self.wire_delay = 0

    # Function to read the input file
    def read_input(self, filename):
        with open(filename, "r") as file:
            for line in file:
                parts = line.split()
                # If line describes a gate (gX width height delay)
                if len(parts) == 4 and parts[0].startswith('g'):
                    name, width, height, delay = parts
                    self.gates[name] = Gate(name, int(width), int(height), int(delay))
                # If line describes pins for a gate (pins gate_name x1 y1 x2 y2 ...)
                elif parts[0] == 'pins':
                    gate_name = parts[1]
                    for i in range(2, len(parts), 2):
                        pin_num = f"p{(i-2)//2 + 1}"
                        x, y = int(parts[i]), int(parts[i + 1])
                        self.gates[gate_name].pins[pin_num] = (x, y)
                # If line describes a wire connection (wire gate1.pin gate2.pin)
                elif parts[0] == 'wire':
                    g1, p1 = parts[1].split('.')
                    g2, p2 = parts[2].split('.')
                
                    self.connections.append((f"{g1}.{p1}", f"{g2}.{p2}"))
                    self.gates[g1].connections.append((g2, p1, p2))
                    self.gates[g2].connections.append((g1, p2, p1))
                # Read the wire delay
                elif parts[0] == 'wire_delay':
                    self.wire_delay = int(parts[1])


            # Identify primary inputs and outputs
        self.get_primary()

        
    def get_primary(self):
        # find primary inputs and outputs based on connections
        srcs = set()
        dsts = set()
        all_src=set()
        all_dst=set()
         #obtaining values from connections
        for src, dst in self.connections:
            g1, p1 = src.split('.')
            g2, p2 = dst.split('.')
     # here it is specifying origin of the connections and the separating where it ends for individua; connectiions
            srcs.add((g1,p1))
            dsts.add((g2,p2))

        
        for gate in self.gates.values():
            src_bool=True
            dst_bool=True
            for pin in gate.pins:
                # print(gate.pins[pin][0])
               
                if gate.pins[pin][0]==0 :
                    # print(gate.pins[pin][0])
                    if src_bool:
                        all_src.add((gate.name,pin))
                        src_bool=False
                else:
                    if dst_bool:

                        all_dst.add((gate.name,pin))
                        dst_bool=False
        
     # it contains all the primary inputs and outputs since it subtracts the one connected from all the pins 
        self.primary_outputs = all_dst - srcs
        self.primary_inputs = all_src - dsts
        # print("pi")
        # for pi in self.primary_inputs:
        #     print(pi)
        
    
    def get_total_paths(self, start, end):
        """Find all possible paths from start to end pin using an iterative approach."""
      # starting with a stack with containg present postion and the path traced 
        stack = [(start, [start])]

    
        all_paths = []
        # print(f"Finding paths from {start[0].name}.{start[1]} to {end[0].name}.{end[1]}")

         
        is_visited= [False]*(len(self.gates)+ 1)
        delayed = [False]*(len(self.gates) + 1)
        parent = [-1]*(len(self.gates) + 1)
        res = False 
        
        while stack:
     # exploring which gate is present and tracing the path further 

            (current_gate, current_pin), path = stack.pop()
            x=current_gate.name
            y=int(x[1:])
            
            is_visited[y]=True
            # print(f"Exploring: {current_gate.name}.{current_pin}")
            # if i have reached at last pin of all that is traced a pth between start and end i transfer the path to my bigger matrix with all the paths
            if (current_gate, current_pin) == end:
                all_paths.append(path)
                # print(f"Path found: {' -> '.join([f'{g.name}.{p}' for g, p in path])}")
                continue

            # Check for connections to right pins within the same gate
            if current_gate.pins[current_pin][0]==0 and delayed[y]==False:
                for pin, coords in current_gate.pins.items():
                    if coords[0] != 0 and pin != current_pin:  # This is a right pin (output)
                        delayed[y]=True
                        next_node = (current_gate, pin)
                        # print(f" checking  internal connection: {current_gate.name}.{pin}")
        # if i have reached my last node i add it to my path and gets one complete path 
                        if next_node == end:
                            new_path = path + [end]
                            all_paths.append(new_path)

                            # path_str = "Path found: "
                            # for i, (g, p) in enumerate(new_path):
                            #     if i > 0:
                            #         path_str += " -> "  
                            #     path_str += f"{g.name}.{p}"  # Add the current element

                            # print(path_str)

                        else:
                            new_path = path + [next_node]
                            stack.append((next_node, new_path))

            # Check for connections to other gates
            for g2, p1, p2 in current_gate.connections:
                a=g2
                z=int(a[1:])
            
                if p1 == current_pin and is_visited[z]==False:

                    next_node = (self.gates[g2], p2)
                    # print(f" Check for: {g2}.{p2}")
                    if next_node == end:
                        new_path = path + [end]
                        all_paths.append(new_path)
                        path_str = "Path found: "
                        for g, p in new_path:
                            path_str += f"{g.name}.{p} -> "
                        # Remove the last ' -> ' at the end of the string
                        path_str = path_str[:-4]  
                        # print(path_str)

                    else:
                        new_path = path + [next_node]
                        stack.append((next_node, new_path))

        # print(f"No. of paths found: {len(all_paths)}")
        return all_paths

    def get_critical_path(self):
        #Find the critical path and its delay based on connections between primary inputs and outputs
        max_delay = 0
        critical_path = None
        wire_length=0

        # print(f"Primary inputs: {self.primary_inputs}")
        # print(f"Primary outputs: {self.primary_outputs}")

        for pi in self.primary_inputs:
            gate_A = self.gates[pi[0]]
            for po in self.primary_outputs:
                gate_B = self.gates[po[0]]
                # print(f"\nChecking paths from {pi} to {po}")
                
                paths = self.get_total_paths((gate_A,pi[1]), (gate_B,po[1]))

                # if not paths:
                #     print(f"No paths found from {pi} to {po}")
                #     continue

                for path in paths:
                    path_delay,wire_length_path = self.calculate_path_delay(path)
                    # print(f"Path delay: {path_delay}")
                    if path_delay > max_delay:
                        max_delay = path_delay
                        critical_path = path
                        wire_length=wire_length_path

        # if critical_path:
        #     print(f"Critical path found: {' -> '.join([f'{g.name}.{p}' for g, p in critical_path])}")
        #     print(f"Critical path delay: {max_delay}")
        #     print(f"Primary inputs: {self.primary_inputs}")
        #     print(f"Primary outputs: {self.primary_outputs}")
        # else:
        #     print("No critical path found.")

        return critical_path, max_delay,wire_length
    


    # Update calculate_path_delay method to work with the new path format
    def calculate_path_delay(self, path):
        """Calculate the delay along a given path, including gate delays of A and B."""
        total_delay = 0
        wire_length=0
        
        for i in range(len(path) - 1):
            gate1, pin1 = path[i]
            gate2, pin2 = path[i + 1]
            if gate1.name==gate2.name:
                total_delay+=gate1.delay
            else:
                wire_length = self.calculate_wire_length_pins([f"{gate1.name}.{pin1}", f"{gate2.name}.{pin2}"])
                wire_delay = self.wire_delay * wire_length
                total_delay += wire_delay
            

        return total_delay, wire_length


    def calculate_wire_length_pins(self, pins_tup):
        """Calculate wire length between connected pins."""
        connected_coordinates = []
        pin11=pins_tup[0]
        gate_name, pin_name = pin11.split('.')
        gate = self.gates[gate_name]
        
        wire_length=0
        
        x = gate.x1 + gate.pins[pin_name][0]
        y = gate.y1 + gate.pins[pin_name][1]
        

        connected_coordinates.append((x, y))
        
        # print(x,y)
       
        for connected_gate_name, pin1, pin2 in gate.connections:
            
            if pin1 == pin_name:
                
                connected_gate = self.gates[connected_gate_name]
                
                x = connected_gate.x1 + connected_gate.pins[pin2][0]
                y = connected_gate.y1 + connected_gate.pins[pin2][1]
                
                
                connected_coordinates.append((x, y))
                # print(x,y)

        if connected_coordinates:
            min_x = min(coord[0] for coord in connected_coordinates)
            max_x = max(coord[0] for coord in connected_coordinates)
            min_y = min(coord[1] for coord in connected_coordinates)
            max_y = max(coord[1] for coord in connected_coordinates)

            
            wire_length = (max_x - min_x) + (max_y - min_y)

        # Debug: Print wire length
        # print(f"Wire length between {pins_tup[0]} and {pins_tup[1]}: {wire_length}")

        return wire_length


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
            x = gate.x1 + gate.pins[pin][0]
            y = gate.y1 + gate.pins[pin][1]
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
                        x = connected_gate.x1 + connected_gate.pins[pin2][0]
                        y = connected_gate.y1+ connected_gate.pins[pin2][1]
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
            x1 = new_gate.x1 + new_gate.pins[pin1][0]
            y1 = new_gate.y1 + new_gate.pins[pin1][1]
            x2 = connected_gate.x1 + connected_gate.pins[pin2][0]
            y2 = connected_gate.y1 + connected_gate.pins[pin2][1]
            
            # Calculate distance between the pins
            wire_length = abs(x2 - x1) + abs(y2 - y1)
            total_wire_length += wire_length

    return total_wire_length
    

# Calculate the bounding box size for all placed gates
def calculate_bounding_box(gates):    
    
    min_x = min(gate.x1 for gate in gates)
    max_x = max(gate.x1 + gate.width for gate in gates)
    min_y = min(gate.y1 for gate in gates) 
    max_y = max(gate.y1 + gate.height for gate in gates)
    return max_x - min_x, max_y - min_y  # Return width and height of the bounding box

# Check if a new gate overlaps with any already placed gates
def is_overlapping(new_gate, placed_gates):
    for gate in placed_gates:
        if not (new_gate.x1 + new_gate.width <= gate.x1 or
                new_gate.x1 >= gate.x1 + gate.width or
                new_gate.y1 + new_gate.height <= gate.y1 or
                new_gate.y1 >= gate.y1 + gate.height):
            return True  # Overlapping detected
    return False

# Greedy gate placement algorithm
def greedy_placement(gates,connection_number):
    # Sort gates by number of connections (in descending order)
    sorted_gates_list = sorted(gates, key=lambda t: len(t.connections), reverse=True)
    n = len(gates)
    

    # Place the gate with the most connections at the center (origin)
    center_gate = sorted_gates_list[0]
    center_gate.x1 = 0
    center_gate.y1 = 0
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
                        x = placed_gate.x1 + placed_gate.width
                        y = placed_gate.y1
                    elif i == 1:  # Place above the current gate
                        x = placed_gate.x1
                        y = placed_gate.y1 + placed_gate.height
                    elif i == 2:  # Place below the current gate
                        x = placed_gate.x1
                        y = placed_gate.y1 - gate.height
                    else:  # Place on the left of the current gate
                        x = placed_gate.x1 - gate.width
                        y = placed_gate.y1
                    
                    # Temporarily place the gate at this position
                    gate.x1, gate.y1 = x, y
                    
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
            best_gate.x1, best_gate.y1 = best_position
            placed_gates.append(best_gate)
            remaining_gates.remove(best_gate)
    
    return placed_gates




def main():
    start_time = time.time()

    circuit = Circuit()
    circuit.read_input("input.txt")

    placed_gates = greedy_placement(list(circuit.gates.values()), len(circuit.connections))
    min_x = min(gate.x1 for gate in placed_gates)
    min_y = min(gate.y1 for gate in placed_gates)
    for gate in placed_gates:
        gate.x1-=min_x
        gate.y1-=min_y

    bounding_width, bounding_height = calculate_bounding_box(placed_gates)
    critical_path1, critical_path_delay1, wire_length1= circuit.get_critical_path()
    with open("output.txt", "w") as file:
        
       
        file.write(f"bounding_box {bounding_width} {bounding_height}\n")
        if critical_path1:
            file.write(f"Critical path found: {' -> '.join([f'{g.name}.{p}' for g, p in critical_path1])}\n")
        else:
            raise Exception("No path found")
        file.write(f"critical_path_delay {critical_path_delay1}\n")
       
        
        for gate in placed_gates:
            file.write(f"{gate.name} {gate.x1 } {gate.y1 }\n")

    end_time = time.time()
    execution_time = end_time - start_time
    print(f"Execution time: {execution_time:.4f} seconds")


if __name__ == "__main__":
    main()