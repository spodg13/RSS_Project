Function Get-InitialTitles ($anyposts)
{       
    ## Put all of the titles into an giant word array
    ##$titlestring = $b -join ' '
    $titlestring = $anyposts.title -join ' '
    $titlestring = $titlestring.split(' ')

    $CleanList =@('a','an','and','as','at','for','from','in','into','is','have', 'has', 'on','of','to','the','with')
    $ti = 0
    Measure-Command {
    $indexarray = [System.Collections.ArrayList]::new()
    
    foreach($title in $anyposts.title){

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
            #Write-Host 'Word count: ' $count    
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
           [void]$indexarray.Add($ti, $avg)
        }
        
        $ti ++
    }
    write-host 'Indexes: ' $indexarray 'count ' $indexarray.count
    }
    return $indexarray
}

