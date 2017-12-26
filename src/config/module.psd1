@{
    StateBasePath = 'D:\HyperVendingMachine\' # Where to read and write files from/to
    VMDirectory = 'D:\Hyper-V\VMs'
    IsoDirectory = 'D:\ISOs'

    OverProvisioningFactors = @{ # Ammounts to multiply installed with
        CPU = 8
        Memory = 1 # 1 = use installed ammount
    }
}