ROOT_DIR=`pwd`/.

action=-B
#action=clean

#cd $ROOT_DIR/CPU2006/429.mcf/original;make $action
#cd $ROOT_DIR/CPU2006/429.mcf/original;make -f Makefile.mipsel $action

#cd $ROOT_DIR/CPU2006/429.mcf/prepush;make $action
#cd $ROOT_DIR/CPU2006/429.mcf/prepush;make -f Makefile.mipsel $action

#cd $ROOT_DIR/CPU2006/462.libquantum/original;make $action
#cd $ROOT_DIR/CPU2006/462.libquantum/original;make -f Makefile.mipsel $action

#cd $ROOT_DIR/CPU2006/462.libquantum/prepush;make $action
#cd $ROOT_DIR/CPU2006/462.libquantum/prepush;make -f Makefile.mipsel $action

cd $ROOT_DIR/Olden/em3d/original;make $action
cd $ROOT_DIR/Olden/em3d/original;make -f Makefile.mipsel $action

#cd $ROOT_DIR/Olden/em3d/prepush;make $action
#cd $ROOT_DIR/Olden/em3d/prepush;make -f Makefile.mipsel $action

cd $ROOT_DIR/Olden/mst/original;make $action
cd $ROOT_DIR/Olden/mst/original;make -f Makefile.mipsel $action

#cd $ROOT_DIR/Olden/mst/prepush;make $action
#cd $ROOT_DIR/Olden/mst/prepush;make -f Makefile.mipsel $action
