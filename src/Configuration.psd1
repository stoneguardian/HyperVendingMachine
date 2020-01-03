@{
    # Ammounts module will multiply installed resources with
    # and not throw out of resource exeptions
    OverprovisionFactors = @{
        CPU    = 8
        Memory = 1
    }

    # Where to store created VMs (configs, disks, snapshots)
    VMStoragePath        = 'D:\HyperVendingMachine\VMs'
    OrderBasePath        = 'D:\HyperVendingMachine\Orders'
    TemplateBasePath     = 'D:\HyperVendingMachine\Templates'
    ImageStoragePath     = 'D:\HyperVendingMachine\Image'

    # cloud-init defaults
    CloudInitDefaults    = @{
        MetaData = @{ }
        UserData = @{
            timezone        = "Europe/Oslo"
            package_upgrade = $true
            packages        = [System.Collections.Generic.List[string]]@('linux-virtual', 'linux-cloud-tools-virtual', 'linux-tools-virtual')
            write_files     = [System.Collections.Generic.List[hashtable]]@(@{
                    content = @"
hv_vmbus
hv_storvsc
hv_blkvsc
hv_netvsc
"@
                    path    = '/etc/initramfs-tools/modules'
                    append  = $true
                })
            power_state     = @{
                mode = 'reboot'
            }
        }
    }
}