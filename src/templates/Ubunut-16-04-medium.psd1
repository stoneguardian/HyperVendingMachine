@{
    # Name = ''
    CPUs = 1
    Memory = 2GB
    DynamicMemory = $false

    NetworkSwitch = @('Default Switch')

    Disks = @(
        @{
            Size = 20GB
        }
    )

    ISO = 'Ubuntu-16-04'
}