Import-Module PSTwitterAPI

$OAuthSettings = @{
  ApiKey = $env:TwAPIKey
  ApiSecret = $env:TwAPISecret
  AccessToken = $env:TwAccessToken
  AccessTokenSecret =$env:TwAccessTokenSecret
}
Set-TwitterOAuthSettings @OAuthSettings