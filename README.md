# Casal no Controle

Aplicação financeira do casal com lançamentos mensais, acerto automático, histórico em **Crônicas**, clonagem do mês anterior e acompanhamento de **Patrimônio Conjunto**. O frontend é estático, publicado no GitHub Pages, e os dados permanecem no Supabase com Row Level Security.

## Atualização de uma instalação existente

Esta é a ordem segura para atualizar sem apagar os dados atuais:

1. Faça um backup do projeto no GitHub e, por segurança, exporte as tabelas do Supabase.
2. No **SQL Editor** do Supabase, execute somente:
   `supabase/migration-v2-patrimonio-clonagem.sql`
3. Execute `supabase/validacao.sql` e confira se `patrimonio_conjunto`, `meses_financeiros`, `iniciar_mes_vazio` e `clonar_mes_anterior` aparecem nos resultados.
4. Substitua os arquivos do repositório pelos arquivos deste pacote.
5. Aguarde a publicação do GitHub Pages e recarregue a aplicação. Em PWA, feche e abra novamente para o novo service worker assumir o controle.
6. Confira os itens migrados da antiga área **Investir**. Como o cadastro antigo não informava a participação individual, esses itens são preservados com a divisão zerada e uma observação para revisão manual.
7. A remoção física das tabelas antigas é opcional. Só depois de conferir tudo, avalie o arquivo `supabase/cleanup-opcional-metas-investimentos.sql`.

**Não execute `supabase/schema.sql` em um banco que já contém dados.** Ele existe apenas para instalações novas.

## Instalação nova

1. Crie um projeto no Supabase.
2. No **SQL Editor**, execute `supabase/schema.sql` uma única vez.
3. Em **Project Settings → API**, copie o Project URL e a chave pública `anon` para `config.js`.
4. Publique todos os arquivos na raiz do repositório do GitHub Pages.
5. No iPhone, abra no Safari e use **Compartilhar → Adicionar à Tela de Início**.

## Funcionalidades principais

### Lançamentos

- Tabela no desktop e cards reorganizados no celular, sem rolagem horizontal.
- Descrição, categoria, responsável, valor e exclusão em cada despesa.
- Opções para iniciar uma competência vazia ou clonar o mês anterior.
- A clonagem é transacional, cria registros independentes e possui trava contra duplicidade.
- Schultz Bank e Sicredi Black mantêm as regras originais do acerto.

### Patrimônio Conjunto

- Nome, categoria, valor total estimado, valor de cada pessoa, data e observações.
- Percentuais calculados automaticamente a partir dos valores individuais.
- Totais do casal e de cada pessoa.
- Distribuição por categoria.
- Criação, edição e exclusão.

### Crônicas

- Comparação mensal e anual.
- O maior gasto de cada mês entre os anos aparece destacado em amarelo.
- Tabelas transformadas em cards no iPhone para evitar rolagem lateral.

### Tela inicial

- Indicadores financeiros.
- Gráfico dos últimos meses com painel integrado ao tema, sem fundo branco chapado.
- Atalhos para Crônicas, Lançamentos e Patrimônio Conjunto.

## Supabase e segurança dos dados

- A URL e a chave pública existentes em `config.js` não foram alteradas.
- Todas as novas estruturas são criadas por migração incremental.
- `patrimonio_conjunto` e `meses_financeiros` possuem RLS por `household_id`.
- O service worker nunca armazena respostas do Supabase em cache.
- A query de limpeza é separada, opcional e contém travas para evitar exclusão de dados ainda não migrados.

## Estrutura dos arquivos

- `index.html`: interface, responsividade e lógica da aplicação.
- `config.js`: conexão existente com o Supabase e dados de importação histórica.
- `manifest.json`: configuração PWA.
- `sw.js`: cache apenas da casca estática.
- `supabase/schema.sql`: banco completo para instalação nova.
- `supabase/migration-v2-patrimonio-clonagem.sql`: atualização segura do banco existente.
- `supabase/cleanup-opcional-metas-investimentos.sql`: remoção opcional das estruturas antigas.
- `supabase/validacao.sql`: consultas de conferência após a migração.
- `ALTERACOES-V2.md`: resumo técnico e lista de arquivos modificados.
- `RELATORIO-TESTES.md`: cenários validados e limitações dos testes.

## Fórmula do acerto mensal preservada

- Cota individual = total das despesas do apartamento ÷ 2.
- Valor devido pelo parceiro = cota − despesas já pagas pelo parceiro.
- Schultz Bank entra integralmente.
- Sicredi Black entra pela metade.
- Acerto = valor devido + Schultz Bank + metade do Sicredi Black.
