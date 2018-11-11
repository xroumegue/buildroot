fdt addr ${fdt_addr_r}
fdt resize
fdt set /amba/serial@e0000000 status "ko"
