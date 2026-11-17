# Remove a entrada "Abrir aqui no Claude Code" do menu de contexto e os arquivos copiados na instalação.
$chaves = 'HKCU:\Software\Classes\Directory\shell\ClaudeCode',
          'HKCU:\Software\Classes\Directory\Background\shell\ClaudeCode'
foreach ($chave in $chaves) {
    if (Test-Path -LiteralPath $chave) { Remove-Item -LiteralPath $chave -Recurse -Force }
}

# Apaga só os arquivos que o instalador copiou. A pasta sai se ficar vazia.
$destino = Join-Path $env:LOCALAPPDATA 'ClaudeCodeContextMenu'
if (Test-Path -LiteralPath $destino) {
    foreach ($arquivo in 'claude-code.ico', 'remover.ps1') {
        $caminho = Join-Path $destino $arquivo
        if (Test-Path -LiteralPath $caminho) { Remove-Item -LiteralPath $caminho -Force }
    }
    if (-not (Get-ChildItem -LiteralPath $destino -Force)) {
        Remove-Item -LiteralPath $destino -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ''
Write-Host 'Removido. "Abrir aqui no Claude Code" saiu do menu de contexto.' -ForegroundColor Green
