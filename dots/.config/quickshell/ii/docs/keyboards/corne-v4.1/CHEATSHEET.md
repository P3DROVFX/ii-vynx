# Teclados na cheatsheet

Abra **Cheatsheet → Keybinds → Keyboards → Corne v4**. A página contém as seis layers lidas do seu teclado em 07/09/2026, incluindo suas alterações mais recentes.

- **Layer 0…5:** escolhem qual mapa consultar. Não ativam uma layer no teclado físico.
- **← / →:** layer anterior/próxima; depois da última, volta à layer 0.
- **0–9:** vai diretamente à layer desse número, se ela existir. Esses atalhos só funcionam na página do teclado, durante a consulta; ficam desativados no editor, no nome e no seletor de layouts. `Ctrl + número` continua sendo o atalho das abas da cheatsheet.
- **Clique em uma tecla:** abre a sidebar direita. Escolha uma tecla da lista ou digite o rótulo; selecione um ícone, use o ícone automático ou mantenha somente texto. Salve para atualizar aquela tecla naquela layer.
- **Detect Vial:** relê geometria e keymap do dispositivo conectado. Atualiza a página do mesmo teclado, mantendo personalizações nas teclas cujos códigos não mudaram. Se a leitura falhar, o mapa salvo continua disponível.
- **Detect layout:** consulta o layout ativo do teclado principal no Hyprland. Para o notebook em português brasileiro, cria **Portuguese (Brazil) · ABNT2**, com Ç, acentos e a tecla extra `/`. As quatro layers visuais são **0 · Base**, **1 · Shift**, **2 · AltGr** e **3 · Shift + AltGr**. Uma nova detecção do mesmo layout atualiza a página e preserva rótulos/ícones cujos símbolos não mudaram. Não altera o idioma no sistema.
- **New keyboard / Add another layout:** cria um mapa manual QWERTY, QWERTZ, AZERTY, Dvorak, Colemak ou **Português (Brasil · ABNT2)**. Você pode editar todas as teclas e adicionar layers. O preset ABNT2 também funciona sem o notebook conectado.
- **− / porcentagem / +:** diminuir, restaurar ou aumentar o zoom. O desenho pode ser arrastado quando ultrapassa a área disponível.
- **Exportar:** salva a página em JSON. O botão Import da biblioteca importa esse arquivo novamente.

As edições modificam **somente a representação visual no ii**. O teclado físico continua sendo configurado pelo Vial.

O mapa usa ícones automáticos em teclas como Super, Enter, Shift e setas. Teclas de layer mantêm seu número visível. Os acentos brasileiros desta página foram nomeados conforme o XKB do Corne; rótulos personalizados permanecem durante uma releitura quando a atribuição correspondente não mudou.

A visualização considera a layer escolhida sobre a layer 0. Teclas transparentes ficam esmaecidas; combinações que mantêm várias layers ativas simultaneamente podem resolver essas posições de outra forma.

A detecção de sistema lê os símbolos XKB, incluindo a variante ativa; o desenho usa uma geometria padrão ANSI/ISO/ABNT2 sem numpad. Ela não identifica a carcaça exata nem teclas Fn específicas do notebook. Para o Corne, use **Detect Vial**, que lê a geometria física e as layers do firmware. A layer exibida na cheatsheet é selecionada manualmente para consulta.

O arquivo [cheatsheet-current.json](cheatsheet-current.json) permite importar esta página. O backup [backup-20260907-154708.vil](backup-20260907-154708.vil) preserva o teclado antes desta integração. As novas edições no Vial não foram substituídas pelo gerador antigo.
