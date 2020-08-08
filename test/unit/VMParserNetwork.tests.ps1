# Load required files
. $PSScriptRoot\..\..\src\classes\VMParserBase.ps1
. $PSScriptRoot\..\..\src\classes\VMParserNetwork.ps1

Describe 'Class: VMParserNetwork' {
    $validConstructorInputTestCases = @(
        @{ type = [string]; value = 'test-switch' }
        @{ type = [hashtable]; value = @{ Switch = 'test-switch' } }
    )

    It 'Accepts <type> as input for constructor' -TestCases $validConstructorInputTestCases {
        param($value)
        [VMParserNetwork]::new($value) # Should "NotThrow"
    }

    It 'Throws if input is missing mandatory keys' {
        { [VMParserNetwork]::new(@{ VlanId = 1 }) } | Should -Throw -ExpectedMessage "Missing required keys*"
    }

    It 'Validates output types' {
        { [VMParserNetwork]::new(@{ Switch = $false; VlanId = "kake" }) } | Should -Throw -ExpectedMessage "* type * but was *"
    }
}