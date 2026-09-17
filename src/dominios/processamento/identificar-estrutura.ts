import { z } from 'zod'
import {
  validarArtefatoNormalizado,
  type ArtefatoNormalizado,
} from './normalizar-conteudo.ts'

const HASH_SHA256 = /^[0-9a-f]{64}$/

export const TipoNoEstruturalEnum = z.enum([
  'obra',
  'parte',
  'capitulo',
  'secao',
  'subsecao',
  'paragrafo',
  'bloco_codigo',
  'citacao',
  'lista',
])

export type TipoNoEstrutural = z.infer<typeof TipoNoEstruturalEnum>

export const NivelNivelNaoNulo = z.number().int().min(1).max(6)

export const ElementoEstruturalSchema = z
  .object({
    id_no: z.string().min(1),
    id_pai: z.string().nullable(),
    tipo: TipoNoEstruturalEnum,
    titulo: z.string().nullable(),
    nivel: z.number().int().nonnegative(),
    ordem: z.number().int().positive(),
    posicao_inicio: z.number().int().nonnegative(),
    posicao_fim: z.number().int().nonnegative(),
    pagina_inicio: z.number().int().positive().nullable(),
    pagina_fim: z.number().int().positive().nullable(),
    conteudo_texto: z.string(),
    confianca_sinal: z.enum(['alta', 'media', 'baixa']),
  })
  .strict()

export type ElementoEstrutural = z.infer<typeof ElementoEstruturalSchema>

export const FonteEstruturadaSchema = z
  .object({
    nome_arquivo: z.string().min(1),
    tipo_mime_registrado: z.string(),
    hash_sha256_original: z.string().regex(HASH_SHA256),
    hash_sha256_artefato_extraido: z.string().regex(HASH_SHA256),
    hash_sha256_artefato_normalizado: z.string().regex(HASH_SHA256),
  })
  .strict()

export const MetadadosEstruturaSchema = z
  .object({
    total_elementos: z.number().int().nonnegative(),
    total_partes: z.number().int().nonnegative(),
    total_capitulos: z.number().int().nonnegative(),
    total_secoes: z.number().int().nonnegative(),
    total_paragrafos: z.number().int().nonnegative(),
    contem_hierarquia_explicitada: z.boolean(),
  })
  .strict()

export const ArtefatoEstruturadoSchema = z
  .object({
    schema_version: z.literal(1),
    formato: z.enum(['texto', 'markdown', 'pdf']),
    encoding: z.literal('utf-8'),
    metodo: z.literal('identificacao_estrutura_deterministica_v1'),
    fonte: FonteEstruturadaSchema,
    metadados: MetadadosEstruturaSchema,
    elementos: z.array(ElementoEstruturalSchema),
  })
  .strict()

export type ArtefatoEstruturado = z.infer<typeof ArtefatoEstruturadoSchema>

export function validarArtefatoEstruturadoJson(conteudoJson: string): ArtefatoEstruturado {
  const dados = JSON.parse(conteudoJson)
  return ArtefatoEstruturadoSchema.parse(dados)
}

export function identificarEstruturaConteudo(
  artefatoNormalizado: ArtefatoNormalizado,
  hashArtefatoNormalizado: string
): ArtefatoEstruturado {
  const fonte = {
    nome_arquivo: artefatoNormalizado.fonte.nome_arquivo,
    tipo_mime_registrado: artefatoNormalizado.fonte.tipo_mime_registrado,
    hash_sha256_original: artefatoNormalizado.fonte.hash_sha256_original,
    hash_sha256_artefato_extraido: artefatoNormalizado.fonte.hash_sha256_artefato_extraido,
    hash_sha256_artefato_normalizado: hashArtefatoNormalizado,
  }

  const elementos: ElementoEstrutural[] = []
  let ordemAtual = 1
  let totalPartes = 0
  let totalCapitulos = 0
  let totalSecoes = 0
  let totalParagrafos = 0
  let contemHierarquia = false

  if (artefatoNormalizado.formato === 'pdf') {
    let posicaoGlobal = 0
    let noPaiAtualId: string | null = null

    for (const pag of artefatoNormalizado.paginas) {
      const linhas = pag.conteudo.split('\n')
      for (const linha of linhas) {
        const linhaLimpa = linha.trim()
        const inicioPos = posicaoGlobal
        const fimPos = inicioPos + linha.length
        posicaoGlobal = fimPos + 1

        if (!linhaLimpa) continue

        const padraoCapitulo = /^(cap[ií]tulo|parte|se[çc][ãa]o)\s+([0-9ivxlcdm]+|[\w\s]+)/i
        const matchCapitulo = linhaLimpa.match(padraoCapitulo)

        if (matchCapitulo) {
          contemHierarquia = true
          const termo = matchCapitulo[1].toLowerCase()
          let tipo: TipoNoEstrutural = 'secao'
          if (termo.startsWith('parte')) {
            tipo = 'parte'
            totalPartes += 1
          } else if (termo.startsWith('cap')) {
            tipo = 'capitulo'
            totalCapitulos += 1
          } else {
            totalSecoes += 1
          }

          const novoId = `elem-${ordemAtual}`
          elementos.push({
            id_no: novoId,
            id_pai: null,
            tipo,
            titulo: linhaLimpa,
            nivel: tipo === 'parte' ? 1 : tipo === 'capitulo' ? 2 : 3,
            ordem: ordemAtual++,
            posicao_inicio: inicioPos,
            posicao_fim: fimPos,
            pagina_inicio: pag.numero,
            pagina_fim: pag.numero,
            conteudo_texto: linhaLimpa,
            confianca_sinal: 'alta',
          })
          noPaiAtualId = novoId
        } else {
          totalParagrafos += 1
          elementos.push({
            id_no: `elem-${ordemAtual}`,
            id_pai: noPaiAtualId,
            tipo: 'paragrafo',
            titulo: null,
            nivel: 0,
            ordem: ordemAtual++,
            posicao_inicio: inicioPos,
            posicao_fim: fimPos,
            pagina_inicio: pag.numero,
            pagina_fim: pag.numero,
            conteudo_texto: linhaLimpa,
            confianca_sinal: 'alta',
          })
        }
      }
    }
  } else {
    // Texto / Markdown
    const texto = artefatoNormalizado.conteudo
    const linhas = texto.split('\n')
    let posicaoGlobal = 0
    let noPaiAtualId: string | null = null

    for (const linha of linhas) {
      const inicioPos = posicaoGlobal
      const fimPos = inicioPos + linha.length
      posicaoGlobal = fimPos + 1

      const linhaLimpa = linha.trim()
      if (!linhaLimpa) continue

      if (artefatoNormalizado.formato === 'markdown' && linhaLimpa.startsWith('#')) {
        contemHierarquia = true
        const matchHeading = linhaLimpa.match(/^(#{1,6})\s+(.*)$/)
        if (matchHeading) {
          const numHashes = matchHeading[1].length
          const tituloTexto = matchHeading[2]
          let tipo: TipoNoEstrutural = 'secao'
          if (numHashes === 1) {
            tipo = 'parte'
            totalPartes += 1
          } else if (numHashes === 2) {
            tipo = 'capitulo'
            totalCapitulos += 1
          } else {
            totalSecoes += 1
          }

          const novoId = `elem-${ordemAtual}`
          elementos.push({
            id_no: novoId,
            id_pai: null,
            tipo,
            titulo: tituloTexto,
            nivel: numHashes,
            ordem: ordemAtual++,
            posicao_inicio: inicioPos,
            posicao_fim: fimPos,
            pagina_inicio: null,
            pagina_fim: null,
            conteudo_texto: linhaLimpa,
            confianca_sinal: 'alta',
          })
          noPaiAtualId = novoId
          continue
        }
      }

      // Parágrafos regulares ou blocos
      totalParagrafos += 1
      elementos.push({
        id_no: `elem-${ordemAtual}`,
        id_pai: noPaiAtualId,
        tipo: 'paragrafo',
        titulo: null,
        nivel: 0,
        ordem: ordemAtual++,
        posicao_inicio: inicioPos,
        posicao_fim: fimPos,
        pagina_inicio: null,
        pagina_fim: null,
        conteudo_texto: linhaLimpa,
        confianca_sinal: 'alta',
      })
    }
  }

  return ArtefatoEstruturadoSchema.parse({
    schema_version: 1,
    formato: artefatoNormalizado.formato,
    encoding: 'utf-8',
    metodo: 'identificacao_estrutura_deterministica_v1',
    fonte,
    metadados: {
      total_elementos: elementos.length,
      total_partes: totalPartes,
      total_capitulos: totalCapitulos,
      total_secoes: totalSecoes,
      total_paragrafos: totalParagrafos,
      contem_hierarquia_explicitada: contemHierarquia,
    },
    elementos,
  })
}
