# Provide the VSS volume as $Path
# The collected empty directory list is saved at $SavePath\dir_list.txt
# Logs are saved at the $SavePath in file logfile.txt

Function Set-NutanixAvamarWorkaround {

  Param(
    [Parameter(
      Mandatory = $True,
      HelpMessage='Volume Path used for VSS')
    ]
    [string]$Path,
    [Parameter(
      Mandatory = $True,
      HelpMessage='File path to save empty directory list')
    ]
    [string]$SavePath
  ) #param

  Process{
    # Marker file for empty directories.
    $marker_name = ".__NTNXMARKER"
    # List of directories which are empty on given path.
    $empty_dirs = Get-ChildItem -Directory $Path -Recurse | `
                Where-Object { $_.GetFiles().Count -eq 0 -and `
                               $_.GetDirectories().Count -eq 0 }

    if ($empty_dirs -eq 0) {
      return }

    # Store the list of empty directories in file dir_list.txt at 
    # give save path.
    $empty_dirs.FullName | Out-File -FilePath "$SavePath\dir_list.txt"

    foreach ( $empty_path in $empty_dirs ) {

      $marker = New-Item -Path $empty_path.FullName -ItemType "file" -Name $marker_name
      $marker.attributes = "hidden"
      Add-Content -Path "$SavePath\logfile.txt" -Value "Added marker $($marker.FullName)" 
    }
  }
}

# Use the dir_list.txt to get list of marker files and delete them.
Function Remove-NutanixAvamarWorkaround {
  Param(   
    [Parameter(
      Mandatory = $True,
      HelpMessage='File path to save empty directory list')
    ]
    [string]$SavePath
  ) #param

  Process{
    $marker_name = ".__NTNXMARKER"

    # Read the file to get the list of marker files.
    $empty_dir_list = Get-Content -Path "$SavePath\dir_list.txt"
    foreach ( $file_path in $empty_dir_list ) {
      $file = Get-ChildItem -Path $file_path -File $marker_name -Force
      if(-not $file) {
        continue }
      Add-Content -Path "$SavePath\logfile.txt" -Value "Deleting file $($file.FullName)"
      $file | Remove-Item -Force
    }    
  }
}