<#
Copyright (c) 2025 Jian Liu (whirls9@hotmail.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
#>

class cas {
  $api_url
  $head

  cas ($address, $apiToken) {
    $this.api_url = "https://$address/api/v1"
    $this.head = @{"Authorization" = $apiToken}
  }

  # https://cas.teradici.com/api/docs#section/API-Examples/1.-Sign-in-using-a-Service-Account
  cas ($address, $tenantId, $username, $apiKey) {
    $this.api_url = "https://$address/api/v1"
    $hash = @{
      username = $username
      password = $apiKey
      tenantid = $tenantId
    }
    $token = (Invoke-RestMethod -Uri "$($this.api_url)/auth/signin" -Method Post -Body $hash).data.token
    $this.head = @{"Authorization" = $token}
  }

  # https://cas.teradici.com/api/docs#tag/AD-Computers/operation/getADComputers
  [object[]] get_adcomputer ($name, $limit, $deploymentName) {
    $uri = "$($this.api_url)/machines/entitlements/adcomputers?limit=$limit"
    if ($deploymentName) { 
      $deploymentId = $this.get_deployment($deploymentName).deploymentId 
      $uri += "&deploymentId=$deploymentId"
    }
    $data = Invoke-RestMethod -Headers $this.head -Uri $uri | 
      select-object -ExpandProperty data |
      Where-Object {$_.computerName -match $name}
    return $data
  }

  # https://cas.teradici.com/api/docs#tag/Users/operation/getUsers
  [object[]] get_aduser ($name, $limit, $deploymentName) {
    $uri = "$($this.api_url)/machines/entitlements/adusers?limit=$limit"
    if ($deploymentName) { 
      $deploymentId = $this.get_deployment($deploymentName).deploymentId 
      $uri += "&deploymentId=$deploymentId"
    }
    $data = Invoke-RestMethod -Headers $this.head -Uri $uri | 
      select-object -ExpandProperty data |
      Where-Object {$_.userName -match $name}
    return $data
  }

  # https://cas.teradici.com/api/docs#tag/Connectors/operation/getConnectors
  [object[]] get_connector ($name, $limit, $deploymentName) {
    $uri = "$($this.api_url)/deployments/connectors?limit=$limit"
    if ($deploymentName) { 
      $deploymentId = $this.get_deployment($deploymentName).deploymentId 
      $uri += "&deploymentId=$deploymentId"
    }
    $data = Invoke-RestMethod -Headers $this.head -Uri $uri | 
      select-object -ExpandProperty data |
      Where-Object {$_.connectorName -match $name}
    return $data
  }

  # https://cas.teradici.com/api/docs#tag/Deployments/operation/getDeployments
  [object[]] get_deployment ($name) {
    $uri = "$($this.api_url)/deployments"
    $data = Invoke-RestMethod -Headers $this.head -Uri $uri | 
      select-object -ExpandProperty data |
      Where-Object {$_.deploymentName -match $name}
    return $data
  }

  # https://cas.teradici.com/api/docs#tag/Entitlements/operation/getEntitlements
  [object[]] get_entitlement ($limit, $deploymentName, $userName, $machineName) {
    $deploymentId = $this.get_deployment($deploymentName).deploymentId
    $uri = "$($this.api_url)/deployments/$deploymentId/entitlements?limit=$limit"
    $data = Invoke-RestMethod -Headers $this.head -Uri $uri | 
      select-object -ExpandProperty data
    if ($userName) {
      $userGuid = $this.get_aduser($userName, 10000, $deploymentName).userGuid
      $data = $data | Where-Object {$_.userGuid -eq $userGuid} 
    }
    if ($machineName) {
      $data = $data | Where-Object {$_.resourceName -eq $machineName} 
    }
    return $data
  }

  # https://cas.teradici.com/api/docs#tag/Anyware-Manager-Service-Account-Keys/operation/getKeys
  [object[]] get_key () {
    $uri = "$($this.api_url)/keys"
    $data = Invoke-RestMethod -Headers $this.head -Uri $uri |
      select-object -ExpandProperty data
    return $data
  }

  # https://cas.teradici.com/api/docs#tag/Machines/operation/getMachines
  [object[]] get_machine ($name, $limit, $deploymentName, $connectorName) {
    $uri = "$($this.api_url)/machines?limit=$limit"
    if ($deploymentName) { 
      $deploymentId = $this.get_deployment($deploymentName).deploymentId 
      $uri += "&deploymentId=$deploymentId"
    }
    if ($connectorName) { 
      $connectorId = $this.get_connector($connectorName).connectorId
      $uri += "&connectorId=$connectorId"
    }
    $data = Invoke-RestMethod -Headers $this.head -Uri $uri | 
      select-object -ExpandProperty data |
      Where-Object {$_.machineName -match $name}
    return $data
  }

  # https://cas.teradici.com/api/docs#tag/Users/operation/getUsers
  [object[]] get_user ($name, $limit) {
    $uri = "$($this.api_url)/auth/users?limit=$limit"
    $data = Invoke-RestMethod -Headers $this.head -Uri $uri | 
      select-object -ExpandProperty data |
      Where-Object {$_.userName -match $name}
    return $data
  }

  # https://cas.teradici.com/api/docs#tag/Connectors/operation/createConnectorToken
  [object] new_connector_token ($connectorName, $deploymentName) {
    $deploymentId = $this.get_deployment($deploymentName).deploymentID
    $hash = @{
      connectorName = $connectorName
      deploymentId = $deploymentId
    }
    $uri = "$($this.api_url)/auth/tokens/connector"
    $data = Invoke-RestMethod -Headers $this.head -Uri $uri -Method Post -body $hash | 
      select-object -ExpandProperty data |
      select-object -ExpandProperty token
    return $data
  }

  # https://cas.teradici.com/api/docs#tag/Deployments/operation/createDeployment
  [object] new_deployment ($name, $registrationCode) {
    $uri = "$($this.api_url)/deployments"
    $hash = @{
      deploymentName = $name
      registrationCode = $registrationCode
    }
    $data = Invoke-RestMethod -Headers $this.head -Uri $uri -Method Post -body $hash | 
      select-object -ExpandProperty data
    return $data
  }

  # https://cas.teradici.com/api/docs#tag/Entitlements/operation/createEntitlement
  [object] new_entitlement ($machineName, $userName, $deploymentName) {
    $aduser = $this.get_aduser($username, 10000, $deploymentName)
    $machine = $this.get_machine($machineName, 10000, $deploymentName, '')
    $uri = "$($this.api_url)/machines/entitlements"
    $hash = @{
      deploymentId = $machine.deploymentId
      machineId = $machine.machineId
      userGuid = $adUser.userGuid
    }
    $data = Invoke-RestMethod -Headers $this.head -Uri $uri -Method Post -Body $hash | 
      select-object -ExpandProperty data
    return $data
  }

  # https://cas.teradici.com/api/docs#tag/Machines/operation/addMachine
  [object] new_machine_aws ($name, $address, $deploymentName, $connectorName, $instanceId, $region) {
    $hash = @{
      machineName = $name
      hostName = $address
      provider = 'aws'
      instanceId = $instanceId
      region = $region
    }
    if ($deploymentName) { $hash.deploymentId = $this.get_deployment($deploymentName).deploymentId }
    if ($connectorName) { $hash.connectorId = $this.get_connector($connectorName).connectorId }
    $uri = "$($this.api_url)/machines"
    $data = Invoke-RestMethod -Headers $this.head -Uri $uri -Method Post -body $hash | 
      select-object -ExpandProperty data
    return $data
  }

  [object] new_machine_azure ($name, $address, $deploymentName, $connectorName, $subscriptionId, $resourceGroup) {
    $hash = @{
      machineName = $name
      hostName = $address
      provider = 'azure'
      subscriptionId = $subscriptionId
      resourceGroup = $resourceGroup
    }
    if ($deploymentName) { $hash.deploymentId = $this.get_deployment($deploymentName).deploymentId }
    if ($connectorName) { $hash.connectorId = $this.get_connector($connectorName).connectorId }
    $uri = "$($this.api_url)/machines"
    $data = Invoke-RestMethod -Headers $this.head -Uri $uri -Method Post -body $hash | 
      select-object -ExpandProperty data
    return $data
  }

  [object] new_machine_gcp ($name, $address, $deploymentName, $connectorName, $projectId, $zone) {
    $hash = @{
      machineName = $name
      hostName = $address
      provider = 'gcp'
      projectId = $projectId
      zone = $zone
    }
    if ($deploymentName) { $hash.deploymentId = $this.get_deployment($deploymentName).deploymentId }
    if ($connectorName) { $hash.connectorId = $this.get_connector($connectorName).connectorId }
    $uri = "$($this.api_url)/machines"
    $data = Invoke-RestMethod -Headers $this.head -Uri $uri -Method Post -body $hash | 
      select-object -ExpandProperty data
    return $data
  }

  [object] new_machine_onprem ($name, $address, $deploymentName, $connectorName) {
    $hash = @{
      machineName = $name
      hostName = $address
      provider = 'onprem'
      managed = $false
    }
    if ($deploymentName) { $hash.deploymentId = $this.get_deployment($deploymentName).deploymentId }
    if ($connectorName) { $hash.connectorId = $this.get_connector($connectorName).connectorId }
    $uri = "$($this.api_url)/machines"
    $data = Invoke-RestMethod -Headers $this.head -Uri $uri -Method Post -body $hash | 
      select-object -ExpandProperty data
    return $data
  }

  # https://cas.teradici.com/api/docs#tag/Deployments/operation/deleteDeployment
  [void] remove_deployment ($id) {
    $uri = "$($this.api_url)/deployments/$id"
    Invoke-RestMethod -Headers $this.head -Uri $uri -Method Delete
  }

  # https://cas.teradici.com/api/docs#tag/Entitlements/operation/deleteEntitlement
  [void] remove_entitlement ($entitlement) {
    $uri = "$($this.api_url)/deployments/$($entitlement.deploymentId)/entitlements/$($entitlement.entitlementId)"
    Invoke-RestMethod -Headers $this.head -Uri $uri -Method Delete
  }

  # https://cas.teradici.com/api/docs#tag/Machines/operation/deleteMachine
  [void] remove_machine ($id) {
    $uri = "$($this.api_url)/machines/$id"
    Invoke-RestMethod -Headers $this.head -Uri $uri -Method Delete
  }
}

function Connect-CAS {
  param(
    $address = 'cas.teradici.com',

    [parameter(
      parameterSetName = "apiToken",
      mandatory = $true
    )]
      $apiToken,
    
    [parameter(
      parameterSetName = "serviceAccount",
      mandatory = $true
    )]
      $username,
    [parameter(
      parameterSetName = "serviceAccount",
      mandatory = $true
    )]  
      $apiKey,
    [parameter(parameterSetName = "serviceAccount")]
      $tenantId
  )
  switch ($pscmdlet.parameterSetName) {
    'apiToken' {
      $global:defaultCAS = [cas]::new($address, $apiToken)
    }
    'serviceAccount' {
      $global:defaultCAS = [cas]::new($address, $tenantId, $username, $apiKey)
    }
  }
}

function Get-CasAdComputer {
  param(
    $name = "\w",
    $limit = 10000,
    $deploymentName
  )
  $defaultCas.get_adcomputer($name, $limit, $deploymentName)
}

function Get-CasAdUser {
  param(
    $name = "\w",
    $limit = 10000,
    $deploymentName
  )
  $defaultCas.get_aduser($name, $limit, $deploymentName)
}

function Get-CasConnector {
  param(
    $name = "\w",
    $limit = 10000,
    $deploymentName
  )
  $defaultCas.get_connector($name, $limit, $deploymentName)
}

function Get-CasDeployment {
  param(
    $name = "\w"
  )
  $defaultCas.get_deployment($name)
}

function Get-CasEntitlement {
  param(
    $userName,
    $machineName,
    $deploymentName,
    $limit = 10000
  )
  $defaultCas.get_entitlement($limit, $deploymentName, $userName, $machineName)
}

function Get-CasMachine {
  param(
    $name = "\w",
    $limit = 10000,
    $deploymentName,
    $connectorName
  )
  $defaultCas.get_machine($name, $limit, $deploymentName, $connectorName)
}

function Get-CasUser {
  param(
    $name = "\w",
    $limit = 10000
  )
  $defaultCas.get_user($name, $limit)
}

function New-CasConnectorToken {
  param(
    $connectorName,
    $deploymentName
  )
  $defaultCas.new_connector_token($connectorName, $deploymentName)
}

function New-CasDeployment {
  param(
    $deploymentName,
    $registrationCode
  )
  $defaultCas.new_deployment($deploymentName, $registrationCode)
}

function New-CasEntitilement {
  param(
    $machineName,
    $userName,
    $deploymentName
  )
  $defaultCas.new_entitlement($machineName, $userName, $deploymentName)
}

function New-CasMachine {
  param (
    $machineName,
    $address,
    $deploymentName,
    $connectorName,
    
    [parameter(parameterSetName="azure")]
    [switch]
      $azure,
    [parameter(parameterSetName="azure")]
      $resourceGroup,
    [parameter(parameterSetName="azure")]
      $subscriptionId,
    
    [parameter(parameterSetName="aws")]
    [switch]
      $aws,
    [parameter(parameterSetName="aws")]
      $instanceId,
    [parameter(parameterSetName="aws")]
      $region,

    [parameter(parameterSetName="gcp")]
    [switch]
      $gcp,
    [parameter(parameterSetName="gcp")]
      $projectId,
    [parameter(parameterSetName="gcp")]
      $zone,
    
    [parameter(parameterSetName="onprem")]
    [switch]
      $onprem
  )

  switch ($pscmdlet.parameterSetName) {
    "azure" {
      $defaultCas.new_machine_azure($machineName, $address, $deploymentName, $connectorName, $subscriptionId, $resourceGroup)
    }
    "aws" {
      $defaultCas.new_machine_aws($machineName, $address, $deploymentName, $connectorName, $instanceId, $region)
    }
    "gcp" {
      $defaultCas.new_machine_gcp($machineName, $address, $deploymentName, $connectorName, $projectId, $zone)
    }
    "onprem" {
      $hash.managed = $false
    }
  }
}

function Remove-CasDeployment {
  param(
    [parameter(
      ValueFromPipeline = $true
    )]
      $deployment
  )
  begin {}
  process {
    $defaultCas.remove_deployment($deployment.$deploymentId)
  }
  end {}
}

function Remove-CasEntitlement {
  param(
    [parameter(
      ValueFromPipeline = $true
    )]
      $entitlement
  )
  begin {}
  process {
    $defaultCas.remove_entitlement($entitlement)
  }
  end {}
}

function Remove-CasMachine {
  param(
    [parameter(
      ValueFromPipeline = $true
    )]
      $machine
  )
  begin {}
  process {
    $defaultCas.remove_machine($machine.machineId)
  }
  end {}
}





