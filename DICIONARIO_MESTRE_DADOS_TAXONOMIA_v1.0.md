# DICIONÁRIO MESTRE DE DADOS E TAXONOMIA v1.0

**Projeto:** Cérebro Autoral  
**Idioma canônico:** Português do Brasil  
**Status:** Base arquitetural para a primeira migration do Supabase  
**Objetivo:** definir, antes da implementação física, os nomes, significados, relações, estados, vocabulários e regras de integridade do banco de dados e da camada de inteligência artificial.

---

## 1. Princípios normativos

Este dicionário é a fonte de verdade para nomes e significados do domínio. Mudanças estruturais no banco, na IA ou na interface devem preservar estes princípios ou atualizar formalmente a versão do dicionário.

### 1.1. Princípios de nomenclatura

1. Todo nome controlado pelo projeto será em português.
2. Identificadores SQL usarão `snake_case`, letras minúsculas, sem espaços e sem acentos.
3. Tabelas serão nomeadas no plural.
4. Chaves primárias usarão `id`.
5. Chaves estrangeiras usarão `<entidade>_id`.
6. Datas e horários usarão `timestamptz`.
7. Datas históricas incertas podem usar campos auxiliares de precisão e período.
8. Campos booleanos devem representar fatos inequívocos.
9. Termos intelectuais não serão salvos como texto livre quando existir um conceito taxonômico equivalente.
10. Dados importantes não existirão somente dentro de `jsonb`. `jsonb` será reservado a metadados flexíveis e detalhes auxiliares.

### 1.2. Regras de vocabulário

**Estados técnicos estáveis** serão implementados como `text` + `CHECK`, pois possuem ciclo de vida bem definido e raramente mudam.

**Vocabulários intelectuais evolutivos** serão implementados como tabelas versionadas: conceitos, dimensões autorais, relações, escopos de influência, categorias intelectuais e outros elementos que podem evoluir com o projeto.

### 1.3. Regras de autoria

Uma obra deve distinguir obrigatoriamente:

- quem escreveu;
- como ela participa do Cérebro Autoral.

Uma fonte externa nunca poderá ser convertida silenciosamente em evidência de autoria.

### 1.4. Regra do Cérebro

```text
Núcleo Autoral
+
Influências Externas Deliberadas
=
Cérebro Ativo
```

O Núcleo Autoral recebe prioritariamente fontes comprovadamente autorais. Uma fonte externa só influencia o Cérebro após decisão explícita do usuário, com escopo e intensidade registrados.

### 1.5. Regra de publicação atômica

Um Documento Processado só poderá alimentar o Cérebro se sua versão estiver integralmente concluída e validada. Processamentos parciais nunca serão considerados fontes ativas.

### 1.6. Regra de proveniência

Toda inferência relevante deve conseguir responder:

- de qual obra veio;
- de qual versão;
- de qual documento processado;
- de qual seção;
- de qual fragmento;
- em qual processamento foi produzida;
- por qual modelo;
- com qual versão de prompt;
- com qual versão de taxonomia;
- se foi confirmada ou corrigida pelo usuário.

---

# 2. Domínios e schemas

| Schema | Nome humano | Responsabilidade |
|---|---|---|
| `biblioteca` | Biblioteca | Obras originais, versões e configuração básica de participação no Cérebro |
| `processamento` | Processamento | Execuções, estrutura documental, fragmentos, sínteses, elementos, evidências, vetores e relações |
| `taxonomia` | Taxonomia | Conceitos, termos preferenciais/alternativos, relações e versões da organização intelectual |
| `cerebro_autoral` | Cérebro Autoral | Versões do cérebro, características, metodologias, regras, transições, evidências e influências |
| `reflexoes` | Reflexões | Entradas, contextos, conflitos, planos, versões, revisões e incorporação autoral |
| `auditoria` | Auditoria | Execuções de IA, workflows, eventos e rastreabilidade operacional |
| `sistema` | Sistema | Modelos de IA, prompts, versões de pipeline e configurações do usuário |
| `aplicacao` | Aplicação | Views e funções seguras destinadas à interface, quando necessário |

Schemas nativos do Supabase (`auth`, `storage`, entre outros) não serão renomeados.

---

# 3. Convenções transversais

## 3.1. Identificadores

- Chaves primárias: `uuid`.
- Geração padrão: `gen_random_uuid()`.
- Códigos humanos: `text`, únicos dentro do escopo adequado.
- Exemplos: `OBR-000001`, `DOC-000001`, `CON-000001`, `CAR-000001`, `REF-000001`.

## 3.2. Controle temporal

Campos preferenciais:

- `criado_em timestamptz not null default now()`
- `atualizado_em timestamptz not null default now()`
- `ativado_em timestamptz`
- `arquivado_em timestamptz`
- `excluido_em timestamptz` somente quando exclusão lógica for necessária.

## 3.3. Confiança

Scores de confiança usarão `numeric(5,4)` no intervalo de `0` a `1`.

A confiança final de características do Cérebro não poderá ser exclusivamente a autopercepção do modelo. Deve incorporar evidência, frequência, diversidade de fontes, contraexemplos e revisão humana.

## 3.4. Multiusuário e RLS

Entidades pertencentes ao usuário terão `usuario_id uuid not null`.

Quando uma tabela filha possuir também `usuario_id`, a integridade recomendada é:

```text
(parent_id, usuario_id)
→
(parent.id, parent.usuario_id)
```

Isso evita vínculos acidentais entre usuários e simplifica políticas RLS.

---

# 4. Schema `biblioteca`

## 4.1. `biblioteca.obras`

**Finalidade:** representa a obra intelectual ou documento lógico, independentemente do arquivo físico e de suas versões.

| Campo | Tipo | Obrigatório | Regra / significado |
|---|---|---:|---|
| `id` | uuid | sim | PK |
| `usuario_id` | uuid | sim | FK `auth.users.id` |
| `codigo` | text | sim | Código humano único por usuário |
| `titulo_original` | text | sim | Título preservado como informado/original |
| `titulo_exibicao` | text | sim | Título apresentado na interface |
| `titulo_normalizado` | text | sim | Versão normalizada para pesquisa e ordenação |
| `tipo_obra` | text | sim | Vocabulário controlado de tipos de obra |
| `autoria` | text | sim | `autoral` ou `externa` |
| `participacao_cerebro` | text | sim | Papel da obra no Cérebro |
| `autor_original` | text | não | Autor quando a obra for externa |
| `idioma` | text | sim | Preferencialmente código BCP-47, ex.: `pt-BR` |
| `categoria` | text | não | Classificação documental de alto nível |
| `descricao` | text | não | Descrição humana |
| `data_producao` | date | não | Data conhecida de produção |
| `periodo_autoral_inicio` | date | não | Início estimado do período |
| `periodo_autoral_fim` | date | não | Fim estimado do período |
| `precisao_data` | text | não | `exata`, `aproximada`, `periodo`, `desconhecida` |
| `importancia` | smallint | não | Escala 1–5 |
| `estado` | text | sim | Ciclo de vida da obra |
| `metadados_auxiliares` | jsonb | não | Metadados não canônicos |
| `criado_em` | timestamptz | sim | default `now()` |
| `atualizado_em` | timestamptz | sim | default `now()` |

**CHECKs principais**

```text
autoria IN ('autoral','externa')

participacao_cerebro IN (
  'autoral_prioritaria',
  'externa_referencia',
  'externa_influencia',
  'excluida_cerebro'
)

estado IN ('ativa','arquivada','excluida')
```

**Regras críticas**

- `autoral_prioritaria` exige `autoria = 'autoral'`.
- `externa_influencia` exige `autoria = 'externa'` e registro ativo em `cerebro_autoral.influencias_externas`.

**Índices**

- unique `(usuario_id, codigo)`
- `(usuario_id, estado)`
- `(usuario_id, autoria, participacao_cerebro)`
- índice de busca textual em título/descrição.

**RLS**

Usuário somente acessa linhas onde `usuario_id = auth.uid()`.

---

## 4.2. `biblioteca.versoes_obras`

**Finalidade:** preserva cada versão física de uma obra.

| Campo | Tipo | Obrigatório | Regra / significado |
|---|---|---:|---|
| `id` | uuid | sim | PK |
| `usuario_id` | uuid | sim | Proprietário |
| `obra_id` | uuid | sim | FK `biblioteca.obras` |
| `codigo` | text | sim | Código humano |
| `numero_versao` | integer | sim | >= 1 |
| `nome_arquivo` | text | sim | Nome original do arquivo |
| `caminho_arquivo` | text | sim | Caminho no Storage privado |
| `tipo_mime` | text | sim | MIME detectado |
| `extensao` | text | não | Extensão normalizada |
| `tamanho_bytes` | bigint | sim | >= 0 |
| `hash_sha256` | text | sim | Integridade e deduplicação |
| `quantidade_paginas` | integer | não | Quando aplicável |
| `quantidade_palavras` | integer | não | Após extração |
| `estado_processamento` | text | sim | Estado resumido da versão |
| `criado_em` | timestamptz | sim | Upload |

**CHECK**

```text
estado_processamento IN (
  'recebido',
  'em_processamento',
  'concluido',
  'falhou'
)
```

**Índices**

- unique `(obra_id, numero_versao)`
- `(usuario_id, hash_sha256)`
- `(usuario_id, estado_processamento)`

---

# 5. Schema `processamento`

## 5.1. `processamento.execucoes`

**Finalidade:** uma execução completa do pipeline sobre uma versão de obra.

| Campo | Tipo | Obrigatório | Regra / significado |
|---|---|---:|---|
| `id` | uuid | sim | PK |
| `usuario_id` | uuid | sim | Proprietário |
| `versao_obra_id` | uuid | sim | Fonte processada |
| `codigo` | text | sim | Código humano |
| `estado` | text | sim | Estado geral |
| `etapa_atual` | text | não | Nome técnico da etapa |
| `percentual` | numeric(5,2) | sim | 0–100 |
| `versao_pipeline_id` | uuid | sim | FK `sistema.versoes_pipeline` |
| `versao_taxonomia_id` | uuid | sim | FK `taxonomia.versoes` |
| `iniciado_em` | timestamptz | sim | |
| `concluido_em` | timestamptz | não | |
| `codigo_erro` | text | não | Código estável |
| `mensagem_erro` | text | não | Resumo seguro |
| `criado_em` | timestamptz | sim | |

**Estados**

```text
recebido
validando
extraindo
normalizando
estruturando
segmentando
sintetizando
analisando
classificando
vetorizando
relacionando
validando_resultado
finalizando
concluido
falhou
cancelado
```

---

## 5.2. `processamento.etapas_execucao`

**Finalidade:** registrar cada etapa idempotente de uma execução.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `execucao_id` | uuid | sim |
| `nome_etapa` | text | sim |
| `ordem` | integer | sim |
| `chave_idempotencia` | text | sim |
| `estado` | text | sim |
| `tentativas` | integer | sim |
| `iniciado_em` | timestamptz | não |
| `concluido_em` | timestamptz | não |
| `duracao_ms` | bigint | não |
| `detalhes_auxiliares` | jsonb | não |

Estados: `pendente`, `executando`, `concluida`, `falhou`, `ignorada`, `cancelada`.

**Índices**

- unique `chave_idempotencia`
- `(execucao_id, ordem)`
- `(estado, criado_em)` quando `criado_em` for incluído na implementação.

---

## 5.3. `processamento.documentos_processados`

**Finalidade:** versão computacional integral e publicada de uma obra.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `obra_id` | uuid | sim |
| `versao_obra_id` | uuid | sim |
| `execucao_id` | uuid | sim |
| `codigo` | text | sim |
| `titulo` | text | sim |
| `resumo_global` | text | não |
| `sintese_analitica` | text | não |
| `quantidade_partes` | integer | sim |
| `quantidade_capitulos` | integer | sim |
| `quantidade_secoes` | integer | sim |
| `quantidade_fragmentos` | integer | sim |
| `quantidade_elementos` | integer | sim |
| `versao_pipeline_id` | uuid | sim |
| `versao_taxonomia_id` | uuid | sim |
| `estado` | text | sim |
| `publicado_em` | timestamptz | não |
| `processado_em` | timestamptz | sim |

Estados: `candidato`, `ativo`, `substituido`, `invalidado`.

**Regra crítica:** apenas `ativo` pode alimentar o Cérebro Autoral.

---

## 5.4. `processamento.secoes`

**Finalidade:** representar a estrutura editorial hierárquica.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `documento_processado_id` | uuid | sim |
| `secao_pai_id` | uuid | não |
| `codigo` | text | sim |
| `tipo` | text | sim |
| `titulo` | text | não |
| `ordem` | integer | sim |
| `nivel_hierarquico` | smallint | sim |
| `pagina_inicial` | integer | não |
| `pagina_final` | integer | não |
| `conteudo` | text | não |
| `criado_em` | timestamptz | sim |

Tipos iniciais: `obra`, `parte`, `capitulo`, `secao`, `subsecao`, `anexo`, `prefacio`, `posfacio`, `nota`.

---

## 5.5. `processamento.fragmentos`

**Finalidade:** unidade fina de recuperação, sempre com contexto e proveniência.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `documento_processado_id` | uuid | sim |
| `secao_id` | uuid | não |
| `codigo` | text | sim |
| `ordem` | integer | sim |
| `fragmento_anterior_id` | uuid | não |
| `fragmento_seguinte_id` | uuid | não |
| `pagina_inicial` | integer | não |
| `pagina_final` | integer | não |
| `conteudo` | text | sim |
| `conteudo_contextualizado` | text | sim |
| `quantidade_tokens` | integer | sim |
| `vetor_textual` | tsvector | sim |
| `criado_em` | timestamptz | sim |

**Índices**

- GIN em `vetor_textual`
- `(documento_processado_id, ordem)`
- `(secao_id, ordem)`

---

## 5.6. `processamento.sinteses`

**Finalidade:** sínteses multinível no estilo hierárquico obra → parte → capítulo → seção.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `documento_processado_id` | uuid | sim |
| `tipo_alvo` | text | sim |
| `alvo_id` | uuid | sim |
| `nivel` | smallint | sim |
| `conteudo` | text | sim |
| `modelo_ia_id` | uuid | sim |
| `versao_prompt_id` | uuid | sim |
| `criado_em` | timestamptz | sim |

Tipos de alvo: `secao`, `capitulo`, `parte`, `obra`.

---

## 5.7. `processamento.vetores`

**Finalidade:** embeddings desacoplados do conteúdo textual.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `tipo_alvo` | text | sim |
| `alvo_id` | uuid | sim |
| `embedding` | vector(1536) | sim |
| `modelo_ia_id` | uuid | sim |
| `dimensoes` | integer | sim |
| `versao` | integer | sim |
| `criado_em` | timestamptz | sim |

**Regra v1:** a arquitetura padroniza 1536 dimensões para permitir HNSW consistente. Uma alteração futura de dimensionalidade exige migration/versionamento explícito.

---

## 5.8. `processamento.elementos`

**Finalidade:** elementos intelectuais/narrativos identificados pela IA.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `documento_processado_id` | uuid | sim |
| `codigo` | text | sim |
| `tipo` | text | sim |
| `titulo` | text | sim |
| `descricao` | text | sim |
| `conteudo_estruturado` | jsonb | não |
| `importancia` | numeric(5,4) | sim |
| `confianca` | numeric(5,4) | sim |
| `estado_revisao` | text | sim |
| `modelo_ia_id` | uuid | sim |
| `versao_prompt_id` | uuid | sim |
| `criado_em` | timestamptz | sim |

Tipos iniciais: `tema`, `conceito`, `ideia`, `tese`, `argumento`, `valor`, `principio`, `pergunta`, `tensao`, `contradicao`, `conclusao`, `historia`, `experiencia`, `pessoa`, `personagem`, `lugar`, `evento`, `metafora`, `analogia`, `contraste`, `frase_relevante`, `padrao_linguistico`, `recurso_narrativo`, `estrutura_argumentativa`, `mudanca_de_pensamento`, `referencia`.

Estados: `nao_revisado`, `confirmado`, `editado`, `rejeitado`.

---

## 5.9. `processamento.evidencias`

**Finalidade:** ligar um elemento a trechos concretos.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `elemento_id` | uuid | sim |
| `fragmento_id` | uuid | sim |
| `pagina_inicial` | integer | não |
| `pagina_final` | integer | não |
| `trecho_referencia` | text | sim |
| `forca_evidencia` | numeric(5,4) | sim |
| `justificativa` | text | não |
| `criado_em` | timestamptz | sim |

---

## 5.10. `processamento.relacoes_elementos`

**Finalidade:** grafo intelectual interno e entre documentos.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `elemento_origem_id` | uuid | sim |
| `tipo_relacao` | text | sim |
| `elemento_destino_id` | uuid | sim |
| `confianca` | numeric(5,4) | sim |
| `justificativa` | text | não |
| `criado_em` | timestamptz | sim |

Relações iniciais: `sustenta`, `contradiz`, `expande`, `deriva_de`, `exemplifica`, `questiona`, `responde_a`, `evolui_para`, `associa_se_a`, `reformula`.

---

# 6. Schema `taxonomia`

## 6.1. `taxonomia.versoes`

**Finalidade:** versionar formalmente a organização intelectual.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `numero_versao` | text | sim |
| `descricao` | text | sim |
| `estado` | text | sim |
| `criado_em` | timestamptz | sim |
| `ativado_em` | timestamptz | não |

Estados: `rascunho`, `ativa`, `arquivada`.

---

## 6.2. `taxonomia.conceitos`

**Finalidade:** unidade canônica de conhecimento.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `versao_taxonomia_id` | uuid | sim |
| `codigo` | text | sim |
| `termo_preferencial` | text | sim |
| `definicao` | text | sim |
| `nota_escopo` | text | não |
| `dominio` | text | sim |
| `estado` | text | sim |
| `criado_em` | timestamptz | sim |

Domínios iniciais: `intelectual`, `axiologico`, `reflexivo`, `narrativo`, `entidades`, `temporal`, `retorico`, `linguistico`, `estrutural`, `autoral`.

---

## 6.3. `taxonomia.termos`

**Finalidade:** termos preferenciais, alternativos e históricos.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `conceito_id` | uuid | sim |
| `termo` | text | sim |
| `termo_normalizado` | text | sim |
| `tipo` | text | sim |
| `idioma` | text | sim |

Tipos: `preferencial`, `alternativo`, `sinonimo`, `historico`, `oculto_busca`.

---

## 6.4. `taxonomia.relacoes`

**Finalidade:** relações semânticas entre conceitos.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `conceito_origem_id` | uuid | sim |
| `tipo_relacao` | text | sim |
| `conceito_destino_id` | uuid | sim |
| `confianca` | numeric(5,4) | sim |
| `origem` | text | sim |
| `criado_em` | timestamptz | sim |

Tipos: `mais_amplo`, `mais_especifico`, `relacionado`, `contrasta_com`, `deriva_de`, `evolui_para`, `associado_a`.

Origem: `curadoria`, `ia`, `importacao`.

---

## 6.5. `taxonomia.classificacoes_elementos`

**Finalidade:** relação muitos-para-muitos entre elementos processados e conceitos canônicos.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `elemento_id` | uuid | sim |
| `conceito_id` | uuid | sim |
| `papel` | text | sim |
| `confianca` | numeric(5,4) | sim |
| `criado_em` | timestamptz | sim |

Papéis: `principal`, `secundario`, `contextual`, `oposicao`.

---

# 7. Schema `cerebro_autoral`

## 7.1. `cerebro_autoral.versoes`

**Finalidade:** snapshot lógico versionado do Cérebro.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `codigo` | text | sim |
| `numero_versao` | integer | sim |
| `estado` | text | sim |
| `quantidade_documentos` | integer | sim |
| `quantidade_evidencias` | integer | sim |
| `descricao` | text | não |
| `criado_em` | timestamptz | sim |
| `ativado_em` | timestamptz | não |

Estados: `em_construcao`, `proposta`, `ativa`, `arquivada`, `invalidada`.

**Regra:** somente uma versão `ativa` por usuário.

---

## 7.2. `cerebro_autoral.dimensoes`

**Finalidade:** taxonomia canônica das áreas metodológicas do Cérebro.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `codigo` | text | sim |
| `nome` | text | sim |
| `descricao` | text | sim |
| `ordem` | integer | sim |
| `ativa` | boolean | sim |

Dimensões v1:

1. `metodologia_de_pensamento`
2. `metodologia_de_interpretacao`
3. `metodologia_de_associacao`
4. `metodologia_argumentativa`
5. `metodologia_de_escrita`
6. `metodologia_de_revisao`
7. `arquitetura_narrativa`
8. `arquitetura_de_paragrafo`
9. `formas_de_abertura`
10. `formas_de_transicao`
11. `formas_de_conclusao`
12. `recursos_retoricos`
13. `identidade_linguistica`
14. `relacao_experiencia_conceito`
15. `padroes_de_tensao`
16. `padroes_de_sintese`
17. `universo_conceitual`
18. `evolucao_autoral`

---

## 7.3. `cerebro_autoral.caracteristicas`

**Finalidade:** padrões autorais inferidos e auditáveis.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `versao_cerebro_id` | uuid | sim |
| `dimensao_id` | uuid | sim |
| `codigo` | text | sim |
| `titulo` | text | sim |
| `descricao` | text | sim |
| `origem` | text | sim |
| `confianca` | numeric(5,4) | sim |
| `frequencia` | numeric(5,4) | sim |
| `diversidade_fontes` | integer | sim |
| `primeira_ocorrencia` | date | não |
| `ultima_ocorrencia` | date | não |
| `estado_revisao` | text | sim |
| `criado_em` | timestamptz | sim |

Origem: `nucleo_autoral`, `influencia_externa`.

Estados: `proposta`, `confirmada`, `editada`, `rejeitada`, `obsoleta`.

---

## 7.4. `cerebro_autoral.evidencias`

**Finalidade:** provas textuais de uma característica.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `caracteristica_id` | uuid | sim |
| `documento_processado_id` | uuid | sim |
| `fragmento_id` | uuid | sim |
| `forca` | numeric(5,4) | sim |
| `justificativa` | text | sim |
| `origem_evidencia` | text | sim |
| `criado_em` | timestamptz | sim |

Origem: `autoral`, `influencia_externa`, `revisao_humana`.

---

## 7.5. `cerebro_autoral.excecoes`

**Finalidade:** contraexemplos que impedem absolutização dos padrões.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `caracteristica_id` | uuid | sim |
| `documento_processado_id` | uuid | sim |
| `fragmento_id` | uuid | sim |
| `descricao` | text | sim |
| `forca` | numeric(5,4) | sim |
| `criado_em` | timestamptz | sim |

---

## 7.6. `cerebro_autoral.metodologias`

**Finalidade:** descrever mecanismos recorrentes, não apenas características isoladas.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `versao_cerebro_id` | uuid | sim |
| `codigo` | text | sim |
| `nome` | text | sim |
| `descricao` | text | sim |
| `origem` | text | sim |
| `confianca` | numeric(5,4) | sim |
| `estado_revisao` | text | sim |
| `criado_em` | timestamptz | sim |

---

## 7.7. `cerebro_autoral.metodologias_caracteristicas`

**Finalidade:** ligar metodologias às características que as sustentam.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `metodologia_id` | uuid | sim |
| `caracteristica_id` | uuid | sim |
| `papel` | text | sim |

Papéis: `central`, `suporte`, `excecao`, `contexto`.

---

## 7.8. `cerebro_autoral.regras`

**Finalidade:** transformar metodologia observada em orientação operacional para a IA.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `versao_cerebro_id` | uuid | sim |
| `metodologia_id` | uuid | não |
| `codigo` | text | sim |
| `titulo` | text | sim |
| `regra_operacional` | text | sim |
| `anti_regra` | text | não |
| `prioridade` | smallint | sim |
| `estado` | text | sim |
| `criado_em` | timestamptz | sim |

Estados: `proposta`, `ativa`, `inativa`, `rejeitada`.

---

## 7.9. `cerebro_autoral.etapas_metodologicas`

**Finalidade:** vocabulário de movimentos cognitivos.

Exemplos iniciais:

`experiencia`, `observacao`, `interpretacao`, `tensao`, `questionamento`, `associacao`, `contraste`, `argumentacao`, `elaboracao`, `sintese`, `conclusao`, `abertura`.

Campos: `id`, `codigo`, `nome`, `descricao`, `ativa`.

---

## 7.10. `cerebro_autoral.transicoes`

**Finalidade:** grafo da arquitetura de raciocínio.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `versao_cerebro_id` | uuid | sim |
| `etapa_origem_id` | uuid | sim |
| `etapa_destino_id` | uuid | sim |
| `confianca` | numeric(5,4) | sim |
| `frequencia` | numeric(5,4) | sim |
| `contexto` | text | não |
| `criado_em` | timestamptz | sim |

---

## 7.11. `cerebro_autoral.fontes_cerebro`

**Finalidade:** declarar exatamente quais Documentos Processados compõem uma versão do Cérebro.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `versao_cerebro_id` | uuid | sim |
| `documento_processado_id` | uuid | sim |
| `tipo_participacao` | text | sim |
| `peso` | numeric(5,4) | sim |
| `criado_em` | timestamptz | sim |

Tipos: `nucleo_autoral`, `influencia_externa`.

---

## 7.12. `cerebro_autoral.influencias_externas`

**Finalidade:** registrar decisão explícita de incorporar metodologia de uma obra externa.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `obra_id` | uuid | sim |
| `estado` | text | sim |
| `grau_influencia` | numeric(5,4) | sim |
| `justificativa_usuario` | text | não |
| `incorporado_em` | timestamptz | sim |
| `removido_em` | timestamptz | não |

Estados: `ativa`, `inativa`, `removida`.

---

## 7.13. `cerebro_autoral.escopos_influencia`

**Finalidade:** selecionar quais dimensões da obra externa podem influenciar o Cérebro.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `influencia_externa_id` | uuid | sim |
| `dimensao_id` | uuid | sim |
| `peso` | numeric(5,4) | sim |

**Regra:** uma influência externa não implica incorporação de opiniões. A seleção deve indicar explicitamente quais dimensões metodológicas estão autorizadas.

---

# 8. Schema `reflexoes`

## 8.1. `reflexoes.reflexoes`

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `codigo` | text | sim |
| `titulo` | text | sim |
| `estado` | text | sim |
| `versao_cerebro_id` | uuid | não |
| `criado_em` | timestamptz | sim |
| `atualizado_em` | timestamptz | sim |

Estados: `criada`, `em_analise`, `contexto_recuperado`, `conflitos_identificados`, `plano_pronto`, `rascunho_pronto`, `em_revisao`, `aprovada`, `arquivada`.

---

## 8.2. `reflexoes.entradas`

**Finalidade:** entradas originais da reflexão.

Tipos: `reflexao_externa`, `comentario_autor`, `observacao`, `transcricao`.

Campos principais: `id`, `usuario_id`, `reflexao_id`, `tipo`, `conteudo`, `obra_id`, `criado_em`.

---

## 8.3. `reflexoes.contextos`

**Finalidade:** snapshot de uma recuperação contextual.

Campos: `id`, `usuario_id`, `reflexao_id`, `versao_cerebro_id`, `estrategia_recuperacao`, `consulta_normalizada`, `criado_em`.

---

## 8.4. `reflexoes.itens_contexto`

**Finalidade:** explicar exatamente o que foi recuperado.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `contexto_id` | uuid | sim |
| `tipo_item` | text | sim |
| `referencia_id` | uuid | sim |
| `relevancia` | numeric(5,4) | sim |
| `motivo_selecao` | text | sim |
| `ordem` | integer | sim |

Tipos: `fragmento`, `secao`, `sintese`, `elemento`, `conceito`, `caracteristica`, `metodologia`, `regra`, `influencia`.

---

## 8.5. `reflexoes.conflitos`

**Finalidade:** divergências entre pensamento presente, memória histórica e/ou influências.

Campos: `id`, `usuario_id`, `reflexao_id`, `tipo`, `descricao`, `conteudo_atual`, `referencia_anterior_id`, `gravidade`, `estado`, `decisao_usuario`, `criado_em`.

Estados: `aberto`, `revisado`, `incorporado`, `ignorado`.

---

## 8.6. `reflexoes.planos`

**Finalidade:** estrutura intelectual antes da redação.

Campos canônicos:

- `questao_central`
- `tese_provisoria`
- `abertura`
- `movimentos_do_raciocinio`
- `experiencias`
- `conceitos`
- `argumentos`
- `tensoes`
- `contrastes`
- `sintese`
- `direcao_conclusao`

Para flexibilidade, o plano completo pode usar `jsonb`, mas deverá ser validado por JSON Schema e versionado.

---

## 8.7. `reflexoes.versoes`

**Finalidade:** histórico imutável da produção textual.

| Campo | Tipo | Obrigatório |
|---|---|---:|
| `id` | uuid | sim |
| `usuario_id` | uuid | sim |
| `reflexao_id` | uuid | sim |
| `numero_versao` | integer | sim |
| `origem` | text | sim |
| `conteudo` | text | sim |
| `modelo_ia_id` | uuid | não |
| `versao_prompt_id` | uuid | não |
| `criado_em` | timestamptz | sim |

Origem: `ia`, `ia_auditada`, `autor`, `final_aprovada`.

---

## 8.8. `reflexoes.revisoes`

**Finalidade:** registrar diferenças e decisões humanas.

Campos: `id`, `usuario_id`, `reflexao_id`, `versao_origem_id`, `versao_destino_id`, `resumo_alteracoes`, `analise_ia`, `confirmada_pelo_usuario`, `criado_em`.

---

## 8.9. `reflexoes.incorporacoes_biblioteca`

**Finalidade:** separar aprovação da reflexão de sua incorporação como conteúdo autoral.

Campos: `id`, `usuario_id`, `reflexao_id`, `versao_reflexao_id`, `obra_criada_id`, `estado`, `solicitado_em`, `concluido_em`.

Estados: `solicitada`, `processando`, `concluida`, `cancelada`, `falhou`.

---

# 9. Schema `sistema`

## 9.1. `sistema.modelos_ia`

Catálogo de modelos disponíveis.

Campos: `id`, `provedor`, `identificador_modelo`, `apelido`, `finalidade`, `dimensoes_embedding`, `ativo`, `criado_em`.

Finalidades: `extracao`, `analise`, `taxonomia`, `cerebro`, `redacao`, `auditoria`, `embedding`.

---

## 9.2. `sistema.prompts`

Identidade lógica de um prompt.

Campos: `id`, `codigo`, `nome`, `finalidade`, `ativo`.

---

## 9.3. `sistema.versoes_prompts`

Campos: `id`, `prompt_id`, `numero_versao`, `conteudo`, `schema_saida`, `hash_conteudo`, `criado_em`, `ativado_em`.

Prompts são também versionados no GitHub; esta tabela registra a versão operacional efetivamente utilizada.

---

## 9.4. `sistema.versoes_pipeline`

Campos: `id`, `numero_versao`, `descricao`, `hash_configuracao`, `estado`, `criado_em`, `ativado_em`.

---

## 9.5. `sistema.configuracoes_usuario`

Configurações seguras e não secretas.

Exemplos:

- idioma preferencial;
- comportamento padrão de recuperação;
- nível de detalhamento;
- necessidade de aprovação manual;
- preferências visuais.

Segredos nunca entram nesta tabela.

---

# 10. Schema `auditoria`

## 10.1. `auditoria.execucoes_ia`

| Campo | Tipo |
|---|---|
| `id` | uuid |
| `usuario_id` | uuid |
| `operacao` | text |
| `modelo_ia_id` | uuid |
| `versao_prompt_id` | uuid |
| `versao_taxonomia_id` | uuid |
| `versao_pipeline_id` | uuid |
| `estado` | text |
| `tokens_entrada` | integer |
| `tokens_saida` | integer |
| `duracao_ms` | bigint |
| `custo_estimado` | numeric |
| `referencias_entrada` | jsonb |
| `referencias_saida` | jsonb |
| `erro` | text |
| `criado_em` | timestamptz |

`jsonb` aqui é aceitável porque as referências de auditoria são auxiliares; os dados primários continuam normalizados em suas próprias tabelas.

---

## 10.2. `auditoria.execucoes_workflow`

Campos: `id`, `usuario_id`, `tipo_workflow`, `identificador_externo`, `estado`, `iniciado_em`, `concluido_em`, `tentativas`, `erro`.

---

## 10.3. `auditoria.eventos`

Registro de decisões relevantes, como:

- influência externa ativada;
- característica confirmada;
- característica rejeitada;
- versão do Cérebro ativada;
- documento processado invalidado;
- reflexão incorporada como autoria.

---

# 11. Vocabulários controlados v1.0

## 11.1. Tipos de obra

```text
livro
capitulo
artigo
carta
reflexao
ensaio
relato
mensagem
anotacao
transcricao
documento_profissional
material_metodologico
referencia_externa
outro
```

## 11.2. Autoria

```text
autoral
externa
```

## 11.3. Participação no Cérebro

```text
autoral_prioritaria
externa_referencia
externa_influencia
excluida_cerebro
```

## 11.4. Tipos de elementos documentais

```text
tema
conceito
ideia
tese
argumento
valor
principio
pergunta
tensao
contradicao
conclusao
historia
experiencia
pessoa
personagem
lugar
evento
metafora
analogia
contraste
frase_relevante
padrao_linguistico
recurso_narrativo
estrutura_argumentativa
mudanca_de_pensamento
referencia
```

## 11.5. Relações intelectuais

```text
sustenta
contradiz
expande
deriva_de
exemplifica
questiona
responde_a
evolui_para
associa_se_a
reformula
```

## 11.6. Relações taxonômicas

```text
mais_amplo
mais_especifico
relacionado
contrasta_com
deriva_de
evolui_para
associado_a
```

## 11.7. Estados de revisão intelectual

```text
nao_revisado
proposta
confirmada
editada
rejeitada
obsoleta
```

## 11.8. Intensidade de influência

O banco armazenará `grau_influencia` como número 0–1.

A interface apresentará faixas:

```text
0.00–0.24  muito_baixa
0.25–0.44  baixa
0.45–0.64  moderada
0.65–0.84  alta
0.85–1.00  muito_alta
```

---

# 12. Taxonomia do Cérebro Autoral v1.0

## 12.1. Metodologia de pensamento

Investiga como o autor inicia o raciocínio, formula problemas, transforma observação em reflexão, progride entre níveis de abstração e sintetiza.

## 12.2. Metodologia de interpretação

Investiga como lê acontecimentos, interpreta experiências, atribui significado, lida com ambiguidade e revisita eventos passados.

## 12.3. Metodologia de associação

Investiga como conecta experiência e conceito, passado e presente, autores e vivências, imagens e argumentos, ideias distantes.

## 12.4. Metodologia argumentativa

Investiga construção de tese, sustentação, contraste, objeção, contraponto, síntese e forma de persuasão.

## 12.5. Metodologia de escrita

Investiga organização textual, ritmo, parágrafos, progressão, densidade e clareza.

## 12.6. Metodologia de revisão

Investiga diferenças entre rascunho e versão aprovada: cortes, adições, simplificações, aprofundamentos, substituições e reorganizações.

## 12.7. Arquitetura narrativa

Investiga cenas, histórias, viradas, temporalidade, personagem e construção de tensão.

## 12.8. Arquitetura de parágrafo

Investiga extensão, função, frase inicial, desenvolvimento interno, fechamento e transição.

## 12.9. Formas de abertura

Exemplos: experiência concreta, afirmação, pergunta, memória, imagem, paradoxo, problema.

## 12.10. Formas de transição

Exemplos: contraste, associação, aprofundamento, mudança temporal, mudança de escala, pergunta.

## 12.11. Formas de conclusão

Exemplos: síntese, conclusão aberta, retorno à experiência inicial, pergunta, consequência prática, ampliação do problema.

## 12.12. Recursos retóricos

Metáfora, analogia, repetição, paralelismo, contraste, pergunta, exemplo, imagem.

## 12.13. Identidade linguística

Vocabulário, formalidade, ritmo, comprimento de frases, modalização, conectores e preferências sintáticas.

## 12.14. Relação experiência-conceito

Dimensão dedicada a compreender como experiências concretas são convertidas em elaboração conceitual e vice-versa.

## 12.15. Padrões de tensão

Como o autor estabelece e mantém problemas, ambiguidades, oposições e conflitos intelectuais.

## 12.16. Padrões de síntese

Como ideias diferentes são combinadas, reconciliadas ou mantidas em tensão.

## 12.17. Universo conceitual

Quais conceitos estruturam persistentemente a produção do autor, sem confundir recorrência temática com metodologia.

## 12.18. Evolução autoral

Mudanças temporais nas demais dimensões do Cérebro.

---

# 13. Regras de IA por domínio

## 13.1. Biblioteca

A IA pode:

- sugerir título de exibição;
- sugerir categoria;
- detectar idioma;
- enriquecer metadados.

A IA não pode:

- alterar o arquivo original;
- declarar autoria sem confirmação quando houver dúvida;
- incorporar fonte externa ao Cérebro sem escolha explícita.

## 13.2. Documento Processado

A IA pode:

- detectar estrutura;
- extrair elementos;
- resumir;
- relacionar;
- classificar;
- sugerir novos conceitos.

A IA deve:

- fornecer evidências;
- registrar confiança;
- utilizar saída estruturada;
- respeitar taxonomia existente antes de propor conceito novo.

## 13.3. Cérebro Autoral

A IA pode:

- propor características;
- propor metodologias;
- propor regras;
- detectar evolução;
- encontrar exceções.

A IA não pode:

- transformar uma hipótese em característica confirmada sem processo definido;
- atribuir influência externa ao autor como se fosse autoria;
- apagar versões anteriores;
- usar rascunho próprio como evidência autoral automática.

## 13.4. Reflexões

A IA pode:

- analisar entrada;
- recuperar contexto;
- detectar conflito;
- gerar plano;
- redigir;
- auditar.

A IA deve separar:

- pensamento atual do usuário;
- evidência histórica do usuário;
- referência externa;
- influência externa deliberada;
- elaboração nova.

---

# 14. Estratégia de RLS

Princípio:

```text
usuário A nunca lê, altera ou referencia dados do usuário B
```

Política base para tabelas com `usuario_id`:

```sql
using (usuario_id = auth.uid())
with check (usuario_id = auth.uid())
```

Tabelas globais do sistema, como dimensões canônicas, poderão ser somente leitura para usuários autenticados.

Tabelas sensíveis de auditoria e processamento poderão ser acessadas exclusivamente pelo backend e por views/funções seguras.

---

# 15. Estratégia de índices

## Biblioteca

- usuário + estado
- usuário + autoria + participação no Cérebro
- hash SHA-256
- título normalizado

## Processamento

- documento + ordem
- seção + ordem
- GIN Full Text
- HNSW embedding
- estado das execuções

## Taxonomia

- termo normalizado
- conceito origem/destino
- versão ativa

## Cérebro

- versão ativa
- dimensão
- estado de revisão
- origem
- característica → evidências
- influência ativa

## Reflexões

- usuário + estado
- reflexão + número de versão
- contexto + ordem

---

# 16. Fluxo de integridade completo

```text
ARQUIVO ORIGINAL
     ↓
biblioteca.obras
     ↓
biblioteca.versoes_obras
     ↓
processamento.execucoes
     ↓
processamento.secoes
     ↓
processamento.fragmentos
     ↓
processamento.sinteses
     ↓
processamento.elementos
     ↓
taxonomia
     ↓
processamento.evidencias
     ↓
processamento.vetores
     ↓
processamento.relacoes_elementos
     ↓
documento_processado candidato
     ↓
validação
     ↓
documento_processado ativo
     ↓
participa do Cérebro?
     │
 ┌───┴───────────────────┐
 │                       │
autoral                externa
 │                       │
núcleo             referência apenas
 │                       │
 │                usuário autorizou?
 │                       │
 │                   ┌───┴───┐
 │                  não     sim
 │                   │       │
 │                   │   influência externa
 └───────────────┬───┴───────┘
                 ↓
         Cérebro candidato
                 ↓
          revisão/validação
                 ↓
           Cérebro ativo
                 ↓
          Motor de Reflexões
```

---

# 17. Ordem recomendada das migrations

1. Extensões PostgreSQL necessárias.
2. Schemas.
3. Tabelas de `sistema`.
4. Tabelas de `taxonomia`.
5. Tabelas de `biblioteca`.
6. Tabelas de `processamento`.
7. Tabelas de `cerebro_autoral`.
8. Tabelas de `reflexoes`.
9. Tabelas de `auditoria`.
10. Constraints e FKs.
11. Índices.
12. Funções utilitárias.
13. Triggers de `atualizado_em`.
14. RLS.
15. Policies.
16. Views e RPCs seguras no schema `aplicacao`.
17. Seeds da Taxonomia Mestre.
18. Seeds das dimensões do Cérebro.
19. Testes de segurança e integridade.

---

# 18. Critérios para a primeira migration

A primeira migration só deverá ser escrita depois que este dicionário for aceito como base.

Ela deverá:

- criar schemas;
- ativar extensões necessárias;
- criar tabelas fundacionais;
- criar constraints;
- criar índices essenciais;
- ativar RLS;
- criar seeds canônicos;
- conter comentários SQL (`COMMENT ON`) explicando cada tabela importante;
- possuir plano explícito de rollback;
- passar por advisors de segurança e desempenho;
- possuir testes de RLS.

---

# 19. Decisões deliberadamente adiadas

Ainda não devem ser congelados na migration inicial:

1. modelo OpenAI exato para cada função;
2. pesos finais da função de reranking;
3. fórmula definitiva da confiança autoral;
4. conjunto completo de tipos de arquivos;
5. estratégia final para OCR de documentos escaneados;
6. intensidade padrão de influências externas;
7. política final de reconstrução completa do Cérebro;
8. thresholds automáticos de criação de novos conceitos.

Essas decisões devem permanecer configuráveis e avaliáveis.

---

# 20. Definição final

```text
BIBLIOTECA
= fonte original

DOCUMENTO PROCESSADO
= compreensão estruturada da obra

TAXONOMIA
= organização canônica do conhecimento

NÚCLEO AUTORAL
= metodologia inferida prioritariamente das obras do usuário

INFLUÊNCIA EXTERNA
= metodologia de terceiros incorporada somente por escolha explícita

CÉREBRO ATIVO
= núcleo + influências autorizadas

REFLEXÃO
= aplicação contextual do Cérebro a uma nova situação
```

A regra máxima do sistema é:

> A inteligência artificial pode interpretar, organizar, propor e escrever; a integridade, a proveniência e a identidade autoral devem permanecer verificáveis pelo sistema e controláveis pelo usuário.

---

## Status do Dicionário v1.0

**Pronto para:** revisão arquitetural e transformação em migration SQL inicial.  
**Próximo artefato recomendado:** `MIGRATION_0001_FUNDACAO_CEREBRO_AUTORAL.sql`.
