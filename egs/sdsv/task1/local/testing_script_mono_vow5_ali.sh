jobid1=$1
startid=$2
jobid=`expr $jobid1 + $startid`

##################################################################################
## This code uses background model (speaker independent) alignment "exp/tri1_ali_${dataset}_te/ali.1.gz"# 

# mkdir -p scores/raw/spk/tri1  ### create folder to store scores
# mkdir -p scores/raw/tri1_ubm_ali ## temporay folder for scores and feature length-Model
# mkdir -p scores/tri1

model_name=$(printf model_'%05d' `expr $jobid - 1`)

echo "model_name is= "${model_name}

bkg_mdl=exp/mono_vow5
dst_mdl=exp/evaluation/mono_vow5_ubm_ali/${model_name}
spk_mdl=exp/mono_vow5_ali_tr_MAPadapt/${model_name}

trl_lst=/data07/maulik/corpus/SdSV/docs/trials.txt
raw_spk=scores/raw/spk/mono_vow5
raw_ubm=scores/raw/mono_vow5_ubm_ali
scr_pth=scores/mono_vow5

lng_mdl=data/lang_vow5
data_dir=data/evaluation/models/${model_name}

mkdir -p ${raw_spk}
mkdir -p ${raw_ubm}
mkdir -p ${scr_pth}

########################################################################################################################################
### Finding speaker independent (UBM) alignments for testing features w.r.t. claimed model ############################################
########################################################################################################################################
numalis=0 				# Number of aligned files, itialize as 0
#numexp=$(${data_dir}/feats.scp | wc -l) # number of expected alignment files
beam=10
retry_beam=40
numexp=$(cat ${trl_lst} | grep ${model_name} | wc -l)

while [ $numalis != $numexp ]
do
    echo "inside the condition"
    steps/align_si.sh --nj 1 --beam $beam --retry-beam $retry_beam  ${data_dir} ${lng_mdl} ${bkg_mdl} ${dst_mdl}
	numalis=$(gunzip -c  ${dst_mdl}/ali.1.gz  | wc -l)
	retry_beam=`expr $retry_beam + 20`
	if [ $retry_beam -eq 120 ]; then
		numalis=$numexp
	fi
	echo "------------------------------------------------------------------"

done


########################################################################################################################################
############################################### Scores with respect to Speaker-Utterance model##########################################
########################################################################################################################################
sil_phones=`cat ${lng_mdl}/phones/optional_silence.csl`
compute-log-likelihood-ali --binary=false ${spk_mdl}/final.mdl "ark,s,cs:apply-cmvn  --utt2spk=ark:${data_dir}/utt2spk scp:${data_dir}/cmvn.scp scp:${data_dir}/feats.scp ark:- | add-deltas  ark:- ark:- |" "ark,s,cs:gunzip -c ${dst_mdl}/ali.1.gz|" ark,t:${raw_spk}/${model_name}.scores ark,t:${raw_spk}/${model_name}.lengths "$sil_phones"

paste ${raw_spk}/${model_name}.scores ${raw_spk}/${model_name}.lengths | awk '{print $1,$2/$4}' > ${scr_pth}/spk_${model_name}.scores


########################################################################################################################################
############################################### Scores with respect to UBM #############################################################
########################################################################################################################################

compute-log-likelihood-ali --binary=false ${bkg_mdl}/final.mdl "ark,s,cs:apply-cmvn  --utt2spk=ark:${data_dir}/utt2spk scp:${data_dir}/cmvn.scp scp:${data_dir}/feats.scp ark:- | add-deltas  ark:- ark:- |" "ark,s,cs:gunzip -c ${dst_mdl}/ali.1.gz|" ark,t:${raw_ubm}/${model_name}.scores ark,t:${raw_ubm}/${model_name}.lengths "$sil_phones"

paste ${raw_ubm}/${model_name}.scores ${raw_ubm}/${model_name}.lengths | awk '{print $1,$2/$4}' > ${scr_pth}/bkg_${model_name}.scores

#########################################################################################################################################
###############################################    Scores with overall      #############################################################
#########################################################################################################################################
paste ${scr_pth}/spk_${model_name}.scores ${scr_pth}/bkg_${model_name}.scores | awk '{print $1,$2-$4}'> ${scr_pth}/${model_name}.scores

#rm ${datadir}/*
#rm data/runtest_${genimp}_${corrwrong}/$1/*
