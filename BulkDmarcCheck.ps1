CLS

# edit path to meet your needs. 

# This is where the output will go.
cd C:\path\

# This is the input file. 
# Expects a file with nothing but domain names. One per line. Like domain1.com
$RecipientDomains = Get-Content C:\path\Domains2Check.txt

$RecipientResults=@()

# Loop through each domain to check the DMARC and SPF records. 
"Processing DMARC and SPF Records"

Foreach ($RecipientDomain in $RecipientDomains) {
    # Check for DMARC record
    $DnsCheck = Resolve-DnsName -Name "_dmarc.$RecipientDomain" -Type TXT -ErrorAction SilentlyContinue

    if ($DnsCheck) {
        # If a DMARC record is returned, parse it into usable variables. 
        if ($DnsCheck.Strings -like "*v=DMARC1*") {
            $DmarcString = $DnsCheck.Strings -replace '\s',''
            $DmarcString = $DmarcString.ToLower()
            $DmarcString = $DmarcString.Split(";")

            #Check the DMARC Domain Policy
            If ($DmarcString -contains "p=none") {
                $DmarcDomainPolicy = "None"
            } elseif ($DmarcString -contains "p=quarantine") {
                $DmarcDomainPolicy = "Quarantine"
            } elseif ($DmarcString -contains "p=reject") {
                $DmarcDomainPolicy = "Reject"
            } else {
                $DmarcDomainPolicy = "None/Unknown"
            }

            #Check the DMARC Subdomain Policy
            If ($DmarcString -contains "sp=none") {
                $DmarcSubDomainPolicy = "None"
            } elseif ($DmarcString -contains "sp=quarantine") {
                $DmarcSubDomainPolicy = "Quarantine"
            } elseif ($DmarcString -contains "sp=reject") {
                $DmarcSubDomainPolicy = "Reject"
            } else {
                $DmarcSubDomainPolicy = "No"
            }
            $DmarcRecordPresent = "Yes"
        } else {
            $DmarcRecordPresent = "No"
        }
    } else {
        $DmarcRecordPresent = "No"
        $DmarcDomainPolicy = ""
        $DmarcSubDomainPolicy = ""
    }
  

    #Check for SPF record
    $DnsCheck=Resolve-DnsName -Name $RecipientDomain -Type "TXT" -ErrorAction SilentlyContinue
        
    if ($DnsCheck) {$DnsCheck = ($DnsCheck | where {$_.strings -like "*spf1*"} | select strings)}

    if ($DnsCheck) {
            
        $pieces = $DnsCheck.Strings -split ' '
        If ($pieces -contains "-all") {
            $SpfAll="Hard Fail"
        } elseif ($pieces -contains "~all"){
            $SpfAll="Soft Fail"
        } elseif ($pieces -contains "+all"){
            $SpfAll="Allow ALL?!?!"
        } elseif ($pieces -contains "?all"){
            $SpfAll="Nuetral"
        } else {
            $SpfAll="None/Unknown"
        }
        $SpfRecord = "Yes"
    } else {
        $SpfRecord = "No"
        $SpfAll = ""
    }

    if ($SpfAll -eq "Hard Fail" -and ($DmarcDomainPolicy -eq "Quarantine" -or $DmarcDomainPolicy -eq "Reject"))
    {
        $CanBeSpoofed = "No"
    } else {
        $CanBeSpoofed = "Yes"
    }
    
    # Add results to arrray for export. 
    $Result = New-Object PSObject
    $Result | Add-Member -membertype NoteProperty -Name "Domain" -Value $RecipientDomain
    $Result | Add-Member -membertype NoteProperty -Name "DmarcRecordPresent" -Value $DmarcRecordPresent
    $Result | Add-Member -membertype NoteProperty -Name "DmarcDomainPolicy" -Value $DmarcDomainPolicy
    $Result | Add-Member -membertype NoteProperty -Name "DmarcSubDomainPolicy" -Value $DmarcSubDomainPolicy
    $Result | Add-Member -membertype NoteProperty -Name "SpfRecordPresent" -Value $SpfRecord
    $Result | Add-Member -membertype NoteProperty -Name "SpfAllSetting" -Value $SpfAll
    $Result | Add-Member -membertype NoteProperty -Name "CanBeSpoofed" -Value $CanBeSpoofed

    $RecipientResults+=$Result
    $Result = $null
    $DmarcRecordPresent = $null
    $DmarcDomainPolicy = $null
    $DmarcSubDomainPolicy = $null
    $SpfRecord = $null
    $SpfAll = $null
    $CanBeSpoofed = $null
    $DnsCheck = $null

    "Processed: $RecipientDomain"
}

$RecipientResults | Export-Csv "Bulk Domain SPF and DMARC Check.csv" -notypeinformation

