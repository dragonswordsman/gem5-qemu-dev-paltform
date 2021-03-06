#!/bin/bash
set -e
source config.sh

if [ ! -f $CONFIG_DIR_GEM5/build/X86/gem5.opt ]; then
  echo -e "${COLOR_RED} Please build gem5 before running! ${COLOR_NORMAL}"
  exit -1
fi

cd $CONFIG_DIR_DISKS

if [ ! -f linux-bigswap2.img ]; then
  dd if=/dev/zero of=linux-bigswap2.img bs=512 count=102400
fi

if [ ! -f $CONFIG_DIR_BINARIES/x86_64-vmlinux-2.6.22.9 ]; then
  # A dummy kernel to cope with hardcode
  touch $CONFIG_DIR_BINARIES/x86_64-vmlinux-2.6.22.9
fi

if [ ! -f $CONFIG_DIR_FS_SCRIPTS/on-boot.sh ]; then
  mkdir -p $CONFIG_DIR_FS_SCRIPTS
  touch $CONFIG_DIR_FS_SCRIPTS/on-boot.sh
fi

echo -e "${COLOR_GREEN}Note: Execte 'cd $CONFIG_DIR_GEM5/util/term && sudo ./m5term 127.0.0.1 3456' to listen to gem5.${COLOR_NORMAL}"

CONFIG_TOTAL_SIZE=$((CONFIG_VM_DRAM_SIZE + CONFIG_VM_PM_SIZE))
CONFIG_PM_BASE=$((CONFIG_VM_DRAM_SIZE + 1))

cd $CONFIG_DIR_GEM5
./build/X86/gem5.opt \
  --outdir=$CONFIG_DIR_OUTPUT_FS \
  configs/example/fs.py \
    --num-cpus=$CONFIG_VM_NUM_CPUS \
    --cpu-type=$CONFIG_VM_CPU_TYPE --cpu-clock=$CONFIG_VM_CPU_CLK \
    --caches --cacheline_size=$CONFIG_VM_CACHELINE_LEN \
    --l1i_size=$CONFIG_VM_L1I_SIZE --l1i_assoc=$CONFIG_VM_L1I_ASSOC \
    --l1d_size=$CONFIG_VM_L1D_SIZE --l1d_assoc=$CONFIG_VM_L1D_ASSOC \
    --l2cache --l2_size=$CONFIG_VM_L2_SIZE --l2_assoc=$CONFIG_VM_L2_ASSOC \
    --mem-type=$CONFIG_MEM_TYPE \
    --mem-size=${CONFIG_TOTAL_SIZE}GB \
    --kernel=x86_64-vm$CONFIG_KERNEL \
    --disk-image=${CONFIG_OS/iso/img} \
    --command-line="earlyprintk=ttyS0 console=ttyS0 lpj=7999923 root=/dev/hda1 memmap=${CONFIG_PM_BASE}G!${CONFIG_VM_PM_SIZE}G" \
    | tee -a $CONFIG_DIR_OUTPUT_FS/log
  # --script="$CONFIG_DIR_FS_SCRIPTS/on-boot-up.sh"
