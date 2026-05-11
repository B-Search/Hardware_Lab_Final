transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+frame_buffer  -L xil_defaultlib -L xpm -L blk_mem_gen_v8_4_12 -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.frame_buffer xil_defaultlib.glbl

do {frame_buffer.udo}

run 1000ns

endsim

quit -force
