# BulkCheckDomainsForDMARC
Used to check if a list of domains has SPF and DMARK records. 

This is a powershell script I wrote to check to see if a list of domains had DMARC and SPF records. I use it to check to see which vendors have domains that can be spoofed. Using the output and a mail merge, I email some of the vendors asking them to implement DMARC to protect both of us. I prefer to keep this process semi-manual so I can be sure of what I am sending.   

It is not sophisticated and requires some knowledge of Powershell to use. 

It starts by reading an input file of domains. You will need to change the path and filename to suit your needs. The file should contain one domain per line like this:

  domain1.com
  domain2.gov

The script will loop through each record and check for an SPF and DKIM record. If the SPF record is not set to "-all" and the DMARC record is not set to "quarantine" or "reject" it will flag the domain as "Can be spoofed."

The output is dumped into a csv file where it can be analyzed. Again, you may need to change the path for this to work. 



