#!/bin/bash
cd /home/maulik/Tools/kaldi/egs/sdsv/task1
. ./path.sh
( echo '#' Running on `hostname`
  echo '#' Started at `date`
  set | grep SLURM | while read line; do echo "# $line"; done
  echo -n '# '; cat <<EOF
local/testing_script_mono_ali.sh ${SLURM_ARRAY_TASK_ID} 11200 
EOF
) >logfiles/log_mono_ali_adapt/11200/align.$SLURM_ARRAY_TASK_ID.log
if [ "$CUDA_VISIBLE_DEVICES" == "NoDevFiles" ]; then
  ( echo CUDA_VISIBLE_DEVICES set to NoDevFiles, unsetting it... 
  )>>logfiles/log_mono_ali_adapt/11200/align.$SLURM_ARRAY_TASK_ID.log
  unset CUDA_VISIBLE_DEVICES
fi
time1=`date +"%s"`
 ( local/testing_script_mono_ali.sh ${SLURM_ARRAY_TASK_ID} 11200  ) &>>logfiles/log_mono_ali_adapt/11200/align.$SLURM_ARRAY_TASK_ID.log
ret=$?
sync || true
time2=`date +"%s"`
echo '#' Accounting: begin_time=$time1 >>logfiles/log_mono_ali_adapt/11200/align.$SLURM_ARRAY_TASK_ID.log
echo '#' Accounting: end_time=$time2 >>logfiles/log_mono_ali_adapt/11200/align.$SLURM_ARRAY_TASK_ID.log
echo '#' Accounting: time=$(($time2-$time1)) threads=1 >>logfiles/log_mono_ali_adapt/11200/align.$SLURM_ARRAY_TASK_ID.log
echo '#' Finished at `date` with status $ret >>logfiles/log_mono_ali_adapt/11200/align.$SLURM_ARRAY_TASK_ID.log
[ $ret -eq 137 ] && exit 100;
touch logfiles/log_mono_ali_adapt/11200/q/done.22287.$SLURM_ARRAY_TASK_ID
exit $[$ret ? 1 : 0]
## submitted with:
# sbatch --export=PATH  --ntasks-per-node=1  -p all --time 23:59:00 --mem-per-cpu 1G -p all  --open-mode=append -e logfiles/log_mono_ali_adapt/11200/q/align.log -o logfiles/log_mono_ali_adapt/11200/q/align.log --array 1-20 /home/maulik/Tools/kaldi/egs/sdsv/task1/logfiles/log_mono_ali_adapt/11200/q/align.sh >>logfiles/log_mono_ali_adapt/11200/q/align.log 2>&1
