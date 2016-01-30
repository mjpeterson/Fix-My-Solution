function GetChildReferences($proj_path){

    [string[]]$refs = $null

    $project = new-object Microsoft.Build.BuildEngine.Project;
    $project.Load($proj_path);
    $project_parent_dir = split-path -path $proj_path -Parent
    
    foreach($i in $project.ItemGroups)
    {
        if($i.Name -eq "ProjectReference")
        {               
            $refs += $i.FinalItemSpec | ?{ $_ -like "*.csproj" } | %{ join-path -path $project_parent_dir -childpath $_ -resolve } | ?{ $_.Length -gt 0 } | sort -Unique
             
            foreach($r in $refs)
            {
                $thisProjectName = Split-Path -Path $r -Leaf
                if($proj_refs.ContainsKey($thisProjectName) -eq $false)
                {                    
                    $proj_refs[$thisProjectName] = $r
                    GetChildReferences($r)
                }
            }
        }
    }
}

$sln = $dte.Solution.FileName
#$ErrorActionPreference = "silentlycontinue"

$executingScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

## this is the tool for parsing the solution
$solution_parser = join-path -path $executingScriptDirectory -childpath ".\SolutionParser.dll"
Add-Type -Path $solution_parser

## this is the tool for parsing each project
Add-Type -AssemblyName Microsoft.Build.Engine

$sp = new-object Matt.Solution((gci $sln).FullName)
$slnPath = (gci $sln).DirectoryName;

$sln_refs = @{};  ### these are the projects that are already in the solution.
$proj_refs = @{}; ### these are the projects that are found as references within the projects.

foreach($p in $sp.Projects)
{
    $fullPath = Join-Path -Path $slnPath -ChildPath $p.RelativePath -Resolve
    $projectName = Split-Path $fullPath -Leaf
    $sln_refs[$projectName] = $fullPath
            
    GetChildReferences($fullPath)
}

[string[]]$refs_added = $null
foreach($pfk in $proj_refs.Keys)
{
    if($sln_refs.ContainsKey($pfk) -eq $false)
    {        
        $refs_added += $pfk
        $dte.Solution.AddFromFile($proj_refs[$pfk])
    }
}

write-host "`n`n`n--- Projects added ---" -ForegroundColor White -BackgroundColor DarkGreen
$refs_added
write-host "`n`n...Saving solution file..." -ForegroundColor White -BackgroundColor DarkGreen

#$dte.Solution.SaveAs($sln) ### save your solution from within VS instead.
