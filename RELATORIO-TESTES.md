# Relatório de validação — Casal no Controle V2

Data da revisão: 01/08/2026

## Validações automatizadas realizadas

- Validação sintática de todos os blocos JavaScript do `index.html` com `node --check`.
- Leitura estrutural do HTML e conferência de IDs duplicados.
- Conferência das páginas e itens de navegação disponíveis.
- Conferência da presença de `mobile-web-app-capable` e ausência da meta tag Apple obsoleta.
- Testes em navegador Chromium nas resoluções:
  - 390 × 844, equivalente ao viewport do iPhone 14;
  - 430 × 932, equivalente ao viewport de um iPhone Pro Max;
  - 1440 × 1000, desktop.
- Abertura das telas Início, Lançamentos, Crônicas e Patrimônio Conjunto.
- Verificação de ausência de rolagem horizontal em todas as telas testadas.
- Verificação do clique no item Crônicas da navegação inferior.
- Verificação de que elementos ocultos, como o toast, não bloqueiam cliques.
- Verificação do console durante a navegação: nenhum erro JavaScript nos cenários executados.

## Funcionalidades revisadas no código

- Autenticação e recuperação da sessão pelo Supabase.
- Leitura e gravação dos lançamentos.
- Criação de competência vazia.
- Clonagem transacional do mês anterior, com confirmação e proteção contra repetição.
- Cadastro, edição e exclusão do Patrimônio Conjunto.
- Cálculo dos totais e percentuais de participação.
- Atalhos da tela inicial.
- Remoção das referências visuais e funcionais à aba Metas.
- Troca de tema claro, escuro e Burn, incluindo o logo Burn.
- Cache da aplicação pelo service worker sem cachear respostas do Supabase.

## Limites desta validação

Os testes de interface foram executados em Chromium com resoluções equivalentes às de iPhone. Não houve execução em um iPhone físico nem no motor WebKit/Safari real. A integração foi exercitada com um cliente Supabase simulado durante os testes de interface, para não alterar os dados reais. As queries SQL foram revisadas estruturalmente, mas não foram executadas no projeto Supabase de produção.

Antes da publicação definitiva, siga a ordem descrita no `README.md`, faça backup e valide a migração no SQL Editor do Supabase.
