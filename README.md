# ResetDomainPasswords.ps1
PowerShell script to generate random passwords (based on a wordlist) and reset passwords of all user accounts in the domain.

### Usage 
Import the scipt with ```Import-Module .\ResetPasswords.ps1```

Then you can use ```Invoke-GenerateCSV -Wordlist wordlist.txt -OutputDirectory C:\Users\Administrator\Desktop```. This will get all users in the domain, generate random passwords for each user and save them to "UsersPasswords.csv" in the procided directory (or current working directory if not specified). The given wordlist will be used to generate new random passwords (word + word + 2 digits = new password). The provided example a Dutch wordlist with medium-length words to prevent either too simple or too conmplex passwords.

```Invoke-GenerateCSV``` does not actually change the passwords. It is strongly recommended to review the CSV before resetting all user's passwords (i.e. exclude your own account or service accounts). When ready ```Invoke-ChangePasswords -CSVFile UsersPasswords.csv``` can be used to actually change the user's passwords. By default users will be required to change the password on first login and for all affected accounts "Password Never Expires" is disabled.

The ```Invoke-GenerateCSV``` function by default uses the query ```Get-Aduser -Filter * -Properties pwdLastSet, name``` to get all users. If this is too broad I recommend filtering by OU as follows: ```Invoke-GenerateCSV -Wordlist wordlist.txt -SearchBase "OU=TestOU,DC=clf,DC=internal"```

Moreover, a template CSV is provided that can be edited as you see fit to later ingest into ```Invoke-ChangePasswords```

