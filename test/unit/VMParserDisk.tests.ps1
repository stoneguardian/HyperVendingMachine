BeforeAll {
    # Load required files
    . $PSScriptRoot\..\..\src\classes\VMParserBase.ps1
    . $PSScriptRoot\..\..\src\classes\VMParserDisk.ps1

    # Silence warning-output
    $_currentWarningPreference = "$WarningPreference"
    $WarningPreference = 'SilentlyContinue'
}

Describe 'Class: VMParserSingleDisk' {
    $constructorInputTestCases = @(
        @{type = [string]; value = '1GB' }
        @{type = [int]; value = 1073741824 } # = 1GB
        @{type = [long]; value = 107374182400 } # = 100GB
        @{type = [hashtable]; value = @{Size = 10GB } }
    )

    It 'Accepts <type> as input' -TestCases $constructorInputTestCases {
        param($value)
        [VMParserSingleDisk]::new($value) # Should "NotThrow"
    }

    It 'Ensures required input is given' {
        { [VMParserSingleDisk]::new(@{ System = $true }) } | Should -Throw -ExpectedMessage "* Size"
    }

    $missingValuesTestCases = @(
        @{
            Case      = 'Simple [string]'
            Parameter = '10GB'
        }
        @{
            Case      = '[hashtable] with "Size"'
            Parameter = @{ Size = 5GB }
        }
        @{
            Case      = '[hashtable] with "Size" and "System"'
            Parameter = @{ Size = 5GB; System = $true }
        }
        @{
            Case      = '[hashtable] with "Size" and "Name"'
            Parameter = @{ Size = 5GB; Name = 'Test2' }
        }
    )

    It 'Generates missing non-required values (<Case>)' -TestCases $missingValuesTestCases {
        param($Parameter)
        $result = [VMParserSingleDisk]::new($Parameter).Build()
        $missingKeys = [VMParserSingleDisk]::OutputMap.Keys.Where{ $_ -notin $result.Keys }
        $missingKeys -join ', ' | Should -BeNullOrEmpty
    }

    $outputTypeTestCases = [VMParserSingleDisk]::OutputMap.Keys | 
        ForEach-Object { @{ Key = $_; Type = [VMParserSingleDisk]::OutputMap[$_] } }

    It "Ensures key '<Key>' is of type <Type>" -TestCases $outputTypeTestCases {
        param($Key, $Type)
        $result = [VMParserSingleDisk]::new(10GB).Build()
        $result[$Key] | Should -BeOfType $Type
    }

    It 'Defaults "System" to $false' {
        $result = [VMParserSingleDisk]::new(10GB).Build()
        $result.System | Should -BeFalse
    }

    It 'sets "System" = $true if AsSystemDisk() is called' {
        $result = [VMParserSingleDisk]::new(10GB).AsSystemDisk('test').Build()
        $result.System | Should -BeTrue
    }

    It 'sets "Name" = "VMName"-parameter if AsSystemDisk() is called' {
        $result = [VMParserSingleDisk]::new(10GB).AsSystemDisk('test').Build()
        $result.Name | Should -Be 'test'
    }
}

Describe 'Class: VMParserDisks' {
    BeforeAll {
        # Silence warning-output
        $_currentWarningPreference = "$WarningPreference"
        $WarningPreference = 'SilentlyContinue'
    
        # Mock Get-VM if command is available
        if ($null -ne (Get-Command 'Get-VM' -ErrorAction SilentlyContinue))
        {
            Mock -CommandName 'Get-VM' -MockWith {
                return $null
            }
        }
        else 
        {
            function Get-VM
            {
                [CmdletBinding()]
                param([string] $Name)
    
                return $null
            }    
        }
    }

    It 'Accepts multiple different types as input' {
        [VMParserDisks]::new('test').WithInput(@('1GB', 1073741824, 107374182400, @{Size = 10GB })).Build() # Should not throw
    }

    $singleInputCases = @(
        @{Type = [string]; Value = '1GB' }
        @{Type = [int]; Value = 1073741824 }
        @{Type = [long]; Value = 107374182400 }
        @{Type = [hashtable]; Value = @{Size = 10GB } }
    )

    It 'Accepts single input (<Type>)' -TestCases $singleInputCases {
        param($Value)
        [VMParserDisks]::new('test').WithInput($Value).Build() # Should not throw
    }

    It 'Outputs [System.Collections.Hashtable] for single input (<Type>)' -TestCases $singleInputCases {
        param($Value)
        $result = [VMParserDisks]::new('test').WithInput($Value).Build()
        $result | Should -BeOfType [System.Collections.Hashtable]
    }

    It 'Outputs [System.Collections.Hashtable] for array input' {
        $result = [VMParserDisks]::new('test').WithInput(@('1GB', 1073741824, 107374182400, @{Size = 10GB })).Build()
        $result | Should -BeOfType [System.Collections.Hashtable]
    }

    It 'Assigns first disk as system if VM does not exist' {
        $result = [VMParserDisks]::new('test').WithInput(@('1GB', '2GB')).Build() # Should not throw
        
        $result.Count | Should -Be 2
        
        $result[0].System | Should -BeTrue 
        $result[0].Name | Should -Be 'test' -Because "disk-name should be the same as VMName"

        $result[1].System | Should -BeFalse
        $result[1].Name | Should -Not -Be 'test'
    }

    It 'Only auto-asigns disk as system-disk if no other disk has been manually designated as system disk' {
        $result = [VMParserDisks]::new('test').WithInput(@('1GB', @{System = $true; Size = 2147483648 })).Build()
        $_system = $result.Where{ $_.System -eq $true }
        $_system.Size | Should -Be 2147483648
    }

    It 'Only allows one system disk' {
        { 
            [VMParserDisks]::new('test').WithInput(@(@{System = $true; Size = 1GB }, @{System = $true; Size = 1GB })).Build()
        } | Should -Throw -ExpectedMessage "Only one*"
    }

    It 'Ensures the system-disk is the first in the list' {
        $result = [VMParserDisks]::new('test').WithInput(@('1GB', @{System = $true; Size = 2147483648 })).Build()

        $result.Count | Should -Be 2

        $result[0].System | Should -BeTrue
        $result[1].System | Should -BeFalse -Because "second disk should not be system-disk"
    }

    AfterAll {
        # Reset warning-output
        $WarningPreference = $_currentWarningPreference
    }
}

