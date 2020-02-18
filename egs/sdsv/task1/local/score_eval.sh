# rm -rf testscoresnum
# for var in {1..12404}
# do

# model_name=$(printf model_'%05d' `expr $var - 1`)
# echo $model_name
# echo "model_name is= "${model_name} >> testscoresnum

# numexp=$(cat /data07/maulik/corpus/SdSV/docs/trials.txt | grep ${model_name} | wc -l)
# numget=$(cat scores/${model_name}.scores | wc -l)

#   if [ $numexp != $numget ]; then
#     echo "Failed" $model_name >>testscoresnum
#   fi

# done


# score_list=pd.read_csv('/data07/maulik/corpus/SdSV/docs/trials.txt',header=None,delimiter=' ')

# for var in range(12404):
#   model_name='model_'+str(var).rjust(5,'0')


input_list=/data07/maulik/corpus/SdSV/docs/trials
output=scores/spk_mono_ubm_ali/res/outputscores

rm -rf $output
while read -r line; 
  do 
  model_name=$(echo $line | cut -d' ' -f1)
  test_name=$(echo $line | cut -d' ' -f2)
  score=$(cat scores/spk_mono_ubm_ali/${model_name}.scores | grep $test_name | cut -d' ' -f2)
  if [ -z "$score" ]
  then
        score=-5  
  fi
  echo $line $score>>$output; 
done<$input_list



# input_list=/data07/maulik/corpus/SdSV/docs/trials.txt
# output=scores/spk_mono_ubm_ali/res/outputscores

# rm -rf $output
# while read -r line; 
#   do 
#   model_name=$(echo $line | cut -d' ' -f1)
#   test_name=$(echo $line | cut -d' ' -f2)
#   echo $model_name $test_name; 
# done<$input_list
