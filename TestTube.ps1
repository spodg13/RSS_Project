$myarray = @()

$mystring = 'Jonathan'
$myotherstring = 'Josephine'
. "/Users/darrylgould/Library/Mobile Documents/com~apple~CloudDocs/Coding/Rss_Project/RSS_Project/GetCharArray.ps1"
$myarray = Get-CharArray $mystring
Write-Host $myarray
$myotherarray = Get-CharArray $myotherstring
Write-Host $myotherarray