export BENCHMARK=/home/itecgo/Flexim2/benchmarks/Olden/mst/original/mst.mipsel
export ARGS="10"

/home/itecgo/Desktop/SimIt-MIPS-1.0/emulator/emips -v $BENCHMARK $ARGS > $BENCHMARK.emips_out
/home/itecgo/Flexim2/code/Flexim2/flexim2 $BENCHMARK $ARGS > $BENCHMARK.flexim2_out

# 8q ok
# array ok
# cmp brk not implemented.
# cq Lwc1 not implemented.
# dag ok
# decl ok
# eight ok
# fact2 ok
# fib ok
# fib_mem ok
# fields ok
# funcptr_test ok
# grep syscall fstat has not been implemented yet.
# hyper ok
# ifthen ok
# incr ok
# init ok
# limits ok
# mm_int ok
# mod ok
# nested Lwc1 not implemented.
# paranoia compilation failed.
# sort ok
# struct ok
# switch ok
# wc syscall read has not been implemented yet.
# wf1 syscall read has not been implemented yet.

