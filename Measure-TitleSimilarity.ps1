Function Measure-TitleSimilarity
{
## Based on VectorSimilarity by .AUTHOR Lee Holmes 
## Modified slightly to match use
##


[CmdletBinding()]
param(
    ## The first set of items to compare
    [Parameter(Position = 0)]
    $Title1,

    ## The second set of items to compare
    [Parameter(Position = 1)]   
    $Title2,
    
     
    [Parameter()]
    $KeyProperty,

   
    [Parameter()]
    $ValueProperty
) 

. 'I:\RSS_Project\Get-CleanTitle.ps1'




## If either set is empty, there is no similarity
if((-not $Title1) -or (-not $Title2))
{
    return 0
}

$Set1=@()
$Set2=@()
$Set1 =  $Title1
$Set2 =  $Title2


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

#$stopwatch
## Return the result
return [Math]::Round($dot / ($mag1 * $mag2), 3)

}

$b='UPDATE: Arrest Made In SoFi Stadium Assault Of 49ers Fan Daniel Luna'
$c='Daniel Luna SoFi Assault suspect arrested'


Measure-TitleSimilarity $b.split(' ') $c.split(' ')
