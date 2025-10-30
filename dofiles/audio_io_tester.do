force -freeze sim:/audio_io_v2/c0 1 0, 0 {7 ns} -r {15 ns}
force -freeze sim:/audio_io_v2/fpga_reset 0 0, 1 30 ns
force -freeze sim:/audio_io_v2/left_channel_out 16'hAAAA 0
force -freeze sim:/audio_io_v2/right_channel_out 16'h5555 0
force -freeze sim:/audio_io_v2/data_valid 1 0, 0 {15 ns} -r {30 ns}
force -freeze sim:/audio_io_v2/AUD_ADCDAT 0 0, 1 600 ns, 0 1200 ns, 1 1800 ns, 0 2400 ns, 1 3000 ns, 0 3600 ns, 1 4200 ns, 0 4800 ns, 1 5400 ns, 0 6000 ns, 1 6600 ns, 0 7200 ns, 1 7800 ns, 0 8400 ns, 1 9000 ns, 0 9600 ns, 1 10200 ns, 0 10800 ns, 1 11400 ns, 0 12000 ns;

#force -freeze sim:/audio_io_v2/AUD_DACLRCK 1 0, 0 {307 ns} -r {19692 ns}
#force -freeze sim:/audio_io_v2/AUD_ADCLRCK 1 0, 0 {307 ns} -r {19692 ns}
#force -freeze sim:/audio_io_v2/AUD_BCLK 1 0, 0 {153 ns} -r {307 ns}
