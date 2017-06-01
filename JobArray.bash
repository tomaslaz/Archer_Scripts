#!/bin/bash
#PBS -N TiJobArray
#PBS -l select=8
#PBS -l walltime=00:20:00
#PBS -A e05-gener-smw
#PBS -J 1-10
#PBS -r y 

# load modules
module load aims

# Make sure any symbolic links are resolved to absolute path
export PBS_O_WORKDIR=$(readlink -f $PBS_O_WORKDIR)

# Change to the directory that the job was submitted from
# (remember this should be on the /work filesystem)
cd $PBS_O_WORKDIR

basedir=$PBS_O_WORKDIR

export NPROC=`qstat -f $PBS_JOBID | awk '/Resource_List.ncpus/ {print $3}'`

# Set the number of threads to 1
export OMP_NUM_THREADS=1

STRIDE=10

fromNo=($PBS_ARRAY_INDEX-1)*STRIDE+1
toNo=$PBS_ARRAY_INDEX*STRIDE+1
for (( i=$fromNo; i<$toNo; i++ ))
do
	workDir=`sed -n "$i"p < jobs.txt`
	echo $workDir
	cd $workDir
	aprun -n 96 aims > FHIaims.out 
	cd ..
done