Function Get-InitialTitles ($anyarray)
{       
    ## Put all of the titles into an giant word array
    $titlestring = $b -join ' '
    ##$titlestring = $anyposts.title -join ' '
    $titlestring = $titlestring.split(' ')

    $CleanList =@('a','an','and','as','at','for','from','in','into','is','have', 'has', 'on','of','to','the','with')
    $ti = 0
    $indexarray = [System.Collections.ArrayList]::new()
    
    foreach($title in $b){

        ##remove common punctuation
        $title = $title -replace ',|\?|:|\.', ''
        $newtitle=@()
        $newtitle=$title.Split(' ')
        $i=0
        $k=0
        $total = 0
        foreach($word in $newtitle){

            $count=$titlestring|Where-Object{$_ -match $word -and $word -notin $CleanList}|Measure-Object|Select-Object -ExpandProperty Count
            if($count -gt 0) { $k++}
            if($count-gt 1) {
                $i++
                $total += $count}
            Write-Host 'Word count: ' $count    
        }
        $title
        Write-Host 'Index ' $ti
        Write-Host 'Title - frequent total: '  $total ' Instances +2: ' $i ' Title Key Words: ' $k 
        if($i -gt 0){$avg = $total/$i}else{$avg=0}
        $hit_ratio = $i/$k
        Write-Host 'Hit ratio: ' $hit_ratio ' Average hit: ' $avg
        ## if hit_ratio is above .3 (Matching on roughly 3/10 words) or hit $avg above 2 (Some word is triggering)
        ## Capture index number for a scientific check
        if($hit_ratio -ge .25 ) {
           [void]$indexarray.Add($ti)
        }
        $ti ++
    }
    write-host 'Indexes: ' $indexarray 'count ' $indexarray.count
    return $indexarray
}

## test data
$b = @()
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
$Titles_to_check=@()
$Titles_to_check = Get-InitialTitles $b