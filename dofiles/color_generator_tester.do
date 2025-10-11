force -freeze sim:/pixel_color_generator/c0 0 0, 1 {5 ns} -r {10 ns}

force -freeze sim:/pixel_color_generator/h_count(0) 0 0, 1 {5 ns} -r {10 ns}
force -freeze sim:/pixel_color_generator/h_count(1) 0 0, 1 {10 ns} -r {20 ns}
force -freeze sim:/pixel_color_generator/h_count(2) 0 0, 1 {20 ns} -r {40 ns}
force -freeze sim:/pixel_color_generator/h_count(3) 0 0, 1 {40 ns} -r {80 ns}
force -freeze sim:/pixel_color_generator/h_count(4) 0 0, 1 {80 ns} -r {160 ns}
force -freeze sim:/pixel_color_generator/h_count(5) 0 0, 1 {160 ns} -r {320 ns}
force -freeze sim:/pixel_color_generator/h_count(6) 0 0, 1 {320 ns} -r {640 ns}
force -freeze sim:/pixel_color_generator/h_count(7) 0 0, 1 {640 ns} -r {1280 ns}
force -freeze sim:/pixel_color_generator/h_count(8) 0 0, 1 {1280 ns} -r {2560 ns}
force -freeze sim:/pixel_color_generator/h_count(9) 0 0, 1 {2560 ns} -r {5120 ns}
force -freeze sim:/pixel_color_generator/h_count(10) 0 0, 1 {5120 ns} -r {10240 ns}
force -freeze sim:/pixel_color_generator/v_count(0) 0 0, 1 {10240 ns} -r {20480 ns}
force -freeze sim:/pixel_color_generator/v_count(1) 0 0, 1 {20480 ns} -r {40960 ns}
force -freeze sim:/pixel_color_generator/v_count(2) 0 0, 1 {40960 ns} -r {81920 ns}
force -freeze sim:/pixel_color_generator/v_count(3) 0 0, 1 {81920 ns} -r {163840 ns}
force -freeze sim:/pixel_color_generator/v_count(4) 0 0, 1 {163840 ns} -r {327680 ns}
force -freeze sim:/pixel_color_generator/v_count(5) 0 0, 1 {327680 ns} -r {655360 ns}
force -freeze sim:/pixel_color_generator/v_count(6) 0 0, 1 {655360 ns} -r {1310720 ns}
force -freeze sim:/pixel_color_generator/v_count(7) 0 0, 1 {1310720 ns} -r {2621440 ns}
force -freeze sim:/pixel_color_generator/v_count(8) 0 0, 1 {2621440 ns} -r {5242880 ns}
force -freeze sim:/pixel_color_generator/v_count(9) 0 0, 1 {5242880 ns} -r {10485760 ns}
force -freeze sim:/pixel_color_generator/balance 8'b01100000 0
force -freeze sim:/pixel_color_generator/master_volume 8'b01100000 0
force -freeze sim:/pixel_color_generator/left_ear_volume 8'b01100000 0
force -freeze sim:/pixel_color_generator/right_ear_volume 8'b01100000 0
force -freeze sim:/pixel_color_generator/echo_intensity 8'b01100000 0
force -freeze sim:/pixel_color_generator/echo_duration 8'b01100000 0
