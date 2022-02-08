Function Get-SimTitles ([psobject]$anyPosts)
{
## Future state
##. 'I:\RSS_Project\Measure-TitleSimilarity.ps1'

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

Function Get-CleanTitle([string]$anyTitle)
{
    $anyTitle =$anyTitle -replace ',|\?', '' 
    $CleanList =@('a','an','and','as','at','for','in','into','have', 'has', 'on','of','to','the','with')
    $anyTitle=$anyTitle.ToLower()
    [System.Collections.ArrayList]$TitleArray = $anyTitle.split(' ')
       
    #Run twice as loop was not working right     
    $CleanList | %{if($_ -in $TitleArray){$TitleArray.Remove($_)} } 
    $CleanList | %{if($_ -in $TitleArray){$TitleArray.Remove($_)} } 
        
    return $TitleArray | Sort-Object -Unique 
}


## If either set is empty, there is no similarity
if((-not $Title1) -or (-not $Title2))
{
    return 0
}

$Set1=@()
$Set2=@()
$Set1 = $Title1
$Set2 = $Title2

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

$i=0
$b=@()

$b=$anyPosts

Foreach($post in $anyPosts) {
    
    $i++
    $post.title
    if($i%10 -eq 0) {write-host $i ' of ' $anyPosts.Count}
    
    $b | Where-Object {$_.source -ne $post.source} | & {
        process {
            if((Measure-TitleSimilarity $_.title.split(' ') $post.title.Split(' ')) -gt .275) {
                $_.SimTitles =$_.SimTitles +1
            }
        }
        
    }
}
    
return $b
}
Get-SimTitles $NewPosts
