
require 'open3'

#> $output
#> $error
#> $benchmark_log
#> $sql_log

# This calcuation can be benchmark-agnostic, we can scan app-specific parameters only in the conf file
#total_runs=$(( $(echo $operations | wc -w) * $(echo $schedulers | wc -w) * $(echo $gpu_modes | wc -w) * $(echo $block_sizes | wc -w) * $(( ($jobs_to - $jobs_from) / $increment + 1 )) * $iterations ))

#total_time=$(($total_runs/2))

def get_total_solver_iterations
  epochs = config.get(:$solver_number_of_epochs)
  @total_solver_iterations = epochs ? epochs * config.get(:dataset_size) / ( $1 * $2) : config.get(:solver_number_of_iterations)
end

def format_eta_to_human(time_str)
  hh, mm = time_str.split(':')
  hh = hh.to_i
  mm = mm.to_i
  eta_human = "#{hh}h #{mm}min"
end

def launch
  invocation=1
  iteration=1
  scheduler=""
  iterations = config.get!(:iterations)

  total_invocations = config.iteratable_size

  real_start_time = Time.now.to_i.to_s

  dimensions = [
    (1..iterations),
    (1..@number_installed_gpus),
    (1..@images_batch_per_gpu),
    (1..@schedulers.size),
    (1..@dataloader_threads_per_gpu)
  ]

#while [ $iteration -le $iterations ]; do
#for num_gpus in $number_of_gpus; do
#for im_batch in $images_batch_per_gpu; do
#for scheduler in $schedulers; do
#for threads in $dataloader_threads_per_gpu; do

  dimensions.inject(&:product).each do |iteration,gpus,bath_per_gpu,scheduler,threads|
    get_total_solver_iterations $im_batch $num_gpus
    switch_scheduler $scheduler
    command = '$app_flags DETECTRON2_DATASETS=$path/detectron2/datasets/ python -W ignore $path/detectron2/tools/train_net.py --config-file $path/detectron2/configs/COCO-InstanceSegmentation/mask_rcnn_R_50_FPN_1x.yaml --num-gpus $num_gpus SOLVER.IMS_PER_BATCH $(echo "scale=3; $im_batch * $num_gpus" | bc ) SOLVER.BASE_LR $(echo "$solver_initial_lr_per_gpu * $num_gpus" | bc) DATALOADER.NUM_WORKERS $(( $threads * $num_gpus )) SOLVER.MAX_ITER $total_solver_iterations'

    pid = nil
    Open3.popen2(command) do |stdin, stderr, wait_thr|
      pid = wait_thr.pid

	
      old_size=0
	stall_counter=0
	while true
	do
		new_size=$(ls -l $output | awk '{print $5}')
		if [ $new_size -gt $old_size ]
		then
                       	chunk="$(tail -1 $output)"
			if [ ! -z "$(echo $chunk | grep -i error)" ];
			then
				echo "application error '$chunk'" | tee -a $benchmark_log
				exit
			fi
			echo "$chunk" >> $benchmark_log
			extract "$chunk"
			if [ -z "$eta" ];
			then
				eta_msg="TBD"
				stall_counter=$(( $stall_counter + 1 ))
			else
                                get_gpu_consumption
                                get_cpu_consumption
                                get_storage_consumption
				format_eta_to_minutes $eta
				get_real_time "$(date +%s)" $real_start_time
				load
                        	old_size=$new_size
                        	stall_counter=0
				format_eta_to_human "$eta"
				eta_msg=$eta_human
			fi
			echo "NODE $HOST | SERIES $series | TIER $project_tier | INVOCATION $invocation of $total_invocations | ETA $eta_msg"
		else
			stall_counter=$(( $stall_counter + 1 ))
		fi
		test $stall_counter -ge $(echo $grace_period / $frequency | bc) && break
		sleep $frequency
	done

	if [ -s $error ]
        then
                warning "iteration drops an error: $(cat $error)"
                error_counter=$(( $error_counter + 1 ))
        fi
        run=$(($run+1))
done
done
done
done
iteration=$(($iteration + 1))
done

