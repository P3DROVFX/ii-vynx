.pragma library

.import "NotesDocument.js" as Doc

/**
 * Built-in and user note templates.
 *
 * A template produces a complete document structure with headings, checklists,
 * lists and code blocks pre-formatted, giving immediate structure to notes.
 */

var BUILTIN_TEMPLATES = [
    {
        id: "meeting",
        name: "Reunião",
        description: "Pauta, participantes, discussão, decisões e ações combinadas.",
        icon: "groups",
        tags: ["reuniao", "meeting"],
        blocks: [
            { type: "heading", level: 1, text: "Reunião: " },
            { type: "callout", calloutType: "info", text: "Data: " + new Date().toLocaleDateString() + " | Facilitador: " },
            { type: "heading", level: 2, text: "Participantes" },
            { type: "list", style: "bullet", text: "" },
            { type: "heading", level: 2, text: "Pauta e Objetivos" },
            { type: "list", style: "numbered", text: "Tópico 1" },
            { type: "list", style: "numbered", text: "Tópico 2" },
            { type: "heading", level: 2, text: "Notas de Discussão" },
            { type: "text", text: "" },
            { type: "heading", level: 2, text: "Decisões Tomadas" },
            { type: "list", style: "checkbox", checked: false, text: "Decisão 1" },
            { type: "heading", level: 2, text: "Ações e Próximos Passos" },
            { type: "list", style: "checkbox", checked: false, text: "Responsável — Ação — Prazo" }
        ]
    },
    {
        id: "journal",
        name: "Diário Pessoal",
        description: "Reflexão diária com gratidão, prioridades e pensamentos.",
        icon: "auto_stories",
        tags: ["diario", "journal"],
        blocks: [
            { type: "heading", level: 1, text: "Diário — " + new Date().toLocaleDateString() },
            { type: "heading", level: 2, text: "Foco Principal do Dia" },
            { type: "list", style: "checkbox", checked: false, text: "A coisa mais importante hoje" },
            { type: "heading", level: 2, text: "Gratidão" },
            { type: "list", style: "bullet", text: "Sou grato por..." },
            { type: "list", style: "bullet", text: "Sou grato por..." },
            { type: "list", style: "bullet", text: "Sou grato por..." },
            { type: "heading", level: 2, text: "Pensamentos e Acontecimentos" },
            { type: "text", text: "" },
            { type: "heading", level: 2, text: "Reflexão da Noite" },
            { type: "quote", text: "O que correu bem hoje? O que pode melhorar amanhã?" }
        ]
    },
    {
        id: "tasks",
        name: "Lista de Tarefas",
        description: "Matriz de prioridades com tarefas urgentes, em progresso e futuras.",
        icon: "checklist",
        tags: ["tarefas", "todo"],
        blocks: [
            { type: "heading", level: 1, text: "Tarefas e Prioridades" },
            { type: "heading", level: 2, text: "🔥 Urgente & Importante" },
            { type: "list", style: "checkbox", checked: false, text: "Prioridade máxima" },
            { type: "heading", level: 2, text: "⚡ Em Progresso" },
            { type: "list", style: "checkbox", checked: false, text: "Em andamento" },
            { type: "heading", level: 2, text: "📋 A Fazer" },
            { type: "list", style: "checkbox", checked: false, text: "Próxima tarefa" },
            { type: "heading", level: 2, text: "💡 Ideias Futuras" },
            { type: "list", style: "bullet", text: "Ideia para avaliar depois" }
        ]
    },
    {
        id: "code",
        name: "Snippet de Código",
        description: "Exemplo de código, contexto, dependências e notas técnicas.",
        icon: "code",
        tags: ["codigo", "code", "dev"],
        blocks: [
            { type: "heading", level: 1, text: "Snippet: " },
            { type: "callout", calloutType: "note", text: "Linguagem / Stack / Arquivo:" },
            { type: "heading", level: 2, text: "Código" },
            { type: "code", language: "python", text: "# Implementação aqui\n" },
            { type: "heading", level: 2, text: "Notas de Implementação" },
            { type: "text", text: "Explicação do funcionamento, parâmetros e retorno:" },
            { type: "heading", level: 2, text: "Exemplo de Uso" },
            { type: "code", language: "bash", text: "# Comando para executar ou testar\n" }
        ]
    },
    {
        id: "recipe",
        name: "Receita Culinária",
        description: "Ingredientes com caixas de seleção, tempo de preparo e passos.",
        icon: "restaurant",
        tags: ["receita", "culinaria"],
        blocks: [
            { type: "heading", level: 1, text: "Receita: " },
            { type: "callout", calloutType: "tip", text: "Tempo de preparo: 30 min | Rendimento: 4 porções | Dificuldade: Fácil" },
            { type: "heading", level: 2, text: "Ingredientes" },
            { type: "list", style: "checkbox", checked: false, text: "Ingrediente 1" },
            { type: "list", style: "checkbox", checked: false, text: "Ingrediente 2" },
            { type: "list", style: "checkbox", checked: false, text: "Ingrediente 3" },
            { type: "heading", level: 2, text: "Modo de Preparo" },
            { type: "list", style: "numbered", text: "Primeiro passo..." },
            { type: "list", style: "numbered", text: "Segundo passo..." },
            { type: "list", style: "numbered", text: "Terceiro passo..." },
            { type: "heading", level: 2, text: "Dicas do Chef" },
            { type: "quote", text: "Dica especial de preparo ou substituição de ingrediente." }
        ]
    },
    {
        id: "review",
        name: "Revisão e Retrospectiva",
        description: "Análise de projeto, marcos alcançados e lições aprendidas.",
        icon: "rate_review",
        tags: ["revisao", "retrospectiva"],
        blocks: [
            { type: "heading", level: 1, text: "Revisão: " },
            { type: "heading", level: 2, text: "Resumo Executivo" },
            { type: "text", text: "Breve síntese do que foi avaliado e do resultado geral." },
            { type: "heading", level: 2, text: "✅ O que funcionou bem" },
            { type: "list", style: "bullet", text: "Ponto positivo 1" },
            { type: "list", style: "bullet", text: "Ponto positivo 2" },
            { type: "heading", level: 2, text: "⚠️ O que pode ser melhorado" },
            { type: "list", style: "bullet", text: "Ponto de atenção 1" },
            { type: "heading", level: 2, text: "🎯 Plano de Ação" },
            { type: "list", style: "checkbox", checked: false, text: "Ação corretiva ou melhoria contínua" }
        ]
    }
];

function getBuiltinTemplates() {
    return BUILTIN_TEMPLATES.slice();
}

/**
 * Instantiates a template into a raw blocks array with fresh IDs.
 */
function instantiateBlocks(templateDef) {
    if (!templateDef || !Array.isArray(templateDef.blocks))
        return [{ id: Doc.newBlockId(), type: "text", text: "" }];

    var blocks = [];
    for (var i = 0; i < templateDef.blocks.length; i++) {
        var raw = templateDef.blocks[i];
        var copy = {};
        for (var key in raw) {
            if (raw.hasOwnProperty(key))
                copy[key] = raw[key];
        }
        copy.id = Doc.newBlockId();
        blocks.push(Doc.normalizeBlock(copy));
    }
    return blocks.length > 0 ? blocks : [{ id: Doc.newBlockId(), type: "text", text: "" }];
}
