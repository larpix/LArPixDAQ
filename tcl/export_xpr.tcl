open_project ./LArPixDAQ/LArPixDAQ.xpr
write_project_tcl -force recreate_xpr.tcl
file rename -force recreate_xpr.tcl tcl/recreate_xpr.tcl
