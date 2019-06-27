@{
    # Ammounts module will multiply installed resources with
    # and not throw out of resource exeptions
    OverprovisionFactors = @{
        CPU    = 8
        Memory = 1
    }

    # Where to store created VMs (configs, disks, snapshots)
    VMStoragePath        = 'D:\HyperVendingMaching\VMs'
}