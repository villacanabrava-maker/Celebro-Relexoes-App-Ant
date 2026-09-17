# Estado Atual do Projeto — Cérebro Autoral

Atualizado em **17/09/2026** — Transição para o novo projeto (Regra Zero).

## Infraestrutura do Projeto Novo

- **Status:** Em transição para as novas contas do autor (Regra Zero aplicada).
- **GitHub:** Repositório novo do autor em configuração.
- **Supabase:** Novo projeto Supabase preparado (PostgreSQL 17 + RLS + Storage).
- **Vercel:** Novo deploy em configuração na Vercel (Node 22.x).
- **IA:** OpenAI (Responses API / Structured Outputs).
- `PROCESSAMENTO_WORKFLOW_ATIVO=false`


## Marco atual

A segunda entrega da Fase 3 foi incorporada à `main` pelos PRs #10/#11. O PR #13 implementa e valida a etapa seguinte:

```text
validar_arquivo          ✅ main
  ↓
identificar_formato      ✅ main
  ↓
extrair_conteudo         ✅ main — PDF textual/TXT/Markdown
  ↓
normalizar_conteudo      🟡 PR #13 — código/Preview em validação final
  ↓
identificar_estrutura    próxima etapa após merge
```

Nenhum artefato parcial é Documento Processado ativo e nenhum resultado parcial alimenta o Cérebro Autoral.

## Normalização — política v1

A etapa `normalizar_conteudo` é determinística e conservadora. Ela não corrige estilo, gramática, argumentos ou escolhas linguísticas.

Regras:

- Unicode NFC;
- CRLF/CR → LF;
- não usar NFKC/NFKD como normalização autoral;
- preservar caixa, pontuação, aspas, travessões e escolhas lexicais;
- preservar espaços internos e espaços significativos de Markdown;
- preservar número, ordem e fronteira de páginas PDF;
- validar schema e cadeia de proveniência `original → conteudo_extraido → conteudo_normalizado`;
- persistir `conteudo_normalizado.json` no bucket privado de artefatos;
- revalidar bytes/hash/tamanho/schema/proveniência também quando um replay reutilizar artefato existente;
- não repetir a transição de estado se o workflow já tiver avançado.

A escolha de NFC foi revisada contra a especificação Unicode atual: NFC preserva equivalência canônica; formas de compatibilidade podem remover distinções e não são adotadas para o texto autoral.

## Validação do PR #13

No head anterior ao hardening final, o job de aplicação passou:

- `npm ci`;
- `npm audit --omit=dev --audit-level=high`;
- ESLint;
- TypeScript;
- testes unitários;
- build Next.js.

O primeiro job `banco-local` conseguiu subir o Supabase e aplicar migrations, mas falhou uma vez em `supabase db reset` com erro genérico do container. A repetição isolada do mesmo job passou integralmente:

- `supabase start`;
- aplicação de todas as migrations/seed;
- `supabase db reset`;
- `supabase status`;
- shutdown limpo.

Portanto, a primeira falha foi classificada como transitória do runner/container, não como migration inválida. O commit final do PR ainda deverá repetir todos os gates depois das atualizações de código/documentação antes do merge.

Os Previews Vercel recentes da branch `feature/processamento-normalizacao` estão `READY`.

## Supabase — migrations recentes

- `0017` (`20260916202853`): RPCs server-only e máquina de etapas;
- `0018` (`20260916212133`): reserva/recuperação do Workflow;
- `0019` (`20260916221057`): locks e transições monotônicas/idempotentes;
- `0020` (`20260916223016`): artefatos intermediários + bucket privado;
- `0021` (`20260916225622`): policy explícita de negação para clientes.

O advisor de segurança após `0021` mostra apenas a pendência externa **Leaked Password Protection Disabled**. O advisor de performance não aponta FK sem índice; `unused_index` permanece informativo enquanto não há corpus real.

## Identificação e extração

Formatos processáveis v1:

- PDF com camada textual;
- TXT UTF-8;
- Markdown UTF-8.

DOCX permanece fora do escopo até validação segura OOXML. PDF sem camada textual retorna caso específico para futura estratégia de OCR; não é enviado à IA.

A extração usa `unpdf 1.8.1`/PDF.js serverless para PDF e decodificação UTF-8 determinística para texto. O original é revalidado por SHA-256/tamanho imediatamente antes da extração. O resultado vira `conteudo_extraido.json` no bucket privado `artefatos-processamento`, com hash, tamanho, MIME e metadados registrados em `processamento.artefatos_execucao`.

Guardrails v1:

```text
TXT/Markdown original: 20 MiB
PDF original:          50 MiB
PDF:                   até 1.000 páginas
Texto extraído:        até 12.000.000 caracteres
Artefato JSON:         até 30 MiB
Imagem interna PDF:    até 16.777.216 pixels
Parsing PDF:           até 90 s
```

## Produção Vercel

O domínio de produção está `READY`, mas ainda aponta para o commit `3a3a25f450fa1bdc2b56ec8f91120718de21adc2`, anterior às entregas de identificação/extração/normalização.

Os Previews das branches posteriores estão `READY`. O atraso de `main` decorreu de `build-rate-limit` da conta Vercel, não de erro de compilação confirmado no código. Como `PROCESSAMENTO_WORKFLOW_ATIVO=false`, funcionalidades parciais não estão expostas aos usuários.

O Dashboard ainda informa Node 24.x, enquanto `package.json` exige Node 22.x; os builds têm respeitado a engine do projeto. O setting administrativo deve ser alinhado manualmente.

## Estado dos dados

O banco oficial ainda possui, na última auditoria:

- 1 usuário Auth;
- 0 obras;
- 0 versões de obra;
- 0 execuções;
- 0 Documentos Processados;
- 0 fragmentos;
- 0 elementos;
- 1 versão ativa de Pipeline;
- 1 versão ativa de Taxonomia.

Por isso ainda não existe um E2E positivo com corpus real. A feature flag continuará desligada até um documento controlado percorrer o Pipeline com sucesso.

## Segurança externa pendente antes de corpus real

1. Supabase Auth: habilitar Leaked Password Protection, se o plano permitir, e confirmar URLs/templates SSR.
2. GitHub: tornar o repositório privado e proteger `main` com Ruleset/PR/checks/sem force push; considerar CodeQL.
3. Vercel: alinhar Node para 22.x e liberar/concluir um novo build de produção de `main`.
4. E2E: usar uma obra controlada antes de ligar o Workflow no frontend.

## OpenAI

A chave antiga foi rotacionada e a nova está configurada diretamente na Vercel. Nenhum segredo foi versionado. A IA ainda não participa das etapas implementadas porque validação, identificação, extração e normalização são deliberadamente determinísticas.

A futura camada cognitiva seguirá Responses API com `store:false`, Structured Outputs/JSON Schema, Zod, modelos centralizados em `MODELO_IA_*` e auditoria completa.

## Próximo passo

Concluir o PR #13 somente quando o **head final** voltar a passar os dois jobs de CI e possuir Preview Vercel `READY`. Depois abrir uma branch própria para `identificar_estrutura`.

A primeira versão de `identificar_estrutura` deverá consumir somente `conteudo_normalizado` validado, usar sinais determinísticos quando confiáveis, registrar incerteza em vez de inventar níveis e preparar dados para `criar_hierarquia` sem publicar Documento Processado parcial.

## Regra permanente

Nenhuma migration aplicada é reescrita para esconder correções. Nenhum segredo é commitido. Toda mudança estrutural é cumulativa, testável e documentada. O usuário permanece a autoridade final sobre autoria e incorporação ao Cérebro Autoral.
