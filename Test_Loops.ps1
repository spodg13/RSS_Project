Function Get-Iterations($anyposts)
{
    $end =$anyposts.count -1 
    write-host $end 
    
    for ($num = 1 ; $num -le 10 ; $num++){    "I count $num"}
 
        $i=0
        Measure-Command{
        For($i=0; $i -le $end-1; $i++)  {
        $k=$i + 1
           
                ($k..$end) | Select-Object {$anyposts[$_], $anyposts[$i]}| Out-host 
        }
         write-host 'Forhhhh Loop'   
    } | Select-Object -Property TotalMilliseconds| Out-host

    $i=0
    $k=0
    Measure-command {
    Foreach ($post in $anyposts) {
        $k=$i+1
        ($k..$end) | Select-Object {$anyposts[$_], $anyposts[$i]}| Out-host 
        $i++
        #if($i -eq $end){break}
    }
    write-host 'Foreach Loop'
} | Select-Object -Property TotalMilliseconds| Out-host

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

Get-Iterations $b
