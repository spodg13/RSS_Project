Function Get-CharCount($anyword)
{
    $anyword =$anyword.ToLower()
    $CharArray = $anyword.ToCharArray()
    $CharArray |  Group-Object |ForEach-Object { $CharCount = @{} } { $CharCount[$_.Name] = $_.Count } 
    return $CharCount
}
Function Get-UniqueChar($anyword)
{
    $anyword =$anyword.ToLower()
    $CharArray = $anyword.ToCharArray()
    $UniqueChar = $CharArray | Sort-Object -Unique

    return $UniqueChar
}
Function Get-VectorLength ($anyobject)
{
    
    foreach ($value in $anyobject){
        $Sum += $value*$value
    }
    $Vl = [math]::Sqrt($Sum)
    return $Vl
}  c
Function Get-Intersection ($w1, $w2)
{   
    $comp=@()
    $comp=  Compare-Object $w1 $w2 -PassThru -IncludeEqual -ExcludeDifferent # intersection
    write-host $comp
    return $comp
}    

$cw=Get-CharCount 'address'
$sw=Get-UniqueChar 'address'
$lw=Get-VectorLength $cw.Values

$cw | Format-Table
$sw 
$lw
$w1 =('The','quick','brown','Fox','jumped','across','andes', 'Mountains', 'tall','building') 
$w2=('rusty','fox','jumping','andes','mountains','building','north')
$Int = Get-Intersection $w1 $w2
$Int
Measure-VectorSimilarity.ps1 $w1 $w2 -keyProperty Name -ValueProperty length