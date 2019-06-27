# Load all functions
$private = Get-ChildItem -Path "$PSScriptRoot\..\src\private" -Filter '*.ps1'
$public = Get-ChildItem -Path "$PSScriptRoot\..\src\public" -Filter '*.ps1'

foreach ($func in @($private + $public))
{
    . $func.FullName # Import to session
}

$TestModuleConfig = @{
    Paths         = @{
        Base       = "TestDrive:\HVM"
        Incoming   = @{
            Base = "Input"
            VMs  = "VM"
        }
        Enqueued   = @{
            Base     = "ReadOnly\Enqueued"
            ToCreate = "New"
            ToChange = "Set"
        }
        Processing = @{
            Base     = "ReadOnly\Processing"
            ToCreate = "New"
            ToChange = "Set"
        }
        Status     = "ReadOnly\Status\"
        Task       = "ReadOnly\Tasks\"
        Error      = "ReadOnly\Error\"
    }

    HyperVStorage = @{
        VMFolder  = ''
        VhdFolder = ''
        VhdDisks  = @($env:SystemDrive[0])
    }
}