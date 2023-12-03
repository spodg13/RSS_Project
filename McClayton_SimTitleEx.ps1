$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

function ConvertTo-WordSets( [psobject] $Posts )
{

    # preprocess each post to break its title into word counts 
    # so we don't need to do it every time we compare 2 posts

    foreach( $post in $Posts )
    {
        $set = new-object PSCustomObject -Property ([ordered] @{
            "Post"   = $post
            "Title"  = $post.Title.Trim()
            "Words"  = $null
            "Counts" = $null
        });
        $set.Words  = $set.Title.Split(" ");
        $set.Counts = $set.Words `
            | group-object `
            | foreach-object `
                -Begin   { $counts = @{} } `
                -Process { $counts.Add($_.Name, $_.Count) } `
                -End     { $counts };
        write-output $set;
    }

}

function Get-SimTitlesMC( [psobject] $NewPosts )
{

    # instead of comparing every object to every object, just compare unique combinations
    # e.g. X compared to Y is the same as Y compared to X so score them both at the same time
    # (and we don't need to compare an object to itself either)

    for( $i = 0; $i -lt $NewPosts.Length; $i++ )
    {
        $left = $NewPosts[$i];
        for( $j = $i + 1; $j -lt $NewPosts.Length; $j++ )
        {
            $right = $NewPosts[$j];
            if ((Measure-TitleSimilarityMC $left $right) -gt .5)
            {
                $left.Post.SimTitles  = $left.Post.SimTitles + 1;
                $right.Post.SimTitles = $right.Post.SimTitles + 1;
            } 
        } 
    }

}

Function Measure-TitleSimilarityMC
{
    param
    (
        [Parameter(Position = 0)]
        $Left,
        [Parameter(Position = 1)]   
        $Right
    ) 

    # we can use the pre-processed word counts now

    $allkeys = $Left.Words + $Right.Words | Sort-Object -Unique

    $dot = 0
    $mag1 = 0
    $mag2 = 0

    foreach($key in $allkeys)
    {
        $dot  += $Left.Counts[$key] * $Right.Counts[$key]
        $mag1 += $Left.Counts[$key] * $Left.Counts[$key]
        $mag2 += $Right.Counts[$key] * $Right.Counts[$key]
    }

    $mag1 = [Math]::Sqrt($mag1)
    $mag2 = [Math]::Sqrt($mag2)

    return [Math]::Round($dot / ($mag1 * $mag2), 3)

}

# get some test data
$sentences = (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SteveMansfield/MNREAD-sentences/master/XMNREAD01.txt").Content;
$sentences = $sentences.Trim("`n").Split("`n") | foreach-object { $_.Substring(1, $_.Length - 3) };
<#
$posts = $sentences `
    | select-object -First 200 `
    | foreach-object {
        new-object PSCustomObject -Property ([ordered] @{
            "Title"     = $_
            "SimTitles" = 0
        })
    };
Measure-Command { Get-SimTitlesMC $posts; }
#>
# build some test data
$posts = $sentences `
    | select-object -First 200 `
    | foreach-object {
        new-object PSCustomObject -Property ([ordered] @{
            "Title"     = $_
            "SimTitles" = 0
        })
    };


Measure-Command {
    $wordSets = @( ConvertTo-WordSets  $myposts);
    Get-SimTitlesMC $wordSets;
}