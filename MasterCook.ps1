$MyPath = "/Users/darrylgould/Documents/MCDGRecipes.txt"
#$Pattern = '(?<=Exported from MasterCook\s\*\n\n)(?<title>[\w\S\s]+\n)(?<RecipeBody>[\w\S\s\n]+(?<=Per serving))'
$Pattern = '(MasterCook\s\*)'


$data = Get-Content -Path $MyPath -Raw
 $data  | Select-String  -Pattern $Pattern -AllMatches | Foreach-Object {$_.Matches.value}
$data.count

