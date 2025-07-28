# Teradici.Anyware.Manager
Powershell module for manipulating Teradici Anyware Manager (https://cas.teradici.com/) by consuming Anyware Manager's RESTful APIs (https://cas.teradici.com/api/docs)

# Function List

Connect-CAS: connect to Teradici Anyware Manager via either an API token or a service account. The connection object is saved as $global:defaultCas.

Get-CasAdComputer: retrieve registered Active Directory (AD) computers
    
Get-CasAdUser: retrieve registered Active Directory (AD) users
    
Get-CasConnector: retrieve PCoIP connectors

Get-CasDeployment: retrieve deployments

Get-CasEntitlement: retrieve entitlements (which user is allowed to access which machine)

Get-CasMachine: retrieve PCoIP host machines

Get-CasUser: retrieve user accounts on Anyware Manager

New-CasConnectorToken: create a connector token to add a new Anyware Connector to an existing deployment

New-CasDeployment: create a new deployment

New-CasEntitlement: create a new entitlement

New-CasMachine: add an existing machine (aws/azure/gcp/onprem) to a deployment

Remove-CasDeployment: delete a deployment

Remove-CasEntitlement: delete an entitlement

Remove-CasMachine: remove a machine from deployment

# Install
```
Install-Module -Name Teradici.Anyware.Manager
```
