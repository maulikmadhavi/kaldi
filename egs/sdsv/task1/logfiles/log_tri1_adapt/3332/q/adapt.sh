#!/bin/bash
cd /home/maulik/Tools/kaldi/egs/sdsv/task1
. ./path.sh
( echo '#' Running on `hostname`
  echo '#' Started at `date`
  set | grep SLURM | while read line; do echo "# $line"; done
  echo -n '# '; cat <<EOF
local/tri1_adapt.sh ${SLURM_ARRAY_TASK_ID} 3332 
EOF
) >logfiles/log_tri1_adapt/3332/adapt.$SLURM_ARRAY_TASK_ID.log
if [ "$CUDA_VISIBLE_DEVICES" == "NoDevFiles" ]; then
  ( echo CUDA_VISIBLE_DEVICES set to NoDevFiles, unsetting it... 
  )>>logfiles/log_tri1_adapt/3332/adapt.$SLURM_ARRAY_TASK_ID.log
  unset CUDA_VISIBLE_DEVICES
fi
time1=`date +"%s"`
 ( local/tri1_adapt.sh ${SLURM_ARRAY_TASK_ID} 3332  ) &>>logfiles/log_tri1_adapt/3332/adapt.$SLURM_ARRAY_TASK_ID.log
ret=$?
sync || true
time2=`date +"%s"`
echo '#' Accounting: begin_time=$time1 >>logfiles/log_tri1_adapt/3332/adapt.$SLURM_ARRAY_TASK_ID.log
echo '#' Accounting: end_time=$time2 >>logfiles/log_tri1_adapt/3332/adapt.$SLURM_ARRAY_TASK_ID.log
echo '#' Accounting: time=$(($time2-$time1)) threads=1 >>logfiles/log_tri1_adapt/3332/adapt.$SLURM_ARRAY_TASK_ID.log
echo '#' Finished at `date` with status $ret >>logfiles/log_tri1_adapt/3332/adapt.$SLURM_ARRAY_TASK_ID.log
[ $ret -eq 137 ] && exit 100;
touch logfiles/log_tri1_adapt/3332/q/done.24931.$SLURM_ARRAY_TASK_ID
exit $[$ret ? 1 : 0]
## submitted with:
# sbatch --export=PATH  --ntasks-per-node=1  -p all --time 23:59:00 --mem-per-cpu 2G -p all  --open-mode=append -e logfiles/log_tri1_adapt/3332/q/adapt.log -o logfiles/log_tri1_adapt/3332/q/adapt.log --array 1-28 /home/maulik/Tools/kaldi/egs/sdsv/task1/logfiles/log_tri1_adapt/3332/q/adapt.sh >>logfiles/log_tri1_adapt/3332/q/adapt.log 2>&1
