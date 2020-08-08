BeforeAll {
    . $PSScriptRoot\..\..\src\private\RenderCloudInitUserData.ps1
}

Describe 'RenderCloudInitUserData' {
    It 'Generates hostname and fqdn automatically' {
        $result = RenderCloudInitUserData -VMName 'test' -ModuleConfigUserData @{ }
        $result | Should -BeLike "*hostname: test*"
        $result | Should -BeLike "*fqdn: test*"
    }

    It 'Generates hostname and fqdn (with domain) automatically' {
        $result = RenderCloudInitUserData -VMName 'test' -Domain 'somedomain.local' -ModuleConfigUserData @{ }
        $result | Should -BeLike "*hostname: test*"
        $result | Should -BeLike "*fqdn: test.somedomain.local*"
    }

    It 'Has "#cloud-config" as first line of output' {
        $result = RenderCloudInitUserData -VMName 'test' -ModuleConfigUserData @{ }
        $result | Should -BeLike '#cloud-config*'
    }

    It 'Does not allow overwriting keys on blacklist' {
        $result = RenderCloudInitUserData -VMName 'test' -UserData @{ hostname = 'something' } -ModuleConfigUserData @{ }
        $result | Should -BeLike "*hostname: test*"
    }

    It 'Adds keys if not in config-UserData' {
        $result = RenderCloudInitUserData -VMName 'test' -UserData @{ nonexisting = 'something' } -ModuleConfigUserData @{ }
        $result | Should -BeLike '*nonexisting: something*'
    }

    It 'Adds complex key' {
        $result = RenderCloudInitUserData -VMName 'test' -UserData @{ users = @(@{ name = 'test'; groups = 'adm', 'sudo' }) } -ModuleConfigUserData @{ }
        $result | Should -BeLike '*users:*'
        $result | Should -BeLike '*name: test*'
        $result | Should -BeLike '*groups:*'
        $result | Should -BeLike '*- adm*'
        $result | Should -BeLike '*- sudo*'
    }

    It 'Adds keys on blacklist if not in config-UserData' {
        $result = RenderCloudInitUserData -VMName 'test' -UserData @{ package_upgrade = $true } -ModuleConfigUserData @{ }
        $result | Should -BeLike '*package_upgrade: true*'
    }

    It 'Overwrites config-UserData if key is not on blacklist' {
        $result = RenderCloudInitUserData -VMName 'test' -UserData @{ nonexisting = 'something' } -ModuleConfigUserData @{ nonexisting = 'else' }
        $result | Should -BeLike '*nonexisting: something*'
    }

    $appendTestCases = @(
        @{
            name              = 'if UserData-key is single string'
            commandParameters = @{
                VMName               = 'test'
                UserData             = @{
                    packages = 'python'
                }
                ModuleConfigUserData = @{
                    packages = [System.Collections.Generic.List[string]]@('linux-virtual')
                }
            }
            likeStrings       = @('*packages:*', '*- linux-virtual*', '*- python*')
        }
        @{
            name              = 'if UserData-key is array'
            commandParameters = @{
                VMName               = 'test'
                UserData             = @{
                    packages = @('python', 'htop')
                }
                ModuleConfigUserData = @{
                    packages = [System.Collections.Generic.List[string]]@('linux-virtual')
                }
            }
            likeStrings       = @('*packages:*', '*- linux-virtual*', '*- python*', '*- htop*')
        }
        @{
            name              = 'if config-UserData is array (@())'
            commandParameters = @{
                VMName               = 'test'
                UserData             = @{
                    packages = @('python')
                }
                ModuleConfigUserData = @{
                    packages = @('linux-virtual')
                }
            }
            likeStrings       = @('*packages:*', '*- linux-virtual*', '*- python*')
        }
    )

    It 'Appends to config-UserData <name>' -TestCases $appendTestCases {
        param($commandParameters, $likeStrings)

        $result = RenderCloudInitUserData @commandParameters
        foreach ($string in $likeStrings)
        {
            $result | Should -BeLike $string
        }
    }

}