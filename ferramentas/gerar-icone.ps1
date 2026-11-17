# Desenha o ícone do atalho (claude-code.ico): o mascote do Claude Code em pixel art, de 16 a 256 px.
# Uso: ferramentas\gerar-icone.ps1 [-Destino pasta] [-Previa]
#   -Previa grava também um PNG com os tamanhos pequenos ampliados, sobre fundo claro e escuro.
param(
    [string]$Destino = (Split-Path $PSScriptRoot -Parent),
    [switch]$Previa
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

# Grade de 18 x 10. X = corpo, E = olho, ponto = transparente.
$grade = @(
    '...XXXXXXXXXXXX...',
    '...XXXXXXXXXXXX...',
    '...XXEXXXXXXEXX...',
    '...XXEXXXXXXEXX...',
    '.XXXXXXXXXXXXXXXX.',
    '.XXXXXXXXXXXXXXXX.',
    '...XXXXXXXXXXXX...',
    '...XXXXXXXXXXXX...',
    '....X.X....X.X....',
    '....X.X....X.X....'
)
$colunas = 18
$linhas = 10
$colunasUsadas = 16   # só as colunas 1 a 16 têm desenho

$corCorpo = [System.Drawing.Color]::FromArgb(255, 217, 119, 87)
$corOlho  = [System.Drawing.Color]::FromArgb(255, 38, 30, 26)

function New-Mascote([int]$lado) {
    $u = [Math]::Max(1, [Math]::Floor($lado / $colunasUsadas))
    $ox = [Math]::Floor(($lado - $colunasUsadas * $u) / 2) - $u   # desconta a coluna 0, que é vazia
    $oy = [Math]::Floor(($lado - $linhas * $u) / 2)

    $bmp = New-Object System.Drawing.Bitmap($lado, $lado, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::Transparent)
    $pCorpo = New-Object System.Drawing.SolidBrush($corCorpo)
    $pOlho = New-Object System.Drawing.SolidBrush($corOlho)
    for ($r = 0; $r -lt $linhas; $r++) {
        for ($c = 0; $c -lt $colunas; $c++) {
            $ch = $grade[$r][$c]
            if ($ch -eq '.') { continue }
            $pincel = if ($ch -eq 'E') { $pOlho } else { $pCorpo }
            $g.FillRectangle($pincel, $ox + $c * $u, $oy + $r * $u, $u, $u)
        }
    }
    $g.Dispose(); $pCorpo.Dispose(); $pOlho.Dispose()
    return $bmp
}

function Get-BytesPng([System.Drawing.Bitmap]$bmp) {
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    return $ms.ToArray()
}

# Entrada do .ico em DIB de 32 bits, que qualquer leitor aceita. Usada nos tamanhos abaixo de 256.
function Get-BytesDib([System.Drawing.Bitmap]$bmp) {
    $s = $bmp.Width
    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)
    $bw.Write([int]40); $bw.Write([int]$s); $bw.Write([int]($s * 2))
    $bw.Write([int16]1); $bw.Write([int16]32); $bw.Write([int]0)
    $bw.Write([int]0); $bw.Write([int]0); $bw.Write([int]0); $bw.Write([int]0); $bw.Write([int]0)
    for ($y = $s - 1; $y -ge 0; $y--) {
        for ($x = 0; $x -lt $s; $x++) {
            $p = $bmp.GetPixel($x, $y)
            $bw.Write([byte]$p.B); $bw.Write([byte]$p.G); $bw.Write([byte]$p.R); $bw.Write([byte]$p.A)
        }
    }
    $bytesPorLinha = [int]([Math]::Ceiling($s / 32.0) * 4)
    for ($y = $s - 1; $y -ge 0; $y--) {
        $mascara = New-Object byte[] $bytesPorLinha
        for ($x = 0; $x -lt $s; $x++) {
            if ($bmp.GetPixel($x, $y).A -eq 0) {
                $i = [Math]::Floor($x / 8)
                $mascara[$i] = $mascara[$i] -bor (0x80 -shr ($x % 8))
            }
        }
        $bw.Write($mascara)
    }
    $bw.Flush()
    return $ms.ToArray()
}

New-Item -ItemType Directory -Force $Destino | Out-Null
$entradas = @()
foreach ($lado in 16, 20, 24, 32, 40, 48, 64, 256) {
    $bmp = New-Mascote $lado
    [byte[]]$dados = if ($lado -ge 256) { Get-BytesPng $bmp } else { Get-BytesDib $bmp }
    $entradas += [pscustomobject]@{ Lado = $lado; Dados = $dados }
    $bmp.Dispose()
}

$ico = Join-Path $Destino 'claude-code.ico'
$fs = [System.IO.File]::Create($ico)
$w = New-Object System.IO.BinaryWriter($fs)
$w.Write([int16]0); $w.Write([int16]1); $w.Write([int16]$entradas.Count)
$posicao = 6 + 16 * $entradas.Count
foreach ($e in $entradas) {
    $dim = if ($e.Lado -ge 256) { 0 } else { $e.Lado }
    $w.Write([byte]$dim); $w.Write([byte]$dim); $w.Write([byte]0); $w.Write([byte]0)
    $w.Write([int16]1); $w.Write([int16]32)
    $w.Write([int]$e.Dados.Length); $w.Write([int]$posicao)
    $posicao += $e.Dados.Length
}
foreach ($e in $entradas) { $w.Write([byte[]]$e.Dados, 0, $e.Dados.Length) }
$w.Flush(); $fs.Close()

if ($Previa) {
    $folha = New-Object System.Drawing.Bitmap(560, 300, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($folha)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $claro = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 243, 243, 243))
    $escuro = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 44, 44, 44))
    $g.FillRectangle($claro, 0, 0, 560, 150)
    $g.FillRectangle($escuro, 0, 150, 560, 150)
    $x = 20
    foreach ($lado in 16, 24, 32, 48) {
        $bmp = New-Mascote $lado
        $escala = [Math]::Floor(110 / $lado)
        foreach ($y in 20, 170) { $g.DrawImage($bmp, $x, $y, $lado * $escala, $lado * $escala) }
        $x += $lado * $escala + 25
        $bmp.Dispose()
    }
    $g.Dispose(); $claro.Dispose(); $escuro.Dispose()
    $folha.Save((Join-Path $Destino 'claude-code-previa.png'), [System.Drawing.Imaging.ImageFormat]::Png)
    $folha.Dispose()
}

$arq = Get-Item $ico
'{0}: {1} tamanhos, {2:N0} KB' -f $arq.Name, $entradas.Count, ($arq.Length / 1KB)
