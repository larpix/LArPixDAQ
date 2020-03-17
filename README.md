# LArPix DAQ

This repo contains the source code for the A7-CMOD used as part of the raspberrypi/artix7 LArPix control board.

## Regenerating vivado project

To generate the vivado project from this repo::

    git clone <repo address>
    cd LArPixDAQ
    vivado -mode batch -source tcl/recreate_xpr.tcl

## Exporting this project to a tcl script

After modifying the project, to generate the tcl script used for version control::

    vivado -mode batch -source tcl/export_xpr.tcl