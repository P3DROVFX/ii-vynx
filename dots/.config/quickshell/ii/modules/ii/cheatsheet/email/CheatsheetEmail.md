# Manual Técnico Exaustivo: Módulo de Email (II-Vynx)

Este documento é a especificação técnica definitiva para o módulo de Email. Ele serve como o "Cérebro" para desenvolvedores e agentes de IA, detalhando cada componente, script e lógica de animação de alta fidelidade implementada.

---

## 1. Visão Geral do Sistema

O módulo de Email do II-Vynx foi projetado para oferecer uma experiência de desktop que rivaliza com aplicativos nativos de dispositivos móveis de alta performance. Ele utiliza os princípios do **Material Design 3 (Expressive)** combinados com uma física de materiais personalizada inspirada no **Android 16**.

---

## 2. O Coração: `EmailService.qml` (Serviço Singleton)

Localizado em `services/EmailService.qml`, este componente é o único ponto de verdade para dados e estado.

### Arquitetura de Dados
O serviço gerencia múltiplos `ListModel` de forma assíncrona:
- `inboxMessages`: Fluxo principal de entrada.
- `sentMessages`: Mensagens enviadas.
- `spamMessages`: Mensagens filtradas como spam.
- `starredMessages`: Mensagens marcadas com estrela.
- `importantMessages`: Marcadas como importantes pelo Google.
- `purchasesMessages`: Recibos e transações.
- `labels`: Lista dinâmica de etiquetas customizadas do usuário.

### Mecanismos de Sincronização
- **Paralelismo**: O serviço dispara múltiplos processos `Process` simultaneamente para buscar cada categoria, evitando gargalos.
- **Debounce**: Mudanças em configurações (como visibilidade de pastas) disparam um timer de debounce de 1 segundo para evitar chamadas de API excessivas.
- **Auto-Refresh**: Timer configurável (padrão 15 min) que mantém a lista atualizada sem intervenção do usuário.

### Gerenciamento de Tokens
O serviço lida com a segurança de forma rigorosa:
- `KeyringStorage`: Armazena o `gmail_refresh_token` de forma segura.
- `token_refresh.py`: Script Python invocado automaticamente antes de qualquer fetch se o Access Token estiver expirado ou prestes a expirar.

---

## 3. Experiência de Inbox (`EmailInbox.qml`)

Esta é a peça mais complexa de engenharia visual do projeto.

### A. Física de Swipe (Arrasto e Descarte)
Implementamos uma física de descarte binária para máxima eficiência UX.

- **Fase de Arrasto (1:1)**: Durante o movimento do mouse, a propriedade `swiping` é ativada, desabilitando todos os `Behaviors` de animação. Isso garante que o card acompanhe o cursor com latência zero.
- **Threshold de Decisão**: Definido em `-220px`.
- **Animação de Snap**:
  - Se `releaseX > -220`: O `snapAnim` usa `Easing.OutCubic` em 350ms para retornar ao centro.
  - Se `releaseX <= -220`: O card completa a saída e o `EmailService.trashMessage` é invocado.

### B. Efeito Magnético (Android 16 Style)
A lista reage ao movimento de um único item como uma membrana elástica.
- **Rastreamento**: `root.swipingIndex` e `root.activeSwipeX` propagam o estado de movimento para toda a lista.
- **Lógica de Vizinhos**:
  ```qml
  readonly property real magneticOffset: {
      if (root.swipingIndex === -1 || root.swipingIndex === index) return 0;
      if (Math.abs(root.swipingIndex - index) === 1) {
          // Puxa vizinhos em 15% da distância, limitado a 30px
          return Math.max(-30, root.activeSwipeX * 0.15);
      }
      return 0;
  }
  ```
- **Resultado**: Os emails adjacentes "escorregam" levemente na mesma direção, criando uma sensação de materialidade física única.

### C. Metamorfose Dinâmica (Morphing Radius)
O card do email não é estático. Ele "muda de forma" conforme é manipulado.
- **Equação de Morphing**: `Math.min(height / 2, Math.abs(swipeX) * 0.5)`.
- **Efeito**: O email transita de cantos suavemente arredondados para uma pílula completa (pill shape) proporcionalmente ao swipe. Isso sincroniza o email com a lixeira que aparece por trás, que também é uma pílula.

### D. Feedback de Clique e Radius
- **Bounce Tátil**: Ao clicar, o card escala para `0.98`. Ao soltar, o `Appearance.animation.clickBounce` cria um efeito de "mola" ao voltar para `1.0`.
- **Consciência de Vizinhos no Clique**: Se um email é clicado, os vizinhos arredondam seus cantos adjacentes para criar uma separação visual clara, simulando a compressão de um material flexível.

---

## 4. Sidebar e Navegação (`EmailSidebar.qml` & `EmailNavButton.qml`)

A sidebar reflete o mesmo cuidado com a física de materiais do Inbox.

### A. Botões de Navegação Adaptativos
Os `EmailNavButton` implementam a lógica de "arredondamento por proximidade":
- Se um botão é selecionado ou pressionado, ele se torna uma pílula (`radius: full`).
- Os botões acima e abaixo detectam essa pressão (`isAbovePressed`/`isBelowPressed`) e arredondam seus cantos de contato para `height/2`.
- Isso cria o efeito de "bolha" que flui pela barra lateral.

### B. Search Box (Barra de Busca)
Reconstruída do zero para ser elegante e responsiva:
- **Camadas de Estilo**: Fundo `transparent` + Borda `1px` (`colOutlineVariant`).
- **Feedback de Hover**: Um `Rectangle` interno com `opacity: 0.05` surge suavemente, e a borda muda para `colOutline`.
- **Cursores**: Implementação obrigatória de `Qt.IBeamCursor` para indicar área de texto.

---

## 5. Fluxo de Autenticação (`EmailAuth.qml` & Scripts)

O onboarding é um balé entre QML e scripts Python.

1. **`EmailAuth.qml`**: Exibe o botão "Connect Account" com animações de morphing no ícone principal (transição entre SoftBurst e Cookie shapes).
2. **`oauth_server.py`**: Inicia um servidor HTTP temporário na porta 8080.
3. **Google Handshake**: Abre o navegador. Após a permissão do usuário, o Google redireciona para `localhost:8080`, onde o script captura o `code`.
4. **Token Exchange**: O script troca o `code` pelo `refresh_token` e o envia ao Quickshell via IPC.
5. **Finalização**: O `EmailService` recebe o token, salva no Keyring e inicia o primeiro `syncAll()`.

---

## 6. Configurações e Customização (`EmailSettings.qml`)

Oferece controle total sobre a experiência:
- **Visibilidade de Pastas**: Switches para cada categoria. A lógica garante que o "Inbox" nunca seja desativado.
- **Intervalo de Refresh**: Spinbox para ajustar a periodicidade das buscas.
- **Densidade**: Opções para ajustar a quantidade de emails exibidos (padrão 50).
- **Gestão de Conta**: Botão "Remove Account" para limpeza completa de credenciais e cache.

---

## 7. Guia Estendido: Tradução de Paradigma (Tailwind to QML)

Para desenvolvedores Web que conhecem Tailwind, este é o dicionário de tradução para os tokens do II-Vynx:

| Conceito Tailwind | Implementação II-Vynx QML | Exemplo de Uso |
| :--- | :--- | :--- |
| `bg-surface-100` | `Appearance.colors.colSurfaceContainerHigh` | `color: Appearance.colors.colSurfaceContainerHigh` |
| `rounded-lg` | `Appearance.rounding.large` | `radius: Appearance.rounding.large` |
| `hover:bg-opacity-10` | `opacity: mouseArea.containsMouse ? 0.1 : 0` | `Behavior on opacity { ... }` |
| `animate-bounce` | `Appearance.animation.clickBounce` | `animation: Appearance.animation.clickBounce.numberAnimation` |
| `transition-colors` | `Behavior on color` | `ColorAnimation { duration: 200 }` |
| `cursor-pointer` | `cursorShape: Qt.PointingHandCursor` | `MouseArea { cursorShape: Qt.PointingHandCursor }` |

---

## 8. Boas Práticas e Manutenção (Guia do Agente)

1. **Clonagem de Efeitos**: Se criar um novo botão, sempre use a combinação de `scale` e `clickBounce` para consistência tátil.
2. **Clipping Seguro**: Evite `clip: true` em elementos arredondados. Use `layer.effect: OpacityMask` para bordas perfeitas e antialiasing superior.
3. **Behaviors e Swipe**: **NUNCA** coloque `Behavior on x` em elementos que são alvo de drag manual. O conflito entre a atualização do mouse e a animação do Behavior causa "jiggles" visuais.
4. **Z-Index**: Lembre-se que em QML, o último elemento declarado fica no topo. No swipe-to-delete, o botão de deletar deve vir **antes** do container do email no código.

---

## 9. Roadmap e Futuro

O sistema está preparado para as seguintes expansões:
- **Notificações Ricas**: Mostrar o conteúdo do email diretamente na área de notificações com ações rápidas.
- **Anexos**: Interface para listagem e download de arquivos vinculados.
- **Busca Remota**: Barra de busca da sidebar disparando queries diretas via `fetch_emails.py` com o parâmetro `q`.
- **Rascunhos (Drafts)**: Suporte para sincronização de rascunhos em tempo real.
