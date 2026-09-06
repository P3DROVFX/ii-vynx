# Media Mode — plano de implementação do player de música local

Data: 2026-09-06. Status: **planejamento; nenhuma funcionalidade deste documento foi implementada nesta tarefa**.

Base: leitura do `AGENTS.md`, dos componentes de background, controles, serviços de mídia/letras, registros de quick toggles e configuração Hyprland. O código atual prevalece sobre exemplos históricos conflitantes do `AGENTS.md`.

Leitura rápida: [auditoria](#2-auditoria-do-estado-atual), [experiência e estados](#3-contrato-de-experiência-e-estados), [layout e animações](#4-layout-preservado-e-comportamento-dos-painéis), [arquitetura](#5-arquitetura-técnica-proposta), [fases](#11-fases-de-implementação) e [validação](#12-estratégia-de-validação).

## 1. Resultado pretendido

Transformar o Media Mode em um player de música local completo, mantendo sua função atual de acompanhar/controlar mídias de outros aplicativos e sua composição visual. O usuário continua abrindo pelo **Super + Z**, pode adicionar um quick toggle, abre uma música ou pasta, controla a reprodução e acompanha letras e próximas faixas.

O player tem duas fontes claramente identificadas:

- **Aplicativos:** acompanha Spotify, navegadores e demais players MPRIS. Não mostra fila, botão de fila ou espaço reservado para fila.
- **Músicas locais:** reproduz arquivos sob controle do ii. Mostra fila somente quando uma sessão de playlist estiver aberta. Abrir uma única música pelo fluxo de arquivo avulso não cria uma fila visível.

Fechar o Media Mode fecha apenas a interface. O áudio local continua, e permanece controlável pela barra, widgets, teclas multimídia e demais clientes MPRIS. Reabrir recupera a sessão em andamento.

### 1.1 Compromissos de produto

1. Preservar capa, informações e controles à esquerda, com Lyrics Studio à direita.
2. Acrescentar à direita um **retângulo de fila abaixo do retângulo de letras**, como superfícies irmãs, sem card externo envolvendo os dois.
3. Quando a busca terminar sem letra, contrair o corpo das letras e expandir a fila. O cabeçalho das letras continua acessível.
4. Permitir expandir/contrair letras e fila manualmente por botões próprios. A decisão automática nunca sobrescreve uma escolha manual ainda válida.
5. Todas as mudanças visuais de estado recebem transições coerentes; respeitar animações desativadas e não acrescentar pulse, bounce ou scale decorativo.
6. Funcionar sem rede para reprodução, metadados, capas disponíveis no disco e letras locais.
7. Manter as personalizações existentes de layout, tema, visualizador, player switcher, seek e volume.

### 1.2 Limite da primeira versão completa

As fases 0–9 deste documento formam a primeira versão completa: reprodução, filas, playlists salvas, letras, atalhos, persistência, recursos de áudio e acabamento. Uma entrega parcial pode ser validada internamente, mas não deve ser apresentada como o player completo solicitado.

Ficam para evolução posterior: crossfade com mixagem de dois decodificadores, ripping de CDs, edição destrutiva de tags, biblioteca remota, streaming autenticado e indexação automática de todo o computador. Não são pré-requisitos para tocar e organizar músicas locais. Gapless será validado na fase 7, sem prometer ausência absoluta de intervalo em qualquer combinação de arquivos/dispositivos.

## 2. Auditoria do estado atual

| Área | Evidência no código atual | Consequência para o plano |
| --- | --- | --- |
| Entrada existente | `BackgroundRoot.qml`: `GlobalShortcut` chamado `mediaModeToggle`; `hyprland/keybinds.lua` associa `quickshell:mediaModeToggle` a Super + Z | Preservar nome e binding; reutilizar o mesmo fluxo de abertura |
| Abertura vazia | `openMediaMode()`, `mediaModeLoader.onActiveChanged` e conexão a `MprisController` exigem player ativo ou fecham ao perdê-lo | Alterar os três pontos em conjunto para suportar o estado local vazio |
| Janela | `BackgroundRoot.qml` cria `PanelWindow` efêmera em Overlay; wallpaper permanece em Background | Não mover a nova UI para a janela permanente do wallpaper |
| Fechamento | `releasingFocus` libera teclado antes de `mediaModeTeardown`, atualmente 60 ms | Preservar liberação de foco e destruição real da janela |
| Multimonitor | `GlobalStates.mediaModeCount`, `mediaModeMonitors`, `mediaModeCloseAllTrigger`; registro/liberação pertencem a `BackgroundRoot` | UI por monitor; áudio, fila e mutações pertencem a um serviço global único |
| Layout | `MediaMode.qml`: margens externas 28, spacing do corpo 24 e proporção pretendida aproximada 44%/56% | Preservar geometria de referência e redistribuir somente a altura da coluna direita |
| Capa e transporte | `MediaModeCoverArt.qml` contém capa, tags, seek, transporte, shuffle, repeat e volume | Reutilizar controles; extrair dependências de contexto antes de ampliar |
| Dependências implícitas | `MediaModeCoverArt.qml` usa `root.player`, `root.displayedArtFilePath` e `root.updateArt()` vindos do contexto pai | Tornar entradas/sinais explícitos sem mudar a apresentação |
| Serviço de mídia | `MprisController.qml` usa `property MprisPlayer`, acompanha players reais e pode trocar o selecionado em eventos de reprodução | O player local precisa ser exportado como MPRIS real; seleção explícita deve resistir a eventos de outros apps |
| Capas ausentes | `updateTrack()`/alguns handlers de `MprisController` dependem de capa; há `_artUrlFallback` | Faixas locais sem arte exigem atualização por identidade de faixa e limpeza de capa anterior |
| Letras | `LyricsService.qml` resolve LRCLib, Genius, YouTube Music e overrides de `CustomLyricsStore.qml` | Acrescentar resolução local antes da rede, mantendo a API dos consumidores existentes |
| Identidade das letras | `CustomLyricsStore` usa título + artista; outros gatilhos observam título | Caminho/identidade local deve distinguir versões, homônimos e faixas sem tags |
| Renderização de letras | `MediaModeLyrics.qml` apresenta cinco linhas focais e acessa `LyricsService`; `LyricsFlickable` atende texto simples | Preservar renderer e adaptar sua altura útil quando a fila aparecer |
| Estados sem letras | `MediaModeLyricsSkeleton.qml` e `MediaModeLyricsFallback.qml` já separam busca, instrumental e ausência | Reaproveitar; ausência não pode ser inferida de uma resposta ainda pendente |
| Fila | Não existe fila em `MediaMode.qml` | Criar contrato de sessão/ordem; não inferir fila de título, artista ou player externo |
| Quick toggles | Catálogos Android/clássico e `QuickToggleRegistry.qml` não contêm um toggle dedicado ao Media Mode | Registrar nos dois estilos e no catálogo de ações, preservando a organização do usuário |
| Vídeo musical | `MusicVideoService.qml` usa mpvpaper, busca online e tem encerramento amplo de processos mpvpaper | Não usar esse processo/socket para tocar áudio local; adicionar elegibilidade explícita por fonte |
| Persistência | `Config.options.background.mediaMode` guarda apresentação; `Persistent.states.background.mediaMode` guarda hoje `userScrollOffset` | Separar aparência de dados pessoais e de fila volumosa |

### 2.1 Dependências verificadas nesta máquina

Encontrados: `mpv` 0.41.0, `ffprobe`, `ffmpeg`, Python 3, GJS, `qmllint`, `qmltestrunner` e módulos Python `gi`, `mutagen` e `dbus_next`. Isso confirma disponibilidade local, não a matriz de instalação de outros usuários.

O plano escolhe Python + PyGObject/Gio para o bridge/MPRIS, Mutagen para tags e mpv para áudio. `dbus_next` e GJS não precisam virar dependências adicionais deste recurso. Os manifestos de distribuição devem ser revisados; não instalar pacotes automaticamente durante implementação sem a autorização exigida pelo projeto.

### 2.2 Pontos históricos que não devem ser copiados

- Há trechos antigos no `AGENTS.md` que descrevem promoção da janela de wallpaper ou contadores em `MediaMode.Component.onCompleted`. O código atual usa janela separada e registro centralizado no host; essa é a base.
- Há animações antigas com valores fixos/scale nos arquivos de mídia. Elas não são precedente para novos efeitos; adequar apenas os trechos tocados, preservando composição e usando os tokens atuais.
- A nova reprodução não deve copiar o encerramento genérico de mpvpaper nem a conversão de posição presente no serviço de vídeo. As unidades corretas são definidas na seção 5.4.

## 3. Contrato de experiência e estados

### 3.1 Abertura e seleção de fonte

**Super + Z:** mantém a semântica de alternar o Media Mode no monitor focado ou globalmente, conforme `togglePerMonitor`. Se já houver fonte escolhida nesta sessão do shell, restaura essa escolha. Na primeira abertura, usa o player externo ativo; sem player, abre Músicas locais vazio. Não inicia áudio só por abrir a interface.

**Quick toggle Media Player:** abre/fecha o mesmo Media Mode e usa a mesma regra de fonte. Fecha a sidebar de origem e encaminha uma única solicitação ao coordenador de abertura, sem executar subprocesso IPC. Seu destaque representa visibilidade da interface no escopo correto, não apenas “há áudio tocando”.

**Chip Músicas locais:** sempre disponível no seletor, mesmo sem backend iniciado ou player externo. Selecioná-lo mostra a sessão local ou o estado vazio, sem autoplay. Players externos mantêm os chips existentes; omitir o bus local da lista repetida para não duplicar o chip.

**Abrir música / Abrir pasta:** ficam acessíveis no Media Mode inclusive quando a fonte atual é um aplicativo. A seleção de arquivos só muda a fonte depois de uma importação válida e confirmada. Cancelamento ou pasta sem áudio conserva fonte e reprodução anteriores.

Se `showPlayerSwitcher` estiver desligado, manter acesso à fonte pelo menu de ações e às duas ações de abrir. Ocultar o switcher não pode tornar o modo local inacessível.

Como o binding atual também está registrado para tela bloqueada, o coordenador deve recusar abertura enquanto `GlobalStates.screenLocked` estiver ativo e fechar a superfície ao bloquear. Ao desbloquear, não reabrir automaticamente. Se o background estiver desativado e seus hosts não existirem, o toggle deve informar a indisponibilidade e oferecer acesso à configuração; nunca alterar a preferência de background silenciosamente ou criar uma segunda janela de wallpaper.

Se o aplicativo selecionado desaparecer durante a visualização, selecionar outro externo conforme a política existente quando houver um candidato válido; sem candidato, apresentar a fonte local com sua sessão guardada ou estado vazio, sem autoplay. A mudança é tratada como seleção de fonte completa, limpando letras/capas antigas. Somente essa decisão explícita pode tornar uma fila local novamente elegível.

### 3.2 Música avulsa e playlist são conceitos diferentes

| Operação | Sessão resultante | Fila visível? | Reprodução |
| --- | --- | --- | --- |
| Abrir uma música pelo seletor de arquivos | `single` | Não | Começa após validação |
| Abrir vários arquivos juntos | `playlist` | Sim | Começa pela primeira faixa válida na ordem apresentada |
| Abrir pasta, inclusive pasta com só uma faixa | `playlist` | Sim | Começa pela primeira válida após concluir a descoberta da ordem |
| Abrir playlist salva ou M3U/M3U8 | `playlist` | Sim | Começa na faixa inicial escolhida |
| Adicionar à fila a partir de uma sessão avulsa | Promove para `playlist` | Sim | Mantém a faixa atual e sua posição |
| Reduzir uma playlist a uma faixa | Continua `playlist` | Sim | Mantém contexto e ações da playlist |
| Chegar à última faixa | Continua `playlist` | Sim, com estado de fim | Para ou repete conforme repeat |
| Fechar playlist | `empty` | Não | Para o áudio local; não apaga arquivos |
| Selecionar aplicativo externo com playlist local carregada | Fonte externa; sessão local guardada | Não | Não inicia nem pausa áudio apenas pela mudança visual |

Invariante de apresentação, em pseudocódigo:

```text
queueEligible = selectedSourceKind == local
                AND localSession.kind == playlist
                AND localSession.playlistOpen

rightColumnVisible = effectiveLyricsVisible OR queueEligible
```

`queueEligible` independe de haver letras, de estar tocando/pausado, da quantidade de próximas faixas e de o título da música estar preenchido. Nunca usar `MprisController.players.length`, nome “mpv” ou `canGoNext` para decidir se existe fila.

### 3.3 Sessão, biblioteca, playlist salva e fila

- **Biblioteca:** índice das pastas que o usuário escolheu adicionar; abrir uma pasta uma vez não a adiciona permanentemente sem intenção explícita.
- **Playlist salva:** sequência nomeada reutilizável de referências a arquivos; pode conter duplicatas deliberadas.
- **Sessão:** contexto carregado (`empty`, `single`, `playlist`), origem e faixa atual.
- **Fila de reprodução:** ordem efetiva da sessão, incluindo shuffle, itens inseridos para tocar a seguir e alterações manuais. Salvar a fila como playlist é uma ação explícita.

Não atualizar automaticamente a playlist salva quando o usuário remover algo da fila temporária. Marcar mudanças não salvas e oferecer Salvar / Salvar como no menu. A sessão em andamento pode ser restaurada automaticamente de estado local sem alterar o documento da playlist.

### 3.4 Concorrência com outros aplicativos

Selecionar um chip escolhe o alvo dos controles, sem iniciar áudio nem executar pause-all. Ao mandar tocar uma faixa local, assumir a fonte local e, por padrão, pausar o player externo anteriormente selecionado **se ele estiver tocando e puder pausar**. Preferência funcional permite manter áudio simultâneo.

Eventos de pause/stop/metadata de um app não roubam uma seleção local explícita. Se outro app começar a tocar por iniciativa externa, manter a seleção explícita e deixar o app acessível no switcher. No modo automático legado, conservar descoberta/prioridade existente. A escolha de um app externo enquanto o local toca não deve gerar dois comandos play/pause em cascata.

## 4. Layout preservado e comportamento dos painéis

### 4.1 Estrutura visual

```text
Toolbar existente: fonte · Abrir música · Abrir pasta · ações · fechar

Coluna esquerda, aproximadamente 44%     Coluna direita, aproximadamente 56%
Capa / forma / tema atuais               Letras: cabeçalho + recolher/expandir
Título, artista, álbum                   Corpo das letras
Seek, tempo, transporte                  Espaçamento existente entre superfícies
Volume e opções de reprodução            Próximas: cabeçalho + recolher/expandir
                                        Linhas da fila com capa, tags e duração
```

Essa representação mostra hierarquia, não novos contornos. Os retângulos reais usam preenchimento tonal, arredondamento e nenhuma borda.

Em Aplicativos, a fila e seu espaçamento desaparecem totalmente. A coluna de letras conserva a apresentação atual. Em música local avulsa, aplica-se a mesma geometria sem fila. Com letras globalmente ocultas e playlist local, a coluna direita passa a ser toda da fila; com ambas inelegíveis, a capa volta à largura disponível como hoje.

As ações novas da toolbar são um pequeno grupo. Em largura reduzida, primeiro recolher controles secundários existentes de offset, provider, tamanho e efeitos para um `StyledPopup` de Mais opções. Não encolher textos/alvos indefinidamente nem criar uma terceira coluna.

### 4.2 Estados automáticos das letras

O resolver publica um estado explícito por faixa:

| Estado | Significado | Resultado automático com playlist local |
| --- | --- | --- |
| `idle` | Não há faixa | Cabeçalho compacto; fila ocupa área restante |
| `loadingLocal` | Lendo sidecar/tags/cache | Reservar última geometria estável; indicador discreto no cabeçalho |
| `loadingRemote` | Consulta online ainda válida | Manter geometria; não declarar ausência |
| `readySynced` | Letra sincronizada disponível | Expandir letras e preservar espaço útil de fila |
| `readyPlain` | Texto sem timestamps disponível | Expandir letras usando texto rolável |
| `notFound` | Busca concluída sem conteúdo | Recolher letras e expandir fila |
| `instrumental` | Resultado explícito sem letra cantada | Recolher letras; cabeçalho informa Instrumental |
| `disabled` | Letras desativadas pelo usuário | Remover corpo/cabeçalho conforme opção global; fila assume área |
| `error` | Falha de leitura ou timeout de provedores | Recolher automaticamente após prazo; exibir Erro e Tentar novamente no cabeçalho |

Não chamar erro de “letra inexistente”. Uma falha de rede não permite afirmar que não existe letra. O layout pode liberar espaço após timeout, mas a mensagem deve refletir a causa.

Na primeira playlist sem geometria anterior, iniciar aproximadamente dividido ao meio enquanto a busca acontece. Em trocas seguintes, manter a última distribuição durante a busca e alterar uma vez quando o resultado relevante chegar. Nunca exibir a letra da faixa anterior como se pertencesse à nova.

Ao passar de faixa sem letra para faixa com letra, o modo automático reexpande o painel. A chegada tardia de resultado pertencente a outra faixa não altera conteúdo nem geometria.

### 4.3 Controle manual e precedência

Manter para cada seção `preference = auto | expanded | collapsed`. São intenções, não valores derivados de altura. Os cabeçalhos têm botão expandir/contrair, tooltip e estado acessível; um item Voltar ao automático remove a preferência manual.

Ordem de decisão:

1. Elegibilidade da fonte e configuração global: jamais permitir fila em Aplicativos ou sessão avulsa.
2. Escolha manual da seção.
3. Resultado automático das letras.
4. Restrições de espaço da tela.

Preferências manuais locais duram ao trocar de faixa e fechar/reabrir o Media Mode, até Voltar ao automático. Guardar estado de apresentação por monitor e fonte, evitando que um ajuste no monitor retrato reorganize o outro monitor. Mudança de playlist não deve silenciosamente apagar a escolha manual.

Se o usuário expandir Letras sem conteúdo, mostrar o fallback já existente e ações de importar/repetir busca. Não recolher novamente quando outro provider terminar. Se recolher manualmente a fila, ela continua só com cabeçalho, contagem e indicação compacta da próxima faixa.

Se os dois corpos forem recolhidos manualmente, deixar somente os dois cabeçalhos e espaço tonal livre; respeitar a intenção sem reabrir um painel à força. Configuração `showLyrics=false` não deve reaparecer por resultado de busca; oferecer Reativar letras no menu, como ação explícita.

### 4.4 Geometria determinística

Criar um controller visual pequeno e puro, `MediaModePanelLayout.js`, que recebe altura útil, mínimos, elegibilidade, preferências e estado das letras. Ele devolve alturas-alvo; não grava Config nem Persistent.

```text
H = altura disponível na coluna direita
G = espaço entre seções, apenas se ambas existirem
HL/HQ = alturas medidas dos cabeçalhos
ML/MQ = mínimos úteis dos corpos expandidos

alturaLetras + alturaFila + G <= H
```

Com ambas expandidas, começar com proporção 55% letras / 45% fila da área dos corpos, limitada pelos mínimos. Quando letras recolherem, sua altura é `HL` e a fila recebe todo o restante, descontado o espaço. O inverso vale ao recolher a fila. A divisão é uma nova regra **interna da direita**, sem alterar a proporção horizontal atual.

O texto focal atual pode exceder meia coluna: derivar o tamanho efetivo de fonte, espaçamento e viewport da altura alocada, respeitando limites de legibilidade e a preferência de tamanho. Não apenas cortar o `MediaModeLyrics` existente com `clip`. Preservar cinco slots focais quando couberem; em tela muito baixa, usar variante compacta explicitamente definida com linha atual e vizinhas, mantendo a versão atual quando a fila estiver ausente.

Quando `HL + HQ + ML + MQ + G > H`, usar modo compacto: um corpo por vez, mantendo os dois cabeçalhos. O último painel expandido manualmente ganha a área; em automático, preferir letras quando presentes e fila quando ausentes. Comunicar no botão qual seção será expandida. A mudança por falta de espaço não sobrescreve as preferências persistidas; ao voltar a caber, restaurá-las.

Em largura lógica insuficiente para duas colunas legíveis, usar uma coluna com capa/controles compactos no topo e os mesmos dois painéis abaixo. Definir o breakpoint a partir das larguras mínimas medidas dos componentes, não da resolução física. No desktop que já cabe, a composição permanece a atual.

### 4.5 Responsabilidade das animações

- Animar um único progresso do split e derivar as duas alturas dele. Não usar `Behavior on height` competindo com `Layout.fillHeight` nem animar pai e filho sobre a mesma geometria.
- Fade do corpo acompanha expansão/contração; o cabeçalho permanece utilizável. Desabilitar interação do corpo na contração e descarregar renderer pesado somente depois da saída.
- Usar `Appearance.animation.*` e `Appearance.animMultiplier`; zero significa acomodação imediata e funcional.
- Troca de fonte: fade curto de conteúdo, sem capa saltar de tamanho e sem mostrar a fila anterior no primeiro frame de um app externo.
- Inserção/remoção/reorder: transições de `ListView`, IDs estáveis, movimento da posição real e feedback tonal. Não animar novamente todos os milhares de itens a cada atualização.
- Ao interromper uma transição, partir da geometria visual corrente; não voltar a um início fixo. Trocas rápidas e cliques repetidos devem convergir ao estado mais recente.
- Reutilizar transições de capa e movimento focal das letras. Não recriar todos os renderers por causa de mudança de progresso.
- Saída da janela: liberar foco primeiro; animar somente uma superfície sem interação e destruir ao fim, respeitando também a margem de commit do compositor. Com animação zero, a folga de liberação de foco continua necessária. Registro de monitor dura até o teardown para não fazer widgets reaparecerem antes da saída.
- Hotplug, bloqueio e destruição do host usam teardown seguro imediato quando necessário; não deixar uma animação atrasar a proteção de tela.

## 5. Arquitetura técnica proposta

### 5.1 Escolha do backend

Usar **um processo mpv dedicado a áudio**, controlado por um helper Python persistente durante a sessão local. O helper mantém o modelo da fila, conecta-se ao socket JSON do mpv e exporta MPRIS via Gio. O mpv fornece comandos, observação de propriedades e eventos de reprodução; sua playlist possui IDs próprios por instância. Esses mecanismos permitem sincronizar a execução sem consultar o processo por shell a cada segundo. [Manual oficial do mpv](https://mpv.io/manual/stable/#json-ipc).

Configuração inicial proposta: sem janela/vídeo, sem terminal/OSC, sem scripts ou configurações pessoais do mpv, modo idle enquanto a sessão estiver viva e saída de áudio padrão do sistema. Revisar a linha de execução contra a versão mínima na fase 0. Não carregar um plugin MPRIS externo: a exportação pertence ao helper e não pode aparecer duplicada.

Por que essa opção: aproveita o mpv já disponível, permite fila real e controles avançados, e preserva o consumo MPRIS já espalhado pelo shell. `QtMultimedia.MediaPlayer` permanece uma alternativa apenas se o protótipo invalidar o backend escolhido; não manter dois motores de reprodução na primeira versão.

### 5.2 Fronteiras e propriedade dos dados

```text
MediaMode / barra / widgets / teclas multimídia
                  |
            MprisController ---- players externos
                  |
         MprisPlayer real do ii
                  |
       helper local Python/Gio ---- mpv de áudio
                  |
       fila, playlists, sessão e metadados
                  |
 LocalMediaService.qml <---- eventos JSON / comandos estruturados
                  |
      fila visual, picker, resolver de letras locais
```

| Componente proposto | Responsabilidade | Não deve fazer |
| --- | --- | --- |
| `services/LocalMediaService.qml` | Singleton cliente, readiness, comandos locais, snapshot e modelo estável de fila | Decodificar áudio, duplicar persistência do helper ou depender da janela |
| `scripts/media/local_player.py` | Dono do processo mpv, protocolo, identificação de sessão, despacho serial de comandos | Executar caminhos recebidos como comandos de shell |
| `scripts/media/queue_store.py` | Único escritor de fila/sessão/playlists; transações e restauração | Gravar em arquivos de música ou publicar estado antes de reconciliar o backend |
| `scripts/media/mpris_bridge.py` | Exportar objetos MPRIS, propriedades, métodos e sinais | Manter uma segunda fila independente |
| `scripts/media/library_index.py` | Descoberta incremental, metadados, capas e cache limitado | Varrer HOME no boot ou criar um processo por arquivo simultaneamente |
| `services/LocalLyricsService.qml` + helper | Resolver sidecars/tags/overrides de faixa local | Fazer novas chamadas de rede independentes dos providers existentes |
| `services/LyricsService.qml` | Fachada compatível de resolução final e sincronização | Continuar expondo letras remotas antigas quando a fonte muda |
| `MediaModePanelLayout.js` | Calcular distribuição dos painéis a partir de intenções | Alterar ordem de músicas ou dados persistentes |

Esses nomes são propostos e podem ser ajustados na fase 0. A divisão de responsabilidades é obrigatória; evitar um script monolítico que misture scanning, D-Bus, parsing e geometria.

### 5.3 Integração MPRIS sem quebrar os tipos existentes

Publicar um bus exclusivo, por exemplo `org.mpris.MediaPlayer2.ii_local`, com nome legível **II Music**. `MprisController.activePlayer`, `trackedPlayer` e `players` continuam contendo `MprisPlayer` reais; não atribuir um `QtObject` que apenas imita suas propriedades.

Adicionar ao controller uma intenção explícita de seleção (`auto`, `external`, `local`) e identificação de bus externo escolhido. No modo local, `activePlayer` resolve o bus próprio do helper; antes do backend estar pronto pode ser `null`, sem que isso feche a UI local vazia. Reconhecimento do player local compara bus e proprietário da sessão conhecidos, nunca `identity` ou prefixo genérico `mpv`.

O controller passa a ser a única autoridade de seleção. Os chips chamam métodos de seleção, em vez de escrever diretamente `trackedPlayer`. O helper/`LocalMediaService` não deve ler de volta o controller para decidir o que tocar: isso criaria dependência circular.

Exportar Root e Player: Play, Pause, PlayPause, Stop, Next, Previous, Seek, SetPosition, volume, rate, loop, shuffle, metadata e capabilities reais. `Raise` solicita abertura pelo canal interno do serviço; `Quit`, se anunciado, encerra somente a sessão local. Um `OpenUri` anunciado aceita somente os esquemas locais efetivamente suportados. [Interface MPRIS Player](https://specifications.freedesktop.org/mpris/latest/Player_Interface.html).

Não exportar `TrackList` inicialmente se não houver consumidor/implementação completa. A interface é opcional e diferente de uma promessa de que todo player externo terá fila. A fila rica do ii vem do seu serviço local, independentemente dessa extensão. Anunciar `HasTrackList=false` enquanto ela não existir. [Interface MPRIS TrackList](https://specifications.freedesktop.org/mpris/latest/Track_List_Interface.html).

Corrigir a atualização de `activeTrack` para reagir à troca real de faixa mesmo sem capa, limpando `_artUrlFallback` quando a identidade muda. O fallback pode atravessar uma resposta incompleta da mesma faixa, nunca uma faixa diferente. Isso é necessário para locais sem APIC/cover e beneficia os consumidores atuais sem mudar a API.

### 5.4 Unidades e identidade

| Fronteira | Posição/duração | Volume |
| --- | --- | --- |
| mpv e domínio interno do helper | Segundos | Converter escala do mpv para domínio interno |
| API JSON do helper | Segundos, nomes explícitos `positionSec`/`durationSec` | Normalizado 0–1 |
| `MprisPlayer` no QML | Segundos com precisão de milissegundos | Normalizado 0–1 |
| Protocolo MPRIS no D-Bus | Microssegundos em campos correspondentes | Normalizado 0–1 |
| LRC e preferências de offset | Timestamps convertidos para segundos; offsets em ms | Não aplicável |

O Quickshell já converte a posição/duração de MPRIS para segundos. Fazer a conversão de microssegundos somente na borda D-Bus do helper. [Documentação de MprisPlayer](https://quickshell.org/docs/v0.2.1/types/Quickshell.Services.Mpris/MprisPlayer/).

Separar três identidades:

- `trackId`: UUID persistente do arquivo catalogado. Primeira importação indexa caminho canônico e fingerprint leve; renomeação é reconciliada quando inequívoca ou por Relocalizar arquivo.
- `queueEntryId`: UUID de cada ocorrência na fila. A mesma música pode aparecer duas vezes e ser removida/movida independentemente.
- `backendEntryId`: ID temporário recebido do mpv, mapeado para `queueEntryId` e descartado ao reiniciar o motor.

O ID MPRIS de faixa deve distinguir a ocorrência atual quando necessário, usando object path válido. Nenhuma dessas identidades depende apenas de índice, título ou URL de capa.

### 5.5 Protocolo e sincronização

Comandos QML → helper por JSON delimitado por linha, com `protocolVersion`, `requestId`, `sessionId`, operação e payload. Saída do helper usa eventos JSON; logs ficam em stderr, nunca misturados no protocolo.

Operações mínimas: `openFiles`, `openFolder`, `openPlaylist`, `append`, `playEntry`, `enqueueNext`, `moveEntry`, `removeEntries`, `clearUpcoming`, `closePlaylist`, `savePlaylist`, `setShuffle`, `setRepeat`, `seek`, `getSnapshot`, `cancelImport` e `shutdown`.

Eventos mínimos: `ready`, `snapshot`, `queueChanged`, `trackChanged`, `playbackChanged`, `importProgress`, `metadataUpdated`, `lyricsLocalResult`, `error` e `shutdown`. Toda alteração de fila leva `revision`; resultado assíncrono de importação/letra leva também sua geração de pedido.

- Uma fila de comandos serial no helper resolve operações concorrentes de MPRIS e UI.
- `requestId` evita repetir mutações após timeout/reconexão; o cliente solicita snapshot quando perde a sequência.
- A UI mostra pendência por ação e aplica mudanças confirmadas; erro restaura a projeção anterior e informa a causa.
- Observar eventos/propriedades do mpv; não iniciar `socat`, `playerctl` ou processo de shell por tick.
- O espelho de execução do mpv e a ordem persistente são reconciliados por IDs. EOF é avançado por **um único mecanismo**, evitando Next duplo pelo mpv e pelo helper.
- Para manter transições entre faixas, preferir sincronizar a ordem completa no motor. Alterações de queue usam operações pontuais sem recarregar a faixa atual. O protótipo precisa provar a sequência de confirmação/reconciliação em Next, remove e shuffle.
- Posição para UI pode usar extrapolação/refresh apenas enquanto um consumidor visível precisa dela. Não persistir posição a 60 Hz nem manter timer de letras por monitor.

### 5.6 Ciclo de vida dos processos

`LocalMediaService` vive fora do loader do Media Mode. O helper é iniciado sob demanda e possui um único mpv filho. Abrir o mesmo player em dois monitores não cria outro helper, outro bus, outro scan ou outra saída de áudio.

Ao fechar a UI, a sessão segue viva. Ao encerrar o shell/reiniciar de verdade, a primeira versão salva estado, encerra somente os processos de sua propriedade e restaura pausado quando solicitado novamente. Sobreviver ininterruptamente a um restart completo do Quickshell não é requisito da primeira versão.

Hot reload pode preservar o serviço ou recriá-lo: implementar detecção de proprietário/lock e handshake antes de iniciar outro motor. Se o proprietário antigo estiver encerrando, aguardar a liberação com timeout. Se ele ainda estiver válido, reconectar ou recusar a segunda inicialização; nunca iniciar áudio em duplicidade. A estratégia exata precisa ser demonstrada na fase 0.

Socket fica em diretório privado do usuário sob `XDG_RUNTIME_DIR`, com permissões restritas, IDs de sessão e limpeza apenas dos arquivos próprios. Não usar `pkill mpv`, `killall`, identificação só pelo nome ou socket compartilhado com mpvpaper. EOF do canal proprietário e sinais de encerramento devem ter cleanup explícito; implementar reconexão/handoff apenas se houver proprietário verificável.

Crash do mpv conserva fila e posição mais recente, marca erro recuperável e oferece Retomar. Não entrar em loop de reinício/autoplay nem fechar a janela de forma inesperada.

## 6. Importação, metadados, biblioteca e fila

### 6.1 Seletor de arquivos e pastas

Criar seletor dentro da própria superfície do Media Mode com `StyledPopup`, listagem virtualizada, breadcrumb, voltar/subir, seleção de arquivos e botão Usar esta pasta. Reaproveitar `FolderListModelWithHistory.qml` e padrões do file browser, isolando as ações de leitura/seleção; não herdar ações de apagar/mover arquivos.

Isso evita que um diálogo externo fique escondido atrás da `PanelWindow` Overlay. Se o protótipo optar por diálogo nativo/portal, precisa validar parent, foco, cancelamento e stacking antes de substituir a solução interna; não chamar zenity de trás da camada fullscreen e supor que aparecerá.

Fluxos:

- Abrir música permite seleção única/múltipla com filtro de áudio; nome, extensão e duração quando disponíveis.
- Abrir pasta mostra seleção explícita de Incluir subpastas, desligada por padrão, e ordenação da importação.
- Se já há sessão carregada, ações visíveis Abrir substituindo / Adicionar à fila deixam o efeito claro, sem confirmação genérica a cada arquivo.
- Drop de arquivos/pasta usa os mesmos comandos e oferece Adicionar ou Substituir. Não interpretar texto arbitrário do clipboard como comando.
- Importação longa é cancelável, informa quantidade descoberta e mantém a sessão anterior até commit válido. Metadados são enriquecidos depois; não esperar todas as capas para habilitar a primeira reprodução.
- Não mudar para a sessão candidata enquanto os arquivos ainda podem resultar em zero itens válidos.

### 6.2 Formatos e ordenação

Cobertura alvo: MP3, FLAC, Ogg Vorbis, Opus, M4A/AAC e WAV, conforme codecs da instalação. Validar conteúdo/decodificação, não apenas extensão. Arquivo misto de vídeo não entra automaticamente na playlist de música.

Ordenação inicial de pasta: subpasta/álbum, número de disco, número da faixa e nome natural como desempate. Ausência de tags usa nome natural determinístico. Preservar ordem explícita de playlist importada. Multisseleção usa ordem apresentada no picker, documentada na UI.

O scanner trabalha fora do thread QML, com cancelamento, lotes e concorrência limitada. Não seguir symlinks de diretórios recursivamente por padrão; detectar ciclos/duplicação de caminhos resolvidos. Respeitar permissões e reportar quantos arquivos foram ignorados. Pastas inacessíveis ou mídias removíveis desmontadas não apagam referências salvas.

Aceitar caminhos Unicode, espaços, aspas, `%`, `#`, caracteres de shell e nomes começando por hífen. Usar arrays de argumentos, URI encoding correto e protocolo JSON. Resolver entradas relativas de M3U em relação à pasta do próprio arquivo. Não buscar URLs remotas ou playlists recursivas: filtrar esquemas para arquivos locais e limitar nesting/tamanho.

### 6.3 Metadados e arte

Mutagen extrai título, artistas, álbum, artista do álbum, faixa/disco, gênero, ano, duração, ReplayGain e letras/capas embutidas. `ffprobe` complementa formato, bitrate, sample rate, canais e duração quando o parser de tags não oferecer os dados. Usar workers limitados e timeouts, sem processos ilimitados por pasta.

Fallbacks: título pelo nome do arquivo; artista/álbum ausentes com texto traduzido; duração desconhecida como “—”, sem somá-la como zero em um total supostamente exato.

Prioridade de capa: override escolhido pelo usuário, capa embutida, `cover`/`folder` da mesma pasta e placeholder tonal com símbolo de música. Cache de miniaturas por arquivo + tamanho/mtime e limite de tamanho/resolução. Nunca manter a imagem da faixa anterior como capa da nova faixa sem arte.

Informações completas ficam em um popup de detalhes, não nas linhas da fila. Reproduzir não altera tags dos arquivos.

### 6.4 Operações e semântica da fila

| Ação | Regra |
| --- | --- |
| Play/Pause | Atua no item atual; abrir painel não muda estado |
| Stop | Para e zera posição, preserva playlist e seleção |
| Próxima | Avança na ordem efetiva; em repeat-one, comando manual avança normalmente |
| Anterior | Após 3 s, volta ao início; antes disso retorna ao item realmente anterior no histórico |
| Clique numa faixa | Seleciona a ocorrência pelo ID e inicia sua reprodução |
| Tocar a seguir | Insere depois da atual; múltiplos pedidos mantêm a ordem escolhida |
| Adicionar ao fim | Mantém áudio/posição; cria sessão playlist se necessário |
| Arrastar para reordenar | Edita ordem efetiva por IDs; faixa atual continua tocando |
| Remover futura/passada | Não interrompe atual; remove somente a ocorrência escolhida |
| Remover atual | Vai para próxima válida; se não existir, para. Estado paused permanece paused ao mudar de seleção |
| Limpar próximas | Conserva atual e histórico; não fecha contexto da playlist |
| Fechar playlist | Para, remove contexto carregado e oculta fila |
| Shuffle | Embaralha apenas futuras com ordem armazenada; preserva atual, histórico e itens explícitos de Tocar a seguir |
| Desligar shuffle | Restaura ordem base para restantes; não repete automaticamente o que já foi consumido |
| Repeat off | Ao final, para e mantém a sessão/fila com indicação Fim da playlist |
| Repeat all | Novo ciclo da playlist; definir nova ordem futura de shuffle sem duplicar a atual acidentalmente |
| Repeat one | EOF repete a atual, respeitando a separação entre avanço automático e manual |
| Arquivo indisponível | Marcar erro da ocorrência, pular com limite e parar se não houver válida; nunca loop infinito |

Separar ordem base, ordem efetiva e histórico em um modelo único do helper. Não sortear novamente a lista durante renderização. Alterar metadados enquanto toca não reordena a fila silenciosamente.

### 6.5 Apresentação da fila

Cabeçalho: Próximas, quantidade de futuras, tempo restante estimado, expandir/contrair e menu. Tempo restante considera rate/repeat; com duração desconhecida mostrar total parcial, com repeat contínuo não mostrar um fim exato fictício.

Cada linha: miniatura, título, artista, álbum quando couber, duração e menu de ações. A faixa atual pode aparecer em uma linha compacta fixa “Tocando agora”; abaixo ficam as futuras na ordem real. Histórico/anteriores fica acessível por ação de lista completa, sem misturar com “Próximas”. Em repeat-one, indicar que a atual repetirá antes de avançar, para a lista não prometer uma próxima imediata.

Busca na fila filtra a apresentação, não muda a reprodução. Reorder fica desabilitado durante filtro ativo ou solicita limpar filtro, evitando destino ambíguo. Reorder também deve ter alternativa de teclado/menu; não depender exclusivamente de drag.

Usar `ListView` com modelo estável e alterações incrementais, nunca `Repeater` com toda a biblioteca. Ao trocar a atual, acompanhar a lista somente se o usuário não estiver rolando/editando; mostrar Voltar à atual quando necessário. Empty state de fim continua dentro do contexto local, com Repetir playlist, Adicionar músicas e Abrir pasta.

## 7. Letras de músicas locais

### 7.1 Resolução e precedência

Nova ordem para a fonte local:

1. Override explícito escolhido/importado/editado para `trackId`.
2. Sidecar com mesmo basename: `.lrc` ou variante sincronizada reconhecida.
3. Letras sincronizadas embutidas quando o formato/timing puder ser interpretado corretamente.
4. Letras de texto embutidas; depois sidecar `.txt` com mesmo basename.
5. Cache local de resultado remoto compatível com identidade e metadados atuais.
6. Providers online existentes, somente conforme preferência e permissões de rede do usuário.

Mutagen expõe frames ID3 de letras sincronizadas e não sincronizadas; a implementação precisa tratar suas representações específicas, além de tags de outros formatos. [Frames ID3 do Mutagen](https://mutagen.readthedocs.io/en/latest/api/id3_frames.html).

Letras locais não dependem de `enableLrclib`, `enableGenius` ou `enableYtmusic`. O master de letras continua respeitado, mas desligar providers online não pode desligar leitura local. A escolha de provider remoto não bloqueia LRC local. Acrescentar preferência funcional para busca online de arquivos locais, desligada por padrão; a mídia deve funcionar inteiramente offline.

Se houver override legado por título/artista, aplicar só como fallback compatível e oferecer migração/associação ao arquivo. Não migrar silenciosamente um mesmo texto para versões de estúdio, ao vivo e remaster que tenham tempos diferentes.

### 7.2 Parser e sincronização

Extrair o parser de `LrclibLyrics.qml` para utilitário puro compartilhado antes de estendê-lo. Manter o contrato `{ time, text }` dos renderers existentes. Testar múltiplos timestamps na mesma linha, frações de segundo, BOM, CRLF, tags de metadados, linhas vazias, offset LRC e timestamps fora de ordem.

Letra sincronizada embutida em unidades de frames de áudio exige conversão confiável para tempo; se não houver, degradar para texto ou indicar formato não suportado, nunca exibir sincronização falsa. Enhanced LRC com tempos por palavra pode inicialmente preservar tempos por linha e texto limpo; apresentação palavra a palavra fica subordinada à existência de dados reais.

Posição de sincronização: posição real da faixa, somada ao offset global existente e ao ajuste específico da faixa. Offset declarado no LRC entra uma única vez no parsing/normalização. Definir sinais, prioridade e conversão em um único local; clique na linha faz seek ao tempo de reprodução correspondente, invertendo corretamente o offset aplicado.

Reutilizar o gesto de seek atual, que confirma um seek absoluto por interação. Não enviar dezenas de seeks no arrasto nem mudar a faixa com base em uma resposta antiga. Velocidade diferente de 1×, pause, seek para trás e troca rápida de faixa precisam refletir imediatamente na linha atual.

### 7.3 Estado, cache e controles

`LyricsService` conserva propriedades públicas usadas por barra/widgets: `syncedLines`, `currentIndex`, `plainLyrics`, `hasAnyLyrics`, `searching`, `instrumental`, `syncPosition` e ações de retry/override. Internamente passa a resolver contexto de origem + trackId + geração de request; não só título.

Acrescentar status de origem: LRC local, Letra embutida, Texto local, Personalizada ou provider remoto. O cabeçalho compacto preserva Importar letra, Editar/colar, Ajustar sincronização, Tentar novamente e Voltar ao automático no menu apropriado.

Invalidar sidecar/cache por caminho, mtime/tamanho e mudança de tags. Arquivo corrigido pelo usuário precisa ser recarregado por ação explícita ou watcher limitado aos arquivos da faixa atual, sem polling de todas as pastas. Cache negativo tem validade limitada e Retry sempre o ignora.

Cada provider tem timeout e cancelamento/generation guard. Primeira letra útil pode ser exibida sem esperar todos; ausência só é final quando todas as fontes elegíveis terminarem ou expirarem. Resultados tardios de faixas passadas não alteram painel, offset nem fila. Recolher letras descarrega efeitos visuais após a animação, sem apagar o resultado nem impedir uma busca pendente de terminar.

## 8. Recursos para uma primeira versão completa

| Grupo | Recursos | Onde aparecem |
| --- | --- | --- |
| Transporte | Play/pause/stop, próxima/anterior, seek, tempo decorrido/restante, volume próprio e mute | Controles atuais da capa; ações secundárias no menu |
| Ordem | Shuffle, repeat off/all/one, tocar a seguir, adicionar, remover, reordenar e limpar futuras | Transporte e fila |
| Playlists | Salvar, renomear, duplicar, abrir, excluir registro com possibilidade de desfazer, importar/exportar M3U/M3U8 | Popup Biblioteca/Playlists |
| Biblioteca local | Pastas explicitamente adicionadas, atualizar/cancelar scan, busca por título/artista/álbum, ordenação e favoritos | Popup ou subpágina contextual, sem coluna permanente nova |
| Conveniência | Recentes, favoritos por faixa, retomar posição, últimos diretórios, sessão restaurada pausada | Estado vazio e Biblioteca |
| Letras | LRC/TXT, tags embutidas, importação manual, edição/override, offsets, fallback online opcional | Lyrics Studio |
| Áudio | Velocidade com preservação de pitch quando suportada, ReplayGain, EQ local com bypass e presets | Mais opções → Áudio |
| Reprodução longa | Sleep timer por duração ou fim da faixa, loop A–B, marcadores de posição por faixa | Mais opções |
| Sistema | Exportação MPRIS, teclas multimídia, widgets existentes, informações de dispositivo e atalho para mixer | Infraestrutura existente |
| Qualidade | Gapless validado em fixtures compatíveis, proteção de clipping ao aplicar ganho/EQ e recuperação de arquivo indisponível | Backend e feedback contextual |

EQ fica restrito ao player local e começa neutro; não altera equalização global do sistema nem conflita silenciosamente com EasyEffects. ReplayGain desativado por padrão e seletor Track/Album quando houver tags. Sem ganho automático surpresa; limitar headroom quando combinar preamp e EQ.

Áudio acompanha o dispositivo padrão via stack existente. Se oferecer override por player, validar disponibilidade e permitir voltar a Padrão do sistema. Remoção de fone/dispositivo deve tratar erro e feedback sem travar a fila. Não solicitar inibição de suspensão permanentemente por ser um player de áudio.

O sleep timer pausa/para conforme opção, não fecha o shell. Cancelar e mostrar tempo restante são operações do serviço global, não timer da janela. Marcadores e A–B usam segundos e identidade de faixa; trocar de faixa encerra A–B anterior.

Não criar uma `.desktop` que mude o aplicativo padrão de música sem intenção do usuário. A exportação MPRIS já permite integração sistêmica; associação “Abrir com II Music” pode ser adicionada explicitamente ao empacotamento mais tarde.

### 8.1 Teclado e foco

| Entrada dentro do Media Mode | Ação proposta |
| --- | --- |
| Espaço | Play/pause, quando o foco não está em campo de texto ou controle que consome Espaço |
| Ctrl + O / Ctrl + Shift + O | Abrir músicas / abrir pasta |
| Alt + esquerda/direita | Anterior/próxima; sem substituir navegação interna do picker |
| Esquerda/direita com foco no seek | Ajustar posição com commit coerente com o slider |
| Ctrl + F | Busca na fila/biblioteca visível |
| Enter em faixa | Tocar ocorrência selecionada |
| Delete na lista | Remover ocorrência da fila, nunca o arquivo do disco |
| Escape | Cancelar drag/fechar menu ou picker primeiro; só depois fechar Media Mode |
| Tab / Shift + Tab | Percorrer toolbar, controles, cabeçalhos e linhas sem focar corpos recolhidos |

Validar conflitos com os componentes reutilizados na fase 8. Teclas multimídia globais continuam vindo da integração existente; não registrar bindings globais duplicados. Ao recolher uma seção que contém o foco, devolvê-lo ao botão de expansão dessa seção. O foco usa preenchimento/ícone/tom, sem borda nova.

## 9. Persistência, recuperação e limites

### 9.1 Distribuição dos dados

| Dado | Local proposto | Política |
| --- | --- | --- |
| Aparência atual e novas opções puramente visuais | `Config.options.background.mediaMode` | Compatível com presets; manter defaults atuais |
| Fonte preferida, preferências de painéis por monitor/fonte e últimos diretórios | `Persistent.states.background.mediaMode` / `Persistent.states.localMedia` | Listas explicitamente tipadas; sobrevive a preset |
| Preferências funcionais: rede para lyrics locais, recursão, retomada, EQ/ganho | `Persistent.states.localMedia` | Não exportar em presets visuais |
| Sessão, queue IDs/ordem/histórico e posição checkpoint | `Directories.state/user/local-media/session.json` | Escritor único no helper, versionado e atômico |
| Playlists nomeadas, favoritos e marcadores | `Directories.state/user/local-media/` | Arquivos versionados por documento; dados pessoais duráveis |
| Overrides locais e offsets por faixa | Store local por trackId sob `user/local-media/` | Sem escrita nos arquivos musicais; manter compatibilidade do store legado |
| Metadados extraídos, thumbnails, buscas de letras | `Directories.cache/media/local-media/` | Reconstruível, quota e invalidação explícitas |
| Socket/lock e arquivos transitórios | Diretório próprio em `XDG_RUNTIME_DIR` | Só sessão ativa; sem metadados pessoais desnecessários |

Adicionar os paths a `Directories.qml`; usar XDG, sem hardcode `/home/pedro`. Não serializar toda a fila em `Config.qml` ou `Persistent.qml`. Arrays em `JsonObject` usam `list<string>` ou `list<var>`; `ListModel.get` recebe apenas índice.

### 9.2 Gravação e retomada

- Um único escritor por arquivo. Estado de UI é escrito pelo Persistent; dados de reprodução, pelo helper.
- Escrita atômica, schemaVersion, guarda de leitura inicial e retry antes de criar defaults para arquivo ausente.
- JSON inválido é preservado para recuperação; não sobrescrever silenciosamente com vazio. Usar último snapshot íntegro quando disponível.
- Gravar fila após commit de mutação; posição em pause/stop/troca/saída e checkpoint espaçado, por exemplo 15 s enquanto toca. O intervalo é de recuperação, não polling de música.
- Retomar sessão pausada após reiniciar o shell. Reabrir somente a janela durante reprodução mantém posição e áudio atuais.
- Não retomar faixa desaparecida; marcar como indisponível, oferecer Relocalizar ou Pular. Reassociar só com evidência suficiente, sem confundir duplicatas.
- Fechar a UI não grava milhares de tags nem percorre novamente a pasta. Atualizações de cache são incrementais.

### 9.3 Presets, backup e quotas

Revisar `scripts/presets_helper.py` para garantir que paths, biblioteca, playlists, histórico e preferências funcionais não sejam exportados como preset. Trocar tema não pode trocar música, fila, volume ou diretório.

Integrar o diretório durável ao backup local do shell; cache e socket ficam fora. Backup/restore não duplica arquivos de música por padrão: os documentos contêm referências e o usuário deve saber quando depende de arquivos externos. Importar playlists não copia músicas sem uma ação específica.

Definir limites verificáveis para histórico, recentes, workers, tamanho de JSON/LRC, capas e cache. Paginar biblioteca/fila em operações grandes; uma pasta com 10 mil músicas não deve gerar 10 mil `Image` ou 10 mil processos. Durante scan, prioridade para metadata da atual e das próximas visíveis.

## 10. Integrações e mapa de arquivos

### 10.1 Arquivos existentes a alterar por etapas

| Arquivo ou grupo | Alteração prevista |
| --- | --- |
| `modules/ii/background/MediaMode.qml` | Estados de fonte/vazio, ações de abrir, composição irmã letras/fila e controlador de layout |
| `modules/ii/background/MediaModeCoverArt.qml` | Dependências explícitas e capacidades; preservar visual e seek seguro |
| `modules/ii/background/MediaModeLyrics.qml` | Altura compacta, entradas de contexto se necessárias, suspensão de efeitos quando recolhido |
| `modules/ii/background/MediaModeLyricsFallback.qml` | Ações locais e encaixe no painel reexpandido sem letra |
| `modules/ii/background/BackgroundRoot.qml` | Abertura sem MPRIS para local, conexão central de requests, guards e saída animada segura |
| `GlobalStates.qml` | Pedido central de abrir/alternar por monitor; preservar contador, registro e fechamento atuais |
| `services/MprisController.qml` | Seleção explícita estável, bus próprio, atualização de metadata sem depender de capa |
| `services/LyricsService.qml` | Resolução por fonte/identidade e API compatível |
| `services/CustomLyricsStore.qml` | Ponte dos overrides legados; sem descartar dados existentes |
| `modules/common/utils/LrclibLyrics.qml` | Parser extraído e provider remoto separado da resolução local |
| `services/MusicVideoService.qml` | Gate por fonte, respeitar sessão local offline e identidade/unidades corretas nas fronteiras tocadas |
| `modules/common/Config.qml`, `Persistent.qml`, `Directories.qml` | Preferências visuais, dados funcionais leves, paths e defaults |
| `modules/settings/configs/MediaMusicConfig.qml` | Acesso à nova configuração funcional de música local |
| `modules/settings/configs/widgets/MediaModeBackgroundConfig.qml` | Opções de aparência/comportamento dos painéis |
| `services/QuickToggleRegistry.qml` | Modelo e palavras-chave de Media Player |
| `modules/common/quickToggles/androidStyle/QuickToggleCatalog.js` e `AndroidToggleDelegateChooser.qml` | Tipo e renderer Android |
| `modules/common/quickToggles/classicStyle/ClassicQuickToggleCatalog.js` e `ClassicToggleDelegateChooser.qml` | Tipo e renderer clássico |
| `modules/common/ShellActionRegistry.qml` | Ação canônica para busca/abertura, sem criar outro fluxo de estado |
| `scripts/presets_helper.py` e integração de backup | Isolamento dos dados pessoais e inclusão do store durável |
| `translations/*.json` e manifestos de instalação do repositório | Strings e dependências distribuíveis |

Alterar `shell.qml` apenas se a infraestrutura de serviços exigir referência global explícita. Primeiro verificar que o novo singleton não depende da vida do `MediaMode`; não instanciar singleton manualmente nem adicionar inicialização pesada ao boot.

### 10.2 Novas peças propostas

```text
services/LocalMediaService.qml
services/LocalLyricsService.qml
scripts/media/local_player.py
scripts/media/mpris_bridge.py
scripts/media/queue_store.py
scripts/media/library_index.py
scripts/media/local_lyrics.py
modules/common/functions/LyricsParser.js
modules/ii/background/MediaModePanelLayout.js
modules/ii/background/MediaModeQueue.qml
modules/ii/background/MediaModeQueueDelegate.qml
modules/ii/background/MediaModeFilePicker.qml
modules/ii/background/MediaModeLibrary.qml
modules/ii/background/MediaModeAudioOptions.qml
modules/common/models/quickToggles/MediaModeToggle.qml
modules/common/quickToggles/androidStyle/AndroidMediaModeToggle.qml
modules/common/quickToggles/classicStyle/MediaModeToggleButton.qml
modules/settings/configs/widgets/LocalMediaPlayerConfig.qml
scripts/tests/test_local_media_queue.py
scripts/tests/test_local_media_import.py
scripts/tests/test_local_media_persistence.py
scripts/tests/test_local_media_mpris.py
scripts/tests/test_local_lyrics.py
tests/mediaMode/
```

Componentes de domínio podem ser novos; controles básicos devem vir de `modules/common/widgets`. Usar `RippleButton`, `StyledText`, `MaterialSymbol`, `StyledSlider`, `StyledPopup` e scrollbar do projeto. Configurações interativas ficam como filhos diretos do `ColumnLayout` de `ContentSection`, sem controles dentro de `ContentSubsection`.

## 11. Fases de implementação

### Estratégia para preservar a versão atual

Fazer mudanças pequenas e verificáveis por fase. Primeiro extrair contratos mantendo a aparência e o comportamento externo; depois conectar o backend; por último acrescentar a composição condicional. Não substituir todos os widgets de mídia nem reescrever o background inteiro no mesmo passo.

Manter um gate de disponibilidade do player local durante desenvolvimento, separado de estado de reprodução e de presets visuais. A fonte externa deve continuar utilizável quando o backend local não estiver instalado ou falhar. Se for necessário desativar a integração para investigar uma regressão, conservar sessão/playlists no disco, oferecer parada explícita do áudio local e desligar apenas o recurso novo. Não usar restauração global do repositório nem apagar alterações de outras tarefas como mecanismo de recuperação.

O gate não dispensa os testes de seleção, metadata e lyrics compartilhados: as alterações no caminho externo precisam passar seus critérios em cada fase. Remover o estado experimental somente após a fase 9.

### Fase 0 — contratos e protótipo do backend

**Objetivo:** resolver riscos de processo, tipo MPRIS e fila antes de mexer no layout.

- Registrar a baseline estrutural e confirmar APIs dos binários locais/versão mínima suportada.
- Criar fixtures sintéticas pequenas: áudio com e sem tags/capa, MP3/FLAC/Opus/WAV, LRC/TXT, caminhos problemáticos e arquivo inválido.
- Provar, em ambiente isolado, mpv sem janela com play/pause/seek e duas faixas, eventos, IDs, mutações de ordem sem reiniciar a atual e EOF sem salto duplo.
- Provar exportação MPRIS por Python/Gio, unidades de tempo, identificação do bus e ausência de duplicação.
- Definir lock, encerramento de processo filho, política de hot reload e reconexão/handshake.
- Validar escolha de picker e limites de geometria a partir de componentes reais.

**Saída:** contrato versionado de comandos/eventos, decisão de backend confirmada e fixtures reutilizáveis.

**Aceite:** protótipo encerra todos os próprios processos; nenhuma janela nem som real é necessário para testes automatizados; uma falha de helper não cria segunda instância. Resolver qualquer impedimento aqui antes da UI.

### Fase 1 — desacoplar a apresentação e preparar a abertura vazia

**Depende:** fase 0.

- Explicitar player, arte, callbacks e contexto em `MediaModeCoverArt` e dependências necessárias de lyrics.
- Acrescentar intenção de fonte ao `MprisController`, conservando compatibilidade dos consumidores atuais.
- Unificar abertura/alternância para shortcut, quick toggle futuro e Raise MPRIS.
- Adaptar os três guards de player em `BackgroundRoot` para renderizar estado local vazio/erro sem superfície transparente órfã.
- Preservar registro idempotente, teardown de foco, close-all, monitor focado e restauração dos widgets.
- Criar estado vazio com Abrir música / Abrir pasta e placeholder coerente; nenhum backend toca automaticamente.

**Aceite:** modo de aplicativos mantém composição e controles; Super + Z abre sem player; fechar devolve foco e widgets; nenhum processo de áudio é iniciado só pela abertura.

### Fase 2 — reprodução local e integração sistêmica

**Depende:** fase 1.

- Implementar `LocalMediaService`, helper proprietário de mpv e exportação MPRIS.
- Play/pause/stop/seek/volume/next/previous por contrato único; capabilities refletem estado real.
- Conectar seleção explícita, resolver atraso entre helper pronto e descoberta D-Bus, evitar roubo de seleção por outros apps.
- Corrigir troca de metadata/capa sem arte e implementar erro recuperável de motor.
- Desacoplar completamente sessão de áudio do loader visual.
- Impedir pesquisa/reprodução de music video automática na fonte local por padrão, sem alterar preferência global da fonte externa.

**Aceite:** arquivo local toca, pausa e busca corretamente; barra/teclas MPRIS controlam o mesmo áudio; fechar/reabrir a UI mantém sessão; dois monitores compartilham um motor; avulsa não mostra fila.

### Fase 3 — arquivos, pastas, metadados e importação transacional

**Depende:** fase 2.

- Implementar picker de música/pasta, múltipla seleção, subpastas, cancelamento e drop pelo mesmo pipeline.
- Scanner incremental, ordenação determinística e cache de tags/capas.
- Distinguir `empty`, `single` e `playlist`, com commit somente de candidato válido.
- Ler/importar M3U/M3U8 locais e tratar URIs/caminhos sem shell.
- Adicionar detalhes de faixa e fallback para ausência de tags/arte.

**Aceite:** pasta grande pode ser cancelada sem destruir sessão anterior; pasta vazia não muda a música; metadata chega progressivamente; Unicode, symlinks, falta de permissões e arquivos inválidos têm tratamento explícito.

### Fase 4 — motor de fila e painel Próximas

**Depende:** fase 3.

- Implementar queueEntryId, histórico, ordem efetiva/base, shuffle e repeat com operações serializadas.
- Implementar tocar a seguir, append, reorder, remoção, limpar futuras, fim e erros por faixa.
- Criar `MediaModeQueue` virtualizado e inseri-lo abaixo das letras somente com `queueEligible`.
- Implementar busca de apresentação, menu de linha, retorno à atual e alterações incrementais do modelo.
- Começar com split estável/manual; automação por resultado de letras entra na fase seguinte.

**Aceite:** ordem desenhada é a ordem tocada; reordenar não reinicia áudio; duplicatas são independentes; última faixa não apaga a sessão; mudar para Spotify remove painel e espaçamento de fila.

### Fase 5 — letras locais e contração automática

**Depende:** fase 4.

- Extrair/testar parser; ler LRC/TXT/tags e associar overrides por trackId.
- Integrar resolução local em `LyricsService`, preservando API de barra e widgets.
- Implementar todos os estados, timeouts, cancelamentos, prioridade local e guard de respostas antigas.
- Criar controller de geometria e preferências auto/expanded/collapsed por painel.
- Recolher letras somente em resultado final sem conteúdo; redistribuir altura à fila; reexpandir em faixa com letra conforme intenção manual.
- Ajustar renderer focal à altura disponível e compactação de telas baixas.

**Aceite:** playlist offline tem letras locais; sem letra a fila se expande; durante busca não há oscilação; controles manuais prevalecem; uma avulsa ou fonte externa nunca adquire fila.

### Fase 6 — playlists salvas, biblioteca e retomada

**Depende:** fases 3–5.

- Store versionado de sessão e playlists, importação/exportação, nomes, duplicação, favoritos, recentes e marcadores.
- Biblioteca de pastas adicionadas explicitamente, busca e rescan limitado.
- Persistência atômica, proteção contra defaults, checkpoints e recuperação de arquivo inválido.
- Restauração pausada após restart, relocalização de arquivo e isolamento de presets.
- Integrar dados duráveis ao backup; documentar que as músicas continuam em seus diretórios originais.

**Aceite:** playlist/ordem/favoritos sobrevivem ao restart e à troca de preset; corrupção não sobrescreve original; cache pode ser descartado sem perder dados pessoais.

### Fase 7 — recursos de áudio e conveniência

**Depende:** fase 6.

- Implementar velocidade, ReplayGain, EQ com bypass, preamp/headroom, sleep timer e loop A–B.
- Validar gapless com pares de formatos compatíveis e fallback em mudança de parâmetros.
- Integrar acesso ao mixer e comportamento de saída/dispositivo removido.
- Posicionar opções avançadas em popups/subpáginas para não inflar toolbar ou card principal.

**Aceite:** valores neutros preservam áudio; controles atuam só no player local; offsets e letras seguem rate/seek; timer continua com janela fechada; recursos têm reset/bypass e estados de erro claros.

### Fase 8 — quick toggles, configurações, animações e acessibilidade

**Depende:** fases 5–7.

- Registrar o toggle nos dois catálogos/renderers e em `QuickToggleRegistry`/`ShellActionRegistry`.
- Mantê-lo disponível na gaveta do editor; não substituir páginas/ordem/IDs configurados pelo usuário.
- Manter binding Super + Z, contexto por monitor e estado destacado coerente.
- Criar configurações de aparência e funcionais em seus locais adequados, com traduções e deep links.
- Concluir transições de split, fonte, lista, menus, empty states e fechamento seguro.
- Implementar foco, teclado, tooltips, nomes acessíveis, navegação em fila e compactação responsiva.

**Aceite:** entrada por atalho/toggle chega à mesma sessão; não há overflow nos tamanhos-alvo; teclado opera sem mouse; animação desligada não deixa elementos invisíveis/desabilitados; nenhuma nova borda, pulse ou scale decorativo.

### Fase 9 — regressão, distribuição e documentação definitiva

**Depende:** todas as anteriores.

- Executar matriz da seção 12, incluindo consumers MPRIS existentes e regressões de janela/foco.
- Verificar empacotamento de mpv, PyGObject, Mutagen e ffmpeg por distribuição suportada; ausência de dependência gera aviso acionável e preserva modo externo.
- Medir fila grande, latência de importação, memória de texturas e número de processos após ciclos de abertura.
- Atualizar `AGENTS.md` com arquitetura implementada, ownership, unidades, fila condicional e state machine dos painéis; atualizar seu sumário com linhas reais.
- Revisar docs antigas conflitantes somente no contexto tocado, identificando o comportamento atual.

**Aceite:** requisitos centrais e regressões passam; limitações reais ficam registradas; nenhuma feature apenas planejada é documentada como entregue.

## 12. Estratégia de validação

### 12.1 Restrições desta tarefa e das verificações

Nesta análise não executar chamadas IPC do Quickshell, capturas de tela do computador, reinício do shell ou playback. A validação futura prioriza testes puros, QML isolado/offscreen, fixtures e revisão de geometria. Não iniciar outra instância de `qs` enquanto houver uma ativa.

Testes de integração do **backend de áudio** podem usar mpv com saída nula e bus D-Bus privado, sem tocar na sessão desktop. O socket JSON desse backend é distinto do IPC do Quickshell. Não usar `qs -p` como harness. Comandos de testes e caminhos de import QML devem ser confirmados no ambiente antes de registrá-los como executáveis.

Para observação de logs durante a implementação, seguir a verificação de instâncias e logs permitida pelo `AGENTS.md`, sem acionar IPC ou capturas. Verificação visual/interativa final pode ser feita pelo usuário nos fluxos descritos, sem automatizar o computador. Não alegar validação visual de layout apenas porque lint passou.

### 12.2 Testes automatizados úteis

| Camada | Casos que precisam de evidência |
| --- | --- |
| Fila pura | IDs duplicados, move/next concorrentes, remoção atual/futura, repeat, shuffle determinístico, EOF único e erro em todas as faixas |
| Scanner | Unicode/espaços/hífen, URI encoding, subpastas, symlink cíclico, cancelamento, pasta vazia, arquivo truncado e duração desconhecida |
| Persistência | Writes atômicos, JSON inválido, FileNotFound transitório, versão desconhecida, restauração pausada, store vazio e escritor concorrente |
| Letras | LRC múltiplas tags/offsets/CRLF, texto plain, tags embutidas, rede desligada, título igual em arquivos diferentes e resposta antiga |
| Layout puro/QML | Matriz de elegibilidade, alturas não negativas, mínimos, recolhimento manual, resultado tardio, ambos recolhidos e modo compacto |
| MPRIS em bus isolado | Tipos D-Bus, tempo segundos↔microssegundos, Seeked, SetPosition de faixa antiga, capabilities, seleção e desaparecimento do bus |
| Lifecycle | UI fechada não para áudio, uma sessão em dois monitores, crash/EOF sem órfãos e cleanup do socket próprio |
| Quick toggles | Registro Android/clássico, catálogo consistente, IDs preservados, abrir/fechar sem mexer na paginação existente |
| Presets/backup | Não exportar pastas/fila/histórico como visual; backup inclui dados duráveis e exclui cache/socket |

Não se limitar a testes que procuram strings no QML. A lógica de fila, layout e protocolo precisa ser exercitada com entradas/saídas e transições reais. Contratos estáticos complementam esses testes para preservar as invariantes arquiteturais.

### 12.3 Matriz de aceite funcional

| Cenário | Resultado esperado |
| --- | --- |
| Nenhum aplicativo MPRIS; Super + Z | Estado local vazio utilizável, com abrir música/pasta |
| Uma música local avulsa com LRC | Áudio, capa/metadata e letras; fila ausente |
| Pasta com 1 faixa | Contexto playlist com fila válida, mesmo sem próxima |
| Playlist com letra sincronizada | Letras acima; próximas abaixo; ambos utilizáveis |
| Playlist com apenas texto simples | Letras roláveis; fila permanece abaixo |
| Playlist sem qualquer letra | Cabeçalho compacto de letras; fila ocupa restante |
| Busca online lenta | Loading estável; não oscila para notFound |
| Busca falhou por timeout | Cabeçalho Erro/Tentar novamente; fila expandida |
| Usuário expande letras sem resultado | Fallback permanece aberto até nova ação manual/automático |
| Usuário recolhe fila | Cabeçalho fica acessível; letras recebem espaço |
| Troca sem letra → com letra em auto | Letras reabrem com transição |
| Mesma troca em manual collapsed | Letras ficam recolhidas |
| Spotify/Firefox com fila local guardada | Fila totalmente ausente na fonte externa |
| Voltar à fonte local | Sessão e escolhas manuais recuperadas |
| Letras globalmente ocultas + playlist | Fila usa toda a direita; não desaparece junto com showLyrics |
| Fechar Media Mode durante playback | Áudio segue; foco e widgets voltam |
| Reabrir em outro monitor | Mesmo áudio/fila, layout adequado ao monitor |
| Monitor removido durante animação | Registro limpo, sem áudio duplicado e sem janela órfã |
| Tela bloqueada | Nenhuma UI local acima da lockscreen; áudio segue política existente |
| Abrir importação B antes de A terminar | Somente candidato vigente pode fazer commit |
| Arquivo removido/desmontagem | Ocorrência indisponível, recuperação explícita |
| 10 mil faixas com capas grandes | Lista virtualizada, scan cancelável, cache limitado |
| Preset/sharp mode/animações zero | Estado musical preservado; cantos/cores/movimento corretos |

### 12.4 Layout e desempenho a conferir

Testar dimensões lógicas representativas: 1280×720, 1366×768, 1920×1080, ultrawide e monitor retrato; escalas 1×/1,5×/2× conforme ambiente isolado disponível. Incluir títulos extensos, nomes de artistas longos, letras com múltiplas linhas/RTL, muitas fontes MPRIS e fonte ampliada.

Critérios: zero overflow sobre fechar/transporte; nenhum binding loop; zero textura de capa em tamanho original desnecessário; somente delegates próximos ao viewport; sem consulta de rede por monitor; nenhuma thread QML bloqueada por scan; memória e processos retornam ao patamar esperado ao fechar janelas/encerrar sessão. Medir antes/depois na fase 9 e estabelecer budgets a partir da baseline, sem inventar números de desempenho não observados.

## 13. Riscos prioritários e mitigação

| Risco | Mitigação | Fase que o resolve |
| --- | --- | --- |
| Quebrar todos os widgets ao substituir `MprisPlayer` por objeto falso | Exportação MPRIS real e API legada preservada | 0–2 |
| Abrir overlay vazio que captura input | Estado vazio renderizado, guards por intenção e foco liberado antes de teardown | 1 |
| Dois motores em hot reload/multimonitor | Serviço único, lock/handshake e PID proprietário | 0–2 |
| Outra aplicação roubar fonte local | Seleção explícita central e teste de eventos externos | 2 |
| Fila da UI divergir da ordem tocada | Escritor único, revisions e reconciliação por IDs | 0, 4 |
| Colapso de letras oscilar/ignorar usuário | Estado terminal separado de loading e precedência manual | 5 |
| Perder cinco linhas focais ao inserir fila | Geometria medida, fonte/viewport adaptados e variante compacta | 5, 8 |
| Letra/capa da faixa anterior aparecer na seguinte | Identidade completa, geração de pedido e limpeza de fallback | 2, 5 |
| Travar ao abrir biblioteca grande | Workers limitados, importação transacional e modelo virtualizado | 3–6 |
| Perder biblioteca ao trocar preset | Dados funcionais em Persistent/store próprio e teste do sanitizer | 6 |
| Music video buscar rede ou disputar recursos no local | Gate de fonte offline e motor/socket totalmente independentes | 2 |
| Dependência existir só nesta máquina | Detecção e revisão dos manifestos, fallback externo funcional | 0, 9 |

## 14. Checklist final de entrega

- [ ] Super + Z preservado e Media Player disponível nos quick toggles Android/clássico.
- [ ] Abre sem qualquer player externo e oferece música/pasta.
- [ ] Fechar a UI não encerra a reprodução local.
- [ ] Barra, widgets e teclas multimídia operam o mesmo player via MPRIS.
- [ ] Fila só aparece na fonte local com contexto de playlist aberto.
- [ ] Avulsa não mostra fila; playlist de uma faixa continua playlist.
- [ ] Letras locais funcionam offline e distinguem faixas homônimas.
- [ ] Ausência de letra recolhe Letras e expande Próximas, após conclusão da busca.
- [ ] Controles manuais de ambas as seções prevalecem até Voltar ao automático.
- [ ] Reprodução, ordem, playlists, biblioteca e opções de áudio da seção 8 entregues.
- [ ] Composição externa atual preservada; direita dividida sem card externo ou bordas.
- [ ] Transições completas, interrompíveis e compatíveis com animação zero.
- [ ] Sem processo por monitor, IPC Quickshell de automação ou capturas de tela.
- [ ] Estado durável protegido de escrita inicial, corrupção e troca de preset.
- [ ] Matriz de testes executada com resultados e limitações registrados.
- [ ] `AGENTS.md` atualizado somente após implementação, incluindo sumário correto.

O marco inicial recomendado é fechar as fases 0–2: provar áudio local integrado por MPRIS e preservar o ciclo de vida atual. Depois, acrescentar importação, fila e resolução de letras sobre essa base estável, seguindo as fases até o aceite completo.
