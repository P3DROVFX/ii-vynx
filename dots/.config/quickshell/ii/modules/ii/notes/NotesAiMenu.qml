pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.services.ai
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.notes

/**
 * AI context menu for the Notes app.
 *
 * Offers categorized single-turn tasks:
 * - 8 rewriting tones (Professional, Casual, Direct, Academic, Empathetic, Poetic, Humorous, Persuasive)
 * - Editing & improvement (Grammar/style fix, summarize paragraph/bullets/TL;DR, expand, continue writing)
 * - Transformations (checklist, markdown table, extract action items, translate)
 * - Code-specific actions (explain, bug hunter, optimize, convert language)
 * - Note-wide actions (generate title, tags, executive summary callout, topic structure)
 * - Custom user-defined styles (persisted in Persistent.states.notes.aiCustomStyles)
 * - Out-of-band ask in sidebar AI chat
 *
 * Strictly respects Config.options.policies.ai:
 * - When 0: completely hidden.
 * - When 2: restricted to local Ollama models.
 */
Item {
    id: root

    property var editor: null
    property string targetText: ""
    property string targetScope: "selection" // "selection" | "block" | "note"
    property string targetBlockId: ""
    property string activeCategory: "tones" // "tones" | "improve" | "transform" | "note" | "code" | "custom"

    signal actionRequested(string taskName, string systemPrompt, string userText, var meta)
    signal chatRequested(string contextText)
    signal closed()

    visible: Number(Config.options?.policies?.ai ?? 1) !== 0

    // Prevent clicks from falling through to the editor underneath
    MouseArea {
        anchors.fill: parent
        onClicked: {}
    }

    readonly property bool isCodeBlock: root.editor && root.editor.activeBlock && root.editor.activeBlock.type === "code"
    readonly property int policy: Number(Config.options?.policies?.ai ?? 1)
    readonly property bool localOnly: root.policy === 2

    // Current active model name
    /// `Ai.currentModel` is the model's *value* — a string — so `.title` on it was
    /// always undefined and this badge always read "AI". The entry is the object.
    readonly property string currentModelName: {
        const entry = Ai.currentModelEntry;
        if (!entry)
            return Translation.tr("No model");
        return entry.title.length > 0 ? entry.title : (entry.name.length > 0 ? entry.name : Ai.currentModel);
    }
    readonly property bool isLocalModel: Ai.currentModelEntry
        ? Ai.catalog.isModelLocal(Ai.currentModelEntry)
        : false

    // Custom styles management
    property var customStylesList: []

    function reloadCustomStyles() {
        const raw = Persistent.states.notes?.aiCustomStyles ?? [];
        const parsed = [];
        for (let i = 0; i < raw.length; i++) {
            try {
                const item = JSON.parse(raw[i]);
                if (item && item.name && item.prompt)
                    parsed.push(item);
            } catch (e) {
                // Ignore corrupt custom style entries
            }
        }
        root.customStylesList = parsed;
    }

    function saveNewCustomStyle(name, prompt) {
        if (!name || !prompt)
            return;
        const current = (Persistent.states.notes?.aiCustomStyles ?? []).slice();
        current.push(JSON.stringify({ name: name.trim(), prompt: prompt.trim() }));
        Persistent.states.notes.aiCustomStyles = current;
        root.reloadCustomStyles();
    }

    function deleteCustomStyle(index) {
        const current = (Persistent.states.notes?.aiCustomStyles ?? []).slice();
        if (index >= 0 && index < current.length) {
            current.splice(index, 1);
            Persistent.states.notes.aiCustomStyles = current;
            root.reloadCustomStyles();
        }
    }

    Component.onCompleted: root.reloadCustomStyles()

    // ── Dialog Container ──────────────────────────────────────────────────
    Rectangle {
        id: menuCard
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: Appearance.m3colors.m3surfaceContainerHighest
        clip: true

        StyledRectangularShadow {
            target: menuCard
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // ── Header ────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialSymbol {
                    text: "auto_awesome"
                    iconSize: 22
                    color: Appearance.colors.colTertiary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: Translation.tr("Ask the AI")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer0
                    }

                    RowLayout {
                        spacing: 6

                        // Scope chip
                        Rectangle {
                            implicitHeight: 18
                            implicitWidth: scopeLabel.implicitWidth + 10
                            radius: Appearance.rounding.small
                            color: Appearance.colors.colSecondaryContainer

                            StyledText {
                                id: scopeLabel
                                anchors.centerIn: parent
                                text: {
                                    if (root.targetScope === "selection")
                                        return Translation.tr("Selection (%1 chars)").arg(root.targetText.length);
                                    if (root.isCodeBlock)
                                        return Translation.tr("Code block");
                                    if (root.targetScope === "block")
                                        return Translation.tr("Current block");
                                    return Translation.tr("Full note (%1 chars)").arg(root.targetText.length);
                                }
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                        }

                        // Model badge
                        Rectangle {
                            implicitHeight: 18
                            implicitWidth: modelLabel.implicitWidth + 14
                            radius: Appearance.rounding.small
                            color: root.isLocalModel
                                ? Appearance.m3colors.m3primaryContainer
                                : Appearance.colors.colLayer2

                            RowLayout {
                                id: modelLabel
                                anchors.centerIn: parent
                                spacing: 4

                                Rectangle {
                                    implicitWidth: 6
                                    implicitHeight: 6
                                    radius: 3
                                    color: root.isLocalModel
                                        ? Appearance.colors.colPrimary
                                        : Appearance.colors.colTertiary
                                }

                                StyledText {
                                    text: root.currentModelName
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: root.isLocalModel
                                        ? Appearance.m3colors.m3onPrimaryContainer
                                        : Appearance.colors.colOnLayer1
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 110
                                }
                            }
                        }
                    }
                }

                NotesIconButton {
                    symbol: "close"
                    size: 32
                    iconSize: 18
                    tooltipText: Translation.tr("Close")
                    onTriggered: root.closed()
                }
            }

            // ── Category Navigation Bar ───────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    buttonRadius: Appearance.rounding.small
                    toggled: root.activeCategory === "tones"
                    colBackground: Appearance.colors.colLayer1
                    colBackgroundToggled: Appearance.colors.colSecondaryContainer
                    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                    onClicked: root.activeCategory = "tones"

                    contentItem: StyledText {
                        anchors.centerIn: parent
                        text: Translation.tr("Tones")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: root.activeCategory === "tones" ? Font.DemiBold : Font.Normal
                        color: root.activeCategory === "tones" ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                    }
                }

                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    buttonRadius: Appearance.rounding.small
                    toggled: root.activeCategory === "improve"
                    colBackground: Appearance.colors.colLayer1
                    colBackgroundToggled: Appearance.colors.colSecondaryContainer
                    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                    onClicked: root.activeCategory = "improve"

                    contentItem: StyledText {
                        anchors.centerIn: parent
                        text: Translation.tr("Improve")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: root.activeCategory === "improve" ? Font.DemiBold : Font.Normal
                        color: root.activeCategory === "improve" ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                    }
                }

                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    buttonRadius: Appearance.rounding.small
                    toggled: root.activeCategory === "transform"
                    colBackground: Appearance.colors.colLayer1
                    colBackgroundToggled: Appearance.colors.colSecondaryContainer
                    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                    onClicked: root.activeCategory = "transform"

                    contentItem: StyledText {
                        anchors.centerIn: parent
                        text: Translation.tr("Transform")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: root.activeCategory === "transform" ? Font.DemiBold : Font.Normal
                        color: root.activeCategory === "transform" ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                    }
                }

                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    buttonRadius: Appearance.rounding.small
                    toggled: root.activeCategory === "note"
                    colBackground: Appearance.colors.colLayer1
                    colBackgroundToggled: Appearance.colors.colSecondaryContainer
                    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                    onClicked: root.activeCategory = "note"

                    contentItem: StyledText {
                        anchors.centerIn: parent
                        text: Translation.tr("Note")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: root.activeCategory === "note" ? Font.DemiBold : Font.Normal
                        color: root.activeCategory === "note" ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                    }
                }

                RippleButton {
                    visible: root.isCodeBlock
                    Layout.fillWidth: true
                    implicitHeight: 30
                    buttonRadius: Appearance.rounding.small
                    toggled: root.activeCategory === "code"
                    colBackground: Appearance.colors.colLayer1
                    colBackgroundToggled: Appearance.colors.colSecondaryContainer
                    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                    onClicked: root.activeCategory = "code"

                    contentItem: StyledText {
                        anchors.centerIn: parent
                        text: Translation.tr("Code")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: root.activeCategory === "code" ? Font.DemiBold : Font.Normal
                        color: root.activeCategory === "code" ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                    }
                }

                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    buttonRadius: Appearance.rounding.small
                    toggled: root.activeCategory === "custom"
                    colBackground: Appearance.colors.colLayer1
                    colBackgroundToggled: Appearance.colors.colSecondaryContainer
                    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                    onClicked: root.activeCategory = "custom"

                    contentItem: StyledText {
                        anchors.centerIn: parent
                        text: Translation.tr("Custom")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: root.activeCategory === "custom" ? Font.DemiBold : Font.Normal
                        color: root.activeCategory === "custom" ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                    }
                }
            }

            // ── Action List Area ──────────────────────────────────────────
            Flickable {
                id: flick
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: contentCol.implicitHeight
                clip: true

                ColumnLayout {
                    id: contentCol
                    width: flick.width
                    spacing: 4

                    // ── Category 1: Tones (8 tones) ───────────────────────
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.activeCategory === "tones"
                        spacing: 4

                        Repeater {
                            model: [
                                { id: "professional", name: Translation.tr("Professional"), icon: "work",
                                  prompt: "Reescreva o texto a seguir em tom profissional, refinado e corporativo. Retorne apenas o texto reescrito, sem saudações ou explicações adicionais." },
                                { id: "casual", name: Translation.tr("Casual"), icon: "chat",
                                  prompt: "Reescreva o texto a seguir em tom casual, descontraído e amigável, mantendo a clareza. Retorne apenas o texto reescrito." },
                                { id: "direct", name: Translation.tr("Direct and short"), icon: "bolt",
                                  prompt: "Reescreva o texto a seguir de forma direta, concisa e objetiva, eliminando palavras vazias e prolixidade. Retorne apenas o texto direto." },
                                { id: "academic", name: Translation.tr("Academic"), icon: "school",
                                  prompt: "Reescreva o texto a seguir em tom acadêmico formal, utilizando vocabulário rigoroso e estrutura precisa. Retorne apenas o texto reescrito." },
                                { id: "empathetic", name: Translation.tr("Empathetic"), icon: "favorite",
                                  prompt: "Reescreva o texto a seguir com tom acolhedor, empático, compreensivo e humano. Retorne apenas o texto reescrito." },
                                { id: "poetic", name: Translation.tr("Poetic"), icon: "auto_stories",
                                  prompt: "Reescreva o texto a seguir com lirismo, elegância estilística e tom poético sutil. Retorne apenas o texto reescrito." },
                                { id: "humorous", name: Translation.tr("Humorous"), icon: "mood",
                                  prompt: "Reescreva o texto a seguir adicionando um toque de humor inteligente, leve e bem-humorado. Retorne apenas o texto reescrito." },
                                { id: "persuasive", name: Translation.tr("Persuasive"), icon: "campaign",
                                  prompt: "Reescreva o texto a seguir de forma persuasiva e convincente, ressaltando valor e clareza de argumentos. Retorne apenas o texto persuasivo." }
                            ]

                            delegate: RippleButton {
                                id: toneBtn
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 38
                                buttonRadius: Appearance.rounding.small
                                colBackground: Appearance.colors.colLayer1
                                colBackgroundHover: Appearance.colors.colLayer1Hover

                                contentItem: RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    MaterialSymbol {
                                        text: toneBtn.modelData.icon
                                        iconSize: 18
                                        color: Appearance.colors.colPrimary
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: toneBtn.modelData.name
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnLayer0
                                    }

                                    MaterialSymbol {
                                        text: "arrow_forward"
                                        iconSize: 16
                                        color: Appearance.colors.colOnLayer1Inactive
                                    }
                                }

                                onClicked: {
                                    root.actionRequested(
                                        Translation.tr("Rewrite (%1)").arg(toneBtn.modelData.name),
                                        toneBtn.modelData.prompt,
                                        root.targetText,
                                        { action: "rewrite", mode: root.targetScope, blockId: root.targetBlockId }
                                    );
                                }
                            }
                        }
                    }

                    // ── Category 2: Improve & Edit ────────────────────────
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.activeCategory === "improve"
                        spacing: 4

                        Repeater {
                            model: [
                                { id: "grammar", name: Translation.tr("Fix the grammar"), icon: "spellcheck",
                                  desc: Translation.tr("Corrects typos, punctuation and grammar while preserving original tone."),
                                  prompt: "Corrija rigorosamente todos os erros de ortografia, acentuação, gramática e concordância do texto a seguir. Mantenha integralmente o sentido, vocabulário e estilo original. Retorne unicamente o texto corrigido, sem preâmbulos." },
                                { id: "sum_para", name: Translation.tr("Summarize in 1 Paragraph"), icon: "short_text",
                                  desc: Translation.tr("Synthesizes the core message in one well-structured paragraph."),
                                  prompt: "Resuma as principais ideias do texto a seguir em um único parágrafo fluido, claro e conciso. Retorne apenas o parágrafo." },
                                { id: "sum_bullets", name: Translation.tr("Summarize as Bullet Points"), icon: "format_list_bulleted",
                                  desc: Translation.tr("Extracts key takeaways into a concise markdown bullet list."),
                                  prompt: "Extraia os pontos fundamentais do texto a seguir em uma lista sucinta de tópicos em Markdown (- item). Retorne apenas a lista." },
                                { id: "sum_tldr", name: Translation.tr("1-Line TL;DR"), icon: "summarize",
                                  desc: Translation.tr("One punchy sentence summarizing everything."),
                                  prompt: "Escreva um resumo ultra-conciso (TL;DR) do texto a seguir em exatamente UMA única frase direta. Retorne apenas a frase." },
                                { id: "expand", name: Translation.tr("Expand & Develop"), icon: "unfold_more",
                                  desc: Translation.tr("Deepens ideas with more depth, clarity and context."),
                                  prompt: "Desenvolva e aprofunde as ideias e argumentos do texto a seguir, agregando contexto explicativo, clareza e riqueza de detalhes, sem fugir do tema nem mudar o tom. Retorne apenas o texto expandido." },
                                { id: "continue", name: Translation.tr("Keep writing it"), icon: "edit_note",
                                  desc: Translation.tr("Completes the thought from the end of the text."),
                                  prompt: "Continue a escrita do texto a seguir a partir de onde ele parou, dando sequência lógica, coerente e natural ao pensamento e completando o raciocínio. Retorne apenas o trecho continuado." }
                            ]

                            delegate: RippleButton {
                                id: improveBtn
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 46
                                buttonRadius: Appearance.rounding.small
                                colBackground: Appearance.colors.colLayer1
                                colBackgroundHover: Appearance.colors.colLayer1Hover

                                contentItem: RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    MaterialSymbol {
                                        text: improveBtn.modelData.icon
                                        iconSize: 20
                                        color: Appearance.colors.colPrimary
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        StyledText {
                                            text: improveBtn.modelData.name
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colOnLayer0
                                        }

                                        StyledText {
                                            text: improveBtn.modelData.desc
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            color: Appearance.colors.colSubtext
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    MaterialSymbol {
                                        text: "arrow_forward"
                                        iconSize: 16
                                        color: Appearance.colors.colOnLayer1Inactive
                                    }
                                }

                                onClicked: {
                                    root.actionRequested(
                                        improveBtn.modelData.name,
                                        improveBtn.modelData.prompt,
                                        root.targetText,
                                        { action: improveBtn.modelData.id, mode: root.targetScope, blockId: root.targetBlockId }
                                    );
                                }
                            }
                        }
                    }

                    // ── Category 3: Transform ─────────────────────────────
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.activeCategory === "transform"
                        spacing: 4

                        Repeater {
                            model: [
                                { id: "checklist", name: Translation.tr("Convert to Checklist"), icon: "checklist",
                                  prompt: "Transforme o texto a seguir em uma checklist de tarefas em formato Markdown (- [ ] item). Seja claro e conciso. Retorne apenas a lista de itens." },
                                { id: "table", name: Translation.tr("Convert to Markdown Table"), icon: "table_chart",
                                  prompt: "Transforme os dados, comparações ou informações do texto a seguir em uma tabela Markdown limpa e bem formatada, com cabeçalho. Retorne apenas a tabela em Markdown." },
                                { id: "actions", name: Translation.tr("Pull out the actions"), icon: "task_alt",
                                  prompt: "Identifique e extraia todas as tarefas, pendências e ações práticas mencionadas no texto a seguir, formulando uma lista organizada de afazeres em Markdown (- [ ] ação). Retorne apenas os itens de ação." },
                                { id: "tr_en", name: Translation.tr("Translate to English"), icon: "translate",
                                  prompt: "Translate the following text into fluent, natural English. Keep markdown formatting and structure. Return only the translated text." },
                                { id: "tr_pt", name: Translation.tr("Translate to Portuguese (PT-BR)"), icon: "translate",
                                  prompt: "Traduza o texto a seguir para português brasileiro fluente, idiomático e natural. Mantenha a estrutura Markdown. Retorne apenas o texto traduzido." },
                                { id: "tr_es", name: Translation.tr("Translate to Spanish"), icon: "translate",
                                  prompt: "Traduce el siguiente texto a español fluido y natural. Mantén el formato Markdown. Devuelve únicamente el texto traducido." }
                            ]

                            delegate: RippleButton {
                                id: transformBtn
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 38
                                buttonRadius: Appearance.rounding.small
                                colBackground: Appearance.colors.colLayer1
                                colBackgroundHover: Appearance.colors.colLayer1Hover

                                contentItem: RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    MaterialSymbol {
                                        text: transformBtn.modelData.icon
                                        iconSize: 18
                                        color: Appearance.colors.colPrimary
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: transformBtn.modelData.name
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnLayer0
                                    }

                                    MaterialSymbol {
                                        text: "arrow_forward"
                                        iconSize: 16
                                        color: Appearance.colors.colOnLayer1Inactive
                                    }
                                }

                                onClicked: {
                                    root.actionRequested(
                                        transformBtn.modelData.name,
                                        transformBtn.modelData.prompt,
                                        root.targetText,
                                        { action: transformBtn.modelData.id, mode: root.targetScope, blockId: root.targetBlockId }
                                    );
                                }
                            }
                        }
                    }

                    // ── Category 4: Full Note Actions ─────────────────────
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.activeCategory === "note"
                        spacing: 4

                        Repeater {
                            model: [
                                { id: "title", name: Translation.tr("Suggest a title"), icon: "title",
                                  desc: Translation.tr("Creates a short, expressive title (max 6 words) based on content."),
                                  prompt: "Com base no conteúdo desta nota, crie um título conciso, memorável e altamente relevante de no máximo 6 palavras. Retorne APENAS o título puro, sem aspas, ponto final ou explicações." },
                                { id: "tags", name: Translation.tr("Suggest tags"), icon: "label",
                                  desc: Translation.tr("Extracts 3 to 5 relevant tags formatted as #tag."),
                                  prompt: "Analise o conteúdo completo desta nota e identifique os 3 a 5 principais temas ou entidades. Retorne apenas as tags no formato '#tag1 #tag2 #tag3', separadas por espaço." },
                                { id: "callout_summary", name: Translation.tr("Summarise it at the top"), icon: "article",
                                  desc: Translation.tr("Drafts a high-level summary to place at the top of the note."),
                                  prompt: "Gere um resumo executivo claro, estruturado e conciso (em 2 a 3 frases) do conteúdo desta nota, adequado para ser destacado como resumo de cabeçalho. Retorne apenas o texto do resumo." },
                                { id: "structure", name: Translation.tr("Structure in Topics"), icon: "format_align_left",
                                  desc: Translation.tr("Reorganizes the note content with clean headings and sections."),
                                  prompt: "Reorganize o conteúdo a seguir em seções lógicas com títulos Markdown (##, ###) e tópicos estruturados, preservando todas as informações originais. Retorne o documento reorganizado em Markdown." }
                            ]

                            delegate: RippleButton {
                                id: noteBtn
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 46
                                buttonRadius: Appearance.rounding.small
                                colBackground: Appearance.colors.colLayer1
                                colBackgroundHover: Appearance.colors.colLayer1Hover

                                contentItem: RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    MaterialSymbol {
                                        text: noteBtn.modelData.icon
                                        iconSize: 20
                                        color: Appearance.colors.colPrimary
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        StyledText {
                                            text: noteBtn.modelData.name
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colOnLayer0
                                        }

                                        StyledText {
                                            text: noteBtn.modelData.desc
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            color: Appearance.colors.colSubtext
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    MaterialSymbol {
                                        text: "arrow_forward"
                                        iconSize: 16
                                        color: Appearance.colors.colOnLayer1Inactive
                                    }
                                }

                                onClicked: {
                                    root.actionRequested(
                                        noteBtn.modelData.name,
                                        noteBtn.modelData.prompt,
                                        root.targetText,
                                        { action: noteBtn.modelData.id, mode: (noteBtn.modelData.id === "title" ? "title" : (noteBtn.modelData.id === "tags" ? "tags" : "note")), blockId: root.targetBlockId }
                                    );
                                }
                            }
                        }
                    }

                    // ── Category 5: Code Block ────────────────────────────
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.activeCategory === "code" && root.isCodeBlock
                        spacing: 4

                        Repeater {
                            model: [
                                { id: "code_explain", name: Translation.tr("Explain this code"), icon: "code",
                                  prompt: "Explique a lógica, o fluxo de execução e o propósito deste bloco de código de forma clara, didática e estruturada." },
                                { id: "code_bugs", name: Translation.tr("Look for bugs"), icon: "bug_report",
                                  prompt: "Analise detalhadamente o código a seguir procurando por possíveis bugs, vulnerabilidades de segurança, casos de borda não tratados, condições de corrida ou vazamentos de recursos. Liste os problemas encontrados e proponha correções." },
                                { id: "code_opt", name: Translation.tr("Suggest a faster way"), icon: "speed",
                                  prompt: "Proponha uma versão otimizada e mais performática para o código a seguir. Explique brevemente as melhorias implementadas e retorne o código aprimorado." }
                            ]

                            delegate: RippleButton {
                                id: codeBtn
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 38
                                buttonRadius: Appearance.rounding.small
                                colBackground: Appearance.colors.colLayer1
                                colBackgroundHover: Appearance.colors.colLayer1Hover

                                contentItem: RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    MaterialSymbol {
                                        text: codeBtn.modelData.icon
                                        iconSize: 18
                                        color: Appearance.colors.colPrimary
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: codeBtn.modelData.name
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnLayer0
                                    }

                                    MaterialSymbol {
                                        text: "arrow_forward"
                                        iconSize: 16
                                        color: Appearance.colors.colOnLayer1Inactive
                                    }
                                }

                                onClicked: {
                                    root.actionRequested(
                                        codeBtn.modelData.name,
                                        codeBtn.modelData.prompt,
                                        root.targetText,
                                        { action: codeBtn.modelData.id, mode: "block", blockId: root.targetBlockId }
                                    );
                                }
                            }
                        }
                    }

                    // ── Category 6: Custom Styles ─────────────────────────
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.activeCategory === "custom"
                        spacing: 4

                        // User saved custom styles
                        Repeater {
                            model: root.customStylesList

                            delegate: RippleButton {
                                id: customStyleBtn
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                implicitHeight: 40
                                buttonRadius: Appearance.rounding.small
                                colBackground: Appearance.colors.colLayer1
                                colBackgroundHover: Appearance.colors.colLayer1Hover

                                contentItem: RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 6
                                    spacing: 8

                                    MaterialSymbol {
                                        text: "tune"
                                        iconSize: 18
                                        color: Appearance.colors.colPrimary
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: customStyleBtn.modelData.name
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnLayer0
                                        elide: Text.ElideRight
                                    }

                                    NotesIconButton {
                                        symbol: "delete"
                                        size: 28
                                        iconSize: 16
                                        colIcon: Appearance.colors.colOnLayer1Inactive
                                        tooltipText: Translation.tr("Delete style")
                                        onTriggered: root.deleteCustomStyle(customStyleBtn.index)
                                    }
                                }

                                onClicked: {
                                    root.actionRequested(
                                        customStyleBtn.modelData.name,
                                        customStyleBtn.modelData.prompt,
                                        root.targetText,
                                        { action: "customStyle", mode: root.targetScope, blockId: root.targetBlockId }
                                    );
                                }
                            }
                        }

                        // Add new custom style button / form
                        property bool addingNew: false

                        RippleButton {
                            visible: !parent.addingNew
                            Layout.fillWidth: true
                            implicitHeight: 36
                            buttonRadius: Appearance.rounding.small
                            colBackground: Appearance.colors.colSecondaryContainer
                            colBackgroundHover: Appearance.colors.colSecondaryContainerHover

                            contentItem: RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                MaterialSymbol {
                                    text: "add"
                                    iconSize: 18
                                    color: Appearance.colors.colOnSecondaryContainer
                                }

                                StyledText {
                                    text: Translation.tr("Add a style of your own…")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: Font.DemiBold
                                    color: Appearance.colors.colOnSecondaryContainer
                                }
                            }

                            onClicked: parent.addingNew = true
                        }

                        // Inline style creator form
                        Rectangle {
                            visible: parent.addingNew
                            Layout.fillWidth: true
                            implicitHeight: formCol.implicitHeight + 16
                            radius: Appearance.rounding.small
                            color: Appearance.colors.colLayer2

                            ColumnLayout {
                                id: formCol
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 6

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28

                                    StyledTextInput {
                                        id: styleNameInput
                                        anchors.fill: parent
                                        font.pixelSize: Appearance.font.pixelSize.small
                                    }

                                    StyledText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Translation.tr("Style name (e.g. Corporate Voice)")
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnLayer1Inactive
                                        visible: styleNameInput.text.length === 0
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28

                                    StyledTextInput {
                                        id: stylePromptInput
                                        anchors.fill: parent
                                        font.pixelSize: Appearance.font.pixelSize.small
                                    }

                                    StyledText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Translation.tr("Instructions (e.g. Rewrite concisely without jargon)")
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnLayer1Inactive
                                        visible: stylePromptInput.text.length === 0
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    RippleButton {
                                        Layout.fillWidth: true
                                        implicitHeight: 28
                                        buttonRadius: Appearance.rounding.verysmall
                                        colBackground: Appearance.colors.colPrimary
                                        colBackgroundHover: Appearance.colors.colPrimaryHover
                                        enabled: styleNameInput.text.trim().length > 0 && stylePromptInput.text.trim().length > 0

                                        contentItem: StyledText {
                                            anchors.centerIn: parent
                                            text: Translation.tr("Save this style")
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colOnPrimary
                                        }

                                        onClicked: {
                                            root.saveNewCustomStyle(styleNameInput.text, stylePromptInput.text);
                                            styleNameInput.text = "";
                                            stylePromptInput.text = "";
                                            parent.parent.parent.parent.addingNew = false;
                                        }
                                    }

                                    RippleButton {
                                        implicitWidth: 60
                                        implicitHeight: 28
                                        buttonRadius: Appearance.rounding.verysmall
                                        colBackground: Appearance.colors.colLayer1
                                        colBackgroundHover: Appearance.colors.colLayer1Hover

                                        contentItem: StyledText {
                                            anchors.centerIn: parent
                                            text: Translation.tr("Cancel")
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            color: Appearance.colors.colOnLayer1
                                        }

                                        onClicked: {
                                            styleNameInput.text = "";
                                            stylePromptInput.text = "";
                                            parent.parent.parent.parent.addingNew = false;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Footer: Ask in Sidebar Chat ───────────────────────────────
            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 36
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colLayer2Hover

                contentItem: RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    MaterialSymbol {
                        text: "forum"
                        iconSize: 18
                        color: Appearance.colors.colTertiary
                    }

                    /// It says copy, because copy is what it does. The row used to
                    /// promise the chat would know about this note, and then opened the
                    /// sidebar with the text dropped on the floor — nothing carries it
                    /// across, so the clipboard does, and one paste finishes the job.
                    StyledText {
                        text: Translation.tr("Copy this and open the chat")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer0
                    }
                }

                onClicked: {
                    root.chatRequested(root.targetText);
                    root.closed();
                }
            }
        }
    }
}
