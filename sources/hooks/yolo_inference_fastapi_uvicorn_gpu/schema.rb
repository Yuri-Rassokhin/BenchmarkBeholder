SCHEMA = "
    add column collect_inference_time double(20,16) not null,
    add column collect_error varchar(500),
    add column iterate_processes int not null,
    add column iterate_requests int not null
  "
