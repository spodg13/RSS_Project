Function Get-CleanTitle([string]$anyTitle)
{
    $anyTitle =$anyTitle -replace ',|\?', '' 
    $CleanList=@()
    $CleanList =@('a','an','and','as','at','for','in','into','have', 'has', 'on','of','to','the','with')
    $anyTitle=$anyTitle.ToLower()
    [System.Collections.ArrayList]$TitleArray = $anyTitle.split(' ')
       
    #Run twice as loop was not working right     
    $CleanList | %{if($_ -in $TitleArray){$TitleArray.Remove($_)} } 
    $CleanList | %{if($_ -in $TitleArray){$TitleArray.Remove($_)} } 
        
    return $TitleArray | Sort-Object -Unique 
}

Function Measure-VectorSimilarity
{ 
## VectorSimilarity by .AUTHOR Lee Holmes 
## 
[CmdletBinding()]
param(
    ## The first set of items to compare
    [Parameter(Position = 0)]
    $Set1,

    ## The second set of items to compare
    [Parameter(Position = 1)]   
    $Set2,
    
     
    [Parameter()]
    $KeyProperty,

   
    [Parameter()]
    $ValueProperty
)

## If either set is empty, there is no similarity
if((-not $Set1) -or (-not $Set2))
{
    return 0
}

## Figure out the unique set of items to be compared - either based on
## the key property (if specified), or the item value directly
$allkeys = @($Set1) + @($Set2) | Foreach-Object {
    if($PSBoundParameters.ContainsKey("KeyProperty")) { $_.$KeyProperty}
    else { $_ }
} | Sort-Object -Unique

## Figure out the values of items to be compared - either based on
## the value property (if specified), or the item value directly. Put
## these into a hashtable so that we can process them efficiently.

$set1Hash = @{}
$set2Hash = @{}
$setsToProcess = @($Set1, $Set1Hash), @($Set2, $Set2Hash)

foreach($set in $setsToProcess)
{
    $set[0] | Foreach-Object {
        if($PSBoundParameters.ContainsKey("ValueProperty")) { $value = $_.$ValueProperty }
        else { $value = 1 }
        
        if($PSBoundParameters.ContainsKey("KeyProperty")) { $_ = $_.$KeyProperty }

        $set[1][$_] = $value
    }
}

## Calculate the vector / cosine similarity of the two sets
## based on their keys and values.
$dot = 0
$mag1 = 0
$mag2 = 0

foreach($key in $allkeys)
{
    $dot += $set1Hash[$key] * $set2Hash[$key]
    $mag1 +=  ($set1Hash[$key] * $set1Hash[$key])
    $mag2 +=  ($set2Hash[$key] * $set2Hash[$key])
}

$mag1 = [Math]::Sqrt($mag1)
$mag2 = [Math]::Sqrt($mag2)

## Return the result
return [Math]::Round($dot / ($mag1 * $mag2), 3)

}

$OldTitles = Import-CSV -Path "\\dcms2ms\Privacy Audit and Logging\TestScript\DirtyLaundry.csv" `
| Where-Object {$_.PullDate -gt (Get-Date).AddDays(-3)}
##Filter by pull date


Foreach($title in $Titles) {
    $Sim = 0
    $test1 = Get-CleanTitle $title.title
    
    Foreach($other in $Titles) {
        if($other.source -ne $title.source) {
            $test2= Get-CleanTitle $other.title
            $VS= Measure-VectorSimilarity $test1 $test2
            if($VS -gt .375) {
                $Sim ++
            }
        }
    }
    #Should always have one equal- the article itself
    $title.SimTitles = $Sim-1
}

$Titles | Select-Object -Property Title, SimTitles | Format-Table
$UseT = Import-Csv -Path "A:\TestScript\DirtyLaundry.csv" | Where-Object {[datetime]$_.pubDate -gt (Get-Date).AddDays(-3) -and $_.PullDate -gt (Get-Date).AddDays(-3)}