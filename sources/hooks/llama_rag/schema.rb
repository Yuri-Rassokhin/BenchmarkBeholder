SCHEMA = "
    add column collect_inference_time double(20,16) not null,
    add column collect_failed_requests int not null,
    add column collect_cuda_error varchar(500),
    add column collect_response_error varchar(500),
    add column iterate_requests int not null
  "
