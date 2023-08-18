function Get-OktaApp {
  [CmdletBinding()]
  param (
    [string]$Identity,
    [ValidateSet('Active', 'Inactive')]
    $Status,
    [ValidateRange(1,500)]
    [int]$Limit = 500,
    [switch]$All
  )
  $filter = switch ($status) {
    Active   {'status eq "ACTIVE"'}
    Inactive {'status eq "INACTIVE"'}
  }
  $query = switch ([wildcardpattern]::ContainsWildcardCharacters($identity)) {
    True  {$Identity.Replace('*','')}
    False {$Identity}
  }

  $oktaAPI              = [hashtable]::new()
  $oktaAPI.All          = $all
  $oktaAPI.Body         = [hashtable]::new()
  $oktaAPI.Body.q       = $query
  $oktaAPI.Body.limit   = $limit
  $oktaAPI.Body.filter  = $filter
  $oktaAPI.Endpoint     = 'apps'
  
  $response = Invoke-OktaAPI @oktaAPI
  if ($response) {
    if ($identity) {
      switch ([wildcardpattern]::ContainsWildcardCharacters($identity)) {
        True    {$response.where({$_.Label -like $Identity -or $_.ID -like $Identity})}
        False   {$response.where({$_.Label -eq $Identity -or $_.ID -eq $Identity})}
      }
    }
    else {
      $response
    }
  }
  else {
    $message = "Failed to retrieve Okta App $identity, verify the ID matches one of the examples:
    ID            : 0oa786gznlVSf15sC5d7
    Name          : okta_enduser
    Label         : Okta Dashboard"

    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
    [Exception]::new($message),
    'ErrorID',
    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
    'Okta'
    )
    $pscmdlet.ThrowTerminatingError($errorRecord)
  }
}