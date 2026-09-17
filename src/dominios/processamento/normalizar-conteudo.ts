import { z } from 'zod'
import type { FormatoConteudoExtraivel } from './extrair-conteudo'

const HASH_SHA256 = /^[0-9a-f]{64}$/

const fonteSchema = z
  .object({
    nome_arquivo: z.string().min(1),
    tipo_mime_registrado: z.string(),
    hash_sha256_original: z.string().regex(HASH_SHA256),
  })
  .strict()

const paginaSchema = z
  .object({
    numero: z.number().int().positive(),
    conteudo: z.string(),
  })
  .strict()

const textoSchema = z
  .object({
    schema_version: z.literal(1),
    formato: z.literal('texto'),
    encoding: z.literal('utf-8'),
    metodo: z.literal('utf8_deterministico'),
    fonte: fonteSchema,
    total_paginas: z.null(),
    conteudo: z.string(),
  })
  .strict()

const markdownSchema = textoSchema.extend({ formato: z.literal('markdown') }).strict()

const pdfSchema = z
  .object({
    schema_version: z.literal(1),
    formato: z.literal('pdf'),
    encoding: z.literal('utf-8'),
    metodo: z.literal('unpdf_pdfjs_texto'),
    fonte: fonteSchema,
    total_paginas: z.number().int().positive(),
    paginas: z.array(paginaSchema).min(1),
  })
  .strict()
  .superRefine((valor, ctx) => {
    if (valor.paginas.length !== valor.total_paginas) {
      ctx.addIssue({
        code: 'custom',
        message: 'A quantidade de páginas não corresponde ao total declarado.',
      })
    }

    for (let indice = 0; indice < valor.paginas.length; indice += 1) {
      if (valor.paginas[indice]?.numero !== indice + 1) {
        ctx.addIssue({
          code: 'custom',
          message: 'As páginas devem ser sequenciais e começar em 1.',
          path: ['paginas', indice, 'numero'],
        })
        break
      }
    }
  })

const artefatoExtraidoSchema = z.union([textoSchema, markdownSchema, pdfSchema])

const fonteNormalizadaSchema = fonteSchema
  .extend({
    hash_sha256_artefato_extraido: z.string().regex(HASH_SHA256),
  })
  .strict()

const normalizacaoSchema = z
  .object({
    unicode: z.literal('NFC'),
    quebras_linha: z.literal('LF'),
    preserva_espacos_internos: z.literal(true),
    alteracoes: z
      .object({
        quebras_crlf_convertidas: z.number().int().nonnegative(),
        quebras_cr_isoladas_convertidas: z.number().int().nonnegative(),
        segmentos_alterados_nfc: z.number().int().nonnegative(),
        caracteres_antes: z.number().int().nonnegative(),
        caracteres_depois: z.number().int().nonnegative(),
      })
      .strict(),
  })
  .strict()

const textoNormalizadoSchema = z
  .object({
    schema_version: z.literal(1),
    formato: z.literal('texto'),
    encoding: z.literal('utf-8'),
    metodo: z.literal('normalizacao_tecnica_nfc_v1'),
    fonte: fonteNormalizadaSchema,
    total_paginas: z.null(),
    conteudo: z.string(),
    normalizacao: normalizacaoSchema,
  })
  .strict()

const markdownNormalizadoSchema = textoNormalizadoSchema
  .extend({ formato: z.literal('markdown') })
  .strict()

const pdfNormalizadoSchema = z
  .object({
    schema_version: z.literal(1),
    formato: z.literal('pdf'),
    encoding: z.literal('utf-8'),
    metodo: z.literal('normalizacao_tecnica_nfc_v1'),
    fonte: fonteNormalizadaSchema,
    total_paginas: z.number().int().positive(),
    paginas: z.array(paginaSchema).min(1),
    normalizacao: normalizacaoSchema,
  })
  .strict()
  .superRefine((valor, ctx) => {
    if (valor.paginas.length !== valor.total_paginas) {
      ctx.addIssue({
        code: 'custom',
        message: 'A quantidade de páginas normalizadas não corresponde ao total declarado.',
      })
    }

    for (let indice = 0; indice < valor.paginas.length; indice += 1) {
      if (valor.paginas[indice]?.numero !== indice + 1) {
        ctx.addIssue({
          code: 'custom',
          message: 'As páginas normalizadas devem ser sequenciais e começar em 1.',
          path: ['paginas', indice, 'numero'],
        })
        break
      }
    }
  })

export const artefatoNormalizadoSchema = z.union([
  textoNormalizadoSchema,
  markdownNormalizadoSchema,
  pdfNormalizadoSchema,
])

export type ArtefatoNormalizado = z.infer<typeof artefatoNormalizadoSchema>
export type ArtefatoConteudoNormalizado = ArtefatoNormalizado



export type ResultadoNormalizacao =
  | {
      ok: true
      artefato: ArtefatoConteudoNormalizado
    }
  | {
      ok: false
      codigo:
        | 'ARTEFATO_EXTRAIDO_NAO_UTF8'
        | 'ARTEFATO_EXTRAIDO_JSON_INVALIDO'
        | 'ARTEFATO_EXTRAIDO_SCHEMA_INVALIDO'
        | 'ARTEFATO_EXTRAIDO_ORIGINAL_DIVERGENTE'
      motivo: string
      detalhes?: Record<string, string | number | boolean | null>
    }

export type ResultadoValidacaoArtefatoNormalizado =
  | { ok: true; artefato: ArtefatoConteudoNormalizado }
  | {
      ok: false
      codigo:
        | 'ARTEFATO_NORMALIZADO_NAO_UTF8'
        | 'ARTEFATO_NORMALIZADO_JSON_INVALIDO'
        | 'ARTEFATO_NORMALIZADO_SCHEMA_INVALIDO'
        | 'ARTEFATO_NORMALIZADO_ORIGEM_DIVERGENTE'
      motivo: string
      detalhes?: Record<string, string | number | boolean | null>
    }

function contarOcorrencias(texto: string, expressao: RegExp) {
  return texto.match(expressao)?.length ?? 0
}

function normalizarSegmento(texto: string) {
  const quebrasCrLf = contarOcorrencias(texto, /\r\n/g)
  const semCrLf = texto.replace(/\r\n/g, '\n')
  const quebrasCr = contarOcorrencias(semCrLf, /\r/g)
  const somenteLf = semCrLf.replace(/\r/g, '\n')
  const nfc = somenteLf.normalize('NFC')

  return {
    texto: nfc,
    quebrasCrLf,
    quebrasCr,
    alterouNfc: nfc !== somenteLf,
    caracteresAntes: texto.length,
    caracteresDepois: nfc.length,
  }
}

export function normalizarArtefatoExtraido({
  bytes,
  hashArtefatoExtraido,
  hashOriginalEsperado,
}: {
  bytes: Uint8Array
  hashArtefatoExtraido: string
  hashOriginalEsperado: string
}): ResultadoNormalizacao {
  let textoJson: string

  try {
    textoJson = new TextDecoder('utf-8', { fatal: true }).decode(bytes)
  } catch {
    return {
      ok: false,
      codigo: 'ARTEFATO_EXTRAIDO_NAO_UTF8',
      motivo: 'O artefato extraído não é UTF-8 válido.',
    }
  }

  let bruto: unknown
  try {
    bruto = JSON.parse(textoJson)
  } catch {
    return {
      ok: false,
      codigo: 'ARTEFATO_EXTRAIDO_JSON_INVALIDO',
      motivo: 'O artefato extraído não contém JSON válido.',
    }
  }

  const validacao = artefatoExtraidoSchema.safeParse(bruto)
  if (!validacao.success) {
    return {
      ok: false,
      codigo: 'ARTEFATO_EXTRAIDO_SCHEMA_INVALIDO',
      motivo: 'O artefato extraído não corresponde ao schema v1 esperado.',
      detalhes: {
        quantidade_erros: validacao.error.issues.length,
      },
    }
  }

  const extraido = validacao.data
  const hashOriginal = extraido.fonte.hash_sha256_original.toLowerCase()

  if (hashOriginal !== hashOriginalEsperado.toLowerCase()) {
    return {
      ok: false,
      codigo: 'ARTEFATO_EXTRAIDO_ORIGINAL_DIVERGENTE',
      motivo: 'O artefato extraído não pertence ao hash do original desta execução.',
      detalhes: { hash_original_corresponde: false },
    }
  }

  let quebrasCrLf = 0
  let quebrasCr = 0
  let segmentosNfc = 0
  let caracteresAntes = 0
  let caracteresDepois = 0

  const base = {
    schema_version: 1 as const,
    formato: extraido.formato,
    encoding: 'utf-8' as const,
    metodo: 'normalizacao_tecnica_nfc_v1' as const,
    fonte: {
      nome_arquivo: extraido.fonte.nome_arquivo,
      tipo_mime_registrado: extraido.fonte.tipo_mime_registrado,
      hash_sha256_original: hashOriginal,
      hash_sha256_artefato_extraido: hashArtefatoExtraido.toLowerCase(),
    },
    total_paginas: extraido.total_paginas,
  }

  const normalizacao = {
    unicode: 'NFC' as const,
    quebras_linha: 'LF' as const,
    preserva_espacos_internos: true as const,
    alteracoes: {
      quebras_crlf_convertidas: quebrasCrLf,
      quebras_cr_isoladas_convertidas: quebrasCr,
      segmentos_alterados_nfc: segmentosNfc,
      caracteres_antes: caracteresAntes,
      caracteres_depois: caracteresDepois,
    },
  }

  if (extraido.formato === 'pdf') {
    const paginasNormalizadas = extraido.paginas.map((pagina) => {
      const normalizado = normalizarSegmento(pagina.conteudo)
      quebrasCrLf += normalizado.quebrasCrLf
      quebrasCr += normalizado.quebrasCr
      segmentosNfc += normalizado.alterouNfc ? 1 : 0
      caracteresAntes += normalizado.caracteresAntes
      caracteresDepois += normalizado.caracteresDepois
      return { numero: pagina.numero, conteudo: normalizado.texto }
    })

    return {
      ok: true,
      artefato: {
        ...base,
        formato: 'pdf' as const,
        total_paginas: extraido.total_paginas,
        paginas: paginasNormalizadas,
        normalizacao: {
          ...normalizacao,
          alteracoes: {
            quebras_crlf_convertidas: quebrasCrLf,
            quebras_cr_isoladas_convertidas: quebrasCr,
            segmentos_alterados_nfc: segmentosNfc,
            caracteres_antes: caracteresAntes,
            caracteres_depois: caracteresDepois,
          },
        },
      },
    }
  }

  const normalizado = normalizarSegmento(extraido.conteudo)
  return {
    ok: true,
    artefato: {
      ...base,
      formato: extraido.formato,
      total_paginas: null,
      conteudo: normalizado.texto,
      normalizacao: {
        ...normalizacao,
        alteracoes: {
          quebras_crlf_convertidas: normalizado.quebrasCrLf,
          quebras_cr_isoladas_convertidas: normalizado.quebrasCr,
          segmentos_alterados_nfc: normalizado.alterouNfc ? 1 : 0,
          caracteres_antes: normalizado.caracteresAntes,
          caracteres_depois: normalizado.caracteresDepois,
        },
      },
    },
  }
}

export function validarArtefatoNormalizado({
  bytes,
  hashOriginalEsperado,
  hashArtefatoExtraidoEsperado,
}: {
  bytes: Uint8Array
  hashOriginalEsperado: string
  hashArtefatoExtraidoEsperado: string
}): ResultadoValidacaoArtefatoNormalizado {
  let textoJson: string

  try {
    textoJson = new TextDecoder('utf-8', { fatal: true }).decode(bytes)
  } catch {
    return {
      ok: false,
      codigo: 'ARTEFATO_NORMALIZADO_NAO_UTF8',
      motivo: 'O artefato normalizado não é UTF-8 válido.',
    }
  }

  let bruto: unknown
  try {
    bruto = JSON.parse(textoJson)
  } catch {
    return {
      ok: false,
      codigo: 'ARTEFATO_NORMALIZADO_JSON_INVALIDO',
      motivo: 'O artefato normalizado não contém JSON válido.',
    }
  }

  const validacao = artefatoNormalizadoSchema.safeParse(bruto)
  if (!validacao.success) {
    return {
      ok: false,
      codigo: 'ARTEFATO_NORMALIZADO_SCHEMA_INVALIDO',
      motivo: 'O artefato normalizado não corresponde ao schema v1 esperado.',
      detalhes: { quantidade_erros: validacao.error.issues.length },
    }
  }

  const artefato = validacao.data
  const originalCorresponde =
    artefato.fonte.hash_sha256_original.toLowerCase() === hashOriginalEsperado.toLowerCase()
  const extraidoCorresponde =
    artefato.fonte.hash_sha256_artefato_extraido.toLowerCase() ===
    hashArtefatoExtraidoEsperado.toLowerCase()

  if (!originalCorresponde || !extraidoCorresponde) {
    return {
      ok: false,
      codigo: 'ARTEFATO_NORMALIZADO_ORIGEM_DIVERGENTE',
      motivo: 'O artefato normalizado não pertence à cadeia de proveniência desta execução.',
      detalhes: {
        hash_original_corresponde: originalCorresponde,
        hash_artefato_extraido_corresponde: extraidoCorresponde,
      },
    }
  }

  return { ok: true, artefato: artefato as ArtefatoConteudoNormalizado }
}
