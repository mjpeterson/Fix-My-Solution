param([Parameter(Mandatory=$true)][string]$sln, [Parameter(Mandatory=$false)][string]$StripFolderPath)

$ErrorActionPreference = "silentlycontinue"

## this is the tool for parsing the solution
Add-Type -Path .\SolutionParser.dll

## this is the tool for parsing each project
Add-Type -AssemblyName Microsoft.Build.Engine

$sp = new-object Matt.Solution((gci $sln).FullName)
$slnPath = (gci $sln).DirectoryName;

[string[]]$refs = "";

## Get all the project directories.
write-host "`nProject file directories" -ForegroundColor Red
$projects = $sp.Projects | %{ Join-Path -Path $slnPath -ChildPath $_.RelativePath -resolve } | gci | %{ $_.DirectoryName} | sort-object -unique
$projects

## Get all the specific DLL references within the .sln's projects.
write-host "`n`nProject DLL references" -ForegroundColor Red
foreach($p in $sp.Projects)
{        

    $fullPath = Join-Path -Path $slnPath -ChildPath $p.RelativePath;
            
    $project = new-object Microsoft.Build.BuildEngine.Project;
    $project.Load($fullPath);
    
    foreach($i in $project.ItemGroups)
    {
        if($i.Name -eq "Reference")
        {            
            if($i.GetMetadata("HintPath").length -gt 0)
            {
                $refs += $i.GetMetadata("HintPath") | ?{ $_.length -gt 0} | %{ join-path -path (gci $project.FullFileName).DirectoryName -childpath $_ -resolve};
            }
        }
    }    
}

$refs | Sort-Object -unique


if($StripFolderPath.Length -gt 0)
{
    write-host -BackgroundColor Red "-- Build Project References ---`n`n`n"
    foreach($p in $projects)
    {        
        write-host " $/Source/Dev$($p.ToString().Replace($StripFolderPath, '').Replace('\','/')): `$(SourceDir)\Source\Dev$($p.ToString().Replace($StripFolderPath, ''))"
    }

    write-host -BackgroundColor Red "`n`n`n-- Build DLL References ---`n`n`n"
    foreach($r in $refs | sort-object -Unique)
    {        
        write-host " $/Source/Dev$($r.ToString().Replace($StripFolderPath, '').Replace('\','/')): `$(SourceDir)\Source\Dev$($r.ToString().Replace($StripFolderPath, ''))"
    }
}
