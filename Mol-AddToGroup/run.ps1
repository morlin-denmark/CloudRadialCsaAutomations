using namespace System.Net
using namespace Microsoft.Azure.Functions.Worker.Http
using namespace Microsoft.Extensions.Logging

param (
    $Request,
    $TriggerMetadata
)

function Get-RequestBody {
    param ($Request)
    $input = [System.IO.StreamReader]::new($Request.Body)
    $json = $input.ReadToEnd()
    $input.Close()
    return $json | ConvertFrom-Json
}

function Add-UserToGroup {
    param (
        [string]$UserEmail,
        [string]$GroupName
    )

    try {
        $user = Get-AzureADUser -Filter "userPrincipalName eq '$UserEmail'"
        if (-not $user) {
            throw "User not found: $UserEmail"
        }

        $group = Get-AzureADGroup -Filter "displayName eq '$GroupName'"
        if (-not $group) {
            throw "Group not found: $GroupName"
        }

        Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId $user.ObjectId
        return "User $UserEmail added to group $GroupName successfully."
    } catch {
        return "Error: $_"
    }
}

# Main script execution
$requestBody = Get-RequestBody -Request $Request
$UserEmail = $requestBody.UserEmail
$GroupName = $requestBody.GroupName

if (-not $UserEmail -or -not $GroupName) {
    $response = @{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = "Invalid input"
    }
} else {
    $result = Add-UserToGroup -UserEmail $UserEmail -GroupName $GroupName
    $response = @{
        StatusCode = [HttpStatusCode]::OK
        Body = $result
    }
}

# Return HTTP response
$Response = [HttpResponseData]::new($TriggerMetadata.FunctionContext)
$Response.StatusCode = $response.StatusCode
$Response.WriteString($response.Body)
$Response
