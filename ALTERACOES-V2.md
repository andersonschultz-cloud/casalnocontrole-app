# Alterações V2

## Interface e iPhone

- Lançamentos convertidos em cards no mobile, sem largura mínima e sem rolagem horizontal.
- Crônicas convertidas em cards no mobile.
- Inputs com fonte de 16 px no iPhone para impedir zoom automático.
- Botões de toque ampliados, suporte a safe area e ajuste ao teclado virtual.
- Navegação inferior reduzida a quatro itens e sem a antiga aba Metas.
- Painéis e gráficos receberam fundos integrados aos temas claro, escuro e Burn.

## Funcionalidades

- Inclusão da categoria nas despesas.
- Criação de mês vazio.
- Clonagem segura do mês anterior com confirmação, registros independentes e proteção contra duplicidade.
- Substituição de Investir por Patrimônio Conjunto.
- Cadastro, edição, exclusão, participação individual e distribuição por categoria do patrimônio.
- Remoção da interface e da lógica de Metas.
- Atalhos da tela inicial para Crônicas, Lançamentos e Patrimônio.

## Banco de dados

- Nova tabela `patrimonio_conjunto`.
- Nova tabela `meses_financeiros`.
- Novas RPCs `iniciar_mes_vazio` e `clonar_mes_anterior`.
- Migração não destrutiva dos registros da antiga tabela `investimentos`.
- Query opcional e protegida para remover `metas_financeiras` e `investimentos`.

## Arquivos modificados

- `index.html`
- `config.js`
- `sw.js`
- `manifest.json`
- `README.md`
- `supabase/schema.sql`
- `supabase/validacao.sql`

## Arquivos criados

- `ALTERACOES-V2.md`
- `supabase/migration-v2-patrimonio-clonagem.sql`
- `supabase/cleanup-opcional-metas-investimentos.sql`
- `RELATORIO-TESTES.md`
