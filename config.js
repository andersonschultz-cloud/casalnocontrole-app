// ════════════════════════════════════════════════════════════════
// CASAL NO CONTROLE — CONFIGURAÇÃO
// ════════════════════════════════════════════════════════════════
// Substitua os valores abaixo pelos do SEU projeto Supabase.
// Onde encontrar: Painel do Supabase -> Settings -> API
//   - "Project URL"      -> cole em SUPABASE_CONFIG.url
//   - "anon public" key   -> cole em SUPABASE_CONFIG.anonKey
//
// A chave "anon" é pública por natureza (é seguro ela aparecer no
// front-end) — a segurança real vem das políticas de RLS definidas
// em supabase/schema.sql, que impedem qualquer casal de ver os
// dados de outro.
// ════════════════════════════════════════════════════════════════

const SUPABASE_CONFIG = {
  url: 'https://opnfhjetfjbrbjctjwpc.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9wbmZoamV0ZmpicmJqY3Rqd3BjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2MTcyMjYsImV4cCI6MjA5NzE5MzIyNn0.Sai55J3lBsDZ25x0gTz3dkjFp66pzBlwst3jnoli_jQ'
};

// Identidade do produto (não precisa alterar isso)
const APP_CONFIG = {
  nomeApp: 'Casal no Controle',
  versao: '1.0.0'
};
// ════════════════════════════════════════════════════════════════
// CASAL NO CONTROLE — CONFIGURAÇÃO
// ════════════════════════════════════════════════════════════════
// Substitua os dois valores abaixo pelos do SEU projeto Supabase.
// Onde encontrar: Painel do Supabase -> Project Settings -> API
//   - "Project URL"     -> cole em SUPABASE_URL
//   - "anon public" key -> cole em SUPABASE_ANON_KEY
//
// A chave "anon" é pública por natureza (é seguro ela aparecer no
// front-end) — a segurança real vem das políticas de RLS definidas
// em supabase/schema.sql, que impedem qualquer casal de ver os
// dados de outro.
// ════════════════════════════════════════════════════════════════

const SUPABASE_URL = 'https://opnfhjetfjbrbjctjwpc.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9wbmZoamV0ZmpicmJqY3Rqd3BjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2MTcyMjYsImV4cCI6MjA5NzE5MzIyNn0.Sai55J3lBsDZ25x0gTz3dkjFp66pzBlwst3jnoli_jQ';

// ────────────────────────────────────────────────────────────────
// Identidade do produto e dados conhecidos para importação única
// (usados pelo botão "Importar histórico" em Lançamentos).
// Não precisa alterar nada abaixo disto.
// ────────────────────────────────────────────────────────────────
const APP_CONFIG = {
  nomeApp: 'Casal no Controle',
  versao: '1.0.0',

  // Totais mensais consolidados de anos anteriores (de planilhas/CSVs
  // históricos). Usado pelas Crônicas para os gráficos de longo prazo.
  historicoSeed: {
    "2022": [4104.38,4937.54,6914.17,4756.89,4366.18,4210.12,4525.39,5908.24,4533.24,4722.70,4261.61,5432.92],
    "2023": [5390.09,4918.11,6608.32,5074.94,5969.63,4867.84,5250.32,5593.19,4981.45,4927.65,7115.32,9076.17],
    "2024": [6371.30,6887.41,9373.91,4559.58,4979.48,5425.01,4997.37,4819.49,5856.62,6288.61,6455.66,9181.60],
    "2025": [9951.02,8455.37,7578.41,5248.11,9267.37,6562.66,6864.20,6821.40,10463.38,6747.82,5741.31,6361.81]
  },

  // Lançamentos itemizados de 2026 (jan-jul), validados contra a
  // planilha original. ap = despesas do apartamento [descricao, valor, perfil].
  seed2026: [
    { mes: 1,
      ap: [["Alelo",2100,"titular"],["Internet",110.50,"titular"],["Condomínio",1150.01,"parceiro"],["CPFL Energia",413.42,"parceiro"],["Gás",44.96,"parceiro"]],
      schultz: [["PIX",100],["IPVA 01/02",808.57]],
      sicredi: [["Sicredi Black",3250.26],["Sofá",1900],["Lord",83.58]] },
    { mes: 2,
      ap: [["Alelo ali/ref",2100,"titular"],["Internet",110.50,"titular"],["Condomínio",1153.41,"parceiro"],["CPFL Energia",323.33,"parceiro"],["Gás",48.31,"parceiro"]],
      schultz: [["IPVA 02/02",808.57]],
      sicredi: [["Sicredi Black",5100.32],["Seg.Mapfre 01/10",45.88],["Growth",259.53]] },
    { mes: 3,
      ap: [["Alelo ali/ref",2100,"titular"],["Internet",110.50,"titular"],["Condomínio",1716.39,"parceiro"],["CPFL Energia",254.46,"parceiro"],["Gás",48.98,"parceiro"]],
      schultz: [],
      sicredi: [["Sicredi Black",2553.22],["Spining 01/10",49.66]] },
    { mes: 4,
      ap: [["Alelo ali/ref",2100,"titular"],["Internet",110.50,"titular"],["Condomínio",1647.74,"parceiro"],["CPFL Energia",273.71,"parceiro"],["Gás",59.27,"parceiro"]],
      schultz: [["Consulta",300]],
      sicredi: [["Sicredi Black",2208.93],["Spining 02/10",49.66],["Pizza",76.90]] },
    { mes: 5,
      ap: [["Alelo ali/ref",2100,"titular"],["Internet",110.50,"titular"],["Condomínio",1000,"parceiro"],["CPFL Energia",170,"parceiro"],["Gás",70,"parceiro"]],
      schultz: [],
      sicredi: [["Sicredi Black",2180.63],["Spining 03/10",49.66]] },
    { mes: 6,
      ap: [["Alelo ali/ref",2100,"titular"],["Stream [NET+SPO]",89,"titular"],["Internet",110.50,"titular"],["Condomínio",1000,"parceiro"],["CPFL Energia",170,"parceiro"],["Gás",70,"parceiro"]],
      schultz: [],
      sicredi: [["Sicredi Black",2000]] },
    { mes: 7,
      ap: [["Alelo ali/ref",2100,"titular"],["Stream [NET+SPO]",89,"titular"],["Internet",110.50,"titular"],["Condomínio",1000,"parceiro"],["CPFL Energia",170,"parceiro"],["Gás",70,"parceiro"]],
      schultz: [],
      sicredi: [["Sicredi Black",2000]] }
  ]
};
