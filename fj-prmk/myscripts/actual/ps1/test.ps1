$word="Windows".ToCharArray()

foreach ($letter in $word)
{
$current=Get-Process -name $letter*|Select-Object -First 1
$current.name

}


