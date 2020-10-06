# This is a Windows PowerShell script
# Be sure to set execution policy so this will run. To do that, open a PowerShell console window as administrator and type the following:
#     Set-ExecutionPolicy RemoteSigned
# Then the script can be run from a normal PowerShell console window by typing .\build.ps1 (assuming you are in the Cessna-182 directory).

# Returns the date in Microsoft Epoch Time--that is the number of microseconds since 1/1/1601 AD
function Convert-To-Microsoft-Epoch-Time([datetime]$d) { 
    (Get-Date -Date $d).ToFileTime()
}

function build {
    [string]$src_dir = "src"
    [string]$build_dir = "Cessna-182T"

    # Delete the build directory if it exists
    if (Test-Path $build_dir) {
        Remove-Item $build_dir -Force -Recurse
    }

    # Create the build directory
    New-Item $build_dir -ItemType directory -Force

    # Copy the source files to the build directory
    Get-ChildItem -Path $src_dir |Copy-Item -Destination $build_dir -Recurse -Force

    $layout_list = New-Object System.Collections.Generic.List[System.Object]
    [int]$package_size = 0

    # Loop through all of the files in the build directory
    Get-ChildItem -Path $build_dir -Recurse | ForEach-Object {
        if ( -not $_.PSIsContainer) {

            # Relative path should start from the build directory
            Push-Location $build_dir

            #generate json for layout.json
            $layout_list.Add([hashtable]@{
                # Get the relative path, replace the back slashes with forward slashes, and cut off the leading ./
                path = (($_.FullName | Resolve-Path -Relative) -replace "[\\\\]", "/").Substring(2)
                size = $_.Length
                date = Convert-To-Microsoft-Epoch-Time $_.LastWriteTimeUtc
                }
            )

            # Accumulate file sizes for the package size
            $package_size += $_.Length

            Pop-Location
        }
    }

    $layout_file_name = "layout.json"
    $layout_full_file_name = [System.IO.Path]::Combine($build_dir, $layout_file_name)

    # Generate the json for layout.json and output the file
    $layout_json = New-Object -Type PSObject -Property @{content = $layout_list } 
    $layout_json | ConvertTo-Json | Out-File $layout_full_file_name -Encoding ascii

    # Add the size of layout.json to the package size
    $package_size += $layout_json_size

    # Create dependency list
    $dependency_list = New-Object System.Collections.Generic.List[System.Object]
    $dependency_list.Add([hashtable]@{
        name = "carenado-aircraft-ct182t-skylane-g1000"
        package_version = "1.1.1"
        }
    )
    $dependency_list.Add([hashtable]@{
        name = "fs-base"
        package_version = "0.1.88"
        }
    )
    $dependency_list.Add([hashtable]@{
        name = "fs-base-aircraft-common"
        package_version = "0.1.65"
        }
    )

    # Output manifest.json
    $manifest_json = New-Object -TypeName PSObject -Property @{
        dependencies         = $dependency_list
        content_type         = "AIRCRAFT"
        title                = "Cessna-182T"
        manufacturer         = "Textron Aviation"
        creator              = "Geoff Darst"
        package_version      = "0.5.1"
        minimum_game_version = "1.9.3"
        release_notes        = @{
            neutral = @{
                LastUpdate   = ""
                OlderHistory = ""
            }
        }
        total_package_size = $package_size.ToString("00000000000000000000")
    }


    $manifest_file_name = "manifest.json"
    $manifest_full_file_name = [System.IO.Path]::Combine($build_dir, $manifest_file_name)

    # Generate the json for manifest.json and output the file
    $manifest_json | ConvertTo-Json | Out-File $manifest_full_file_name -Encoding ascii
}

build