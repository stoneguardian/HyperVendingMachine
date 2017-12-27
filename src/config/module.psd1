@{
    BasePath = 'D:\HyperVendingMachine\'
    PathTree = @{
        Module = @{ # Public ReadOnly folder
            AvailableResources = ''
        }
    }

    HyperVStorage = @{
        VMDirectory = 'D:\Hyper-V\VMs'
        VhdDirectory = 'Hyper-V\VHDs'
        VhdDriveLetters = @('D') # Which disks can contain VHDs
    }

    StatePath = @{ # Where to read and write files from/to
        Base = ''
        PublicReadOnly = 'ReadOnly'
        PublicWrite = 'ReadWrite'

        Resources = ''
    }

    VMDirectory = 'D:\Hyper-V\VMs'
    IsoDirectory = 'D:\ISOs'

    OverProvisioningFactors = @{ # Ammounts to multiply installed with
        CPU = 8
        Memory = 1 #1 = use installed ammount
    }
}