SCHEMA = "
    add column collect_size int not null after iterate_operation,
    add column collect_time double not null after collect_size
  "
