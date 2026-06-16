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
