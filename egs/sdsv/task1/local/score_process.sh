# jobid1=$1
# startid=$2
# jobid=`expr $jobid1 + $startid`

jobid=$1
##################################################################################
## This code uses background model (speaker independent) alignment "exp/tri1_ali_${dataset}_te/ali.1.gz"# 


model_name=$(printf model_'%05d' `expr $jobid - 1`)

echo "model_name is= "${model_name}
data_dir=data/evaluation/models/${model_name}

paste scores/raw/spk/${model_name}.scores scores/raw/spk/${model_name}.lengths | awk '{print $1,$2/$4}' > scores/raw/spk_mono_ubm_ali/spk_${model_name}.scores

paste scores/raw/mono_ubm_ali/${model_name}.scores scores/raw/mono_ubm_ali/${model_name}.lengths | awk '{print $1,$2/$4}' > scores/raw/spk_mono_ubm_ali/bkg_${model_name}.scores

paste scores/raw/spk_mono_ubm_ali/spk_${model_name}.scores scores/raw/spk_mono_ubm_ali/bkg_${model_name}.scores | awk '{print $1,$2-$4}'> scores/spk_mono_ubm_ali/${model_name}.scores

#rm ${datadir}/*
#rm data/runtest_${genimp}_${corrwrong}/$1/*
