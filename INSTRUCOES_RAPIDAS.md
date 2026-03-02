# ⚡ Instruções Rápidas - Instalar Sistema de Assinaturas

## 🎯 O QUE FAZER

### **3 Passos Simples:**

```
1️⃣ Abrir Supabase Dashboard
   👉 https://supabase.com/dashboard

2️⃣ Ir em SQL Editor → New Query

3️⃣ Copiar e colar este arquivo:
   👉 SETUP_COMPLETO_ASSINATURAS.sql
   
4️⃣ Clicar em RUN

✅ PRONTO!
```

---

## 📋 Passo a Passo Detalhado

### **1. Acessar Supabase**
- Ir em: https://supabase.com/dashboard
- Fazer login
- Selecionar seu projeto

### **2. Abrir SQL Editor**
- Menu lateral → **SQL Editor**
- Clicar em **+ New query**

### **3. Copiar o SQL**
- Abrir arquivo: `SETUP_COMPLETO_ASSINATURAS.sql`
- Selecionar tudo: `Ctrl + A`
- Copiar: `Ctrl + C`

### **4. Colar e Executar**
- Colar no SQL Editor: `Ctrl + V`
- Clicar em **RUN** (ou `Ctrl + Enter`)
- Aguardar 10-30 segundos

### **5. Verificar Sucesso**
Deve aparecer:
```
🎉 SUCESSO! Sistema de assinaturas configurado completamente!

✅ Tabelas criadas: 3 de 3
✅ Funções RPC criadas: 5 de 5
✅ Triggers criados: 1 de 1
✅ Planos inseridos: 3 de 3
```

---

## ✅ Testar no Frontend

Após executar o SQL:

1. Acessar: `http://localhost:5173/planos`
2. Deve ver 3 planos:
   - Teste Gratuito (R$ 0,00)
   - Plano Mensal (R$ 29,90)
   - Plano Anual (R$ 299,90)

3. Clicar em "Iniciar Teste Gratuito"
4. Deve ativar e redirecionar para `/admin`

---

## 📁 Arquivos Importantes

| Arquivo | Para Que Serve |
|---------|----------------|
| `SETUP_COMPLETO_ASSINATURAS.sql` | ⭐ **SQL para executar no Supabase** |
| `EXECUTAR_SQL_SUPABASE.md` | Como executar o SQL |
| `GUIA_INSTALACAO_COMPLETA.md` | Guia detalhado |
| `README_ASSINATURAS.md` | Visão geral do sistema |

---

## 🐛 Se Der Erro

### **"Não foi possível carregar os planos"**
- Limpar cache: `Ctrl + Shift + R`
- Fazer logout e login
- Consultar: `SOLUCAO_ERRO_PLANOS.md`

### **"relation already exists"**
- As tabelas já existem
- Deletar tabelas antigas primeiro
- Consultar: `EXECUTAR_SQL_SUPABASE.md`

---

## 📞 Precisa de Ajuda?

Consulte estes arquivos na ordem:

1. `EXECUTAR_SQL_SUPABASE.md` - Como executar SQL
2. `GUIA_INSTALACAO_COMPLETA.md` - Guia completo
3. `SOLUCAO_ERRO_PLANOS.md` - Solução de erros
4. `README_ASSINATURAS.md` - Documentação geral

---

## 🎉 É Isso!

**Tempo total:** 5 minutos  
**Dificuldade:** Fácil  
**Resultado:** Sistema completo de assinaturas funcionando!

---

**Criado em:** 19 de outubro de 2025  
**Versão:** 2.0
