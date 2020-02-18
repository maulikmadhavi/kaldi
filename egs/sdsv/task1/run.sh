#!/bin/bash
export LC_ALL=C

. ./path.sh

export train_cmd="slurm.pl -p all --time 23:59:00 --mem 4G"
export train_cmd="slurm.pl -p all --time 23:59:00 --mem 2G"

# export train_cmd="run.pl"
export align_cmd="slurm.pl -p all --time 11:59:00 --mem 4G"
export decode_cmd="slurm.pl -p all --time 11:59:00 --mem 15G"
export mkgraph_cmd="slurm.pl -p all --time 11:59:00 --mem 4G"
export rnn_cmd="slurm.pl -p all --num-threads 1 --time 11:59:00 --mem 12G"
export cuda_cmd="slurm.pl -p all --num-threads 1 --time 05:30:00 --mem 4G"
export egs_cmd="slurm.pl -p all --time 11:59:00 --mem 4G"
#export train_cmd="run.pl"
feats_nj=20
train_nj=28
stage=15

numLeavesTri1=128   # Number of triphone states
numGaussTri1=512    # Number of Gaussians, which is equal to 

## Prepare data
if [ $stage -eq 1 ]; then

    wavdir=/data07/maulik/corpus/SdSV/wav/
    resdir=/data07/maulik/corpus/SdSV/docs
    for var in enrollment  evaluation  train; do
        datadir=data/$var
        mkdir -p $datadir
        if [ $var == 'train' ]; then
            echo "$var data preparation"
            cat $resdir/train_labels.txt | sed 1d |awk 'BEGIN {}{print $1,"/data07/maulik/corpus/SdSV/wav/train/"$1".wav"}' > $datadir/wav.scp
            cat $resdir/train_labels.txt | sed 1d | awk 'BEGIN {}{print $1,$1}' > $datadir/spk2utt
            cat $resdir/train_labels.txt | sed 1d | awk 'BEGIN {}{print $1,$1}' > $datadir/utt2spk
            cat $resdir/train_labels.txt | sed 1d | awk 'BEGIN {}{print $3}' > uttid
            cat $resdir/train_labels.txt | sed 1d | awk 'BEGIN {}{print $1}' > senid
            rm -rf text 
            cnt=0
            while read -r line; do echo $(cat $resdir/transcripts | grep $line| cut -d' ' -f2-)>>text; done<uttid
            paste senid text > $datadir/text
            rm -rf text uttid senid
        fi

        if [ $var == 'enrollment' ]; then
            echo "$var data preparation"
            cat $resdir/model_enrollment.txt | sed 1d | awk 'BEGIN {}{ print $3, " ", "/data07/maulik/corpus/SdSV/wav/enrollment/"$3".wav" }{ print $4, " ", "/data07/maulik/corpus/SdSV/wav/"$4".wav" }{ print $5, " ", "/data07/maulik/corpus/SdSV/wav/"$5".wav" }' >$datadir/wav.scp
            cat $resdir/model_enrollment.txt | sed 1d | awk 'BEGIN {}{ print $3, " ", $3 }{ print $4, " ", $4 }{ print $5, " ", $5 }' >$datadir/spk2utt
            cat $resdir/model_enrollment.txt | sed 1d | awk 'BEGIN {}{ print $3, " ", $3 }{ print $4, " ", $4 }{ print $5, " ", $5 }' >$datadir/utt2spk
            cat $resdir/model_enrollment.txt | sed 1d | awk 'BEGIN {}{print $2}{print $2}{print $2}' > uttid
            cat $resdir/model_enrollment.txt | sed 1d | awk 'BEGIN {}{print $3}{print $4}{print $5}' > senid
            rm -rf text 
            cnt=0
            while read -r line; do echo $(cat $resdir/transcripts | grep $line| cut -d' ' -f2-)>>text; done<uttid
            paste senid text > $datadir/text
            rm -rf text uttid senid
        fi

        if [ $var == 'evaluation' ]; then
            echo "$var data preparation"
            cat $resdir/trials.txt | sed 1d | awk 'BEGIN {}{ print $2, " ", "/data07/maulik/corpus/SdSV/wav/evaluation/"$2".wav" }' >$datadir/wav.scp
            cat $resdir/trials.txt | sed 1d | awk 'BEGIN {}{ print $2, " ", $2 }' >$datadir/spk2utt
            cat $resdir/trials.txt | sed 1d | awk 'BEGIN {}{ print $2, " ", $2 }' >$datadir/utt2spk
        fi

    done

fi

## preapre lang
if [ $stage -eq 2 ]; then
    local/timit_prepare_dict.sh
    utils/prepare_lang.sh --sil-prob 0.0 --position-dependent-phones false --num-sil-states 3 \
    data/local/dict "sil" data/local/lang_tmp data/lang
fi

## Extract features
mfccdir=mfcc

if [ $stage -eq 3 ]; then
    
    for x in evaluation; do
      utils/fix_data_dir.sh data/$x
      steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --cmd "$train_cmd" --nj $feats_nj data/$x exp/make_mfcc/$x $mfccdir
      steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir

    done

fi


## Train UBM
if [ $stage -eq 4 ]; then
steps/train_mono.sh  --nj "$train_nj" --cmd "$train_cmd" data/train data/lang exp/mono
fi


## Monophone training

resdir=/data07/maulik/corpus/SdSV/docs
cat $resdir/model_enrollment.txt | sed 1d | cut -d' ' -f1 > $resdir/model


if [ $stage -eq 5 ]; then
while read model_name
do
#    resdir=/data07/maulik/corpus/SdSV/docs
#    cat $resdir/model_enrollment.txt | head | sed 1d | cut -d' ' -f1 > $resdir/model
#    model_name=model_00000
    cat $resdir/model_enrollment.txt | grep $model_name | cut -d' ' -f3- | tr ' ' '\n' >id.list

    utils/subset_data_dir.sh --utt-list id.list data/enrollment data/enrollment/models/$model_name
    [ -d exp/mono_ali_tr/${model_name} ] && rm -r exp/mono_ali_tr/${model_name}
    [ -d exp/mono_ali_tr_MAPadapt/${model_name} ] && rm -r exp/mono_ali_tr_MAPadapt/${model_name}
    steps/align_si.sh --nj 1 data/enrollment/models/$model_name data/lang exp/mono exp/mono_ali_tr/${model_name}  ### alignment
    steps/train_map.sh --tau 15 data/enrollment/models/$model_name data/lang exp/mono_ali_tr/${model_name} exp/mono_ali_tr_MAPadapt/${model_name} ## MAP adaptation
done < $resdir/model
fi



###Number of jobs have to given in the loop 
## preapre data folder for evaluation model 
if [ $stage -eq 6 ]; then
    while read model_name_utt
    do
    # model_name_utt="model_00000 10"

#    resdir=/data07/maulik/corpus/SdSV/docs
#    cat $resdir/model_enrollment.txt | head | sed 1d | cut -d' ' -f1 > $resdir/model
#    model_name=model_00000
    model_name=$(echo $model_name_utt | cut -d' ' -f1)
    cat $resdir/trials.txt | grep $model_name | cut -d' ' -f2 >id.list
    utils/subset_data_dir.sh --utt-list id.list data/evaluation data/evaluation/models/$model_name

    num_tests=`cat data/evaluation/models/$model_name/feats.scp | wc -l`
    utt=$(echo $model_name_utt | cut -d' ' -f2)
    utt_tra=`grep $utt /data07/maulik/corpus/SdSV/docs/transcripts | cut -d' ' -f2-`    
    rm -rf text1 text
    for i in $(seq 1 $num_tests); do echo $utt_tra>>text1; done
    paste id.list text1 | tr '\t' ' ' > text
    mv text data/evaluation/models/$model_name

done < $resdir/model_utt

fi

## monophone adapt
if [ $stage -eq 7 ]; then
    mkdir -p logfiles/log_mono_ali_adapt
    [ -d scores ] && rm -r scores

    num_models=`cat /data07/maulik/corpus/SdSV/docs/model_utt | wc -l`
    #for i in `seq 0 60 12403`; 
    for i in `seq 0 20 12400`; 
        do 
        	echo $i; 
        	mkdir -p logfiles/log_mono_ali_adapt/$i
        	$train_cmd JOB=1:$train_nj logfiles/log_mono_ali_adapt/$i/align.JOB.log local/testing_script_mono_ali.sh JOB $i
        	if [ $i -eq 12400 ]; then
        		$train_cmd JOB=1:4 logfiles/log_mono_ali_adapt/$i/align.JOB.log local/testing_script_mono_ali.sh JOB $i
        	fi
        done
#$train_cmd JOB=1:30 logfiles/log_mono_ali_adapt/align.JOB.log local/testing_script_mono_ali.sh JOB
fi


## train triphone UBM
if [ $stage -eq 8 ]; then
    steps/align_si.sh --boost-silence 1.25 --nj "$train_nj" --cmd "$train_cmd" \
      data/train data/lang exp/mono exp/mono_ali

    steps/train_deltas.sh --cmd "$train_cmd" \
      $numLeavesTri1 $numGaussTri1 data/train data/lang exp/mono_ali exp/tri1
fi


## Adapt tri phone
if [ $stage -le 9 ]; then
    #while read model_name
    #do
    #    mdl_dir=exp/tri1
    #    ali_dir=exp/tri1_ali_tr/${model_name}
    #    adpt_dir=exp/tri1_ali_tr_MAPadapt/${model_name}
    #    data_dir=data/enrollment/models/$model_name
    #    lang_dir=data/lang
    #    [ -d ${ali_dir} ] && rm -r ${ali_dir}
    #    [ -d ${adpt_dir} ] && rm -r ${adpt_dir}
    #    steps/align_si.sh --nj 1 ${data_dir} ${lang_dir} ${mdl_dir} ${ali_dir}  ### alignment
    #    steps/train_map.sh --tau 15 ${data_dir} ${lang_dir} ${ali_dir} ${adpt_dir} ## MAP adaptation
    #done < $resdir/model

    for i in `seq 0 28 12376`; 
    do 
        echo $i; 
        mkdir -p logfiles/log_tri1_adapt/$i
        $train_cmd JOB=1:$train_nj logfiles/log_tri1_adapt/$i/adapt.JOB.log local/tri1_adapt.sh JOB $i
    done

fi



# if [ $stage -eq 10 ]; then
#     mkdir -p logfiles/log_tri1_ali_adapt
#     [ -d scores ] && rm -r scores
#     echo "Testing.."
#     num_models=`cat /data07/maulik/corpus/SdSV/docs/model_utt | wc -l`
#     #for i in `seq 0 60 12403`; 
#     # local/testing_script_tri1_ali.sh 1 0
#     for i in `seq 0 20 12400`; 
#         do 
#             echo $i; 
#             mkdir -p logfiles/log_tri1_ali_adapt/$i
#             $train_cmd JOB=1:$train_nj logfiles/log_tri1_ali_adapt/$i/align.JOB.log local/testing_script_tri1_ali.sh JOB $i
#             if [ $i -eq 12400 ]; then
#                 $train_cmd JOB=1:4 logfiles/log_tri1_ali_adapt/$i/align.JOB.log local/testing_script_tri1_ali.sh JOB $i
#             fi
#         done
# fi
## Testing triphone 
if [ $stage -le 10 ]; then
    for i in `seq 0 28 12376`; 
    do 
        echo $i; 
        mkdir -p logfiles/log_tri1_adapt/$i
        $train_cmd JOB=1:$train_nj logfiles/log_tri1_adapt/$i/align.JOB.log local/testing_script_tri1_ali.sh JOB $i
    done
fi



## Train UBM
if [ $stage -eq 11 ]; then
steps/train_mono.sh  --nj "$train_nj" --cmd "$train_cmd" data/train data/lang_vow5 exp/mono_vow5
fi


## Monophone training

resdir=/data07/maulik/corpus/SdSV/docs
cat $resdir/model_enrollment.txt | sed 1d | cut -d' ' -f1 > $resdir/model


if [ $stage -eq 12 ]; then
    for i in `seq 0 28 12376`; 
    do 
        echo $i; 
        mkdir -p logfiles/log_mono_vow5_adapt/$i
        $train_cmd JOB=1:$train_nj logfiles/log_mono_vow5_adapt/$i/adapt.JOB.log local/mono_adapt.sh JOB $i
    done
fi


## Testing monophone vow5
if [ $stage -eq 13 ]; then
    for i in `seq 8988 28 12376`; 
    do 
        echo $i; 
        mkdir -p logfiles/log_mono_vow5_adapt/$i
        $train_cmd JOB=1:$train_nj logfiles/log_mono_vow5_adapt/$i/align.JOB.log local/testing_script_mono_vow5_ali.sh JOB $i
    done
fi


## Monophone training

resdir=/data07/maulik/corpus/SdSV/docs
cat $resdir/model_enrollment.txt | sed 1d | cut -d' ' -f1 > $resdir/model

tau=3
if [ $stage -eq 14 ]; then
    for i in `seq 0 28 12376`; 
    do 
        echo $i; 
        mkdir -p logfiles/log_mono_vow5_adapt_tau${tau}/$i
        $train_cmd JOB=1:$train_nj logfiles/log_mono_vow5_adapt_tau${tau}/$i/adapt.JOB.log local/mono_adapt_tau.sh JOB $i $tau
    done
fi


## Testing monophone vow5
train_nj=100
if [ $stage -eq 15 ]; then
    for i in `seq 703 100 12303`; 
    do 
        echo $i; 
        mkdir -p logfiles/log_mono_vow5_adapt_tau${tau}/$i
        $train_cmd JOB=1:$train_nj logfiles/log_mono_vow5_adapt_tau${tau}/$i/align.JOB.log local/testing_script_mono_vow5_ali_tau.sh JOB $i $tau
    done
fi