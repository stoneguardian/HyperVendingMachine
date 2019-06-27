@{
    # Name = ''
    CPUs = 1
    Memory = 1GB
    DynamicMemory = $false

    NetworkSwitch = @('Default Switch')

    Disks = @(
        @{
            Size = 10GB
        }
    )

    ISO = 'Ubuntu-16-04'
}