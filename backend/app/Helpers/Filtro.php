<?php
namespace Helpers;

class Filtro
{
    private int   $threshold;
    private array $rules;
    private array $contextRules; // Reglas que requieren contexto (N-gramas)

    public function __construct(int $threshold = 60)
    {
        $this->threshold    = $threshold;
        $this->rules        = $this->buildRules();
        $this->contextRules = $this->buildContextRules();
    }

    /**
     * Evalúa el historial de conversación en texto plano.
     */
    public function run(string $textoCompleto): array
    {
        if (empty(trim($textoCompleto))) {
            return ['suspicious' => false, 'score' => 0, 'flags' => [], 'risk_level' => 'NONE'];
        }

        return $this->localFilter($textoCompleto);
    }

    private function localFilter(string $text): array
    {
        $normalized = $this->normalize($text);
        $score      = 0;
        $flags      = [];
        $matchedLabels = [];

        // ── Paso 1: Reglas atómicas ──────────────────────────────────────────
        foreach ($this->rules as $rule) {
            if (isset($matchedLabels[$rule['label']])) {
                continue; // evitar doble conteo del mismo label
            }
            if (preg_match($rule['pattern'], $normalized)) {
                $score += $rule['score'];
                $flags[] = [
                    'label'    => $rule['label'],
                    'score'    => $rule['score'],
                    'category' => $rule['category'] ?? 'general',
                ];
                $matchedLabels[$rule['label']] = true;
            }
        }

        // ── Paso 2: Reglas de contexto (combinaciones de señales) ───────────
        $contextBonus = $this->evaluateContext($normalized, $matchedLabels);
        $score       += $contextBonus['bonus'];
        if (!empty($contextBonus['flags'])) {
            $flags = array_merge($flags, $contextBonus['flags']);
        }

        // ── Paso 3: Penalización por acumulación de señales débiles ──────────
        // Si hay 4+ señales de baja puntuación, el patrón es más sospechoso
        $weakSignals = array_filter($flags, fn($f) => ($f['score'] ?? 0) <= 20);
        if (count($weakSignals) >= 4) {
            $accumBonus = count($weakSignals) * 8;
            $score     += $accumBonus;
            $flags[]    = [
                'label'    => 'acumulacion_senales_debiles',
                'score'    => $accumBonus,
                'category' => 'meta',
            ];
        }

        // ── Paso 4: Cap de score para evitar inflación excesiva ──────────────
        $score = min($score, 500);

        return [
            'suspicious' => $score >= $this->threshold,
            'score'      => $score,
            'risk_level' => $this->getRiskLevel($score),
            'flags'      => $flags,
            'categories' => $this->summarizeCategories($flags),
        ];
    }

    /**
     * Evalúa combinaciones de señales para detectar patrones compuestos.
     */
    private function evaluateContext(string $text, array $matchedLabels): array
    {
        $bonus = 0;
        $flags = [];

        foreach ($this->contextRules as $rule) {
            $allPresent = true;
            foreach ($rule['requires'] as $label) {
                if (!isset($matchedLabels[$label])) {
                    $allPresent = false;
                    break;
                }
            }
            if ($allPresent) {
                $bonus  += $rule['bonus'];
                $flags[] = [
                    'label'    => $rule['label'],
                    'score'    => $rule['bonus'],
                    'category' => 'context_combo',
                ];
            }
        }

        return ['bonus' => $bonus, 'flags' => $flags];
    }

    private function getRiskLevel(int $score): string
    {
        return match(true) {
            $score >= 150 => 'CRITICAL',
            $score >= 100 => 'HIGH',
            $score >= 60  => 'MEDIUM',
            $score >= 30  => 'LOW',
            default       => 'NONE',
        };
    }

    private function summarizeCategories(array $flags): array
    {
        $categories = [];
        foreach ($flags as $flag) {
            $cat = $flag['category'] ?? 'general';
            $categories[$cat] = ($categories[$cat] ?? 0) + ($flag['score'] ?? 0);
        }
        arsort($categories);
        return $categories;
    }

    private function normalize(string $text): string
    {
        $text = mb_strtolower($text, 'UTF-8');

        // Diacríticos extendidos (incluye variedades latinoamericanas)
        $from = ['á','é','í','ó','ú','ü','ñ','à','è','ì','ò','ù','â','ê','î','ô','û'];
        $to   = ['a','e','i','o','u','u','n','a','e','i','o','u','a','e','i','o','u'];
        $text = str_replace($from, $to, $text);

        // Normalizar separadores no estándar (puntos, guiones usados como espacios)
        $text = preg_replace('/[.\-_]+/', ' ', $text);

        // Colapsar espacios múltiples
        $text = preg_replace('/\s+/', ' ', trim($text));

        // Eliminar caracteres de control y zero-width
        $text = preg_replace('/[\x00-\x1F\x7F\xAD\x{200B}-\x{200D}\x{FEFF}]/u', '', $text);

        return $text;
    }

    private function buildRules(): array
    {
        return [
            // ══════════════════════════════════════════════════════════════════
            // CATEGORÍA: dinero_facil
            // Señales de oferta económica sospechosa dirigida a jóvenes
            // ══════════════════════════════════════════════════════════════════
            ['category' => 'dinero_facil', 'label' => 'dinero_facil',        'score' => 65,  'pattern' => '/dinero\s*(f[aá]cil|r[aá]pido|bueno|seguro|extra)/i'],
            ['category' => 'dinero_facil', 'label' => 'ganar_rapido',        'score' => 60,  'pattern' => '/ganar\s*(r[aá]pido|bien|mucho|m[aá]s|lana|extras?)/i'],
            ['category' => 'dinero_facil', 'label' => 'trabajo_sencillo',    'score' => 35,  'pattern' => '/trabajo\s*(sencillo|f[aá]cil|bueno|tranquilo|de\s*confianza)/i'],
            ['category' => 'dinero_facil', 'label' => 'sin_experiencia',     'score' => 25,  'pattern' => '/sin\s*(experiencia|estudios|requisitos|papeles)/i'],
            ['category' => 'dinero_facil', 'label' => 'ingresos_extras',     'score' => 30,  'pattern' => '/ingresos?\s*extras?/i'],
            ['category' => 'dinero_facil', 'label' => 'oportunidad_negocio', 'score' => 25,  'pattern' => '/oportunidad\s*(de\s*)?(negocio|trabajo|chamba)/i'],
            ['category' => 'dinero_facil', 'label' => 'ganar_dinero',        'score' => 30,  'pattern' => '/(quieres?|puedes?|vas\s*a)\s*ganar\s*(dinero|\${1,})/i'],
            ['category' => 'dinero_facil', 'label' => 'trabajo_cel',         'score' => 45,  'pattern' => '/solo\s*(necesitas?|ocupa[s]?)\s*(tu\s*)?(cel(ular)?|tel[eé]fono|smart)/i'],
            ['category' => 'dinero_facil', 'label' => 'trabajo_casa',        'score' => 20,  'pattern' => '/trabajo\s*(desde|en)\s*casa/i'],
            ['category' => 'dinero_facil', 'label' => 'paga_chida',          'score' => 50,  'pattern' => '/paga\s*(chida|buena|extra|generosa)/i'],
            ['category' => 'dinero_facil', 'label' => 'te_alivianas',        'score' => 55,  'pattern' => '/te\s*alivan[aá]s/i'],
            ['category' => 'dinero_facil', 'label' => 'sacar_gustos',        'score' => 45,  'pattern' => '/sacar\s*(pa(ra)?\s*)?(tus\s*)?(gustos|cosas|lo\s*que\s*quieras)/i'],
            ['category' => 'dinero_facil', 'label' => 'te_cae_dinero',       'score' => 60,  'pattern' => '/te\s*(cae|va\s*(a\s*)?caer)\s*dinero/i'],
            ['category' => 'dinero_facil', 'label' => 'te_va_ir_bien',       'score' => 25,  'pattern' => '/te\s*va\s*(a\s*)?ir\s*(muy\s*)?bien/i'],
            ['category' => 'dinero_facil', 'label' => 'hacer_billete',       'score' => 60,  'pattern' => '/hacer\s*(buen\s*)?billete/i'],
            ['category' => 'dinero_facil', 'label' => 'chamba',              'score' => 10,  'pattern' => '/\bchamba\b/i'],

            // ── Jerga monetaria ───────────────────────────────────────────────
            ['category' => 'dinero_facil', 'label' => 'billete',             'score' => 15,  'pattern' => '/\bbillete\b/i'],
            ['category' => 'dinero_facil', 'label' => 'lana',                'score' => 15,  'pattern' => '/\blana\b/i'],
            ['category' => 'dinero_facil', 'label' => 'feria',               'score' => 15,  'pattern' => '/\bferia\b/i'],
            ['category' => 'dinero_facil', 'label' => 'varo',                'score' => 20,  'pattern' => '/\bvaro\b/i'],
            ['category' => 'dinero_facil', 'label' => 'cash',                'score' => 15,  'pattern' => '/\bcash\b/i'],
            ['category' => 'dinero_facil', 'label' => 'signo_pesos',         'score' => 10,  'pattern' => '/\${2,}/'],

            // ══════════════════════════════════════════════════════════════════
            // CATEGORÍA: manipulacion_emocional
            // Señales de control, lealtad forzada y aislamiento
            // ══════════════════════════════════════════════════════════════════
            ['category' => 'manipulacion_emocional', 'label' => 'confio_en_ti',      'score' => 35,  'pattern' => '/conf[ií]o\s*(en\s*ti|en\s*vos|mucho\s*en\s*ti)/i'],
            ['category' => 'manipulacion_emocional', 'label' => 'te_puedo_ayudar',   'score' => 20,  'pattern' => '/te\s*puedo\s*ayudar/i'],
            ['category' => 'manipulacion_emocional', 'label' => 'eres_especial',      'score' => 45,  'pattern' => '/eres\s*(muy\s*)?especial/i'],
            ['category' => 'manipulacion_emocional', 'label' => 'te_voy_cuidar',     'score' => 65,  'pattern' => '/te\s*voy\s*(a\s*)?cuidar/i'],
            ['category' => 'manipulacion_emocional', 'label' => 'somos_equipo',       'score' => 35,  'pattern' => '/somos\s*(equipo|familia|carnales?|uno)/i'],
            ['category' => 'manipulacion_emocional', 'label' => 'nadie_tiene_saber',  'score' => 95,  'pattern' => '/nadie\s*(tiene|tiene\s*que|debe)\s*saber/i'],
            ['category' => 'manipulacion_emocional', 'label' => 'es_secreto',         'score' => 90,  'pattern' => '/(es\s*(un\s*)?secreto|es\s*confidencial|queda\s*entre\s*nos(otros)?)/i'],
            ['category' => 'manipulacion_emocional', 'label' => 'no_le_digas',        'score' => 95,  'pattern' => '/no\s*le\s*digas?\s*(a\s*nadie|a\s*tus?\s*(pap[aá]s?|ma[ms]|familia|jefes?))/i'],
            ['category' => 'manipulacion_emocional', 'label' => 'borra_chat',         'score' => 100, 'pattern' => '/borra\s*(este\s*)?(chat|mensaje(s)?|conversaci[oó]n|historial)/i'],
            ['category' => 'manipulacion_emocional', 'label' => 'te_estoy_probando',  'score' => 85,  'pattern' => '/te\s*(estamos?|estoy)\s*probando/i'],
            ['category' => 'manipulacion_emocional', 'label' => 'cumple_primero',     'score' => 55,  'pattern' => '/cumple\s*(primero|y\s*(ganas?|te\s*pago)\s*m[aá]s)/i'],
            // NUEVO: love bombing / halagos excesivos
            ['category' => 'manipulacion_emocional', 'label' => 'eres_el_unico',      'score' => 60,  'pattern' => '/eres\s*(el|la)\s*[uú]nico?\s*(que\s*(puedo|me\s*importa))?/i'],
            ['category' => 'manipulacion_emocional', 'label' => 'nadie_te_quiere',    'score' => 70,  'pattern' => '/(nadie\s*(te\s*quiere|te\s*entiende|est[aá]\s*para\s*ti)|solo\s*(yo\s*)?(te\s*quiero|te\s*entiendo))/i'],
            ['category' => 'manipulacion_emocional', 'label' => 'te_entiendo',        'score' => 20,  'pattern' => '/yo\s*(si|s[ií])\s*te\s*entiendo/i'],
            // NUEVO: culpabilización
            ['category' => 'manipulacion_emocional', 'label' => 'me_fallarias',       'score' => 75,  'pattern' => '/(me\s*fall(as|ar[ií]as?)|nos\s*defraudar[ií]as?|no\s*me\s*hagas\s*eso)/i'],

            // ══════════════════════════════════════════════════════════════════
            // CATEGORÍA: enganche_lenguaje
            // Vocabulario coloquial de captación
            // ══════════════════════════════════════════════════════════════════
            ['category' => 'enganche_lenguaje', 'label' => 'todo_tranqui',   'score' => 15,  'pattern' => '/(todo\s*(tranqui|tranquilo)|es\s*(relax|leve|facil))/i'],
            ['category' => 'enganche_lenguaje', 'label' => 'jalas',          'score' => 40,  'pattern' => '/\bjalas?\b/i'],
            ['category' => 'enganche_lenguaje', 'label' => 'te_animas',      'score' => 30,  'pattern' => '/te\s*animas?(\s*o\s*que)?/i'],
            ['category' => 'enganche_lenguaje', 'label' => 'te_late',        'score' => 20,  'pattern' => '/te\s*late/i'],
            ['category' => 'enganche_lenguaje', 'label' => 'no_pasa_nada',   'score' => 55,  'pattern' => '/no\s*pasa\s*nada/i'],
            ['category' => 'enganche_lenguaje', 'label' => 'te_interesa',    'score' => 20,  'pattern' => '/te\s*interesa/i'],
            ['category' => 'enganche_lenguaje', 'label' => 'mas_info',       'score' => 20,  'pattern' => '/(m[aá]s\s*info|te\s*paso\s*m[aá]s\s*info|te\s*cuento\s*m[aá]s)/i'],
            // NUEVO: minimización de riesgo
            ['category' => 'enganche_lenguaje', 'label' => 'no_es_peligroso','score' => 60,  'pattern' => '/(no\s*es\s*(peligroso|arriesgado)|no\s*hay\s*riesgo|est[aá]\s*controlado)/i'],
            ['category' => 'enganche_lenguaje', 'label' => 'es_temporal',    'score' => 35,  'pattern' => '/(es\s*temporal|solo\s*(por\s*)?(un\s*rato|esta\s*vez|una\s*vez))/i'],
            ['category' => 'enganche_lenguaje', 'label' => 'nomas_una_vez',  'score' => 50,  'pattern' => '/n[oó]mas?\s*(una|esta)\s*(vez|rola)/i'],

            // ══════════════════════════════════════════════════════════════════
            // CATEGORÍA: reclutamiento
            // Patrones de invitación directa a grupos
            // ══════════════════════════════════════════════════════════════════
            ['category' => 'reclutamiento', 'label' => 'trabajar_nosotros',  'score' => 35,  'pattern' => '/(quieres?|vente\s*a?)\s*trabajar\s*(con\s*nosotros|aqui|ac[aá])?/i'],
            ['category' => 'reclutamiento', 'label' => 'tenemos_grupo',      'score' => 45,  'pattern' => '/tenemos?\s*un\s*grupo/i'],
            ['category' => 'reclutamiento', 'label' => 'te_voy_agregar',     'score' => 40,  'pattern' => '/te\s*voy\s*(a\s*)?agregar(\s*(al\s*grupo|al\s*canal|al\s*chat))?/i'],
            ['category' => 'reclutamiento', 'label' => 'mensaje_privado',    'score' => 35,  'pattern' => '/(m[aá]ndame|escr[ií]beme|h[aá]blame)\s*(mensaje\s*)?(por\s*)?(privado|DM|inbox)/i'],
            ['category' => 'reclutamiento', 'label' => 'pasame_numero',      'score' => 55,  'pattern' => '/(p[aá]same|dame|manda)\s*(tu\s*)?n[uú]mero(\s*(de\s*)?(cel|wha?ts?))?/i'],
            // NUEVO
            ['category' => 'reclutamiento', 'label' => 'unete_equipo',       'score' => 45,  'pattern' => '/(un[eé]te|[eú]nete)\s*(al\s*)?(equipo|grupo|familia|proyecto)/i'],
            ['category' => 'reclutamiento', 'label' => 'te_presento_jefe',   'score' => 80,  'pattern' => '/(te\s*(presento|llevo\s*con))\s*(el\s*)?(jefe|lider|encargado|patron)/i'],

            // ══════════════════════════════════════════════════════════════════
            // CATEGORÍA: canales_cifrados
            // Migración a plataformas con menor rastreo
            // ══════════════════════════════════════════════════════════════════
            ['category' => 'canales_cifrados', 'label' => 'telegram',        'score' => 35,  'pattern' => '/\btelegram\b/i'],
            ['category' => 'canales_cifrados', 'label' => 'signal',          'score' => 70,  'pattern' => '/\bsignal\b/i'],
            ['category' => 'canales_cifrados', 'label' => 'dm_inbox',        'score' => 20,  'pattern' => '/\b(DM|inbox)\b/i'],
            // NUEVO: migración activa de canal
            ['category' => 'canales_cifrados', 'label' => 'habla_por_otro',  'score' => 55,  'pattern' => '/(h[aá]blame|escr[ií]beme|cont[aá]ctame)\s*(por\s*)?(telegram|signal|otro\s*lado|otro\s*chat|esa\s*(app|aplicacion))/i'],
            ['category' => 'canales_cifrados', 'label' => 'aqui_no_hablemos','score' => 80,  'pattern' => '/(no\s*(hablemos?|digamos?|escribamos?)\s*(aqui|en\s*(esta|la)\s*(app|red|plataforma|p[aá]gina)))/i'],

            // ══════════════════════════════════════════════════════════════════
            // CATEGORÍA: eufemismos_ilicitos
            // Lenguaje codificado para actividades delictivas
            // ══════════════════════════════════════════════════════════════════
            ['category' => 'eufemismos_ilicitos', 'label' => 'hacer_paro',       'score' => 30,  'pattern' => '/(hacer|tirar)\s*(un\s*)?paro/i'],
            ['category' => 'eufemismos_ilicitos', 'label' => 'dar_vuelta',        'score' => 40,  'pattern' => '/dar\s*(la\s*)?vuelta/i'],
            ['category' => 'eufemismos_ilicitos', 'label' => 'mover_cosas',       'score' => 90,  'pattern' => '/mover\s*(cosas|mercanc[ií]a|paquetes?|producto|material)/i'],
            ['category' => 'eufemismos_ilicitos', 'label' => 'hacer_entrega',     'score' => 65,  'pattern' => '/hacer\s*(una\s*)?entrega/i'],
            ['category' => 'eufemismos_ilicitos', 'label' => 'andar_al_tiro',     'score' => 50,  'pattern' => '/andar\s*al\s*tiro/i'],
            ['category' => 'eufemismos_ilicitos', 'label' => 'recoger_mandado',   'score' => 85,  'pattern' => '/recoger\s*(el\s*)?mandado/i'],
            ['category' => 'eufemismos_ilicitos', 'label' => 'paquete_encargo',   'score' => 55,  'pattern' => '/\b(paquete|encargo|mercanc[ií]a|producto|material)\b/i'],
            // NUEVO
            ['category' => 'eufemismos_ilicitos', 'label' => 'chambita_rapida',   'score' => 55,  'pattern' => '/chambita\s*(r[aá]pida|sencilla|facil)/i'],
            ['category' => 'eufemismos_ilicitos', 'label' => 'llevar_algo',       'score' => 50,  'pattern' => '/llevar\s*(algo|una\s*cosa|un\s*paquete|esto)\s*(para|a)\s*alguien/i'],
            ['category' => 'eufemismos_ilicitos', 'label' => 'cuidar_algo',       'score' => 60,  'pattern' => '/cuidar\s*(algo|un\s*paquete|esto|eso)\s*(un\s*rato|mientras)/i'],

            // ══════════════════════════════════════════════════════════════════
            // CATEGORÍA: jerga_criminal
            // Lenguaje operativo directo — riesgo máximo
            // ══════════════════════════════════════════════════════════════════
            ['category' => 'jerga_criminal', 'label' => 'punto_zona',        'score' => 85,  'pattern' => '/\b(punto|zona|ruta|plaza)\b/i'],
            ['category' => 'jerga_criminal', 'label' => 'halcon',            'score' => 100, 'pattern' => '/\bhalc[oó]n(es)?\b/i'],
            ['category' => 'jerga_criminal', 'label' => 'cuidar_vigilar',    'score' => 90,  'pattern' => '/(cuidar|vigilar|checar|reportar)\s*(zona|movimientos?|la\s*plaza|el\s*punto)?/i'],
            ['category' => 'jerga_criminal', 'label' => 'levantar_bajar',    'score' => 100, 'pattern' => '/\b(levantar|bajar|dar\s*piso)\b/i'],
            ['category' => 'jerga_criminal', 'label' => 'ya_estas_dentro',   'score' => 85,  'pattern' => '/ya\s*est[aá]s?\s*(dentro|adentro|del\s*negocio)/i'],
            ['category' => 'jerga_criminal', 'label' => 'no_te_rajes',       'score' => 100, 'pattern' => '/no\s*(te|se)?\s*raj(es|as|aste)/i'],
            ['category' => 'jerga_criminal', 'label' => 'hay_consecuencias', 'score' => 100, 'pattern' => '/(hay|habr[aá])\s*consecuencias/i'],
            ['category' => 'jerga_criminal', 'label' => 'ya_sabes_como',     'score' => 65,  'pattern' => '/ya\s*sabes?\s*(c[oó]mo\s*es\s*(esto|la\s*cosa|el\s*jale))?/i'],
            ['category' => 'jerga_criminal', 'label' => 'cumple_no_falles',  'score' => 95,  'pattern' => '/(cumple|no\s*falles?|no\s*te\s*rajes?)/i'],
            // NUEVO
            ['category' => 'jerga_criminal', 'label' => 'el_jale',           'score' => 75,  'pattern' => '/\bel\s*jale\b/i'],
            ['category' => 'jerga_criminal', 'label' => 'raza_gente',        'score' => 40,  'pattern' => '/\b(la\s*raza|la\s*gente|el\s*grupo)\s*(te\s*necesita|est[aá]\s*contigo)/i'],

            // ══════════════════════════════════════════════════════════════════
            // CATEGORÍA: logistica_desplazamiento
            // Indicadores de traslado físico — riesgo crítico
            // ══════════════════════════════════════════════════════════════════
            ['category' => 'logistica_desplazamiento', 'label' => 'mandar_ubicacion',  'score' => 90,  'pattern' => '/(manda|pasa|comparte)\s*(tu\s*)?ubicaci[oó]n(\s*(en\s*tiempo\s*real|actual|ahorita))?/i'],
            ['category' => 'logistica_desplazamiento', 'label' => 'comprar_boleto',    'score' => 100, 'pattern' => '/(te\s*compro|te\s*mando|hay|tengo)\s*(el\s*)?(boleto|pasaje|camion|vuelo|viaje)/i'],
            ['category' => 'logistica_desplazamiento', 'label' => 'pasar_por_ti',      'score' => 100, 'pattern' => '/(paso|vamos|van|voy)\s*por\s*ti/i'],
            ['category' => 'logistica_desplazamiento', 'label' => 'vernos_en_persona', 'score' => 85,  'pattern' => '/(vernos|toparnos|conocernos|juntarnos)\s*(en\s*persona|fuera\s*de\s*aqu[ií]|en\s*vivo)/i'],
            // NUEVO
            ['category' => 'logistica_desplazamiento', 'label' => 'dime_donde_estas',  'score' => 75,  'pattern' => '/(d[ií]me|dinos|manda)\s*(d[oó]nde\s*est[aá]s|tu\s*direcci[oó]n|d[oó]nde\s*vives)/i'],
            ['category' => 'logistica_desplazamiento', 'label' => 'quedamos_ahorita',  'score' => 70,  'pattern' => '/(quedamos|nos\s*vemos|te\s*espero)\s*(ahorita|ya\s*mismo|en\s*un\s*rato|hoy)/i'],

            // ══════════════════════════════════════════════════════════════════
            // CATEGORÍA: vigilancia_roles
            // Asignación de roles operativos
            // ══════════════════════════════════════════════════════════════════
            ['category' => 'vigilancia_roles', 'label' => 'ser_la_antena',     'score' => 95,  'pattern' => '/(ser|hacer|ser\s*como)\s*la\s*antena/i'],
            ['category' => 'vigilancia_roles', 'label' => 'limpiar_zona',      'score' => 90,  'pattern' => '/limpiar\s*(la\s*)?(zona|calle|[aá]rea|cuadra)/i'],
            ['category' => 'vigilancia_roles', 'label' => 'avisar_patrullas',  'score' => 100, 'pattern' => '/(avisar|reportar|checar)\s*(si\s*pasan|a\s*los|gobierno|azules|patrullas|polic[ií]a)/i'],
            ['category' => 'vigilancia_roles', 'label' => 'escolta_seguridad', 'score' => 80,  'pattern' => '/(hacer|trabajar\s*de)\s*seguridad\s*(privada|personal|de\s*alguien)/i'],
            // NUEVO
            ['category' => 'vigilancia_roles', 'label' => 'estar_de_campana',  'score' => 95,  'pattern' => '/(estar|andar|quedarte)\s*(de\s*)?(campa[nñ]a|camp[aá])/i'],
            ['category' => 'vigilancia_roles', 'label' => 'dar_el_pitazo',     'score' => 90,  'pattern' => '/(dar|tirar|echar)\s*(el\s*)?(pitazo|aviso|se[nñ]al)/i'],

            // ══════════════════════════════════════════════════════════════════
            // CATEGORÍA: presion_grupo
            // Coerción psicológica y desafíos de masculinidad/valentía
            // ══════════════════════════════════════════════════════════════════
            ['category' => 'presion_grupo', 'label' => 'tienes_miedo',       'score' => 75,  'pattern' => '/(tienes?|no\s*tengas)\s*miedo|eres\s*miedoso|no\s*seas\s*(puto|gallina|miedoso)/i'],
            ['category' => 'presion_grupo', 'label' => 'demostrar_valor',    'score' => 85,  'pattern' => '/(demostrar|probar)\s*(que\s*eres\s*hombre|tu\s*valor|de\s*qu[eé]\s*est[aá]s\s*hecho)/i'],
            ['category' => 'presion_grupo', 'label' => 'reto_mision',        'score' => 75,  'pattern' => '/(tengo|hay)\s*una\s*(misi[oó]n|tarea|reto|prueba)\s*para\s*ti/i'],
            // NUEVO
            ['category' => 'presion_grupo', 'label' => 'todos_lo_hacen',     'score' => 60,  'pattern' => '/(todos\s*(lo\s*hacen|est[aá]n\s*metidos)|es\s*normal\s*aqu[ií])/i'],
            ['category' => 'presion_grupo', 'label' => 'ya_no_hay_vuelta',   'score' => 95,  'pattern' => '/(ya\s*no\s*hay\s*(vuelta|salida|retroceso)|no\s*puedes\s*(salir|rajarte))/i'],
            ['category' => 'presion_grupo', 'label' => 'palabra_de_hombre',  'score' => 70,  'pattern' => '/(palabra\s*de\s*hombre|lo\s*prometiste|ya\s*dijiste\s*que\s*si)/i'],
        ];
    }

    /**
     * Reglas de contexto: se activan solo cuando dos o más señales coexisten.
     * Permiten detectar patrones compuestos sin elevar scores de señales aisladas.
     */
    private function buildContextRules(): array
    {
        return [
            [
                'label'    => 'combo_dinero_secreto',
                'requires' => ['dinero_facil', 'es_secreto'],
                'bonus'    => 40,
                // Oferta económica + pedir secreto = señal clásica de captación
            ],
            [
                'label'    => 'combo_reclutamiento_cifrado',
                'requires' => ['pasame_numero', 'telegram'],
                'bonus'    => 35,
                // Pedir contacto directo + migrar a app cifrada
            ],
            [
                'label'    => 'combo_trabajo_vigilancia',
                'requires' => ['trabajo_sencillo', 'cuidar_vigilar'],
                'bonus'    => 50,
                // "Trabajo fácil" + vigilar zona = rol de halcón
            ],
            [
                'label'    => 'combo_desplazamiento_secreto',
                'requires' => ['pasar_por_ti', 'nadie_tiene_saber'],
                'bonus'    => 60,
                // Traslado físico + pedido de secreto = riesgo crítico
            ],
            [
                'label'    => 'combo_presion_dinero',
                'requires' => ['tienes_miedo', 'dinero_facil'],
                'bonus'    => 45,
                // Presión de valentía + oferta económica = enganche por ego
            ],
            [
                'label'    => 'combo_emocional_aislamiento',
                'requires' => ['nadie_te_quiere', 'somos_equipo'],
                'bonus'    => 55,
                // Hacer sentir al menor solo + ofrecerse como familia sustituta
            ],
            [
                'label'    => 'combo_coercion_activa',
                'requires' => ['ya_estas_dentro', 'hay_consecuencias'],
                'bonus'    => 80,
                // Ya está dentro + amenaza = coerción activa, riesgo máximo
            ],
            [
                'label'    => 'combo_ubicacion_encuentro',
                'requires' => ['mandar_ubicacion', 'vernos_en_persona'],
                'bonus'    => 70,
                // Pedir ubicación + proponer encuentro físico
            ],
            [
                'label'    => 'combo_canal_borra',
                'requires' => ['habla_por_otro', 'borra_chat'],
                'bonus'    => 65,
                // Migrar canal + borrar evidencia = encubrimiento activo
            ],
        ];
    }
}
?>