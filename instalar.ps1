# Instala a entrada "Abrir aqui no Claude Code" no menu de contexto do Explorer.
# Grava só em HKCU, por isso não pede administrador. Pode ser executado mais de uma vez.
$ErrorActionPreference = 'Stop'

$titulo  = 'Abrir aqui no Claude Code'
$destino = Join-Path $env:LOCALAPPDATA 'ClaudeCodeContextMenu'

# -w -1  : sempre uma janela nova do Windows Terminal.
# "%V."  : o ponto impede que a barra final de raízes como C:\ escape a aspa de fechamento.
# claude : roda sem shell por baixo, então a janela fecha quando você sai do Claude.
$comando = 'wt.exe -w -1 -d "%V." claude'

# O ícone e o desinstalador vão para uma pasta fixa, e a pasta baixada pode ser apagada depois.
New-Item -ItemType Directory -Force -Path $destino | Out-Null
if ((Resolve-Path -LiteralPath $PSScriptRoot).Path -ne (Resolve-Path -LiteralPath $destino).Path) {
    foreach ($arquivo in 'claude-code.ico', 'remover.ps1') {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $arquivo) -Destination $destino -Force
    }
}
$icone = Join-Path $destino 'claude-code.ico'

$chaves = 'HKCU:\Software\Classes\Directory\shell\ClaudeCode',
          'HKCU:\Software\Classes\Directory\Background\shell\ClaudeCode'
foreach ($chave in $chaves) {
    New-Item -Path "$chave\command" -Force | Out-Null
    Set-Item -LiteralPath $chave -Value $titulo
    Set-ItemProperty -LiteralPath $chave -Name 'Icon' -Value $icone
    Set-Item -LiteralPath "$chave\command" -Value $comando
}

Write-Host ''
Write-Host 'Pronto. "Abrir aqui no Claude Code" já está no menu de contexto das pastas.' -ForegroundColor Green
Write-Host 'No Windows 11, segure Shift ao clicar com o botão direito ou escolha "Mostrar mais opções".'

if (-not (Get-Command wt.exe -ErrorAction SilentlyContinue)) {
    Write-Warning 'Não encontrei o Windows Terminal. Instale pela Microsoft Store ou com: winget install Microsoft.WindowsTerminal'
}
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Warning 'Não encontrei o comando "claude". Instale o Claude Code: https://claude.com/claude-code'
}
