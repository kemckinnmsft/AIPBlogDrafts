# Azure Information Protection Frequently Asked Questions and Best Practices

The AIP Scanner is a very powerful tool that allows corporate administrators to scan on premises CIFS file shares and SharePoint libraries. Sometimes however, things do not go as expected.  Below are a few frequently asked questions and best practices that may help you when using the AIP Scanner.

## Frequently Asked Questions

Q: I installed the new AIP Scanner Preview (1.38.7.0) so I could see data in the AIP Log Analytics dashboards, but the dashboards are still blank??

A: Make sure you have run the commands below to update the AIP Scanner to the latest version.
 >```PowerShell
 >Update-AIPScanner
 >Restart-Service AIPScanner
 >```

## Best Practices

Always install the GA version of the scanner before updating to a preview client.

If you install the preview client and it is not operating as expected, uninstall the preview client and make sure it is working with the GA before continuing to troubleshoot or opening a support ticket.