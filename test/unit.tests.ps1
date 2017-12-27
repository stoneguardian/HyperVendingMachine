# Load shared
. "$PSScriptRoot\shared.ps1"

Describe 'Get-AllConfigPaths' {
    $result = Get-AllConfigPaths -PathHash $TestmoduleConfig.Paths

    It 'Returns paths where key is string: <key>' -TestCases @(
        @{ key = 'Task'; p = 'TestDrive:\HVM\ReadOnly\Tasks\' }
        @{ key = 'Error'; p = 'TestDrive:\HVM\ReadOnly\Error\' }
    ) {
        param($p)
        $p -in $result | Should Be $true
    }

    It 'Returns paths where key is hashtable: <key>' -TestCases @(
        @{ key = 'Incoming'; p = 'TestDrive:\HVM\Input\VM\' }
        @{ key = 'Enqueued->ToCreate'; p = 'TestDrive:\HVM\ReadOnly\Enqueued\New\' }
        @{ key = 'Enqueued->ToChange'; p = 'TestDrive:\HVM\ReadOnly\Enqueued\Set\' }
    ) {
        param($p)
        $p -in $result | Should Be $true
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
        @{ key = 'Enqueued->ToCreate'; pn = @('Enqueued', 'ToCreate'); p = 'TestDrive:\HVM\ReadOnly\Enqueued\New\' }
        @{ key = 'Processing->ToChange'; pn = @('Processing', 'ToChange'); p = 'TestDrive:\HVM\ReadOnly\Processing\Set\' }
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
        Test-Path $movedToPath | Should Be $true
    }

    It 'Rejects order if template is not found' {

    }

    It 'Rejects order if mandatory parameter is missing' {

    }

    It 'Rejects order if parameter-validation fails' {
        
    }

}