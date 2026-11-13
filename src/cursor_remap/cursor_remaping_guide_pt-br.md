## Guia Técnico: Correção de Proporção e Mapeamento de Tamanhos para Temas XCursor no GNOME

Este documento descreve a lógica matemática e arquitetônica utilizada para resolver o problema de descompasso de escala, *hotspots* estourados e proporção visual em cursores customizados (como o tema *Layan*) quando executados em ambientes Linux modernos com GNOME e Wayland.

---

### O Problema Arquitetônico

Muitos temas de cursores legados ou independentes (como o Layan) são projetados com escalas nominais arbitrárias (ex: `24, 30, 36, 48, 96`) e proporções internas de SVG que fazem com que o cursor pareça visualmente menor do que os temas nativos do sistema (como o *Adwaita*).

Quando compilados de forma padrão, ocorrem duas falhas críticas:

1. **Descompasso no Seletor do GNOME:** O GNOME busca rigidamente a escada padrão de acessibilidade de tamanhos lógicos: **`24, 32, 48, 64, 96`**. Valores fora dessa matriz fazem o gerenciador de janelas se perder no mapeamento, exibindo cursores menores ou maiores do que o selecionado pelo usuário.
2. **Proporção Interna Pequena:** Os vetores originais possuem uma margem interna de *canvas* maior que o desenho útil. Usar uma correspondência 1:1 de pixels gera cursores miúdos na tela.

---

### A Solução: Escala Compensatória e Mapeamento Rigoroso

Para corrigir o comportamento sem perder qualidade de imagem em telas de alta densidade (HiDPI), o processo desacopla o **tamanho nominal lógico** (o que o sistema lê) da **resolução física real** (o arquivo PNG renderizado pelo Inkscape).

#### 1. A Matriz de Mapeamento (Nominal vs. Físico)

Ajusta-se o índice de tamanhos do GNOME para a escada padrão, alimentando cada degrau com uma imagem física maior (um degrau acima) para "encorpar" o cursor e compensar a proporção interna do SVG:

* **Tamanho Nominal `24**` $\rightarrow$ Aponta para a imagem física real de **`32px`** (`x1`)
* **Tamanho Nominal `32**` $\rightarrow$ Aponta para a imagem física real de **`48px`** (`x1_5`)
* **Tamanho Nominal `48**` $\rightarrow$ Aponta para a imagem física real de **`64px`** (`x2`)
* **Tamanho Nominal `64**` $\rightarrow$ Aponta para a imagem física real de **`96px`** (`x4`)
* **Tamanho Nominal `96**` $\rightarrow$ Aponta para a imagem física real máxima de **`128px`** (`x5`), garantindo nitidez absoluta em alta definição.

#### 2. Lógica de Recálculo dos *Hotspots*

Para evitar o erro clássico de "quadrados brancos" (que ocorre quando o ponto de clique — *hotspot* — ultrapassa os limites físicos da imagem) e manter o ponteiro precisamente alinhado, as coordenadas originais de clique devem ser redimensionadas de forma puramente proporcional ao fator de escala de cada camada.

Seja $(H_x, H_y)$ o *hotspot* original da base de referência (32px):

* Para a camada de **48px** ($1.5\times$):

$$H_{x32} = \text{int}(H_x \times 1.5), \quad H_{y32} = \text{int}(H_y \times 1.5)$$


* Para a camada de **64px** ($2.0\times$):

$$H_{x64} = \text{int}(H_x \times 2.0), \quad H_{y64} = \text{int}(H_y \times 2.0)$$


* Para a camada de **96px** ($3.0\times$):

$$H_{x96} = \text{int}(H_x \times 3.0), \quad H_{y96} = \text{int}(H_y \times 3.0)$$


* Para a camada mestre de **128px** ($4.0\times$):

$$H_{x128} = \text{int}(H_x \times 4.0), \quad H_{y128} = \text{int}(H_y \times 4.0)$$



---

### Preparação do Script de Ajuste (Instruções para Automação Futura)

Qualquer script voltado para automatizar essa correção em arquivos `.cursor` deve seguir esta ordem lógica de execução:

1. **Varredura Estrutural:** Localizar todos os arquivos de configuração de cursor (extensão `.cursor`) no diretório de origem.
2. **Extração de Referência:** Ler o arquivo e identificar o *hotspot* base (`H_x`, `H_y`) da menor resolução declarada.
3. **Reescrita Geométrica:** Substituir o conteúdo de cada arquivo `.cursor` por uma estrutura limpa contendo exatamente os 5 tamanhos lógicos do GNOME (`24, 32, 48, 64, 96`), associando cada um deles à respectiva pasta de imagens físicas (`x1`, `x1_5`, `x2`, `x4`, `x5`) e aplicando as multiplicações proporcionais correspondentes nos eixos X e Y.
4. **Declaração do Índice:** Garantir que o arquivo `index.theme` do tema declare explicitamente a linha de tamanhos suportados:
```ini
Size=24
Sizes=24,32,48,64,96

```
