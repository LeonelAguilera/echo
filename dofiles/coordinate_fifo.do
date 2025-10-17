force -freeze sim:/coordinate_fifo/c0 0 0, 1 {5 ns} -r 10
force -freeze sim:/coordinate_fifo/load_new 0 0, 1 {40 ns} -r 200
force fpga_reset_n 0 0ns, 1 20ns, 0 214ns
force new_x_coordinate 8'h00 0200ns, 8'h01 0400ns, 8'h02 0600ns, 8'h03 0800ns, 8'h04 0900ns, 8'h05 1000ns, 8'h06 1100ns, 8'h07 1200ns, 8'h08 1300ns, 8'h09 1400ns, 8'h0A 1500ns
force new_y_coordinate 8'h7F 0200ns, 8'hEA 0400ns, 8'hF2 0600ns, 8'h90 0800ns, 8'h1F 0900ns, 8'h05 1000ns, 8'hEA 1100ns, 8'hF2 1200ns, 8'h90 1300ns, 8'h1F 1400ns, 8'h05 1500ns
force next_data 0 0200ns, 0 0400ns, 1 0600ns, 0 640ns, 1 660ns, 0 680ns, 1 700ns, 0 720ns, 1 740ns, 0 760ns, 1 780ns, 0 800ns,  1 820ns, 0 840ns, 1 860ns, 0 880ns, 0 1500ns

