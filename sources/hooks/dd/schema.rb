SCHEMA = "
    add column iterate_operation varchar(50) not null first,
    add column iterate_size int not null after iterate_operation,
    add column collect_bandwidth double not null after iterate_size,
    add column infra_filesystem_mount_options varchar(200) after infra_filesystem,
    add column infra_filesystem_block_size varchar(20) after infra_filesystem_mount_options
  "
