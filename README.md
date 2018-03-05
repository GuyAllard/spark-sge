# spark-sge

This script will launch a spark cluster on a sge cluster.

| Arg | Destription | Default |
| --- | ----------- | ------- |
| -d  | Log directory | .spark |
| -e  | Number of executors | 4 |
| -c  | Number of CPU per executor | 4 |
| -m  | Memory per executor in GB | 20 |
| -l  | Resource tag | h_vmem |
| -p  | Parallel environment (required) | - |

On ctrl-c The executor jobs will be killed

### Example:

```bash
# This will start a cluster with 20 executors with 4 cpu's each, 80 cpu in total and 400Gb of memory
spark-start-sge-cluster -e 20 -p <pe>
```

```bash
# This will start a cluster with 5 executors with 5 cpu's each, 25 cpu in total and 200Gb of memory
spark-start-sge-cluster -e 5 -m 40 -c 5 -p <pe>
```
