force c0 0 0, 1 {5 ns} -r {10 ns}

force h_count(0) 0 0, 1 {5 ns} -r {10 ns}
force h_count(1) 0 0, 1 {10 ns} -r {20 ns}
force h_count(2) 0 0, 1 {20 ns} -r {40 ns}
force h_count(3) 0 0, 1 {40 ns} -r {80 ns}
force h_count(4) 0 0, 1 {80 ns} -r {160 ns}
force h_count(5) 0 0, 1 {160 ns} -r {320 ns}
force h_count(6) 0 0, 1 {320 ns} -r {640 ns}
force h_count(7) 0 0, 1 {640 ns} -r {1280 ns}
force h_count(8) 0 0, 1 {1280 ns} -r {2560 ns}
force h_count(9) 0 0, 1 {2560 ns} -r {5120 ns}
force h_count(10) 0 0, 1 {5120 ns} -r {10240 ns}
force v_count(0) 0 0, 1 {10240 ns} -r {20480 ns}
force v_count(1) 0 0, 1 {20480 ns} -r {40960 ns}
force v_count(2) 0 0, 1 {40960 ns} -r {81920 ns}
force v_count(3) 0 0, 1 {81920 ns} -r {163840 ns}
force v_count(4) 0 0, 1 {163840 ns} -r {327680 ns}
force v_count(5) 0 0, 1 {327680 ns} -r {655360 ns}
force v_count(6) 0 0, 1 {655360 ns} -r {1310720 ns}
force v_count(7) 0 0, 1 {1310720 ns} -r {2621440 ns}
force v_count(8) 0 0, 1 {2621440 ns} -r {5242880 ns}
force v_count(9) 0 0, 1 {5242880 ns} -r {10485760 ns}

force fpga_reset_n 0 20ns, 1 40ns, 0 60ns

force new_x_coordinate 8'h00 0, 8'd0   100ns, 8'd16  140ns, 8'd32  180ns, 8'd48  220ns, 8'd64  260ns, 8'd80 300ns, 8'd96 340ns, 8'd112 380ns, 8'd128 420ns, 8'd144 460ns, 8'd160 500ns
force new_y_coordinate 8'h00 0, 8'd127 100ns, 8'd218 140ns, 8'd253 180ns, 8'd212 220ns, 8'd119 260ns, 8'd30 300ns, 8'd0  340ns, 8'd46  380ns, 8'd141 420ns, 8'd227 460ns, 8'd252 500ns
force load_new '0' 0ns, '1' 110ns, '0' 130ns, '1' 150ns, '0' 170ns, '1' 190ns, '0' 210ns, '1' 230ns, '0' 250ns, '1' 270ns, '0' 290ns, '1' 310ns, '0' 330ns, '1' 350ns, '0' 370ns, '1' 390ns, '0' 410ns, '1' 430ns, '0' 450ns, '1' 470ns, '0' 490ns, '1' 510ns, '0' 530ns
