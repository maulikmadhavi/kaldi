job=$1
genimp=$2 #"gen" or "imp"
corrwrong=$3 #"corr" or "wrong"
dataset=$4
##################################################################################
## This code uses background model (speaker independent) alignment "exp/tri1_ali_${dataset}_te/ali.1.gz"# 

mkdir -p scores/${dataset}/${genimp}_${corrwrong}  ### create folder to store scores
mkdir -p feat_length/${dataset}/${genimp}_${corrwrong}/spkutt ## temporay folder for scores and feature length-Model
mkdir -p feat_length/${dataset}/${genimp}_${corrwrong}/ubm  ### temporay folder for scores and feature length-UBM
mkdir -p data/runtest_${genimp}_${corrwrong}/$1 ## data directory for trial list 

rm -r scores/${dataset}/${genimp}_${corrwrong}/${genimp}_${corrwrong}_model$1.scores 
rm -r scores/${dataset}/${genimp}_${corrwrong}/${genimp}_${corrwrong}_bkg$1.scores 

model_name=`sed -n "${job}p" data/${dataset}_tr/model`
data_dir=data/${dataset}_te/${genimp}_${corrwrong}/${model_name}

rm ${data_dir}/{text,wav.scp,feats.scp,cmvn.scp,spk2utt,utt2spk}
utils/subset_data_dir.sh --utt-list ${data_dir}/id.list data/${dataset}_te ${data_dir}

########################################################################################################################################
### Finding speaker independent (UBM) alignments for testing features w.r.t. claimed model ############################################
########################################################################################################################################

steps/align_si.sh --nj 1 ${data_dir} data/lang_transfree exp/bkg_rsr_mono exp/runtest_bkg_${genimp}_${corrwrong}/${model_name}

########################################################################################################################################
############################################### Scores with respect to Speaker-Utterance model##########################################
########################################################################################################################################
sil_phones=`cat data/lang_transfree/phones/optional_silence.csl`
compute-log-likelihood-ali --binary=false exp/mono_ali_${dataset}_tr_MAPadapt/$model_name/final.mdl "ark,s,cs:apply-cmvn  --utt2spk=ark:${data_dir}/utt2spk scp:${data_dir}/cmvn.scp scp:${data_dir}/feats.scp ark:- | add-deltas  ark:- ark:- |" "ark,s,cs:gunzip -c exp/runtest_bkg_${genimp}_${corrwrong}/${model_name}/ali.1.gz|" ark,t:feat_length/${dataset}/${genimp}_${corrwrong}/spkutt/${genimp}_${corrwrong}_model$1.scores ark,t:feat_length/${dataset}/${genimp}_${corrwrong}/spkutt/feats_$1.lengths "$sil_phones"


paste feat_length/${dataset}/${genimp}_${corrwrong}/spkutt/${genimp}_${corrwrong}_model$1.scores feat_length/${dataset}/${genimp}_${corrwrong}/spkutt/feats_$1.lengths | awk '{print $2/$4}' > scores/${dataset}/${genimp}_${corrwrong}/${genimp}_${corrwrong}_model$1.scores


########################################################################################################################################
############################################### Scores with respect to UBM #############################################################
########################################################################################################################################

compute-log-likelihood-ali --binary=false exp/bkg_rsr_mono/final.mdl "ark,s,cs:apply-cmvn  --utt2spk=ark:${data_dir}/utt2spk scp:${data_dir}/cmvn.scp scp:${data_dir}/feats.scp ark:- | add-deltas  ark:- ark:- |" "ark,s,cs:gunzip -c exp/runtest_bkg_${genimp}_${corrwrong}/${model_name}/ali.1.gz|" ark,t:feat_length/${dataset}/${genimp}_${corrwrong}/ubm/${genimp}_${corrwrong}_bkg$1.scores ark,t:feat_length/${dataset}/${genimp}_${corrwrong}/ubm/feats_$1.lengths "$sil_phones"

paste feat_length/${dataset}/${genimp}_${corrwrong}/ubm/${genimp}_${corrwrong}_bkg$1.scores feat_length/${dataset}/${genimp}_${corrwrong}/ubm/feats_$1.lengths | awk '{print $2/$4}' > scores/${dataset}/${genimp}_${corrwrong}/${genimp}_${corrwrong}_bkg$1.scores

#rm ${datadir}/*
#rm data/runtest_${genimp}_${corrwrong}/$1/*
