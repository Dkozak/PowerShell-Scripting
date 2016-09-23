$cert = New-SelfSignedCertificate -DnsName smartscale.demo.net -CertStoreLocation "cert:\LocalMachine\My"
$password = ConvertTo-SecureString -String "<PWD>" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "c:\temp\my-cert-file.pfx" -Password $password
