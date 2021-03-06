# Using Office 365 Message Encryption to Encrypt Sensitive Information in Email



```Powershell
# Connect to EXO

$UserCredential = Get-Credential

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

Import-PSSession $Session

# Go to S/MIME Encryption mode

Set-IRMConfiguration -DecryptAttachmentForEncryptOnly $true

# Create an EO mail flow rule for DLP policy hits

New-TransportRule -Name "Default Office 365 OME policy - Encrypt external mails with sensitive content" `
-SentToScope NotInOrganization `
-ApplyRightsProtectionTemplate "Encrypt" `
-MessageContainsDataClassifications @(@{Name="ABA Routing Number"; minCount="1"},@{Name="Credit Card Number"; minCount="1"},@{Name="Drug Enforcement Agency (DEA) Number"; minCount="1"},@{Name="International Classification of Diseases (ICD-10-CM)"; minCount="1"},@{Name="International Classification of Diseases (ICD-9-CM)"; minCount="1"},@{Name="U.S. / U.K. Passport Number"; minCount="1"},@{Name="U.S. Bank Account Number"; minCount="1"},@{Name="U.S. Individual Taxpayer Identification Number (ITIN)"; minCount="1"},@{Name="U.S. Social Security Number (SSN)"; minCount="1"})
```

This will create an Exchange Online mail flow rule which can be modified to meet your organization’s specific sensitive information policies.