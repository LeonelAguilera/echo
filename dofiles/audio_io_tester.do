force -freeze sim:/audio_io/clk 1 0, 0 {7 ns} -r {15 ns}
force -freeze sim:/audio_io/reset_n 0 0, 1 30 ns
force -freeze sim:/audio_io/bclk 1 0, 0 {162 ns} -r {325 ns}
force -freeze sim:/audio_io/dac_lrc 1 0, 0 {10416 ns} -r {20833 ns}
force -freeze sim:/audio_io/left_channel_out 16'hAAAA 0
force -freeze sim:/audio_io/right_channel_out 16'h5555 0
force -freeze sim:/audio_io/data_valid 1 0
