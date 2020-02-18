jobid1=$1
startid=$2
jobid=`expr $jobid1 + $startid`

##################################################################################
## This code uses background model (speaker independent) alignment "exp/tri1_ali_${dataset}_te/ali.1.gz"# 

mkdir -p scores/raw/spk  ### create folder to store scores
mkdir -p scores/raw/mono_ubm_ali ## temporay folder for scores and feature length-Model


model_name=$(printf model_'%05d' `expr $jobid - 1`)

echo "model_name is= "${model_name}
data_dir=data/evaluation/models/${model_name}
########################################################################################################################################
### Finding speaker independent (UBM) alignments for testing features w.r.t. claimed model ############################################
########################################################################################################################################
numalis=0 				# Number of aligned files, itialize as 0
#numexp=$(${data_dir}/feats.scp | wc -l) # number of expected alignment files
beam=10
retry_beam=40
numexp=$(cat /data07/maulik/corpus/SdSV/docs/trials.txt | grep ${model_name} | wc -l)

while [ $numalis != $numexp ]
do
    echo "inside the condition"
    steps/align_si.sh --nj 1 --beam $beam --retry-beam $retry_beam  ${data_dir} data/lang exp/mono exp/evaluation/mono_ubm_ali/${model_name}
	numalis=$(gunzip -c  exp/evaluation/mono_ubm_ali/${model_name}/ali.1.gz  | wc -l)
	#retry_beam=`expr $retry_beam + 10`
	retry_beam=`expr $retry_beam + 20`
	if [ $retry_beam -eq 120 ]; then
		numalis=$numexp
	fi
	echo "------------------------------------------------------------------"

done


########################################################################################################################################
############################################### Scores with respect to Speaker-Utterance model##########################################
########################################################################################################################################
sil_phones=`cat data/lang/phones/optional_silence.csl`
compute-log-likelihood-ali --binary=false exp/mono_ali_tr_MAPadapt/$model_name/final.mdl "ark,s,cs:apply-cmvn  --utt2spk=ark:${data_dir}/utt2spk scp:${data_dir}/cmvn.scp scp:${data_dir}/feats.scp ark:- | add-deltas  ark:- ark:- |" "ark,s,cs:gunzip -c exp/evaluation/mono_ubm_ali/${model_name}/ali.1.gz|" ark,t:scores/raw/spk/${model_name}.scores ark,t:scores/raw/spk/${model_name}.lengths "$sil_phones"

paste scores/raw/spk/${model_name}.scores scores/raw/spk/${model_name}.lengths | awk '{print $1,$2/$4}' > scores/spk_${model_name}.scores


########################################################################################################################################
############################################### Scores with respect to UBM #############################################################
########################################################################################################################################

compute-log-likelihood-ali --binary=false exp/mono/final.mdl "ark,s,cs:apply-cmvn  --utt2spk=ark:${data_dir}/utt2spk scp:${data_dir}/cmvn.scp scp:${data_dir}/feats.scp ark:- | add-deltas  ark:- ark:- |" "ark,s,cs:gunzip -c exp/evaluation/mono_ubm_ali/${model_name}/ali.1.gz|" ark,t:scores/raw/mono_ubm_ali/${model_name}.scores ark,t:scores/raw/mono_ubm_ali/${model_name}.lengths "$sil_phones"

paste scores/raw/mono_ubm_ali/${model_name}.scores scores/raw/mono_ubm_ali/${model_name}.lengths | awk '{print $1,$2/$4}' > scores/bkg_${model_name}.scores

paste scores/spk_${model_name}.scores scores/bkg_${model_name}.scores | awk '{print $1,$2-$4}'> scores/${model_name}.scores

#rm ${datadir}/*
#rm data/runtest_${genimp}_${corrwrong}/$1/*
