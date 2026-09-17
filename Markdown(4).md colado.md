# ARQUITETURA TÉCNICA DE IMPLEMENTAÇÃO

## CÉREBRO AUTORAL

### Versão arquitetural canônica

---

# 1. OBJETIVO DO PRODUTO

O aplicativo será uma plataforma pessoal de inteligência autoral.

O objetivo técnico principal do sistema será construir progressivamente um:

# CÉREBRO AUTORAL

Esse cérebro deverá representar computacionalmente:

- metodologia de pensamento;
- metodologia de interpretação;
- metodologia de associação;
- metodologia argumentativa;
- metodologia de escrita;
- metodologia narrativa;
- metodologia de revisão;
- estruturas recorrentes de raciocínio;
- maneiras de iniciar uma reflexão;
- maneiras de desenvolver uma tensão;
- maneiras de relacionar experiência e conceito;
- maneiras de construir argumentos;
- maneiras de realizar transições;
- maneiras de chegar a conclusões;
- identidade linguística;
- recursos retóricos;
- evolução intelectual.

Seu propósito final será aplicar essa metodologia para auxiliar na construção de:

# NOVAS REFLEXÕES PERSONALIZADAS.

---

# 2. MACROARQUITETURA

O sistema terá quatro grandes áreas funcionais.

```text
BIBLIOTECA
      ↓
PROCESSAMENTO INTELIGENTE
      ↓
DOCUMENTOS PROCESSADOS
      ↓
CONSTRUÇÃO DO CÉREBRO AUTORAL
      ↓
MOTOR DE REFLEXÕES
      ↓
REFLEXÃO PERSONALIZADA
      ↓
REVISÃO HUMANA
      ↓
NOVAS EVIDÊNCIAS AUTORAIS

```

A inteligência artificial participa de praticamente todo o fluxo.

Entretanto:

**IA interpreta.**

**IA propõe.**

**IA organiza.**

**IA relaciona.**

**IA raciocina.**

O sistema determinístico controla:

**identidade, integridade, permissões, estados, versões, proveniência e persistência.**

---

# 3. STACK TECNOLÓGICA

## Aplicação

Next.js + React + TypeScript.

## Repositório e engenharia

Git + GitHub.

## Hospedagem

Vercel.

## Banco de dados

Supabase PostgreSQL.

## Arquivos

Supabase Storage privado.

## Autenticação

Supabase Auth.

## Vetores

PostgreSQL + pgvector.

## Pesquisa lexical

PostgreSQL Full Text Search.

## Inteligência artificial

OpenAI API.

## Orquestração de tarefas demoradas

Vercel Workflows.

---

# 4. TAXONOMIA TÉCNICA

Tudo que controlarmos terá nomenclatura canônica em português.

Banco:

```text
snake_case
minúsculas
sem espaços
sem acentos

```

Exemplo:

```text
documentos_processados
caracteristicas_autorais
nivel_confianca
pagina_inicial

```

Interface:

```text
Documentos Processados
Características Autorais
Nível de Confiança
Página Inicial

```

Não utilizaremos nomes diferentes para representar a mesma entidade.

---

# 5. SCHEMAS PRINCIPAIS DO SUPABASE

```text
biblioteca
processamento
taxonomia
cerebro_autoral
reflexoes
auditoria
sistema

```

Schemas pertencentes ao Supabase continuarão intactos:

```text
auth
storage

```

---

# 6. BIBLIOTECA

A Biblioteca representa as fontes originais.

Ela contém:

- livros;
- cartas;
- textos;
- reflexões;
- capítulos;
- documentos;
- referências externas.

O arquivo original nunca será alterado durante o processamento.

---

# 7. CLASSIFICAÇÃO DA FONTE

Cada obra terá dois conceitos distintos.

## Autoria

```text
autoral
externa

```

## Participação no Cérebro

```text
autoral_prioritaria
externa_referencia
externa_influencia
excluida_cerebro

```

---

# 8. REGRA DO NÚCLEO AUTORAL

Se:

```text
autoria = autoral

```

e:

```text
participacao_cerebro = autoral_prioritaria

```

o documento poderá contribuir para o Núcleo Autoral depois do processamento completo.

---

# 9. DOCUMENTOS EXTERNOS

Por padrão:

```text
autoria = externa
participacao_cerebro = externa_referencia

```

Esses materiais poderão:

- aparecer em pesquisas;
- fornecer conhecimento;
- ser utilizados em reflexões;
- ser citados;
- ser relacionados com pensamentos do autor.

Mas não modificarão automaticamente a metodologia pessoal do Cérebro.

---

# 10. INFLUÊNCIA EXTERNA DELIBERADA

O usuário poderá selecionar:

# INCORPORAR METODOLOGIA AO CÉREBRO

Nesse momento:

```text
participacao_cerebro = externa_influencia

```

O sistema perguntará quais dimensões serão incorporadas.

Exemplo:

```text
[x] metodologia de pensamento
[x] metodologia argumentativa
[ ] opiniões e conceitos
[x] arquitetura narrativa
[ ] vocabulário
[x] recursos retóricos

```

Portanto, será possível aprender intelectualmente com outro autor sem transformar suas ideias em supostas ideias históricas do usuário.

---

# 11. COMPOSIÇÃO DO CÉREBRO

```text
NÚCLEO AUTORAL
       +
INFLUÊNCIAS DELIBERADAS
       =
CÉREBRO ATIVO

```

As duas origens jamais serão confundidas.

---

# 12. TABELAS DA BIBLIOTECA

## `biblioteca.obras`

Principais campos:

```text
id
usuario_id
codigo
titulo_original
titulo_exibicao
titulo_normalizado
tipo_obra
autoria
participacao_cerebro
autor_original
idioma
categoria
descricao
data_producao
periodo_autoral
estado
criado_em
atualizado_em

```

---

# 13. VERSIONAMENTO DAS OBRAS

## `biblioteca.versoes_obras`

```text
id
obra_id
codigo
numero_versao
nome_arquivo
caminho_arquivo
tipo_mime
tamanho_bytes
hash_sha256
quantidade_paginas
quantidade_palavras
criado_em

```

Uma nova versão nunca destrói a anterior.

---

# 14. STORAGE

Bucket privado:

```text
originais-biblioteca

```

Caminho:

```text
/{usuario_id}/{obra_id}/{versao_id}/original.ext

```

---

# 15. UPLOAD

```text
arquivo recebido
      ↓
validação
      ↓
hash
      ↓
verificação de duplicidade
      ↓
preservação do original
      ↓
registro da obra
      ↓
registro da versão
      ↓
workflow de processamento

```

A interface não ficará esperando o livro ser totalmente processado.

---

# 16. WORKFLOW PRINCIPAL

Função conceitual:

```text
processar_obra()

```

Etapas:

```text
01_validar_arquivo
02_identificar_formato
03_extrair_conteudo
04_normalizar_conteudo
05_identificar_estrutura
06_construir_hierarquia
07_criar_fragmentos
08_criar_sinteses
09_extrair_elementos
10_normalizar_taxonomia
11_criar_relacoes
12_gerar_embeddings
13_criar_indices
14_realizar_analise_autoral_local
15_validar_processamento
16_publicar_documento_processado
17_avaliar_participacao_cerebro
18_atualizar_cerebro

```

---

# 17. PROCESSAMENTO RESILIENTE

Cada etapa deverá ser:

- idempotente;
- reexecutável;
- versionada;
- observável;
- independente;
- recuperável.

Exemplo:

```text
obra: OBR-00014
versao: 3
pipeline: 2.0
etapa: gerar_embeddings

```

Essa combinação terá uma chave única.

Executá-la novamente não poderá gerar duplicações.

---

# 18. ESTADOS

```text
recebido
validando
extraindo
normalizando
estruturando
segmentando
analisando
classificando
vetorizando
relacionando
validando_resultado
concluido
falhou

```

---

# 19. DOCUMENTO ATÔMICO

O Cérebro nunca utilizará um documento parcialmente processado.

Teremos:

```text
versao_processada_candidata

```

e:

```text
versao_processada_ativa

```

Somente depois das verificações críticas:

```text
candidata
→
ativa

```

---

# 20. DOCUMENTO PROCESSADO

## `processamento.documentos_processados`

```text
id
obra_id
versao_obra_id
execucao_id
codigo
titulo
resumo_global
sintese_analitica
quantidade_partes
quantidade_capitulos
quantidade_secoes
quantidade_fragmentos
quantidade_elementos
versao_pipeline
versao_taxonomia
estado
processado_em

```

---

# 21. REPRESENTAÇÃO HIERÁRQUICA

O documento possuirá vários níveis.

```text
OBRA
│
├── síntese da obra
│
├── PARTE
│   ├── síntese
│   │
│   └── CAPÍTULO
│       ├── síntese
│       │
│       └── SEÇÃO
│           ├── síntese
│           │
│           └── FRAGMENTOS

```

Não trabalharemos apenas com chunks planos.

---

# 22. SEÇÕES

## `processamento.secoes`

```text
id
documento_processado_id
secao_pai_id
codigo
tipo
titulo
ordem
pagina_inicial
pagina_final
conteudo

```

---

# 23. FRAGMENTOS

## `processamento.fragmentos`

```text
id
documento_processado_id
secao_id
codigo
ordem
fragmento_anterior_id
fragmento_seguinte_id
pagina_inicial
pagina_final
conteudo
quantidade_tokens

```

---

# 24. SÍNTESES HIERÁRQUICAS

## `processamento.sinteses`

```text
id
documento_processado_id
tipo_alvo
alvo_id
nivel
conteudo
modelo_ia
versao_prompt

```

Exemplos:

```text
fragmento
secao
capitulo
parte
obra

```

Isso permitirá consultas globais sem precisar reconstruir todo o livro.

---

# 25. VETORES

## `processamento.vetores`

```text
id
tipo_alvo
alvo_id
embedding
modelo
dimensoes
versao
criado_em

```

Poderemos vetorizar:

- fragmentos;
- seções;
- capítulos;
- sínteses.

---

# 26. MOTOR DOCUMENTAL DE IA

Responsável por transformar texto estruturado em conhecimento estruturado.

Ele identificará:

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
recurso_linguistico
recurso_narrativo
estrutura_argumentativa
mudanca_de_pensamento
referencia

```

---

# 27. ELEMENTOS

## `processamento.elementos`

```text
id
documento_processado_id
codigo
tipo
titulo
descricao
conceito_taxonomico_id
importancia
confianca
estado_revisao
modelo_ia
versao_prompt
criado_em

```

---

# 28. EVIDÊNCIAS

## `processamento.evidencias`

```text
id
elemento_id
fragmento_id
pagina_inicial
pagina_final
trecho_referencia
forca_evidencia

```

Nenhum elemento importante deverá existir sem procedência.

---

# 29. TAXONOMIA MESTRE

## `taxonomia.conceitos`

```text
id
codigo
termo_preferencial
definicao
nota_escopo
categoria
estado

```

## `taxonomia.termos`

```text
id
conceito_id
termo
tipo
idioma

```

Tipos:

```text
preferencial
alternativo
sinonimo
historico

```

---

# 30. RELAÇÕES TAXONÔMICAS

## `taxonomia.relacoes`

```text
conceito_origem_id
tipo_relacao
conceito_destino_id
confianca

```

Tipos iniciais:

```text
mais_amplo
mais_especifico
relacionado
contrasta_com
deriva_de
evolui_para
associado_a

```

---

# 31. MOTOR TAXONÔMICO DE IA

Ao encontrar algo novo:

```text
extrair
  ↓
normalizar
  ↓
buscar taxonomia
  ↓
comparar sinônimos
  ↓
comparar conceitos próximos
  ↓
reutilizar ou propor
  ↓
relacionar
  ↓
registrar evidência

```

A IA não poderá simplesmente gerar milhares de tags diferentes.

---

# 32. GRAFO INTELECTUAL

## `processamento.relacoes_elementos`

Relações possíveis:

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

```

Exemplo:

```text
experiencia
→ exemplifica
→ conceito

argumento
→ sustenta
→ tese

ideia
→ contradiz
→ ideia

```

---

# 33. TRÊS PLANOS ANALÍTICOS

O Cérebro deverá separar obrigatoriamente:

## CONTEÚDO

Sobre o que o autor pensa.

## MÉTODO

Como o autor desenvolve o pensamento.

## EXPRESSÃO

Como o pensamento aparece linguisticamente.

Isso evita confundir:

```text
tema recorrente

```

com:

```text
metodologia autoral

```

---

# 34. CÉREBRO AUTORAL

Schema:

```text
cerebro_autoral

```

O Cérebro será formado por:

```text
versoes
dimensoes
caracteristicas
metodologias
regras
transicoes
evidencias
excecoes
influencias_externas
fontes_cerebro

```

---

# 35. DIMENSÕES DO CÉREBRO

Taxonomia inicial:

```text
metodologia_de_pensamento
metodologia_de_interpretacao
metodologia_de_associacao
metodologia_argumentativa
metodologia_de_escrita
metodologia_de_revisao
arquitetura_narrativa
arquitetura_de_paragrafo
formas_de_abertura
formas_de_transicao
formas_de_conclusao
recursos_retoricos
identidade_linguistica
relacao_experiencia_conceito
padroes_de_tensao
padroes_de_sintese
universo_conceitual
evolucao_autoral

```

---

# 36. CARACTERÍSTICAS AUTORAIS

## `cerebro_autoral.caracteristicas`

```text
id
versao_cerebro_id
dimensao_id
codigo
titulo
descricao
origem
confianca
frequencia
diversidade_fontes
primeira_ocorrencia
ultima_ocorrencia
estado_revisao

```

Origem:

```text
nucleo_autoral
influencia_externa

```

---

# 37. CONFIANÇA

A confiança não será simplesmente um número criado pela IA.

Será calculada a partir de sinais como:

```text
quantidade de evidências
quantidade de documentos
diversidade de documentos
diversidade temporal
frequência
contraexemplos
confirmação humana

```

---

# 38. EVIDÊNCIAS DO CÉREBRO

## `cerebro_autoral.evidencias`

```text
id
caracteristica_id
documento_processado_id
fragmento_id
forca
justificativa

```

---

# 39. EXCEÇÕES

## `cerebro_autoral.excecoes`

Exemplo:

```text
Característica:
Normalmente inicia pelo concreto.

Suporte:
42 ocorrências.

Exceções:
11 ocorrências.

```

Isso impede que padrões se transformem em caricaturas.

---

# 40. MOTOR AUTORAL

Pipeline:

```text
selecionar corpus
      ↓
separar autoria e influências
      ↓
analisar documentos individualmente
      ↓
comparar documentos
      ↓
descobrir recorrências
      ↓
buscar contraexemplos
      ↓
analisar evolução temporal
      ↓
formular características
      ↓
ligar evidências
      ↓
formular metodologias
      ↓
criar regras operacionais
      ↓
criar versão candidata do Cérebro

```

---

# 41. METODOLOGIAS

## `cerebro_autoral.metodologias`

Exemplo:

```text
Nome:
Do acontecimento à interpretação.

Descrição:
O autor frequentemente começa por
um acontecimento concreto, identifica
uma tensão e transforma essa tensão
em pergunta conceitual.

```

---

# 42. REGRAS OPERACIONAIS

## `cerebro_autoral.regras`

Transformam observação em orientação utilizável.

Exemplo:

```text
CARACTERÍSTICA

O autor frequentemente inicia pelo concreto.

REGRA

Quando adequado, começar a reflexão
pela experiência antes de apresentar
a abstração.

ANTI-REGRA

Não utilizar obrigatoriamente essa
estrutura em todos os textos.

```

---

# 43. GRAFO METODOLÓGICO

## `cerebro_autoral.transicoes`

Exemplo:

```text
experiencia
     ↓
observacao
     ↓
tensao
     ↓
questionamento
     ↓
associacao
     ↓
contraste
     ↓
elaboracao
     ↓
sintese
     ↓
conclusao

```

Esse grafo será uma das estruturas mais importantes do sistema.

Ele representa:

# COMO O RACIOCÍNIO SE MOVE.

---

# 44. INFLUÊNCIAS EXTERNAS

## `cerebro_autoral.influencias_externas`

```text
id
obra_id
estado
grau_influencia
justificativa_usuario
incorporado_em
removido_em

```

## `cerebro_autoral.escopos_influencia`

Permitirá escolher:

```text
metodologia_pensamento
metodologia_escrita
argumentacao
arquitetura_narrativa
recursos_retoricos
interpretacao
universo_conceitual

```

---

# 45. VERSIONAMENTO DO CÉREBRO

## `cerebro_autoral.versoes`

```text
id
usuario_id
codigo
numero_versao
estado
quantidade_documentos
quantidade_evidencias
criado_em
ativado_em

```

Estados:

```text
em_construcao
proposta
ativa
arquivada

```

Toda reflexão saberá qual versão do Cérebro utilizou.

---

# 46. ATUALIZAÇÃO INCREMENTAL

Novo documento processado:

```text
Documento Processado
      ↓
comparar com Cérebro atual
      ↓
reforça característica?
      ↓
enfraquece?
      ↓
gera exceção?
      ↓
apresenta característica nova?
      ↓
indica evolução?
      ↓
versão candidata

```

Nem todo livro exigirá reconstrução integral.

---

# 47. RECONSTRUÇÃO COMPLETA

Também existirá:

```text
reconstruir_cerebro()

```

Usada quando:

- taxonomia mudar significativamente;
- pipeline autoral mudar;
- modelo mudar;
- usuário solicitar;
- grande volume de documentos for incorporado.

---

# 48. RECUPERAÇÃO HÍBRIDA

O sistema combinará:

```text
Full Text Search
+
pgvector
+
taxonomia
+
metadados
+
hierarquia documental
+
grafo intelectual
+
autoria
+
período
+
tipo de fonte
+
Cérebro Autoral

```

---

# 49. RECUPERAÇÃO MULTINÍVEL

Uma consulta poderá recuperar:

```text
fragmentos
seções
capítulos
sínteses
conceitos
elementos
relações
características autorais
metodologias
regras

```

---

# 50. RECUPERAÇÃO ADAPTATIVA

O Motor de IA deverá decidir primeiro:

```text
preciso consultar documentos?

preciso consultar o Cérebro?

preciso consultar influências?

preciso das três coisas?

o pensamento atual é suficiente?

```

Isso reduz ruído.

---

# 51. PACOTE DE CONTEXTO

Para cada tarefa, criaremos um objeto:

```text
contexto_trabalho

```

Contendo:

```text
objetivo

reflexao_externa

comentario_atual

documentos_relevantes

fragmentos_relevantes

conceitos_relevantes

experiencias_relevantes

caracteristicas_autorais

metodologias

regras

influencias_deliberadas

conflitos

```

---

# 52. OPENAI

Teremos uma camada:

```text
ia/

```

Com motores especializados:

```text
motor_documental
motor_taxonomico
motor_autoral
motor_recuperacao
motor_planejamento
motor_redacao
motor_auditoria
motor_aprendizado

```

---

# 53. MODELOS CONFIGURÁVEIS

Configuração:

```text
MODELO_IA_EXTRACAO
MODELO_IA_ANALISE
MODELO_IA_CEREBRO
MODELO_IA_REDACAO
MODELO_IA_AUDITORIA
MODELO_IA_EMBEDDING

```

Não haverá nomes de modelos espalhados pelo código.

---

# 54. STRUCTURED OUTPUTS

Tudo que virar dado estruturado seguirá:

```text
modelo
  ↓
JSON Schema
  ↓
validação
  ↓
normalização
  ↓
validação de referências
  ↓
persistência

```

A IA nunca poderá executar:

```text
resposta textual
→
salvar como verdade

```

sem validação intermediária.

---

# 55. PROMPTS VERSIONADOS

Estrutura:

```text
prompts/
├── processamento/
├── taxonomia/
├── cerebro/
├── recuperacao/
├── reflexoes/
└── auditoria/

```

Cada prompt terá:

```text
nome
versao
finalidade
entrada
schema_saida

```

---

# 56. MOTOR DE REFLEXÕES

Fluxo completo:

```text
REFLEXÃO EXTERNA
       ↓
análise
       ↓
COMENTÁRIO ATUAL
       ↓
análise
       ↓
classificação da tarefa
       ↓
recuperação adaptativa
       ↓
contexto de trabalho
       ↓
detecção de conflitos
       ↓
plano
       ↓
rascunho
       ↓
auditoria
       ↓
revisão do autor
       ↓
versão aprovada

```

---

# 57. PLANO ANTES DA REDAÇÃO

## `reflexoes.planos`

Estrutura:

```text
questao_central
tese_provisoria
abertura
movimentos_do_raciocinio
experiencias
conceitos
argumentos
tensoes
contrastes
sintese
direcao_da_conclusao

```

---

# 58. AUDITOR INDEPENDENTE

O processo que escreve não será o único processo que verifica.

O auditor analisará:

```text
há afirmação sem fundamento?

houve cópia excessiva?

o comentário atual foi respeitado?

a metodologia foi utilizada corretamente?

a influência externa foi identificada?

há caricatura de estilo?

há conflito ignorado?

a reflexão realmente é nova?

```

---

# 59. REFLEXÕES

Schema:

```text
reflexoes

```

Tabelas principais:

```text
reflexoes
entradas
contextos
itens_contexto
conflitos
planos
versoes
revisoes

```

---

# 60. VERSIONAMENTO DA REFLEXÃO

```text
V1 — IA
V2 — IA após auditoria
V3 — edição do autor
V4 — versão aprovada

```

Nada será sobrescrito silenciosamente.

---

# 61. APROVAÇÃO E APRENDIZADO SÃO DIFERENTES

Botão:

```text
APROVAR REFLEXÃO

```

não significa:

```text
INCORPORAR AO CÉREBRO

```

Para aprender:

```text
INCORPORAR COMO CONTEÚDO AUTORAL

```

A reflexão então percorre:

```text
Biblioteca
↓
Processamento
↓
Documento Processado
↓
Cérebro

```

---

# 62. APRENDIZADO POR REVISÃO

A versão gerada e a versão final serão comparadas.

```text
rascunho_ia
       ↕
versao_final_autor

```

Analisar:

```text
remoções
adições
substituições
reordenações
mudança de abertura
mudança de argumentação
mudança de transição
mudança de conclusão
mudança de linguagem

```

Isso gera:

# PROPOSTAS DE NOVAS EVIDÊNCIAS AUTORAIS.

Nunca alterações silenciosas.

---

# 63. AUDITORIA DAS CHAMADAS DE IA

## `auditoria.execucoes_ia`

```text
id
usuario_id
operacao
modelo
versao_prompt
versao_taxonomia
versao_pipeline
estado
tokens_entrada
tokens_saida
duracao_ms
criado_em

```

---

# 64. PROVENIÊNCIA

Toda informação relevante deverá responder:

```text
de onde veio?

qual arquivo?

qual versão?

qual página?

qual fragmento?

qual processamento?

qual modelo?

qual prompt?

qual taxonomia?

quando?

foi revisada pelo usuário?

```

---

# 65. SEGURANÇA

Todas as informações pessoais serão privadas.

Princípios:

```text
Storage privado
RLS
autenticação
privilégio mínimo
segredos apenas no servidor
URLs temporárias
logs sem conteúdo sensível desnecessário

```

---

# 66. PROMPT INJECTION

O conteúdo de um livro sempre será tratado como:

```text
DADO

```

Nunca:

```text
INSTRUÇÃO

```

Uma frase no documento como:

```text
"ignore as instruções anteriores"

```

não poderá controlar nenhum agente.

---

# 67. FRONTEND

Rotas conceituais:

```text
/
 /biblioteca
 /biblioteca/[obra]
 /documentos-processados
 /documentos-processados/[documento]
 /cerebro-autoral
 /cerebro-autoral/caracteristicas
 /cerebro-autoral/influencias
 /criar-reflexao
 /reflexoes
 /reflexoes/[id]
 /configuracoes

```

---

# 68. PÁGINA BIBLIOTECA

Mostrará:

```text
livros
arquivos
tipo
autoria
participação no Cérebro
status de processamento
data

```

---

# 69. PÁGINA DOCUMENTO PROCESSADO

Mostrará:

```text
estrutura
sínteses
temas
conceitos
ideias
argumentos
experiências
histórias
metáforas
relações
mapa conceitual
padrões linguísticos
evidências

```

---

# 70. PÁGINA CÉREBRO AUTORAL

Será dividida em:

```text
Visão Geral

Metodologia de Pensamento

Metodologia de Interpretação

Metodologia Argumentativa

Metodologia de Escrita

Arquitetura Narrativa

Identidade Linguística

Universo Conceitual

Grafo Metodológico

Evolução

Influências Deliberadas

Evidências

Versões

```

---

# 71. PAINEL DE INFLUÊNCIAS

Exemplo:

```text
NÚCLEO AUTORAL
18 obras

INFLUÊNCIAS DELIBERADAS
3 obras

Livro X — Autor Y
Influência:
Metodologia argumentativa

Peso:
Moderado

[Editar]
[Desativar]
[Remover]

```

---

# 72. INFRAESTRUTURA GITHUB

Branch principal:

```text
main

```

Branches:

```text
funcionalidade/biblioteca
funcionalidade/processamento
funcionalidade/taxonomia
funcionalidade/cerebro
funcionalidade/reflexoes

```

Fluxo:

```text
branch
↓
Pull Request
↓
CI
↓
Preview
↓
testes
↓
merge
↓
produção

```

---

# 73. CI

Checks obrigatórios:

```text
lint
TypeScript
testes unitários
testes integração
testes SQL
testes migrations
testes RLS
testes taxonomia
testes schemas IA
testes recuperação
testes E2E
build

```

---

# 74. AMBIENTES

```text
DESENVOLVIMENTO LOCAL

PREVIEW / PR

PRODUÇÃO

```

Idealmente:

```text
GitHub PR
   ├── Vercel Preview
   └── Supabase Preview Branch

```

Produção permanece isolada.

---

# 75. ORGANIZAÇÃO DO REPOSITÓRIO

```text
src/
├── app/
├── componentes/
├── dominios/
│   ├── biblioteca/
│   ├── processamento/
│   ├── taxonomia/
│   ├── cerebro-autoral/
│   └── reflexoes/
│
├── ia/
│   ├── documental/
│   ├── taxonomica/
│   ├── autoral/
│   ├── recuperacao/
│   ├── planejamento/
│   ├── redacao/
│   ├── auditoria/
│   └── aprendizado/
│
├── workflows/
│   ├── processar-obra/
│   ├── atualizar-cerebro/
│   └── construir-reflexao/
│
└── infraestrutura/
    ├── supabase/
    ├── openai/
    └── vercel/

supabase/
├── migrations/
├── seeds/
└── tests/

taxonomia/
prompts/
avaliacoes/
docs/
tests/

```

---

# 76. OBSERVABILIDADE

Precisamos conseguir responder:

```text
por que o livro falhou?

em qual etapa?

qual chamada de IA?

qual prompt?

qual modelo?

qual documento?

quanto custou?

quanto demorou?

quantas tentativas?

qual versão produziu o resultado?

```

---

# 77. TESTES DO CÉREBRO

Criar avaliações específicas para:

```text
detecção de metodologia

separação entre tema e método

identificação de evidências

identificação de exceções

distinção entre autoria e influência

recuperação correta

aplicação metodológica

não-caricatura

não-cópia

```

---

# 78. TESTE DE CONTAMINAÇÃO

Cenário:

```text
10 livros autorais
5 livros externos
2 influências deliberadas

```

Pergunta:

```text
"Como eu penso sobre X?"

```

O sistema deverá distinguir:

```text
o autor escreveu...

```

de:

```text
uma referência externa afirma...

```

de:

```text
o autor escolheu incorporar esta
metodologia externa ao Cérebro...

```

Esse será um teste crítico.

---

# 79. ORDEM DE IMPLEMENTAÇÃO

## FASE 0

Fundação técnica.

## FASE 1

Dicionário Mestre de Dados e Taxonomia.

## FASE 2

Biblioteca.

## FASE 3

Pipeline documental.

## FASE 4

Documento Processado.

## FASE 5

Taxonomia inteligente.

## FASE 6

Busca híbrida e grafo.

## FASE 7

Cérebro Autoral.

## FASE 8

Influências Deliberadas.

## FASE 9

Motor de Recuperação.

## FASE 10

Motor de Reflexões.

## FASE 11

Aprendizado pelas revisões.

## FASE 12

Avaliações e otimizações.

---

# 80. CRITÉRIO CENTRAL DE SUCESSO

O produto não será avaliado apenas pela aparência das telas.

Ele estará funcionando quando conseguirmos demonstrar:

```text
obras autorais
      ↓
processamento confiável
      ↓
conhecimento estruturado
      ↓
padrões transversais
      ↓
metodologia comprovável
      ↓
Cérebro Autoral
      ↓
nova situação
      ↓
pensamento presente
      ↓
recuperação pertinente
      ↓
aplicação metodológica
      ↓
nova reflexão personalizada

```

A nova reflexão deverá demonstrar:

**conteúdo pertinente + pensamento atual + memória do autor + metodologia autoral + elaboração nova.**

---

# PRINCÍPIO DEFINITIVO

# A BIBLIOTECA PRESERVA.

# A IA PROCESSA.

# O DOCUMENTO PROCESSADO ORGANIZA O CONHECIMENTO.

# A TAXONOMIA DÁ ORDEM.

# O NÚCLEO AUTORAL REPRESENTA O AUTOR.

# AS INFLUÊNCIAS EXTERNAS SÓ ENTRAM POR ESCOLHA EXPLÍCITA.

# O CÉREBRO APRENDE A METODOLOGIA.

# O MOTOR DE RECUPERAÇÃO SELECIONA O CONTEXTO.

# A IA APLICA A METODOLOGIA.

# O MOTOR DE REFLEXÕES PRODUZ ALGO NOVO.

# O AUTOR REVISA.

# O SISTEMA APRENDE COM EVIDÊNCIAS.

# E O AUTOR PERMANECE A AUTORIDADE FINAL.