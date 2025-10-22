force -freeze sim:/point_computation/angle 8'd127 0
force -freeze sim:/point_computation/c0 1 0, 0 {5 ns} -r {10 ns}
force -freeze sim:/point_computation/v_count(0) 0 0, 1 {6715 ns} -r {13430 ns}
force -freeze sim:/point_computation/v_count(1) 0 0, 1 {13430 ns} -r {26860 ns}
force -freeze sim:/point_computation/v_count(2) 0 0, 1 {26810 ns} -r {53720 ns}
force -freeze sim:/point_computation/v_count(3) 0 0, 1 {53720 ns} -r {107440 ns}
force -freeze sim:/point_computation/v_count(4) 0 0, 1 {107440 ns} -r {214880 ns}
force -freeze sim:/point_computation/v_count(5) 0 0, 1 {214880 ns} -r {429760 ns}
force -freeze sim:/point_computation/v_count(6) 0 0, 1 {429760 ns} -r {859520 ns}
force -freeze sim:/point_computation/v_count(7) 0 0, 1 {859520 ns} -r {1719040 ns}
force -freeze sim:/point_computation/v_count(8) 0 0, 1 {1719040 ns} -r {3438080 ns}
force -freeze sim:/point_computation/v_count(9) 0 0, 1 {3438080 ns} -r {6876160 ns}
