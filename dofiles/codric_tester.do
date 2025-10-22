add wave sim:/codric/*
force -freeze sim:/codric/c0 1 0, 0 {5 ns} -r {10 ns}
force -freeze sim:/codric/start 0 0
force -freeze sim:/codric/radius 8'h2C 0
force -freeze sim:/codric/theta 10'h01C 0
