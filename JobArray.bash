#!/bin/bash --login

# PBS job options (name, compute nodes, job time)
#PBS -N TomasJobArray
#PBS -l select=1
#PBS -l walltime=00:01:00

# Replace [project code] below with your project code (e.g. t01)
#PBS -A 

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
#   This prevents any system libraries from automatically
#   using threading.
export OMP_NUM_THREADS=1

# Define a xyz2geometry function
xyz2geometry() {
  fileName="$1"
  numLines=`wc -l $fileName | awk '{print $1}'`
  let "numLines = $numLines - 2"
  tail -$numLines $fileName > tmp
  awk '{print "atom", $2, $3, $4, $1}' tmp > geometry.in
  rm -f tmp
}

# preparing directories for the simulations
rm -rf output_backup
mv -f output output_backup > /dev/null
mkdir output > /dev/null

cd input

for entry in `ls $search_dir`; do
	if [ ${entry: -4} == ".xyz" ]
	then
	  filename="${entry%.*}"
	  
	  xyz2geometry $entry
	  
	  echo "Preparing" $filename
	  
	  mkdir ../output/$filename
	  cp -f control.in ../output/$filename/ > /dev/null
	  mv geometry.in ../output/$filename/ > /dev/null
	fi
done

cd ..

echo "--------------------------"
echo "Done preparing"
echo "--------------------------"
echo 
echo
echo "--------------------------"
echo "Executing"
echo "--------------------------"

cd output

# execute the jobs
for entry in `ls $search_dir`; do
	if [ -d "$entry" ] ; then
	  cd $entry
	  echo $entry
	  aprun -n 48 aims > FHIaims${i}.out &
	  
	  cd ..
	fi
done

cd ..

# Wait for all jobs to finish before exiting the job submission script
wait
exit 0