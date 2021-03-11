$ErrorActionPreference = "Continue"


function Invoke-ChangePasswords {

    param (
        [Parameter(Mandatory=$true)]
        [string]$CSVFile,
        [string]$OutputDirectory
    )
    
    if (!$CSVFile) {Write-Host "Invalid CSV file path..."; break}

    Import-Csv $CSVFile | foreach-object {
        $user = $_.SamAccountName
        $password = $_.Password

        try{
            Write-Host "Changing password for: " $user
            Set-ADAccountPassword -Identity $user -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "$password" -Force) 
            # Set password to expire, so change at next login can be enforced
            Set-ADUser -Identity $user -PasswordNeverExpires $false
            # User must change password on login
            Set-ADUser -Identity $user -ChangePasswordAtLogon $true
            $log = $user + "," + $password
            # If no ouptut directory is specified, write to working directory
            if (!$OutputDirectory) {$OutputDirectory = $PSScriptRoot}
            Out-File -Append -FilePath $OutputDirectory\Changed_Passwords.txt -InputObject $log
        }
        catch {
            Write-Error $Error[0]
            $err = $user + "," + $Error[0]
        }     
    }

}

function Get-Passwords {

    param (
        [Parameter(Mandatory=$true)]
        [string]$Wordlist,
        [Parameter(Mandatory=$true)]
        [int]$Amount,
        [string]$OutFile
    )

    [string[]]$wordlist = Get-Content -Path $Wordlist

    if (!$Wordlist) {Write-Host "Invalid wordlist path..."; break}

    $passwords = @()

    for ($i=1; $i -le $Amount; $i++){
        # Get 2 random words, random number and append them
        $word1 = Get-Random -InputObject $wordlist
        $word2 = Get-Random -InputObject $wordlist
        $number = Get-Random -Minimum -10 -Maximum 99
        $password = $word1 + $word2 + $number

        $passwords += $password
    }

    if ($OutFile){
            $passwords | Out-File -FilePath $OutFile
            return $passwords
    }
    else {
        return $passwords
    }  
}


function Invoke-GenerateCSV {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Wordlist,
        [string]$OutputDirectory,
        [string]$SearchBase
    )
    
    # Generate passwords, equal to the count of users
    $count = Get-Aduser -Filter * -Properties pwdLastSet, name | measure
    $count = $count.Count
    $passwords = Get-Passwords -Amount $count -Wordlist $Wordlist
    
    # Get users from AD
    if($SearchBase){
        $users = Get-Aduser -Filter * -Properties pwdLastSet, name | Select-Object name, SamAccountName, pwdLastSet
    }
    else {
        $users =  Get-Aduser -SearchBase $SearchBase -Filter * -Properties pwdLastSet, name | Select-Object name, SamAccountName, pwdLastSet
    }

    # Add random passwords to user object
    $cnt = 0
    foreach($user in  $users){
        $user | Add-Member -NotePropertyName "Password" -NotePropertyValue $passwords[$cnt]
        $cnt++
    }

    # Export to CSV
    if (!$OutputDirectory) {$OutputDirectory = $PSScriptRoot}
    $users | Export-Csv -NoTypeInformation -Path $OutputDirectory\UsersPasswords.csv

    Write-Host "CSV written to $OutputDirectory\UsersPasswords.csv"
}
