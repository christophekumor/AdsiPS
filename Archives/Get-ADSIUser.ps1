﻿function Get-ADSIUser
{
<#
.SYNOPSIS
	This function will query Active Directory for User information. You can either specify the DisplayName, SamAccountName or DistinguishedName of the user

.PARAMETER SamAccountName
	Specify the SamAccountName of the user
	
.PARAMETER DisplayName
	Specify the DisplayName of the user
	
.PARAMETER DistinguishedName
	Specify the DistinguishedName path of the user
	
.PARAMETER Credential
    Specify the Credential to use for the query
	
.PARAMETER SizeLimit
    Specify the number of item maximum to retrieve
	
.PARAMETER DomainDistinguishedName
    Specify the Domain or Domain DN path to use
	
.PARAMETER MustChangePasswordAtNextLogon
	Find user that must change their password at the next logon
	
.EXAMPLE
	Get-ADSIUser -SamAccountName fxcat
	
.EXAMPLE
	Get-ADSIUser -DisplayName "Cat, Francois-Xavier"
	
.EXAMPLE
	Get-ADSIUser -DistinguishedName "CN=Cat\, Francois-Xavier,OU=Admins,DC=FX,DC=local"
	
.EXAMPLE
    Get-ADSIUser -SamAccountName testuser -Credential (Get-Credential -Credential Msmith)
	
.NOTES
	Francois-Xavier Cat
	LazyWinAdmin.com
	@lazywinadm
#>
	[CmdletBinding(DefaultParameterSetName = "SamAccountName")]
	PARAM (
		[Parameter(ParameterSetName = "DisplayName", Mandatory = $true)]
		[System.String]$DisplayName,
		
		[Parameter(ParameterSetName = "SamAccountName", Mandatory = $true)]
		[System.String]$SamAccountName,
		
		[Parameter(ParameterSetName = "DistinguishedName", Mandatory = $true)]
		[System.String]$DistinguishedName,
		
		[Parameter(ParameterSetName = "MustChangePasswordAtNextLogon", Mandatory = $true)]
		[System.Management.Automation.SwitchParameter]$MustChangePasswordAtNextLogon,
		
		[Parameter(ParameterSetName = "PasswordNeverExpires", Mandatory = $true)]
		[System.Management.Automation.SwitchParameter]$PasswordNeverExpires,
		
		[Parameter(ParameterSetName = "NeverLoggedOn", Mandatory = $true)]
		[System.Management.Automation.SwitchParameter]$NeverLoggedOn,
		
		[Parameter(ParameterSetName = "DialIn", Mandatory = $true)]
		[boolean]$DialIn,
		
		[Alias("RunAs")]
		[System.Management.Automation.Credential()]
		$Credential = [System.Management.Automation.PSCredential]::Empty,
		
		[Parameter()]
		[Alias("DomainDN", "Domain")]
		[System.String]$DomainDistinguishedName = $(([adsisearcher]"").Searchroot.path),
		
		[Alias("ResultLimit", "Limit")]
		[int]$SizeLimit = '100'
		
	)
	BEGIN { }
	PROCESS
	{
		TRY
		{
			# Building the basic search object with some parameters
			$Search = New-Object -TypeName System.DirectoryServices.DirectorySearcher -ErrorAction 'Stop'
			$Search.SizeLimit = $SizeLimit
			$Search.SearchRoot = $DomainDN
			
			If ($PSBoundParameters['DisplayName'])
			{
				$Search.filter = "(&(objectCategory=person)(objectClass=User)(displayname=$DisplayName))"
			}
			IF ($PSBoundParameters['SamAccountName'])
			{
				$Search.filter = "(&(objectCategory=person)(objectClass=User)(samaccountname=$SamAccountName))"
			}
			IF ($PSBoundParameters['DistinguishedName'])
			{
				$Search.filter = "(&(objectCategory=person)(objectClass=User)(distinguishedname=$distinguishedname))"
			}
			
			IF ($DomainDistinguishedName)
			{
				IF ($DomainDistinguishedName -notlike "LDAP://*") { $DomainDistinguishedName = "LDAP://$DomainDistinguishedName" }#IF
				Write-Verbose -Message "[PROCESS] Different Domain specified: $DomainDistinguishedName"
				$Search.SearchRoot = $DomainDistinguishedName
			}
			
			IF ($PSBoundParameters['Credential'])
			{
				$Cred = New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList $DomainDistinguishedName, $($Credential.UserName), $($Credential.GetNetworkCredential().password)
				$Search.SearchRoot = $Cred
			}
			
			IF ($PSBoundParameters['MustChangePasswordAtNextLogon'])
			{
				$Search.Filter = "(&(objectCategory=person)(objectClass=user)(pwdLastSet=0))"
			}
			
			IF ($PSBoundParameters['PasswordNeverExpires'])
			{
				$Search.Filter = "(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=65536))"
			}
			IF ($PSBoundParameters['NeverLoggedOn'])
			{
				$Search.Filter = "(&(objectCategory=person)(objectClass=user))(|(lastLogon=0)(!(lastLogon=*)))"
			}
			
			IF ($PSBoundParameters['DialIn'])
			{
				$Search.Filter = "(objectCategory=user)(msNPAllowDialin=$dialin)"
			}
			
			foreach ($user in $($Search.FindAll()))
			{
				
				# Define the properties
				#  The properties need to be lowercase!!!!!!!!
				$Properties = @{
					"DisplayName" = $user.properties.displayname -as [System.String]
					"SamAccountName" = $user.properties.samaccountname -as [System.String]
					"Description" = $user.properties.description -as [System.String]
					"DistinguishedName" = $user.properties.distinguishedname -as [System.String]
					"ADsPath" = $user.properties.adspath -as [System.String]
					"MemberOf" = $user.properties.memberof
					"Location" = $user.properties.l -as [System.String]
					"Country" = $user.properties.co -as [System.String]
					"PostalCode" = $user.Properties.postalcode -as [System.String]
					"Mail" = $user.properties.mail -as [System.String]
					"TelephoneNumber" = $user.properties.telephonenumber -as [System.String]
					"LastLogonTimeStamp" = $user.properties.lastlogontimestamp -as [System.String]
					"ObjectCategory" = $user.properties.objectcategory -as [System.String]
					"Manager" = $user.properties.manager -as [System.String]
					"HomeDrive" = $user.properties.homedrive -as [System.String]
					"LogonCount" = $user.properties.logoncount -as [System.String]
					"DirectReport" = $user.properties.l -as [System.String]
					"useraccountcontrol" = $user.properties.useraccountcontrol -as [System.String]
					
					<#
					lastlogoff
					codepage
					c
					department
					msexchrecipienttypedetails
					primarygroupid
					objectguid
					title
					msexchumdtmfmap
					whenchanged
					distinguishedname
					targetaddress
					homedirectory
					dscorepropagationdata
					msexchremoterecipienttype
					instancetype
					memberof
					usnchanged
					usncreated
					description
					streetaddress
					directreports
					samaccountname
					logoncount
					co
					msexchpoliciesexcluded
					userprincipalname
					countrycode
					homedrive
					manager
					samaccounttype
					showinaddressbook
					badpasswordtime
					msexchversion
					objectsid
					objectclass
					proxyaddresses
					objectcategory
					extensionattribute3
					givenname
					pwdlastset
					managedobjects
					st
					whencreated
					physicaldeliveryofficename
					legacyexchangedn
					lastlogon
					accountexpires
					useraccountcontrol
					badpwdcount
					postalcode
					displayname
					msexchrecipientdisplaytype
					sn
					mail
					lastlogontimestamp
					company
					adspath
					name
					telephonenumber
					cn
					msexchsafesendershash
					mailnickname
					l
					
					#>
				}#Properties
				
				# Output the info
				New-Object -TypeName PSObject -Property $Properties
			}#FOREACH
		}#TRY
		CATCH
		{
			Write-Warning -Message "[PROCESS] Something wrong happened!"
			Write-Warning -Message $error[0].Exception.Message
		}
	}#PROCESS
	END { Write-Verbose -Message "[END] Function Get-ADSIUser End." }
}