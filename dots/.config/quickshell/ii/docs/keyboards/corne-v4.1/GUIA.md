# Corne — guia por número de layer

Conferido com o teclado em **07/09/2026**. As letras citadas indicam sempre a posição física na **layer 0**, a de digitação normal.

**“layer 1 + A” significa: segure o acesso à layer 1 e toque A.** Para as outras layers, use o acesso da tabela abaixo. `+` significa manter pressionado; “depois” indica a ordem de pressionamento.

## Polegares e acesso às layers

Olhando o teclado de frente, da esquerda para a direita:

| Mão | Polegar da esquerda | Polegar central | Polegar da direita |
|---|---|---|---|
| Esquerda | **layer 1** | **Espaço** | **Super** |
| Direita | **Enter** | **Shift** | **layer 2** |

| Layer | Função | Como acessar |
|---|---|---|
| **0** | Digitação normal | Solte os acessos momentâneos; na layer 5, use a tecla de saída |
| **1** | Setas e navegação | Segure o polegar esquerdo marcado **layer 1** |
| **2** | Acentos | Segure o polegar direito marcado **layer 2** |
| **3** | Números, Fs e controles | Segure os dois polegares marcados **layer 1 + layer 2** |
| **4** | Símbolos | Double tap no **Shift direito da layer 0**, breve pausa e uma tecla de símbolo |
| **5** | Jogos FPS | **Layer 1 + G**, depois solte ambas; para sair, toque o polegar que acessa **layer 2** na layer 0 |

Os nomes dos polegares nessa tabela são suas funções na layer 0. Dentro de outra layer, o Vial pode mostrar uma função diferente na mesma posição: por exemplo, segurando layer 1, o polegar direito passa a mostrar `MO(3)`.

No acesso momentâneo à layer 3, solte **as duas teclas usadas para entrar**. A layer 4 pelo double tap termina após uma tecla de símbolo. A **layer 5 permanece ativa** até você usar sua tecla de saída.

O acesso à layer 2, Espaço, Super, Enter e as letras da layer 0 são imediatos. O acesso à layer 1 usa seu TD(4), com 180 ms; segure essa tecla para acessar a layer 1. O polegar direito central usa Shift TD(2) na layer 0, **Super na layer 1** e Shift comum nas layers 2–5. O Shift esquerdo é sempre comum.

## Layer 1 — setas e edição

Segure **layer 1**. Q/E ajustam o split ratio; a seta ↑ esquerda fica em W:

```text
 W ↑                         I ↑
 S ←  D ↓  F →          J ←  K ↓  L →
```

**Ctrl, Shift esquerdo e Alt usam suas posições da layer 0. O polegar direito central vira Super nesta layer.** A posição de Tab também envia Shift, conforme seu ajuste manual; os polegares esquerdos de Espaço e Super ficam desativados. Neste guia, “seta” significa uma das posições do desenho acima.

| Ação | Combinação |
|---|---|
| Mover o cursor | layer 1 + seta |
| Pular palavras | layer 1 + Ctrl + ←/→ |
| Selecionar texto | layer 1 + Shift esquerdo + seta |
| Selecionar palavras | layer 1 + Ctrl + Shift esquerdo + ←/→ |
| Alt + seta | layer 1 + Alt + seta |
| Home / End | layer 1 + U / O |
| Page Up / Page Down | layer 1 + Y / H |

U/O ficam acima das setas esquerda/direita; Y/H formam um par vertical. Para seleção, use o Shift esquerdo; o polegar esquerdo sustenta a layer 1. O efeito de Alt + seta depende do aplicativo.

Estas ações usam as teclas nas posições habituais:

| Ação | Combinação |
|---|---|
| Ctrl + Backspace | Ctrl + Backspace, na layer 0 |
| Alt + Backspace | Alt + Backspace, na layer 0 |
| Shift + Enter | **layer 1 + Enter** |
| Delete | **layer 4 + Backspace** |

Seus controles extras na layer 1: à esquerda, rolagem para cima/baixo; à direita, colar/copiar. Z envia Undo (desfazer), cujo suporte depende do aplicativo.

## Layer 2 — acentos

**Segure layer 2 e toque a tecla desejada uma vez. Todos os acentos são imediatos.**

| Família | Agudo na própria letra | Til à direita | Circunflexo na vizinha vertical |
|---|---|---|---|
| A | **A → á** | **S → ã** | **Q → â**, acima de A |
| E | **E → é** | — | **D → ê**, abaixo de E |
| O | **O → ó** | **P → õ** | **L → ô**, abaixo de O |

| Combinação | Caractere |
|---|---|
| **layer 2 + Z**, abaixo de A | **à** |
| layer 2 + I | í |
| layer 2 + U | ú |
| layer 2 + C | ç |

Q → â e Z → à mantêm a troca que você fez no Vial. Na layer 2, dois toques apenas repetem o mesmo caractere; não há Tap Dance nem distinção entre toque e hold para os acentos.

**Maiúsculas:** segure layer 2, depois Shift esquerdo, e toque o acento desejado. Exemplo: **layer 2 + Shift + Q → Â**.

As quatro extras desta layer seguem seu ajuste manual: **esquerda superior/anterior, esquerda inferior/parar, direita superior/próxima, direita inferior/reproduzir ou pausar** a mídia.

## Hyprland e workspaces

Para comandos com setas, **segure layer 1 primeiro e depois o polegar direito central**, que passa de Shift para **Super**. Nesta tabela, **Super** é esse polegar: você usa uma tecla por polegar e mantém os outros dedos livres para as setas. Ctrl, Alt e Shift esquerdo mantêm suas posições habituais.

| Ação configurada | Combinação |
|---|---|
| Diminuir split ratio | **layer 1 + Q** |
| Aumentar split ratio | **layer 1 + E** |
| Focar janela na direção | layer 1 + Super + seta |
| Mover janela na direção | layer 1 + Super + Shift esquerdo + seta |
| Usar o tiling assistant | layer 1 + Super + Alt + seta |
| Trocar grupo de workspaces | layer 1 + Super + Ctrl + ↑/↓ |

Q/E ajustam a divisão em passos de **0,1**; segurar repete o ajuste. É a proporção do divisor no dwindle: o efeito sobre o tamanho da janela focada depende do lado onde ela está. Uma janela flutuante ou sozinha não tem essa divisão para ajustar.

Para trocar workspaces individualmente, use as **duas teclas extras inferiores dos indicadores na layer 0**:

| Ação | Combinação |
|---|---|
| Workspace anterior/próximo | Extra inferior esquerda/direita |
| Mover janela ao workspace anterior/próximo | Shift + extra inferior esquerda/direita |
| Workspace ocupado anterior/próximo no monitor | Alt + extra inferior esquerda/direita |

As teclas extras já enviam Ctrl + Super + esquerda/direita. Os atalhos que usam letras, como Super + Shift + S, continuam na layer 0 com as teclas habituais.

## Layer 3 — números, mídia e iluminação

**Acesso: segure os polegares layer 1 + layer 2.**

```text
 F1  F2 F3 F4 F5 F6       F7 F8 F9 F10 F11 F12
     1  2  3  4  5        6  7  8  9   0
```

Os números ficam na fileira central: A/S/D/F/G = 1/2/3/4/5; H/J/K/L/`;` = 6/7/8/9/0. F1–F12 ocupam a fileira superior, incluindo Tab e Backspace nas pontas.

As quatro teclas extras dos indicadores concentram os controles:

| Com layer 3 ativa | Esquerda superior | Esquerda inferior | Direita superior | Direita inferior |
|---|---|---|---|---|
| Sem modificador | Volume + | Volume − | Brilho da tela + | Brilho da tela − |
| Com Shift esquerdo | Faixa anterior | Próxima faixa | Play/pause | Mute |

| Iluminação | Combinação |
|---|---|
| Backlight do computador | layer 3 + B |
| Ligar/desligar RGB do Corne | layer 3 + N |
| Mudar efeito RGB | layer 3 + M |
| Diminuir/aumentar brilho RGB | layer 3 + vírgula/ponto |
| Mudar cor RGB | layer 3 + `/` |

As variantes avançadas dos quatro controles estão na referência de Key Overrides ao final.

## Layer 4 — símbolos

**Acesso: dê double tap no Shift direito da layer 0, solte, faça uma breve pausa e toque o símbolo.** A layer 4 vale para uma tecla e depois retorna à digitação normal. Os símbolos já incluem os modificadores necessários: não acrescente Shift.

O Tap Dance está em **220 ms**, conforme seu ajuste no Vial. Se a próxima tecla interromper o reconhecimento cedo demais, o gesto pode ser interpretado como dois toques de Shift. Exemplo: double tap, pausa, D → `(`.

| Teclas físicas, com layer 4 ativa | Resultado, na mesma ordem |
|---|---|
| A · S · D · F · G | `[` · `{` · `(` · `)` · `]` |
| J · K · L · `;` · tecla de aspas | `}` · `=` · `+` · `-` · `_` |
| Q · W · E · R · T | `!` · `@` · `#` · `$` · `%` |
| Y · U · I | `^` · `&` · `*` |
| Z · X · C · V · B | acento grave literal · `~` · `°` · `\` · `\|` |
| N · M · vírgula · ponto · `/` | `"` · `'` · `<` · `>` · `?` |
| Extras esquerdas, superior/inferior | `;` · `:` |
| Extras direitas, superior/inferior | `º` · `ª` |

Exemplo: **layer 4 + D → `(`**. `º` é o ordinal, como em 1º; `°` é o símbolo de graus. Os acentos desta layer são literais: `~` e `^` não aguardam uma vogal.

## Layer 5 — jogos FPS

**Entrar: layer 1 + G**, de *game*. Depois solte ambas: a layer 5 continua ativa. **Sair: toque o polegar que acessa layer 2 na layer 0**; você volta à layer 0.

O Espaço fica **exatamente na posição que acessa layer 1 na layer 0**, como solicitado. Os polegares ficam assim, seguindo a mesma ordem física do primeiro mapa:

| Mão | Posição da esquerda | Posição central | Posição da direita |
|---|---|---|---|
| Esquerda | **Espaço** | **Ctrl** | **Shift** |
| Direita | **Enter** | **Shift comum** | **Sair para layer 0** |

WASD, Q/E/R/F/G, Z/X/C/V/B e T do lado esquerdo continuam sendo suas letras normais. Tab, Esc, Ctrl e Shift também ficam disponíveis. Espaço, Ctrl e Shift nos polegares servem para associar pulo, agachar e corrida conforme os controles do jogo.

Na metade direita:

| Posições físicas da layer 0 | Enviam na layer 5 |
|---|---|
| I / J / K / L | ↑ / ← / ↓ / →, como na layer 1 |
| N / M / vírgula / ponto / barra | **1 / 2 / 3 / 4 / 5**, em uma fileira para seleção de armas |
| U / O / P | Q / E / R |
| H / ponto e vírgula / aspas | F / G / V |
| Y | Tab |
| Backspace | Backspace |

Essas teclas enviam os códigos indicados; a ação de cada um depende dos binds do jogo. Para movimentação pelas setas, associe as quatro direções no jogo quando necessário.

Todas as teclas de jogo são diretas, inclusive o Shift direito. A layer 5 não usa Tap Dance, acesso aos acentos ou Super. As duas teclas extras inferiores de workspace ficam desativadas; as superiores enviam Esc. Para escrever no chat com o teclado normal, saia pela tecla indicada e retorne com layer 1 + G quando terminar.

## Consulta no Vial

<details>
<summary>Códigos, Tap Dance e como modificar</summary>

Na aba **Keymap**, selecione o número da layer e a posição física. O arquivo para importar é [corne-ii-p3drovfx.vil](corne-ii-p3drovfx.vil).

| Código | Significado |
|---|---|
| `MO(n)` | Mantém a layer n ativa enquanto a tecla está pressionada |
| `TO(5)` / `TO(0)` | Entra no modo FPS / volta à digitação normal; soltar a tecla não desfaz a troca |
| `OSL(4)` | Ativa a layer 4 para a próxima tecla, usado no double tap do Shift direito |
| `KC_LCTL`, `KC_LSFT`, `KC_LALT`, `KC_LGUI` | Ctrl, Shift, Alt e Super comuns |
| `KC_TRNS` / `▽` | Usa a função da layer inferior ativa |
| `KC_NO` / `—` | Sem função nesta layer |
| `LSFT(KC_ENTER)` | Shift+Enter pronto, na posição Enter das layers 1 e 2; a cópia na layer 2 é seu ajuste manual |
| `LCG(KC_LEFT)` / `LCG(KC_RIGHT)` | Teclas extras de workspaces |
| `KC_LGUI`, polegar direito central da layer 1 | Super imediato para combinar com setas; na layer 0 a mesma posição continua sendo Shift TD(2) |
| `QK_MOUSE_WHEEL_UP` / `QK_MOUSE_WHEEL_DOWN` | Rolagem para cima/baixo nas extras esquerdas da layer 1 |
| `KC_F13` / `KC_F14` | Q/E da layer 1; Hyprland transforma em diminuir/aumentar split ratio, sem modificadores |
| `RALT(KC_A)` | Envia AltGr+A; seu XKB transforma em á |
| `TD(n)` | Usa a entrada n da aba Tap Dance; n não é o número de uma layer |

Na aba **Tap Dance**, as entradas 2 e 4 estão atribuídas a teclas, preservando seus ajustes manuais:

| Entrada | Posição | On tap | On hold | On double tap | On tap + hold | Term |
|---|---|---|---|---|---|---|
| 2 | Shift direito, layer 0 | RShift | RShift | `OSL(4)` | vazio | 220 ms |
| 4 | Acesso à layer 1, layer 0 | vazio | `MO(1)` | Shift+Super one-shot (`0x52AA`) | vazio | 180 ms |

As configurações antigas das entradas 0, 1 e 3 foram preservadas, mas nenhuma tecla as utiliza. Para modificar os acentos atuais, edite as teclas da **layer 2 na aba Keymap**, usando os códigos abaixo.

**TD(4)** é sua personalização do acesso à layer 1: ao segurar, acessa essa layer; double tap prepara Shift+Super para a próxima tecla. No modo FPS, essa posição é Espaço comum.

**TD(2)** preserva sua personalização atual: o double tap abre a layer 4 para uma tecla. O uso diário dos acentos continua na layer 2. Para tornar esse Shift uma tecla comum também na layer 0, substitua apenas a atribuição da tecla por `KC_RSFT`. TD(2) não abre a layer 2.

Os códigos de saída dos caracteres são:

| Caracteres | Códigos, na mesma ordem |
|---|---|
| á · é · í · ó · ú | `RALT(KC_A)` · `RALT(KC_E)` · `RALT(KC_I)` · `RALT(KC_O)` · `RALT(KC_U)` |
| ã · õ | `RALT(KC_S)` · `RALT(KC_L)` |
| â · ê · ô | `RALT(KC_Q)` · `RALT(KC_F)` · `RALT(KC_P)` |
| ç · à | `RALT(KC_COMMA)` · `RALT(KC_W)` |
| º · ª · ° | `RALT(KC_M)` · `RSFT(RALT(KC_M))` · `RSFT(RALT(KC_SCLN))` |

As entradas 5–31 de Tap Dance e a aba Combos estão vazias. Não há home-row mod-tap, layer-tap ou macro atribuída. Os one-shots atribuídos são `OSL(4)` no double tap do Shift direito e Shift+Super no double tap do acesso à layer 1, ambos na layer 0. As macros antigas continuam guardadas no dispositivo.

As 12 entradas ativas de **Key Overrides** pertencem somente à **layer 3**: 0–3 para Shift, 4–7 para Ctrl, 8–11 para Alt. Trocam apenas os quatro controles extras e suprimem o modificador usado para escolher a variante.

As substituições com Ctrl são Page Up, Page Down, workspace anterior e próximo; com Alt são Home, End, mover janela ao workspace anterior e próximo. A ordem das quatro posições é esquerda superior, esquerda inferior, direita superior, direita inferior. Use apenas um modificador por vez.

Para manter a layer 4 ativa durante uma sequência de símbolos, o acesso anterior permanece disponível: segure layer 2 e depois Espaço. Solte ambas para encerrar esse acesso.

Referências: [layers no Vial](https://get.vial.today/manual/layers.html), [Tap Dance](https://get.vial.today/manual/tap-dance.html) e [implementação do reconhecimento no Vial](https://github.com/vial-kb/vial-qmk/blob/vial/quantum/vial.c).

</details>

<details>
<summary>Backups, portabilidade e verificação</summary>

O [backup-20260907-145406.vil](backup-20260907-145406.vil) preserva suas edições manuais antes de configurar Q/E para o split ratio. O [backup-20260907-032751.vil](backup-20260907-032751.vil) preserva o estado antes de criar o modo FPS, incluindo suas últimas edições manuais. O [backup-20260907-023215.vil](backup-20260907-023215.vil) preserva o estado antes de levar Super ao polegar direito da layer 1. O [backup-20260907-021245.vil](backup-20260907-021245.vil) preserva o estado antes da troca das layers 1 e 2. Os arquivos `before-simplification-20260907-005348-*` são históricos; suas instruções não descrevem o layout atual. Use este **GUIA.md** como referência atual. O backup original é `backup-20260906-211347.vil`.

O `.vil` configura as teclas USB. A extensão [corne-v4.1.xkb](corne-v4.1.xkb), instalada em `~/.config/hypr/custom/corne-v4.1.xkb`, define os caracteres no Hyprland somente para o Corne. Levar o `.vil` a outro sistema não instala essa extensão.

**Acentos diferentes após reiniciar:** o keyd estava capturando o Corne pela regra `*` e reenviando suas teclas por um teclado virtual com outro mapa. A correção persistente é excluir o Corne em `/etc/keyd/default.conf`:

```ini
[ids]
*
-4653:0004
```

A exclusão foi aplicada e o serviço recarregado. O restante da configuração do keyd foi preservado. O backup anterior está em `/etc/keyd/default.conf.before-corne-20260907-145238-259440.bak`; a cópia da configuração corrigida está em [keyd-default-with-corne-excluded.conf](keyd-default-with-corne-excluded.conf). Se reinstalar o keyd ou seus dotfiles, mantenha essa exclusão e o `hl.device` de `custom/input.lua` que aponta para o XKB do Corne.

Q/E enviam F13/F14 pelo Vial. Os binds em `~/.config/hypr/custom/keybinds.lua` usam `code:191` e `code:192`, respectivamente, para chamar `hl.dsp.layout("splitratio -0.1")` / `hl.dsp.layout("splitratio +0.1")` com repetição. Os códigos físicos evitam que o mapa internacional altere o atalho. Importar o `.vil` sozinho não cria esses comandos no compositor. A sintaxe foi conferida no [parser Lua do Hyprland 0.56.2](https://github.com/hyprwm/Hyprland/blob/v0.56.2/src/config/lua/bindings/LuaBindingsToplevel.cpp).

Edições feitas manualmente no Vial não atualizam o gerador nem este guia. Salve-as em **File → Save current layout** e não rode `apply` para reaplicar o gerador sem considerar essas edições.

```bash
cd ~/.config/quickshell/ii/docs/keyboards/corne-v4.1
python3 device_layout.py snapshot  # backup do estado atual
python3 verify_layout.py           # caracteres e layers, sem digitar no computador
python3 device_layout.py verify    # compara a memória do teclado com layout.json
```

A verificação cobre caracteres com libxkbcommon, entradas/saídas de layers e releitura USB. Não mede conforto físico nem testa os atalhos dentro de cada aplicativo.

</details>

## Mapas por número de layer

Os rótulos **layer 1**, **layer 2**, **layer 3** e **layer 4** representam `MO(1)`, `MO(2)`, `MO(3)` e `MO(4)` no Vial. `▽` conserva a função inferior; `—` desativa a tecla naquela layer. `WS−/WS+` são as teclas extras de workspace; `S+Enter` envia Shift+Enter. Os mapas seguem o layout conferido no teclado. `L1 TD` é o acesso à layer 1 por TD(4). `FPS` significa `TO(5)` e `Sair` significa `TO(0)`. A layer 5 tem seu próprio mapa completo.

<!-- LAYER_MAPS -->

### Layer 0

```text
  Tab       q        w        e        r        t       Esc    ||   Menu      y        u        i        o        p       Bksp
 Shift      a        s        d        f        g       WS−    ||   WS+       h        j        k        l        ;        '
  Ctrl      z        x        c        v        b              ||             n        m        ,        .        /       Alt

                            L1 TD    Space    Super            ||           Enter   Shift TD layer 2
```

### Layer 1

```text
 Shift   Ratio −     ↑     Ratio +  Super+'     —     Rolar ↑  ||  Colar     PgUp     Home      ↑       End       —       Bksp
 Shift      —        ←        ↓        →       FPS    Rolar ↓  ||  Copiar    PgDn      ←        ↓        →        —        —
  Ctrl   Desfazer    —        —        —        —              ||           RGB on  RGB fx−   RGB fx  RGB cor− RGB cor    Alt

                           layer 1     —        —              ||          S+Enter   Super   layer 3
```

### Layer 2

```text
  Tab       â        ▽        é        ▽        ▽       Prev   ||   Next      ▽        ú        í        ó        õ       Bksp
 Shift      á        ã        ê        ▽        ▽       Stop   ||   Play      ▽        ▽        ▽        ô        ▽        ▽
  Ctrl      à        ▽        ç        ▽        ▽              ||             ▽        ▽        ▽        ▽        ▽       Alt

                           layer 3  layer 4   Super            ||          S+Enter   Shift   layer 2
```

### Layer 3

```text
   F1       F2       F3       F4       F5       F6     VolUp   ||  BriUp      F7       F8       F9      F10      F11      F12
 Shift      1        2        3        4        5      VolDn   ||  BriDn      6        7        8        9        0        —
  Ctrl      —        —        —        —      Luz PC           ||           RGB on   RGB fx   RGB −    RGB +   RGB cor    Alt

                           layer 1   Space    Super            ||           Enter    Shift   layer 2
```

### Layer 4

```text
  Tab       !        @        #        $        %        ;     ||    º        ^        &        *        —        —       Del
 Shift      [        {        (        )        ]        :     ||    ª        —        }        =        +        -        _
  Ctrl      `        ~        °        \        |              ||             "        '        <        >        ?       Alt

                           layer 1   Space    Super            ||           Enter    Shift   layer 2
```

### Layer 5

```text
  Tab       q        w        e        r        t       Esc    ||   Esc      Tab       q        ↑        e        r       Bksp
 Shift      a        s        d        f        g        —     ||    —        f        ←        ↓        →        g        v
  Ctrl      z        x        c        v        b              ||             1        2        3        4        5       Alt

                            Space     Ctrl    Shift            ||           Enter    Shift     Sair
```
