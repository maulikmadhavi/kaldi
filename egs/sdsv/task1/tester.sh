jobid=$1

echo "Hi this is jobid="$jobid
#model_name=$( printf 'model_%05d' $1 )
model_name=$(printf model_'%05d' `expr $jobid - 1`)
model_name=$(printf model_'%05d' `expr $jobid - 1`)

echo ${model_name}
