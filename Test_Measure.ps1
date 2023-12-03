Function Measure-TitleSimilarity
{
## Based on VectorSimilarity by .AUTHOR Lee Holmes 
## Modified slightly to match use

[CmdletBinding()]
param(
    
    [Parameter(Position = 0)]
    $Title1,

    [Parameter(Position = 1)]   
    $Title2
    
        
) 

$allkeys = @($Title1) + @($Title2) |  Sort-Object -Unique

$set1Hash = @{}
$set2Hash = @{}
$setsToProcess = @($Title1, $Set1Hash), @($Title2, $Set2Hash)

foreach($set in $setsToProcess)
{
    $set[0] | Foreach-Object {
         $value = 1 
         $set[1][$_] = $value
    }
}

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

return [Math]::Round($dot / ($mag1 * $mag2), 3)

}

Function Get-SimTitles([psobject]$NewPosts) {

    $i=0
    $end = $NewPosts.Count - 1
     
    For($i =0; $i -lt $end; $i++){
      
        $k=$i+1        
        $k..$end | Where-Object {(Measure-TitleSimilarity $NewPosts[$i].title.split(' ') $NewPosts[$_].title.split(' ')) -gt .35}  |
         & {process {$NewPosts[$_].SimTitles = $NewPosts[$_].SimTitles + 1; $NewPosts[$i].SimTitles+=1} }
         } 
                         
   }


$b = ('UPDATE: Arrest Made In SoFi Stadium Assault Of 49ers Fan Daniel Luna',
'Con radars is dreams on sinch wear',
'Daniel Luna SoFi Assault suspect arrested',
'Klay Thompson dazzles in return shooting from deep',
'Shooting guard Thompson on fire from deep',
'Brendon Gould waves goodbye to soccer crowd at Woodcreek HS',
'Seniors play their last soccer game at Woodcreek High',
'Woodcreek HS beats Yuba City 3-0 for senior night soccer game',
'Seniors have big night for Woodcreek Soccer',
'Norrin Radd has cosmic awareness',
'Woodcreek seniors defeat Yuba City in soccer game',
'Babybel maker Bel Brands USA unveiled a new plant-based cheese Tuesday',
'Bel Brands USA already offers a dairy-free version of its Boursin cheese',
'Chances are your local grocery store now carries an array of plant-based items',
'Now hungry kids may be reaching for a cheese cocooned in another color -- lime green',
'Knowing how to take a screenshot is an essential skill',
'Mac you have three ways to take a screenshot',
'Apple gives you a fair number',
'Press and release the space bar',
'your initial selection area is off',
'Hold down the Shift key',
'embrace the Floating Thumbnail',
'Human rights activists had asked athletes to boycott the Ceremony',
'Chad Johnson raises good point about outrageous Super Bowl LVI ticket prices',
'Bill Riccette',
'Cincinnati Bengals fans have been dying to see their team back in the Super Bowl for decades')
$myposts = @() 

$myposts = $b|ForEach-Object{New-Object PSCustomObject -Property ([ordered] @{
    Title = $_
    SimTitles = 0
    })
}

<#
Measure-Command{
Foreach ($title in $b){
    $myposts += [PSCustomObject]@{
        title = $title
        SimTitles = 0
    }
}}
#>

Measure-Command {
Get-SimTitles $posts

}