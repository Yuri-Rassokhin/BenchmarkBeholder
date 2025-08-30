# Benchmarking SPDK #

## About SPDK

SPDK is a framework that allows user-space application to directly access your NVMe drives.
It follows it own, VERY specialized implementation approach of NVMe IO:

* It revokes NVMe drives from Linux kernel
* It puts NVMe drives under control of its own user-space drivers
* From that point, user-space applications can directly access NVMe via the drivers
* 'Directly' really means directly - you read from/write to raw devices, there's no more filesystem whatsoever
* In addition, SPDK implements its own concurrency model with respect to CPU cores and NUMA

SPDK substantionally boosts IO performance of your NVMe drives compared to conventional approach based on a filesystem. Quite naturally, exact numbers heavily depend on your HW configuration: NVMe features, NVMe generation, PCI generation, width of PCI connections, PCI topology, NUMA topology, RAM volume, and CPU model.

Please note that SPDK requires some expertise in HW architecture - so it's assumed that you know what you're doing if you're reading this.

1. Install SPDK.

```bash
cd /tmp
git clone https://github.com/spdk/spdk
cd ./spdk
git submodule update --init
./configure
make -j"$(nproc)"
ls ./build/examples/bdevperf 
```

2. Pick PCI locations of the NVMe drives you want to benchmark: `lspci | grep -i nvme`

3. Create drive configuration file `/tmp/spdk/drives.conf` for SPDK benchmarking. This file should describe NVMe drives that you want to benchmark using SPDK format, here's the template - just customize it for your NVMe drives and their PCI locations:

```json
{
  "subsystems": [
    {
      "subsystem": "bdev",
      "config": [
        {
          "method": "bdev_nvme_attach_controller",
          "params": {
            "name": "nvme0",
            "trtype": "PCIe",
            "traddr": "0000:1b:00.0"
          }
        },
        {
          "method": "bdev_nvme_attach_controller",
          "params": {
            "name": "nvme1",
            "trtype": "PCIe",
            "traddr": "0000:1c:00.0"
          }
        },
        {
          "method": "bdev_nvme_attach_controller",
          "params": {
            "name": "nvme2",
            "trtype": "PCIe",
            "traddr": "0000:3e:00.0"
          }
        },
        {
          "method": "bdev_nvme_attach_controller",
          "params": {
            "name": "nvme3",
            "trtype": "PCIe",
            "traddr": "0000:3f:00.0"
          }
        },
        {
          "method": "bdev_nvme_attach_controller",
          "params": {
            "name": "nvme4",
            "trtype": "PCIe",
            "traddr": "0000:94:00.0"
          }
        },
        {
          "method": "bdev_nvme_attach_controller",
          "params": {
            "name": "nvme5",
            "trtype": "PCIe",
            "traddr": "0000:95:00.0"
          }
        },
        {
          "method": "bdev_nvme_attach_controller",
          "params": {
            "name": "nvme6",
            "trtype": "PCIe",
            "traddr": "0000:e6:00.0"
          }
        },
        {
          "method": "bdev_nvme_attach_controller",
          "params": {
            "name": "nvme7",
            "trtype": "PCIe",
            "traddr": "0000:e7:00.0"
          }
        }
      ]
    }
  ]
}
```

4. In `./spdk.json`, modify parameter values in `sweep` section as you wish.

5. Note that BenchmarkBeholder will run SPDK's `bdevperf` utility using `sudo`, so please check that your user is a sudoer.

You're good to go :)

