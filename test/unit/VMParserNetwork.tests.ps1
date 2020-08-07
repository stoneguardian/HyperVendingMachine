# Load required files
. $PSScriptRoot\..\..\src\classes\VMParserBase.ps1
. $PSScriptRoot\..\..\src\classes\VMParserNetwork.ps1

# Silence warning-output
#$_currentWarningPreference = "$WarningPreference"
#$WarningPreference = 'SilentlyContinue'

$validConstructorInputTestCases = @(
    @{ type = [string]; value = 'test-switch' }
    @{ type = [hashtable]; value = @{ Switch = 'test-switch' } }
)

Describe 'Class: VMParserNetwork' {
    It 'Accepts <type> as input for constructor' -TestCases $validConstructorInputTestCases {
        param($value)
        [VMParserNetwork]::new($value) # Should "NotThrow"
    }

    It 'Throws if input is missing mandatory keys' {
        { [VMParserNetwork]::new(@{ VlanId = 1 }) } | Should -Throw "is required"
    }

    It 'Validates output types' {
        { [VMParserNetwork]::new(@{ Switch = $false; VlanId = "kake" }) } | Should -Throw "[$([VMParserNetwork]::OutputMap['Switch'])] but was [bool]"
    }
}

# Reset warning-output
#$WarningPreference = $_currentWarningPreference