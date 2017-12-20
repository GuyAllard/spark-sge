#!/bin/bash

set -e

DIR=.spark
EXECUTORS=4
CPU_PER_EXECUTOR=4
GB_MEM_PER_EXECUTOR=20
MEMORY_RESOURCE=h_vmem

while getopts "d:e:c:m:p:l:" opt; do
  case ${opt} in
    d ) DIR=$OPTARG
      ;;
    e ) EXECUTORS=$OPTARG
      ;;
    c ) CPU_PER_EXECUTOR=$OPTARG
      ;;
    m ) GB_MEM_PER_EXECUTOR=$OPTARG
      ;;
    p ) PE_ENV=$OPTARG
      ;;
    l ) MEMORY_RESOURCE=$OPTARG
      ;;
    \? ) 
      echo "Usage: $0 [-d] output_dir [-e] executors [-c] cpu_per_executor [-m] gb_mem_per_executor"
      exit 1
      ;;
  esac
done

if [ -z "$PE_ENV" ]
then
      echo "Parallel env is required, please set it with -p"
      exit 1
fi

set -eu

echo "Dir: $DIR"
echo "Executors: $EXECUTORS"
echo "Cpu per executor: $CPU_PER_EXECUTOR"
echo "Gb mem per executor: $GB_MEM_PER_EXECUTOR"
echo "Parallel env: $PE_ENV"
echo "Memory resource: $MEMORY_RESOURCE"

WORK_DIR=$DIR/work
LOG_DIR=$DIR/log

GB_MEM_PER_CPU=`expr $GB_MEM_PER_EXECUTOR / $CPU_PER_EXECUTOR`

mkdir -p $WORK_DIR $LOG_DIR

kill_child_processes() {
  kill `jobs -p`
}

# Ctrl-C trap. Catches INT signal
trap "kill_child_processes 1 $$" INT

echo "Starting a master"
spark-class org.apache.spark.deploy.master.Master 2>> $LOG_DIR/master.log &
echo "Master log: $LOG_DIR/master.log"

sleep 10

SPARK_MASTER=`tail -n 40 $LOG_DIR/master.log | grep "Starting Spark master at" | tail -n 1 | sed "s/.*Starting Spark master at //"`
echo "Spark master: $SPARK_MASTER"

for i in $(seq 1 $EXECUTORS)
do
qrsh -N spark-worker -now no \
-pe $PE_ENV $CPU_PER_EXECUTOR -l ${MEMORY_RESOURCE}=`echo "$GB_MEM_PER_CPU * 1.2" | bc`G \
ssh localhost -t -t `which spark-class` \
org.apache.spark.deploy.worker.Worker $SPARK_MASTER \
-c $CPU_PER_EXECUTOR \
-m ${GB_MEM_PER_EXECUTOR}G \
-d $PWD >> $LOG_DIR/executor-${i}.log &
echo "Executor $i submitted: log: $LOG_DIR/executor-${i}.log"
done

echo "Executors submitted"

wait `jobs -p`

kill_child_processes

