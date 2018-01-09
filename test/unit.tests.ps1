# Load shared
. "$PSScriptRoot\shared.ps1"

Describe 'Get-AllConfigPaths' {
    $result = Get-AllConfigPaths -PathHash $TestmoduleConfig.Paths

    It 'Returns paths where key is string: <key>' -TestCases @(
        @{ key = 'Task'; p = 'TestDrive:\HVM\ReadOnly\Tasks\' }
        @{ key = 'Error'; p = 'TestDrive:\HVM\ReadOnly\Error\' }
    ) {
        param($p)
        $p | Should -BeIn $result
    }

    It 'Returns paths where key is hashtable: <key>' -TestCases @(
        @{ key = 'Incoming'; p = 'TestDrive:\HVM\Input\VM' }
        @{ key = 'Enqueued->ToCreate'; p = 'TestDrive:\HVM\ReadOnly\Enqueued\New' }
        @{ key = 'Enqueued->ToChange'; p = 'TestDrive:\HVM\ReadOnly\Enqueued\Set' }
    ) {
        param($p)
        $p | Should -BeIn $result
    }


}

Describe 'Get-ConfigPath' {
    It 'Returns base if "PathName" is not set' {
        Get-ConfigPath -ModuleConfig $TestModuleConfig | Should Be $TestModuleConfig.Paths.Base
    }

    It 'Returns path if key is string (one level): <key>' -TestCases @(
        @{ key = 'Task'; p = 'TestDrive:\HVM\ReadOnly\Tasks\' }
        @{ key = 'Error'; p = 'TestDrive:\HVM\ReadOnly\Error\' }
    ) {
        param($p, $key)
        Get-ConfigPath -Key $key -ModuleConfig $TestModuleConfig | Should Be $p
    }

    It 'Returns base-path if key is hashtable (one level): <key>' -TestCases @(
        @{ key = 'Incoming'; p = 'TestDrive:\HVM\Input' }
        @{ key = 'Enqueued'; p = 'TestDrive:\HVM\ReadOnly\Enqueued' }
    ) {
        param($p, $key)
        Get-ConfigPath -Key $key -ModuleConfig $TestModuleConfig | Should Be $p
    }

    It 'Returns path if key is string (two levels): <key>' -TestCases @(
        @{ key = 'Enqueued->ToCreate'; pn = @('Enqueued', 'ToCreate'); p = 'TestDrive:\HVM\ReadOnly\Enqueued\New' }
        @{ key = 'Processing->ToChange'; pn = @('Processing', 'ToChange'); p = 'TestDrive:\HVM\ReadOnly\Processing\Set' }
    ) {
        param($p, $pn)
        Get-ConfigPath -Key $pn -ModuleConfig $TestModuleConfig | Should Be $p
    }
}

Describe 'Import-HvVmOrder' {
    # Create folder structure
    Get-AllConfigPaths -PathHash $TestModuleConfig.Paths | Create-AllConfigPaths
    Copy-Item "$PSScriptRoot\testfiles\Import-HVNewVmOrder\*" -Destination (Get-ConfigPath -Key 'Incoming', 'VMs' -ModuleConfig $TestModuleConfig) -ErrorAction Stop

    # Run 
    Import-HvVmOrder -ModuleConfig $TestModuleConfig

    It 'Rejects order if filename is not a GUID' {
        $movedToPath = "$(Get-ConfigPath -Key 'Error' -ModuleConfig $TestModuleConfig)\Error-NameNotGuid-wrong-filename.json"
        Test-Path $movedToPath | Should -Be $true
    }

    It 'Recjects order <reason>' -TestCases @(
        @{ Reason = 'if template is not found'; StatusError = '*template with name *'; TestFileGuid = '859e80e0-0c71-4999-8ab4-dd0e1c5dba92'}
        @{ Reason = 'if name is missing'; StatusError = '*does not contain Name'; TestFileGuid = '6279e528-bde9-4f11-aa3e-a884497ea33d' }
        @{ Reason = 'if parameter-validation fails: NetworkSwitch does not exist'; StatusError = '*NetworkSwitch * not found*'; TestFileGuid = '97e4d62f-5322-4fd7-904b-8cc9bada39e7' }
    ) {
        param($StatusError, $TestFileGuid)
        
        $statusPath = "$(Get-ConfigPath -Key Status -ModuleConfig $TestModuleConfig)$TestFileGuid.json"
        $status = Get-Content $statusPath | ConvertFrom-Json 
        $status.Error | Should -BeLike $StatusError

        $errorPath = "$(Get-ConfigPath -Key Error -ModuleConfig $TestModuleConfig)$TestFileGuid.json"
        Test-Path $errorPath | Should -Be $true
    }

    Context 'OK Order - Self Contained' {

        $TestFileGuid = '9348b1a-c396-4378-9812-063fd92fe14b'

        It 'Creates file in staging directory' {
            $stagePath = "$(Get-ConfigPath -Key Enqueued, ToCreate -ModuleConfig $TestModuleConfig)$TestFileGuid.json"
            Test-Path $stagePath | Should -Be $true
        }
        
        It 'Second disk is named "Data" if no name is given' {
            $stagePath = "$(Get-ConfigPath -Key Enqueued, ToCreate -ModuleConfig $TestModuleConfig)$TestFileGuid.json"
            $order = Get-Content $stagePath | ConvertFrom-Json
            $order.Disks[1].Name | Should -Be 'Data'
        }
        
        It 'Status updated' {
            $statusPath = "$(Get-ConfigPath -Key Status -ModuleConfig $TestModuleConfig)$TestFileGuid.json"
            $status = Get-Content $statusPath | ConvertFrom-Json 
            $status.CurrentStage | Should -BeLike '*Queued*'
        }
    }

    Context 'OK Order - Template' {
        
        #It ''

    }
}