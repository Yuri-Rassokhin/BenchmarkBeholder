### PROJECT: what project this benchmark is a part of
$project_code = "kudu"
$project_tier = "test"

### SERIES: identification of this benchmark series
$series_benchmark = "detectron2training"
$series_description = '#{benchmark} on #{target} on #{mode} #{shape} | 1 epoch | #{number_of_gpus}xGPU | #{images_batch_per_gpu} images/GPU | #{dataloader_threads_per_gpu} threads/GPU | #{solver_initial_lr_per_gpu} LR'
$series_owner_name = "Yuri Rassokhin"
$series_owner_email = "yuri.rassokhin@oracle.com"

# STARTUP: app input to be able to start it up
$startup_path = "/tmp" # Directory under which the application is installed
$startup_src = "#{$startup_path}/dummy_benchmark.sh" # Path to Detectron2
# learning rate, that is, a size of the gradient step when adapting the weights upon each learning iteration
$startup_solver_initial_lr_per_gpu = 0.0025 # TODO: BBH does NOT iterate this one
# This parameter hard-stops the training after predefined learning iterations, no matter the result
$startup_solver_iterations = 500
# This is auxillary parameter, helps to determine the epoch
$startup_dataset_size = 117226 # TODO: to be extracted automatically
# epoch is a number of learning iterations to traverse the entire dataset
# if number of epochs is set, then it suppresses solver_iterations
$startup_solver_number_of_epochs = 1
# TODO
$startup_app_flags = "NCCL_DEBUG=0"

# ITERATE: what parameters to benchmark
$iterate_schedulers = "none" # Linux IO schedulers: mq-deadline, bfq, kyber, none
# Combinations of GPU to run on
$iterate_number_of_gpus = 4
# how many images each GPU will be receiving at a time
$iterate_images_batch_per_gpu = 4
$iterate_dataloader_threads_per_gpu = 1

# COLLECT: How to collect benchmark numbers
# How many times to repeat every individual invocation (to accumulate statistics)
$collect_iterations = 1
# How often to fetch data from the application during training, seconds (can be a fraction, 0.1 or greater)
$collect_frequency = 1
# How long (in seconds) should BBH wait for the training to start showing progress (ETA)
# Upon expiration of the grace period, BBH will stop.
$collect_grace_period = 300

# INFRASTRUCTURE: where to run the benchmark
# Hosts to run the benchmark on
$infra_hosts = "dev"
# User for passwordless ssh to the benchmark nodes
$infra_user = "yuri"

