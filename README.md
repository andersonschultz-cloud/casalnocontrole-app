# Casal no Controle

Controle financeiro do casal — despesas do apartamento, Schultz Bank, Sicredi Black, investimentos e metas, com acerto mensal calculado automaticamente. PWA instalável, dados sincronizados em tempo real via Supabase, hospedagem 100% estática no GitHub Pages.

---

## 1. Criar seu projeto no Supabase (passo a passo)

Você ainda não tem um projeto — aqui está o caminho completo, do zero.

1. Acesse **https://supabase.com** e crie uma conta gratuita (pode usar login com GitHub).
2. Clique em **New Project**.
3. Escolha um nome (ex: `casal-no-controle`), uma senha forte para o banco (guarde-a) e a região mais próxima de você (ex: South America).
4. Aguarde 1–2 minutos enquanto o projeto é provisionado.
5. No menu lateral, vá em **SQL Editor** → **New query**.
6. Abra o arquivo `supabase/schema.sql` deste pacote, copie todo o conteúdo, cole no editor e clique em **Run**. Isso cria todas as tabelas, as regras de segurança (RLS) e a automação que monta a "casa" de cada casal automaticamente no cadastro.
7. Vá em **Project Settings** (ícone de engrenagem) → **API**. Copie os dois valores:
   - **Project URL**
   - **anon public** key
8. Abra o arquivo `config.js` deste pacote e cole esses dois valores nas variáveis `SUPABASE_URL` e `SUPABASE_ANON_KEY`.
9. (Recomendado para simplificar o primeiro uso) Vá em **Authentication** → **Providers** → **Email**, e desative **Confirm email**. Assim a conta criada já entra direto, sem precisar clicar em link de confirmação. Se preferir manter a confirmação por e-mail ativada, basta confirmar pelo link recebido antes do primeiro login.

Pronto — seu backend está no ar.

---

## 2. Publicar no GitHub Pages

1. Crie um repositório novo no GitHub (pode ser privado ou público).
2. Envie todos os arquivos desta pasta para a raiz do repositório (`index.html`, `config.js`, `manifest.json`, `sw.js`, `icon.svg`, `icon-192.png`, `icon-512.png`, a pasta `supabase/`, e este `README.md`).
3. No repositório, vá em **Settings** → **Pages**.
4. Em **Source**, selecione **Deploy from a branch**, escolha a branch `main` e a pasta `/ (root)`.
5. Salve. Em 1–2 minutos o GitHub mostra o link público (algo como `https://seu-usuario.github.io/seu-repositorio/`).
6. Abra esse link no celular (Android ou iPhone) e instale como app:
   - **Android (Chrome):** toque no menu (⋮) → "Adicionar à tela inicial" ou aguarde o banner automático de instalação.
   - **iPhone (Safari):** toque em Compartilhar → "Adicionar à Tela de Início".

---

## 3. Primeiro acesso

1. Abra o app publicado e toque em **Criar conta**.
2. Preencha o nome da casa (ex: "AP Mont Serrat"), o nome de quem paga as contas principais (titular — equivalente ao papel que o Schultz Bank e o Sicredi Black assumem hoje) e o nome do parceiro(a).
3. Defina um e-mail e senha — **esse login é único e compartilhado pelo casal**, os dois usam a mesma conta.
4. Ao entrar, vá em **Lançamentos** — vai aparecer um banner para **importar o histórico conhecido (2022–2026)**. Toque para trazer todos os dados que você já tinha de uma vez.

A partir daí, o uso mensal é só:

1. Abrir **Lançamentos**, lançar as despesas do mês.
2. Lançar o que entrar no Schultz Bank e no Sicredi Black.
3. Tocar em **Salvar lançamentos do mês**.

O acerto do mês, a cota de cada um e todo o histórico em **Crônicas** são recalculados automaticamente. Nenhuma fórmula precisa ser tocada.

---

## 4. Sobre o módulo de Investimentos

A estrutura (tabela, RLS, tela de cadastro, distribuição por categoria) já está pronta e funcionando. Porém, o arquivo de investimentos mencionado nas primeiras conversas deste projeto (a planilha do OneDrive) nunca chegou a ser enviado de fato — só recebi os CSVs de despesas mensais. Por isso o módulo começa vazio: cadastre os ativos manualmente pela tela **Investir**, ou me envie o arquivo de investimentos que você tinha em mente e eu preparo um script de importação igual ao do histórico de despesas.

---

## 5. Arquitetura, em resumo

- **Frontend:** um único `index.html` (HTML + CSS + JavaScript puro), sem build, sem Node.js, sem framework — funciona direto no GitHub Pages.
- **Backend:** Supabase (Postgres + Auth + API REST automática), acessado via `supabase-js` carregado por CDN.
- **Multi-usuário:** cada conta criada gera automaticamente um `household` (a "casa" do casal). Todas as tabelas têm `household_id`, e as Row Level Security Policies do `schema.sql` garantem que um casal nunca vê dados de outro — mesmo todos usando o mesmo projeto Supabase. Isso deixa o app pronto para outros casais usarem no futuro, bastando cada um criar sua própria conta.
- **PWA:** `manifest.json` + `sw.js` deixam o app instalável e com a interface disponível offline; os dados em si sempre vêm do Supabase ao reconectar.
- **Fórmula validada (preservada integralmente):**
  - Cota individual = total das despesas do apartamento ÷ 2
  - O que o parceiro deve = cota − o que o parceiro já pagou nas despesas
  - Schultz Bank entra **inteiro** no acerto
  - Sicredi Black entra **pela metade** no acerto
  - Acerto do mês = (o que o parceiro deve) + (Schultz Bank inteiro) + (metade do Sicredi Black)

---

## 6. Limitações conhecidas

- Não há recuperação de senha configurada por padrão — se precisar, ative em **Authentication → Email Templates** no painel do Supabase.
- O módulo de Investimentos não tem dados históricos pré-carregados (veja item 4).
- Como o login é compartilhado, não há controle de "quem editou o quê" — ambos têm acesso total aos mesmos dados, por design.
