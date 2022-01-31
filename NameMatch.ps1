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
}  
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

$Int = Get-Intersection ('The','quick','brown','fox','jumped','across','andes', 'Mountains', 'tall','building') ('rusty','fox','jumping','andes','mountains','building','north')
$Int