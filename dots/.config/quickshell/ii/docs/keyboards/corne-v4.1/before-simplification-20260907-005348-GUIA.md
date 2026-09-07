# Corne v4.1 — ii-p3drovfx

Layout gravado no Corne em **06/09/2026**. São seis camadas. As posições abaixo usam o nome da letra na BASE, mesmo quando a camada faz essa tecla produzir outra coisa.

O arquivo para carregar no Vial é [corne-ii-p3drovfx.vil](corne-ii-p3drovfx.vil). O mapa complementar de caracteres é [corne-v4.1.xkb](corne-v4.1.xkb), já instalado para este Corne no Hyprland. O teclado do notebook continua com sua configuração anterior.

## Comece pelos polegares

Olhando o teclado de frente, da esquerda para a direita:

| Mão | Primeiro polegar | Polegar do meio | Terceiro polegar |
|---|---|---|---|
| Esquerda | **NAV** — `MO(1)` | **Espaço** | **Super** — `KC_LGUI` |
| Direita | **Enter** | **NUM** — `MO(2)` | **Shift direito** |

Revisão mais recente de 06/09/2026: NAV seguido do Shift do polegar direito abre TIL/CIRCUNFLEXO, usando um polegar de cada mão. NAV+Espaço agora envia Espaço normal. Na camada TIL, D e K são Shifts imediatos para facilitar maiúsculas. NAV+Enter continua enviando Shift+Enter; o Super duplicado da NAV fica em G. Backup antes desta mudança: [backup-20260906-231140.vil](backup-20260906-231140.vil).

Espaço, Super, Shift e Enter são teclas comuns: começam no pressionamento, podem ficar seguradas e não esperam distinguir toque de hold. Letras também são comuns. Não há home-row mods na BASE, one-shot, combos de letras ou layers que ficam ligadas depois de soltar todos os polegares.

Há **Shift esquerdo duplicado** na primeira tecla da fileira de A/S/D/F, imediatamente acima do Ctrl. Isso mantém Shift, Ctrl, WASD e Espaço utilizáveis com a mão esquerda em jogos. Tab fica no alto à esquerda; Esc fica na tecla extra superior do indicador esquerdo. Alt fica no canto inferior direito. Backspace continua no alto à direita e também aparece em H na NAV.

**Shift+Enter fácil:** primeiro segure NAV com o polegar esquerdo; depois toque o Enter de sempre com o polegar direito. Na camada NAV, Enter envia a combinação pronta (`LSFT(KC_ENTER)`, código `0x0228`), sem hold-tap, double tap ou macro. Não precisa pressionar Shift. Com NAV solto, essa mesma tecla continua enviando Enter normal; G na BASE continua sendo G.

## Como abrir cada camada

`+` significa manter pressionado; `→` significa pressionar em seguida. Não significa apertar o caractere `+`.

| Camada no Vial | Nome | Gesto |
|---|---|---|
| 0 | BASE | Todos os polegares de camada soltos |
| 1 | NAV | Segure NAV |
| 2 | NUM / SISTEMA | Segure NUM |
| 3 | CÓDIGO | Segure NAV e depois NUM, ou NUM e depois NAV |
| 4 | AGUDOS | Segure NUM → pressione e mantenha Espaço |
| 5 | TIL / CIRCUNFLEXO | Segure NAV → pressione e mantenha o Shift do polegar direito |

**Nos acentos, a ordem é obrigatória: NAV/NUM primeiro, a outra tecla depois.** AGUDOS usa NUM direito + Espaço esquerdo; TIL usa NAV esquerdo + Shift do polegar direito. Assim, cada polegar segura uma única tecla. A posição do Shift direito funciona como `MO(5)` quando pressionada depois de NAV; ela não acrescenta Shift aos caracteres nesse gesto. NAV+Espaço envia um espaço comum.

Esses gestos usam `MO` dentro de camadas, sem uma janela de simultaneidade. Não são entradas da aba **Combos** do Vial. A última tecla pressionada sustenta a camada extra: se soltar apenas a primeira, a camada extra pode continuar enquanto a segunda está segurada. **Solte as duas para voltar à BASE**. Nada continua ativo depois disso. É possível usar esse comportamento para liberar a primeira mão depois de entrar na camada.

Nas camadas de acentos, as demais teclas têm explicitamente sua função da BASE, com uma exceção: **D e K na TIL são Shift esquerdo e direito**. Portanto, não herdam números ou setas da camada usada para entrar. D/K continuam letras normais na BASE e na AGUDOS.

## Português sem mudar a posição das vogais

| Caractere | Como digitar |
|---|---|
| á | AGUDOS + A |
| é | AGUDOS + E |
| í | AGUDOS + I |
| ó | AGUDOS + O |
| ú | AGUDOS + U |
| ç | AGUDOS + C; também TIL + C |
| ã | TIL + A uma vez; alternativa imediata: TIL + F |
| õ | TIL + O uma vez; alternativa imediata: TIL + J |
| ê | TIL + E; alternativa: AGUDOS + F |
| â | TIL + A duas vezes; alternativa imediata: TIL + S ou AGUDOS + S |
| ô | TIL + O duas vezes; alternativa imediata: TIL + L ou AGUDOS + L |
| à | AGUDOS + Q ou TIL + Q, imediatamente acima do A |
| º | AGUDOS + M ou TIL + M; também CÓDIGO + extra direita superior |
| ª | AGUDOS + `;` ou TIL + `;`; também CÓDIGO + extra direita inferior |
| ° | AGUDOS ou TIL + extra direita superior |

**Maiúsculas:** acrescente Shift à mesma combinação. Na AGUDOS, use Shift esquerdo: AGUDOS + Shift esquerdo + E = É. Na TIL, há Shifts imediatos em **D e K**, na homerow: TIL + K + E = Ê; TIL + D + O = Õ. Prefira o Shift da mão oposta à letra. Para Ã e Õ sem esperar tap dance: TIL + K + F = Ã; TIL + D + J = Õ. São teclas dedicadas nessa camada, sem função diferente no toque e no hold.

Somente **A e O na camada TIL** usam tap dance, com janela de **170 ms**. O toque simples pode esperar essa janela ou ser resolvido quando outra tecla interrompe a dança. Essa espera não existe no A/O normal nem na camada AGUDOS. Para máxima velocidade, use as alternativas diretas F/J/S/L. No double tap, mantenha TIL ativo até completar os dois toques.

`º` é o indicador ordinal, como em “1º”; `°` é o símbolo de graus. Eles são caracteres diferentes.

## Símbolos para programação

Entre em **CÓDIGO segurando NAV + NUM**. Os símbolos abaixo já incluem os modificadores necessários. **Não acrescente Shift para produzi-los.**

| Saída | Tecla na BASE | Saída | Tecla na BASE |
|---|---|---|---|
| `(` | D; também O | `)` | F; também P |
| `{` | S; também H | `}` | J |
| `[` | A | `]` | G |
| `=` | K | `+` | L |
| `-` | `;` | `_` | tecla de aspas, à direita de `;` |
| `\` | V | `\|` | B |
| `!` | Q | `@` | W |
| `#` | E | `$` | R |
| `%` | T | `^` | Y; também C |
| `&` | U | `*` | I |
| `~` | X | acento grave literal | Z |
| `'` literal | M | `"` literal | N |
| `<` | vírgula | `>` | ponto |
| `?` | barra `/` | `;` | extra esquerda superior |
| `:` | extra esquerda inferior | `º` / `ª` | extras direitas superior / inferior |

Na BASE: vírgula, ponto, barra, ponto e vírgula e apóstrofo têm suas posições habituais à direita. `:` também sai com Shift + `;`; `?` com Shift + `/`; `<`/`>` com Shift + vírgula/ponto. A tecla de apóstrofo é literal: não consome a próxima letra para acentuá-la.

Para escrever `(){}º|+=-\_`, por exemplo: CÓDIGO + D, F, S, J, extra direita superior, B, L, K, `;`, V, tecla de aspas. Solte as teclas dos caracteres entre eles; pode continuar segurando a camada durante toda a sequência.

**NUM mantém os números na homerow:** A/S/D/F/G = 1/2/3/4/5; H/J/K/L/`;` = 6/7/8/9/0. F1–F12 ficam na fileira acima, incluindo as duas teclas das pontas, exatamente nas posições anteriores.

## Setas dos dois lados

Segure NAV:

```text
       E = ↑                      I = ↑
 S = ← D = ↓ F = →          J = ← K = ↓ L = →
```

Na NAV, Z/X/C são **Ctrl/Alt/Shift esquerdos** e M/vírgula/ponto são **Ctrl/Alt/Shift direitos da área de navegação**. São modificadores comuns, ativos imediatamente enquanto pressionados, e só substituem essas letras na NAV. Os Ctrl/Alt duplicados enviam os códigos esquerdos para os aplicativos, mesmo quando posicionados na metade direita.

| Ação | Combinação concreta |
|---|---|
| Mover cursor | NAV + S/D/F/E ou J/K/L/I |
| Pular palavra à esquerda/direita | NAV + V/B ou N/`/` — já incluem Ctrl |
| Ctrl + qualquer seta | NAV + Z (Ctrl) + J/K/L/I; ou Ctrl da BASE + NAV + seta |
| Alt + seta | NAV + X (Alt) + J/K/L/I |
| Selecionar com setas | NAV + C (Shift) + J/K/L/I; ou NAV + ponto (Shift) + S/D/F/E |
| Selecionar palavra | NAV + Z (Ctrl) + C (Shift) + J/L |
| Usar as setas da mão esquerda para selecionar palavras | NAV + M (Ctrl) + ponto (Shift) + S/F |
| Backspace perto da homerow | NAV + H |
| Shift + Enter | NAV + Enter — mesma tecla do Enter normal, com Shift incluído |
| Ctrl + Backspace | NAV + Z + H |
| Alt + Backspace | NAV + X + H |
| Delete | NAV + A ou `;` |
| Ctrl + Delete | NAV + Z + `;` |
| Home / End | NAV + Q/T ou Y/P |
| Page Up / Page Down | NAV + W/R ou U/O |
| Ctrl + Home / End | NAV + Z + Y/P |
| Selecionar até começo/fim | Acrescente Shift à combinação Home/End desejada |

O efeito de Alt+seta e Alt+Backspace depende do aplicativo. Em navegadores, Alt+esquerda/direita geralmente navega pelo histórico; em terminais, Alt+Backspace frequentemente apaga uma palavra. O teclado envia a combinação, sem substituí-la por um comando de “apagar linha”.

**Na NAV, use C ou ponto para Shift.** O Shift do polegar direito agora abre TIL quando pressionado depois de NAV; por isso, os exemplos de seleção usam essas duplicatas. Fora da NAV, o Shift do polegar continua normal.

## Hyprland sem contorcer os polegares

Na BASE, use **Super esquerdo + Shift do polegar direito + letra**. Exemplos:

| Atalho | Como pressionar | Ação configurada |
|---|---|---|
| Super + Shift + S | Super + Shift direito + S | Seleção de região para captura |
| Super + Ctrl + C | Super + Ctrl esquerdo + C | Compactar workspaces |
| Super + Ctrl + V | Super + Ctrl esquerdo + V | Mixer de volume |
| Super + Ctrl + T | Super + Ctrl esquerdo + T | Seletor de wallpaper |
| Super + Alt + N | Super + Alt inferior direito + N | Notas |
| Super + V | Super + V | Clipboard |
| Super + Tab | Super + Tab do canto superior esquerdo | Overview de workspaces |
| Super + Enter | Super + Enter do polegar direito | Terminal |
| Ctrl + Space | Ctrl esquerdo + Espaço | Pesquisa do shell |
| Super + I | Super + I | Settings |
| Super + Z | Super + Z | Media mode, pelo override em custom/keybinds.lua |

Para combinar **Super com as setas**, segure NAV e G, que nessa camada é um Super comum. Use as setas J/K/L/I com a mão direita. Esse Super duplicado passou do polegar Enter para G para liberar NAV+Enter como Shift+Enter. G na BASE continua sendo a letra G.

| Atalho | Forma fácil |
|---|---|
| Super + seta | NAV + G (Super) + J/K/L/I |
| Super + Ctrl + seta | A combinação acima + Ctrl da borda esquerda ou Z na NAV |
| Super + Alt + seta | NAV + G (Super) + X (Alt) + J/K/L/I |
| Super + Shift + seta | NAV + G (Super) + C (Shift) + J/K/L/I |
| Super + Ctrl + Shift + esquerda/direita | Use Shift + a tecla extra de workspace da BASE: já contém Super+Ctrl+seta |
| Super + Ctrl + Alt + esquerda/direita | Use Alt + a tecla extra de workspace da BASE |

### Workspaces e janelas

As duas teclas extras **inferiores dos indicadores** foram preservadas na BASE:

- Extra esquerda inferior: `LCG(KC_LEFT)` = Ctrl + Super + esquerda.
- Extra direita inferior: `LCG(KC_RIGHT)` = Ctrl + Super + direita.

| Gesto | Resultado nos seus keybinds |
|---|---|
| Extra esquerda/direita da BASE | Workspace anterior/próximo |
| Shift + extra esquerda/direita da BASE | Mover janela ao workspace anterior/próximo |
| Alt + extra esquerda/direita da BASE | Workspace ocupado anterior/próximo no monitor (`m-1`/`m+1`) |
| Super + NUM + A…`;` | Selecionar workspace pelo número 1…10, relativo ao início do grupo atual |
| Super + Alt + NUM + A…`;` | Enviar janela silenciosamente ao número 1…10 relativo ao início do grupo atual |
| NAV + G (Super) + Ctrl + E/I ou D/K | Grupo anterior/próximo de workspaces (`r-5`/`r+5` na sua configuração atual) |
| NAV + G (Super) + Page Up/Down | Workspace anterior/próximo |
| NAV + G (Super) + Ctrl + Page Up/Down | Workspace relativo anterior/próximo (`r-1`/`r+1`) |
| NAV + G (Super) + Alt ou Shift + Page Up/Down | Mover janela ao workspace anterior/próximo |

Nos seus arquivos, **Super+seta foca janelas**, **Super+Shift+seta move janelas na direção** e **Super+Alt+seta chama o tiling assistant**. Super+Alt+seta não é um atalho de trocar workspace. O layout conserva essas combinações, sem editar keybinds.lua.

Seu `custom/variables.lua` define **workspaceGroupSize = 5**. A função `workspace_in_group(i)` soma o número ao começo do grupo, sem limitar i a 5: no grupo 1–5, os números 6–0 selecionam 6–10; no grupo 6–10, os números 1–5 selecionam 6–10 e 6–0 selecionam 11–15.

## A área de quatro controles na NUM

EXL↑/EXL↓ são as duas extras do indicador esquerdo; EXR↑/EXR↓, do direito. Primeiro segure NUM, depois o modificador desejado, por último a tecla de controle. Solte a tecla de controle antes do modificador.

| Com NUM segurado | EXL↑ | EXL↓ | EXR↑ | EXR↓ |
|---|---|---|---|---|
| Sem modificador | Volume + | Volume − | Brilho da tela + | Brilho da tela − |
| + Shift | Faixa anterior | Próxima faixa | Play/pause | Mute |
| + Ctrl | Page Up | Page Down | Workspace anterior | Próximo workspace |
| + Alt | Home | End | Mover janela ao workspace anterior | Mover janela ao próximo workspace |

As variantes são **Key Overrides**, com efeito restrito à camada 2. Ctrl/Shift/Alt usados para escolher a função são suprimidos na saída; a substituição envia exatamente a ação indicada. Use **um desses modificadores por vez** nessa área.

Há alternativas na fileira inferior da NUM:

| Tecla | Função |
|---|---|
| Z / X / C | Faixa anterior / play-pause / próxima faixa |
| V | Mute |
| B | Super+F7: atalho existente que alterna o backlight do computador |
| N | Liga/desliga RGB do Corne — `RGB_TOG` |
| M | Próximo efeito RGB do Corne — `RGB_MOD` |
| vírgula / ponto | Reduz / aumenta brilho RGB do Corne — `RGB_VAD` / `RGB_VAI` |
| `/` | Muda a tonalidade RGB — `RGB_HUI` |

Brilho de tela, backlight do computador e RGB do Corne são controles separados. `RGB_MOD` percorre os efeitos que este firmware disponibiliza. A aba **Lighting** do Vial também continua disponível.

## Como entender e editar no Vial

Se o Vial que já estava aberto ainda mostrar o mapa anterior, feche e abra novamente para reler o dispositivo. As alterações já estão na memória do teclado; não é necessário carregar o arquivo para ativá-las agora.

| Código/termo | Significado |
|---|---|
| `KC_LGUI` / `KC_RGUI` | Super. “GUI” é o nome USB/QMK da tecla Windows/Super |
| `KC_LCTL`, `KC_LSFT`, `KC_LALT` | Ctrl, Shift e Alt comuns: só ficam ativos enquanto segurados |
| `MO(n)` | Abre a camada n enquanto a tecla está pressionada |
| `▽` / `KC_TRNS` | Procura a função nas camadas inferiores que estiverem ativas |
| `KC_NO` | Tecla sem ação; na matriz deste arquivo, usada nas posições físicas inexistentes |
| `LCTL(KC_LEFT)` | Ctrl+esquerda em uma tecla; segurá-la mantém essa combinação |
| `LCG(KC_LEFT)` | Ctrl+Super+esquerda |
| `LSFT(KC_9)` | Parêntese `(`; o Shift está incluído no código |
| `LSFT(KC_ENTER)` | Shift+Enter em uma tecla; está no polegar Enter na NAV |
| `RALT(KC_A)` | AltGr+A: á no mapa de caracteres do Corne |
| `RALT(KC_COMMA)` | AltGr+vírgula: ç; evita a composição agudo+C, que no Linux pode dar ć |
| `TD(0)` / `TD(1)` | Tap dances de A/O, usados somente na camada 5 |
| Key Override | Troca uma tecla por outra quando um modificador está pressionado, em uma camada específica |

Na aba **Keymap**, escolha a camada, clique na posição física e escolha o novo código. A categoria **Any** permite informar códigos como `MO(3)`, `LCG(KC_LEFT)` ou `RALT(KC_A)`. [Referência de camadas do Vial](https://get.vial.today/manual/layers.html).

Na aba **Tap Dance**, as entradas 0 e 1 são:

| Entrada | Toque | Hold | Double tap | Tap + hold | Term |
|---|---|---|---|---|---|
| 0 | `RALT(KC_S)` → ã | mesmo ã | `RALT(KC_Q)` → â | mesmo â | 170 ms |
| 1 | `RALT(KC_L)` → õ | mesmo õ | `RALT(KC_P)` → ô | mesmo ô | 170 ms |

Hold não é um modificador nem abre uma camada nesses tap dances. As outras entradas estão vazias. Para eliminar também a espera dos acentos secundários, substitua TD(0) por `RALT(KC_S)` e TD(1) por `RALT(KC_L)`; â/ô continuam disponíveis em S/L. [Referência de Tap Dance](https://get.vial.today/manual/tap-dance.html).

**Double press em NAV/NUM foi avaliado e não foi ativado.** Com uma camada momentânea, seria necessário tocar, soltar e manter o segundo toque pressionado; dois toques completamente soltos não manteriam a camada para a letra seguinte. Além disso, no Tap Dance padrão do Vial, outra tecla pressionada antes do fim da janela pode transformar o gesto em dois toques simples, em vez de executar a ação de tap + hold. Esperar a janela resolveria essa ambiguidade, mas prejudicaria a prioridade de acesso imediato. Por isso, NAV/NUM continuam `MO(1)`/`MO(2)`. [Implementação do Tap Dance no Vial](https://github.com/vial-kb/vial-qmk/blob/vial/quantum/vial.c).

Na aba **Key Overrides**, entradas 0–3 = variantes com Shift; 4–7 = Ctrl; 8–11 = Alt. Dentro de cada grupo a ordem é Vol+, Vol−, Brilho+, Brilho−. Todas usam somente a layer 2. Ativam ao pressionar a tecla de controle e não reapresentam a função original ao soltar o modificador. Entradas 12–31 estão desativadas. [Referência de Key Overrides no QMK](https://docs.qmk.fm/features/key_overrides).

A aba **Combos** está vazia. As macros antigas foram preservadas como backup, mas nenhuma tecla do layout novo as chama. Não use as macros antigas como referência para os acentos novos. Auto Shift está desativado; os ajustes de tapping term globais não introduzem hold-tap neste layout.

## O mapa XKB e a portabilidade

O Vial grava **teclas USB**, enquanto o XKB do sistema decide quais caracteres elas representam. Para acrescentar ã/õ/â/ê/ô/à/º diretamente, o Corne recebeu uma extensão de US International aplicada somente ao dispositivo `foostan-corne-v4-keyboard`.

| Código enviado pelo Vial | Sem Shift | Com Shift |
|---|---|---|
| AltGr + A/E/I/O/U | á/é/í/ó/ú | Á/É/Í/Ó/Ú |
| AltGr + vírgula | ç | Ç |
| AltGr + S | ã | Ã |
| AltGr + L | õ | Õ |
| AltGr + Q | â | Â |
| AltGr + F | ê | Ê |
| AltGr + P | ô | Ô |
| AltGr + W | à | À |
| AltGr + M | º | ª |
| AltGr + Shift + `;` | ° | — |

Essas são as teclas **enviadas**, não necessariamente a posição física: por exemplo, a posição física E na camada TIL envia AltGr+F e por isso produz ê. A posição continua sendo E para você.

Apóstrofo, aspas, acento grave, til e circunflexo literais usam os níveis literais de US International (`RALT(KC_QUOTE)`, `RALT(KC_GRAVE)` e suas versões com Shift, além de AltGr+Shift+6 para `^`). Não dependem de uma tecla morta seguida de Espaço.

O arquivo ativo fica em `~/.config/hypr/custom/corne-v4.1.xkb`; a última seção de `~/.config/hypr/custom/input.lua` aponta somente este dispositivo para ele. O [Hyprland aceita mapas XKB via kb_file](https://wiki.hypr.land/configuring/core/config-options/).

**Em outro computador, o .vil sozinho não reproduz todos os acentos:** instale também o mapa XKB equivalente. Os atalhos, letras, números, camadas e controles ficam no firmware; a extensão brasileira depende do sistema. Em uma tela de login ou outro compositor que não carregue a configuração do Hyprland, a extensão também precisa ser configurada lá.

## Backups, mudanças futuras e verificação

O backup imediatamente anterior à primeira gravação é **backup-20260906-211347.vil**. O JSON do mesmo nome contém também os dados brutos lidos do dispositivo. `hypr-input-antes-20260906-211344.lua` preserva o arquivo de configuração do Hyprland antes da inclusão do Corne. Backups com horários posteriores já podem conter o layout novo.

Para voltar ao layout anterior, carregue aquele `.vil` no menu File do Vial. Se também quiser desfazer a extensão de caracteres, remova somente o bloco `hl.device` do Corne ao final de `custom/input.lua`; o backup serve para comparar essa seção, sem sobrescrever outras mudanças suas.

Para salvar suas próximas mudanças, use **File → Save current layout** no Vial. `layout.json` e `build_layout.py` descrevem a versão criada nesta tarefa; eles não se atualizam automaticamente quando você edita no Vial. Não rode `apply` depois de personalizar sem a intenção de reaplicar esta versão.

Os scripts deste diretório não precisam de dependências Python adicionais:

```bash
cd ~/.config/quickshell/ii/docs/keyboards/corne-v4.1
python3 device_layout.py snapshot   # lê e salva um novo backup; não modifica o teclado
python3 verify_layout.py            # valida caracteres e desenho das camadas offline
python3 device_layout.py verify     # compara teclado e layout.json; não escreve no teclado
# Somente se você quiser reaplicar a versão deste diretório:
python3 build_layout.py
python3 device_layout.py apply      # salva backup antes de gravar; relê para conferir
```

Foram conferidos os 336 endereços da matriz, incluindo as posições sem tecla, os 32 registros de tap dance, combos e overrides, e 97 casos de caracteres/maiúsculas pelo libxkbcommon. A releitura USB confirma a gravação; os testes offline não medem conforto, rollover físico ou o comportamento de cada aplicativo. Nenhuma captura de tela ou chamada IPC do Quickshell foi usada para testar os atalhos.

## Mapas completos das seis camadas

Os diagramas abaixo seguem a disposição física. As duas posições EX aparecem junto à divisão central. `▽` mantém a função de uma camada ativa inferior; as exceções nos polegares estão explicadas acima. `C/S/A/G` significam Ctrl/Shift/Alt/Super. Os diagramas são gerados a partir do mesmo `layout.json` usado na gravação.

<!-- LAYER_MAPS -->

### 0 — BASE

```text
   Tab       q        w        e        r        t       Esc     ||     Menu      y        u        i        o        p       Bksp
  Shift      a        s        d        f        g       CG←     ||     CG→       h        j        k        l        ;        '
   Ctrl      z        x        c        v        b               ||               n        m        ,        .        /       Alt

                              NAV     Space    Super                            Enter     NUM     Shift
```

### 1 — NAV

```text
   Tab      Home     PgUp      ↑       PgDn     End      Home    ||     PgUp     Home     PgUp      ↑       PgDn     End      Bksp
  Shift     Del       ←        ↓        →      Super     End     ||     PgDn     Bksp      ←        ↓        →       Del      Ctrl
   Ctrl     Ctrl     Alt     Shift      C←       C→              ||               C←      Ctrl     Alt     Shift      C→      Alt

                               ▽      Space      ▽                             S+Enter   CÓDIGO    TIL
```

### 2 — NUM / SISTEMA

```text
    F1       F2       F3       F4       F5       F6     VolUp    ||    BriUp      F7       F8       F9      F10      F11      F12
  Shift      1        2        3        4        5      VolDn    ||    BriDn      6        7        8        9        0        '
   Ctrl     Prev     Play     Next     Mute     G+F7             ||             RGB on   RGB fx   RGB −    RGB +   RGB cor    Alt

                             CÓDIGO   AGUDOS     ▽                                ▽        ▽        ▽
```

### 3 — CÓDIGO

```text
   Tab       !        @        #        $        %        ;      ||      º        ^        &        *        (        )       Bksp
  Shift      [        {        (        )        ]        :      ||      ª        {        }        =        +        -        _
   Ctrl      `        ~        ^        \        |               ||               "        '        <        >        ?       Alt

                              NAV     Space    Super                            Enter     NUM     Shift
```

### 4 — AGUDOS

```text
   Tab       à        w        é        r        t       Esc     ||      °        y        ú        í        ó        p       Bksp
  Shift      á        â        d        ê        g       CG←     ||     CG→       h        j        k        ô        ª        '
   Ctrl      z        x        ç        v        b               ||               n        º        ,        .        /       Alt

                              NAV     Space    Super                            Enter     NUM     Shift
```

### 5 — TIL / CIRCUNFLEXO

```text
   Tab       à        w        ê        r        t       Esc     ||      °        y        ú        í      õ/ô×2      p       Bksp
  Shift    ã/â×2      â      Shift      ã        g       CG←     ||     CG→       h        õ      Shift      ô        ª        '
   Ctrl      z        x        ç        v        b               ||               n        º        ,        .        /       Alt

                              NAV     Space    Super                            Enter     NUM     Shift
```
