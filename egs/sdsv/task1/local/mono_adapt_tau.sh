jobid1=$1
startid=$2
tau=$3
jobid=`expr $jobid1 + $startid`

model_name=$(printf model_'%05d' `expr $jobid - 1`)

echo "model_name is= "${model_name}
data_dir=data/enrollment/models/${model_name}
mdl_dir=exp/mono_vow5
ali_dir=exp/mono_vow5_ali_tr_tau${tau}/${model_name}
adapt_dir=exp/mono_vow5_ali_tr_MAPadapt_tau${tau}/${model_name}
lang_dir=data/lang_vow5

[ -d ${ali_dir} ] && rm -r ${ali_dir}
[ -d ${adapt_dir} ] && rm -r ${adapt_dir}
steps/align_si.sh --retry-beam 100 --nj 1 ${data_dir} ${lang_dir} ${mdl_dir} ${ali_dir}  ### alignment
steps/train_map.sh --tau $tau ${data_dir} ${lang_dir} ${ali_dir} ${adapt_dir} ## MAP adaptation
