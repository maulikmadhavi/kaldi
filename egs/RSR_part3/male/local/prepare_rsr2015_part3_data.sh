#!/bin/bash
#1.data/all
base_dir=/home/rohan/database/RSR2015
data_dir=data/all
[ -d $data_dir ] && rm -r $data_dir
mkdir -p ${data_dir}
python local/rsr2015.py $base_dir $data_dir
perl utils/utt2spk_to_spk2utt.pl $data_dir/utt2spk > $data_dir/spk2utt
utils/fix_data_dir.sh $data_dir

#2. data/dev_p3_tr
[ -d data/dev_p3_tr ] && rm -r data/dev_p3_tr
mkdir -p data/dev_p3_tr
train_base_file=${base_dir}/key/part3/trn/3seq10_dev_m.trn
while read line
do
    echo $line
    model_name=`echo $line | awk '{print $1}'`
    model_dir=data/dev_p3_tr/${model_name}
    mkdir -p ${model_dir}
    echo $line | awk '{print $2}' | awk -F"," '{print $1"\n"$2"\n"$3}' | awk -F"[/.]" '{print $(NF-1)}' > ${model_dir}/id.list
    cat ${model_dir}/id.list >> data/dev_p3_tr/id.list
    echo ${model_name} >> data/dev_p3_tr/model
done < ${train_base_file}
utils/subset_data_dir.sh --utt-list data/dev_p3_tr/id.list data/all data/dev_p3_tr
perl utils/utt2spk_to_spk2utt.pl data/bkg_rsr/utt2spk > data/bkg_rsr/spk2utt

#3. data/dev_p3_te
[ -d data/dev_p3_te ] && rm -r data/dev_p3_te
mkdir -p data/dev_p3_te
test_base_dir=bak/dev_p3
for i in `seq 1 150`
do
    model_name=`awk '{print $2}' ${test_base_dir}/OP_gen_corr/list$i | sort -u`
    mkdir -p data/dev_p3_te/gen_corr/${model_name}
    awk '{print $3}' ${test_base_dir}/OP_gen_corr/list$i | awk -F"." '{print $1}' > data/dev_p3_te/gen_corr/${model_name}/id.list
    mkdir -p data/dev_p3_te/imp_corr/${model_name}
    awk '{print $3}' ${test_base_dir}/OP_imp_corr/list$i | awk -F"." '{print $1}' > data/dev_p3_te/imp_corr/${model_name}/id.list
done
cat ${test_base_dir}/OP_gen_corr/list* ${test_base_dir}/OP_imp_corr/list* | \
  awk '{print $3}' | awk -F"." '{print $1}' | sort -u > data/dev_p3_te/id.list
utils/subset_data_dir.sh --utt-list data/dev_p3_te/id.list data/all data/dev_p3_te
perl utils/utt2spk_to_spk2utt.pl data/bkg_rsr/utt2spk > data/bkg_rsr/spk2utt

#4. data/bkg_rsr
[ -d data/bkg_rsr ] && rm -r data/bkg_rsr
mkdir -p data/bkg_rsr
python local/get_wav_bkg_part3.py data/all data/bkg_rsr m
utils/subset_data_dir.sh --utt-list data/bkg_rsr/id.list data/all data/bkg_rsr
perl utils/utt2spk_to_spk2utt.pl data/bkg_rsr/utt2spk > data/bkg_rsr/spk2utt

