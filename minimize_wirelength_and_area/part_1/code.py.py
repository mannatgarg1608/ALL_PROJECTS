import math

# Declared a class
class Gates:
    def __init__(self, name, width, height):
        self.name = name
        self.width = width
        self.height = height
        self.x = 0  # x-coordinate of bottom-left corner
        self.y = 0  # y-coordinate of bottom-left corner


def packing_gates(gates):#returns dimensions and minimum area of bounding box
   
    max_width = 0
    sum_of_widths = 0
    min_area = float('inf')
    
    for gate in gates:
        
        max_width = max(max_width, gate.width)
        sum_of_widths += gate.width
    
   
    # Sorted the gates in decreasing order to minimize gaps within a row
    gates.sort(key=lambda gate: gate.height, reverse=True)
    #width and height of bounding box
    bounding_width = 0
    bounding_height = 0
    #created a list to store coordinates of the min_area case
    best_coordinates = []  
    #iterating through all possible widths of bounding box to find minimum area
    for max_row_width in range(max_width, sum_of_widths + 1):
        #stores rows which inside them stores gates
        recorded_packing = []
        
        curr_height = 0 #stores current height of bounding box
        
        max_width_used = 0 #stores the maximum width used among all the rows
        #count is 0 when no gate is placed(just to handle the first gate of first row)
        count = 0
         
        row_width = 0   #used width of the current row 
        
        for gate in gates:
            # check if there is enough remaining space to keep the gate in the row; if not, then create a new row and place it there
            #also we check if its the first gate or not(if it is first then we have to append a row)
            if row_width + gate.width <= max_row_width and count != 0:
                gate.x = row_width        
                row_width += gate.width
                gate.y = recorded_packing[-1][0].y
                recorded_packing[-1].append(gate)
            else:
                gate.x = 0
                gate.y = curr_height
                recorded_packing.append([gate])
                curr_height += gate.height
                row_width = gate.width
            
            max_width_used = max(max_width_used, gate.x + gate.width)
            count += 1
        #we check if this area is lesser than the minimum area we have found yet,if yes then we update the variables
        if min_area > max_width_used * curr_height:
            bounding_width = max_width_used
            bounding_height = curr_height
            min_area =bounding_width * bounding_height
            # we store coordinates of all gates for the min_area case
            best_coordinates = [(gate.name, gate.x, gate.y) for gate in gates]

    return bounding_width, bounding_height, best_coordinates

# Taking input using file handling and then computing width and height and storing them in list of objects
gates = []
file=open("input.txt","r")
    
for line in file:
    n = line.split()
    #check if the line has exactly three elements
    if len(n) == 3:
        name = n[0]
        width = int(n[1])
        height = int(n[2])
        gate = Gates(name, width, height)
        gates.append(gate)

# Calling the function
width, height, best_coordinates = packing_gates(gates)


# Sending the output to the output file
fileo=open("output.txt","w")
fileo.write(f"bounding_box {width} {height}\n")

    # Sending dimensions and coordinates of individual gates for the min_area case
for name, x, y in best_coordinates:
    fileo.write(f"{name} {x} {y}\n")