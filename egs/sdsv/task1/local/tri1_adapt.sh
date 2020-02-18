jobid1=$1
startid=$2
jobid=`expr $jobid1 + $startid`

model_name=$(printf model_'%05d' `expr $jobid - 1`)

echo "model_name is= "${model_name}
data_dir=data/evaluation/models/${model_name}
mdl_dir=exp/tri1
ali_dir=exp/tri1_ali_tr/${model_name}
adapt_dir=exp/tri1_ali_tr_MAPadapt/${model_name}
lang_dir=data/lang

[ -d ${ali_dir} ] && rm -r ${ali_dir}
[ -d ${adapt_dir} ] && rm -r ${adapt_dir}
steps/align_si.sh --nj 1 ${data_dir} ${lang_dir} ${mdl_dir} ${ali_dir}  ### alignment
steps/train_map.sh --tau 15 ${data_dir} ${lang_dir} ${ali_dir} ${adapt_dir} ## MAP adaptation
