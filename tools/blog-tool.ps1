# PowerShell helper for Hexo workflow
param(
  [ValidateSet("preview", "deploy")]
  [string]$Action
)

if (-not $Action) {
  Write-Host "Usage: powershell -ExecutionPolicy Bypass -File tools/blog-tool.ps1 -Action <preview|deploy>"
  exit 1
}

$repoRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
$repoRoot = Split-Path $repoRoot -Parent
Set-Location $repoRoot

function Invoke-Step {
  param(
    [string[]]$Command,
    [string]$Message
  )

  Write-Host "`n==> $Message" -ForegroundColor Cyan
  $cmd = $Command[0]
  $cmdArgs = @()
  if ($Command.Length -gt 1) {
    $cmdArgs = $Command[1..($Command.Length - 1)]
  }
  & $cmd @cmdArgs
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed: $($Command -join ' ')"
  }
}

switch ($Action) {
  "preview" {
    Invoke-Step @("npx", "hexo", "clean") "Hexo clean"
    Invoke-Step @("npx", "hexo", "generate") "Hexo generate"
    Invoke-Step @("npx", "hexo", "server") "Hexo server (Ctrl+C to stop)"
  }
  "deploy" {
    Invoke-Step @("npx", "hexo", "clean") "Hexo clean"
    Invoke-Step @("npx", "hexo", "generate") "Hexo generate"
    Invoke-Step @("npx", "hexo", "deploy") "Hexo deploy"

    $status = git status --short
    if ([string]::IsNullOrWhiteSpace($status)) {
      Write-Host "No git changes to commit." -ForegroundColor Yellow
    } else {
      git add .
      $message = Read-Host "Commit message"
      if ([string]::IsNullOrWhiteSpace($message)) {
        $message = "update blog"
      }
      git commit -m $message
      $sshRemote = "git@github.com:djdgctw/djdgctw.github.io.git"
      git remote set-url origin $sshRemote
      git branch -M main
      git push origin main
    }
  }
}
