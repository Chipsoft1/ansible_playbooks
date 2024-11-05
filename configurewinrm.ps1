try {
    Write-Output 'Configuring WinRM...'
    
    # Configure WinRM with basic settings
    winrm quickconfig -force | Out-String
    winrm set winrm/config/service/auth '@{Basic="true"}' | Out-String
    winrm set winrm/config/service '@{AllowUnencrypted="true"}' | Out-String

    # Check if a WinRM listener for HTTPS already exists
    if (-not (Get-Item -Path WSMan:\localhost\Listener | Where-Object { $_.Keys -eq 'Transport=HTTPS' })) {
        # Create a self-signed certificate
        $cert = New-SelfSignedCertificate -DnsName '{{ vm_name }}' -CertStoreLocation Cert:\LocalMachine\My
        # Create a new HTTPS listener with the certificate thumbprint and use -Force to avoid prompts
        New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * -CertificateThumbprint $cert.Thumbprint -Force | Out-String
    }

    # Create firewall rules for WinRM
    New-NetFirewallRule -DisplayName 'Allow WinRM HTTPS' -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow | Out-String
    New-NetFirewallRule -DisplayName 'Allow WinRM HTTP' -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow | Out-String
}
catch {
    Write-Output 'An error occurred during script execution.'
    Write-Output $_.Exception.Message
}

