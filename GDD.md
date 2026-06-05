# GAME DESIGN DOCUMENT
# MERCADO PARALELO

**Versão:** 1.0
**Plataformas:** Android / iOS
**Gênero:** Trading Tycoon / Idle Economy / Casual-Strategy
**Engine alvo:** Unity 2D (URP 2D) ou Godot 4 (2D)
**Orientação:** Vertical (Portrait)
**Modelo:** Free-to-Play com monetização ética
**Público-alvo primário:** 16-45 anos, jogadores de Tycoon, Idle, Adventure Capitalist, Travel Town, Egg Inc., Stardew Valley mobile
**Sessões:** 3-8 sessões por dia, 2-15 minutos cada

---

## ÍNDICE

1. Visão de Alto Nível
2. Pilares de Design
3. Loop Principal e Granularidade Temporal
4. Estrutura Geral de Progressão
5. Sistema Econômico
6. Cidades
7. Produtos
8. Sistema de Raridade
9. Sistema de Coleção (Enciclopédia)
10. Sistema de Inventário e Logística
11. Sistema de NPCs
12. Sistema de Negociação
13. Sistema de Funcionários
14. Sistema Idle (Offline)
15. Sistema de Contratos
16. Sistema de Eventos
17. Sistema de Prestígio
18. Sistema de Retenção
19. Monetização
20. Psicologia de Retenção
21. Escalabilidade e Roadmap Pós-Lançamento
22. Arquitetura Técnica Resumida
23. KPIs e Métricas de Sucesso

---

## 1. VISÃO DE ALTO NÍVEL

### 1.1 Pitch (uma frase)
"Mercado Paralelo" é um simulador 2D casual onde o jogador compra barato em uma cidade, vende caro em outra, lê o pulso de uma economia viva e constrói, comerciante a comerciante, um império logístico que continua crescendo mesmo quando o celular está no bolso.

### 1.2 Fantasia do Jogador
"Eu sou o cara que sempre sabe onde está a oportunidade. Tenho contatos em todas as cidades, leio as notícias antes dos outros e construí tudo isso do zero — com uma mochila."

### 1.3 Hook das primeiras 90 segundos
1. (0-15s) O jogador vê uma mochila e R$ 50.
2. (15-40s) Um NPC oferece 10 maçãs por R$ 30.
3. (40-70s) Uma seta indica a próxima cidade. Lá, maçãs valem R$ 8 cada.
4. (70-90s) Primeira venda. Animação de moedas. Subida de XP. Desbloqueia "Mapa de Cidades". Onboarding terminou.

### 1.4 Diferenciais Competitivos
- **Economia viva real** (não apenas timers): cada cidade tem oferta/demanda flutuante influenciada por eventos, notícias e ações do próprio jogador.
- **Profundidade de Negociação**: minigame de barganha com NPCs com personalidades persistentes.
- **Colecionismo profundo** (500+ itens): a enciclopédia é um meta-objetivo emocional, não apenas estatístico.
- **Idle saudável**: ganhos offline existem, mas as melhores decisões exigem o jogador acordado, leitor do mercado.
- **Sem pay-to-win**: monetização 100% baseada em cosméticos, conveniência e tempo, jamais em poder direto.

---

## 2. PILARES DE DESIGN

Toda decisão de design deve responder "sim" a pelo menos um destes pilares:

1. **Leio o mercado, logo lucro.** — informação tem valor.
2. **Cada cidade é uma personalidade.** — variedade emocional, não apenas numérica.
3. **A coleção me chama de volta.** — colecionismo > grind.
4. **Sou dono do meu império.** — apego emocional a veículos, funcionários, rotas.
5. **Tempo respeitado.** — sessões curtas devem ser tão satisfatórias quanto longas.
6. **Ganhar é satisfatório, mas perder ensina.** — variância controlada, nunca punitiva.

---

## 3. LOOP PRINCIPAL E GRANULARIDADE TEMPORAL

### 3.1 Loop Principal (Core Loop)
```
COMPRAR → TRANSPORTAR → LER MERCADO → NEGOCIAR → VENDER → REINVESTIR
                                ↓
                  COLECIONAR / EVOLUIR / PRESTIGIAR
```

Cada volta do loop dura, em média:
- **Iniciante (Hora 1):** 90-120 segundos.
- **Médio (Semana 2):** 4-6 minutos (rotas mais complexas).
- **Avançado (Mês 2):** 8-12 minutos por decisão consciente, mas várias rotas rodando em paralelo via funcionários.

### 3.2 Gameplay Minuto a Minuto
A sessão típica de 3 minutos contém:
- 1 leitura rápida do feed de notícias (5-10s).
- 1-2 compras em cidades visitadas (20-40s cada).
- 1 negociação (15-30s).
- 1 venda com clímax de lucro (10s).
- 1 pequeno upgrade ou contratação (15s).
- 1 micro-conquista (item raro na enciclopédia, level up de funcionário, etc.) — gatilho dopaminérgico.

A regra de ouro: **toda sessão termina com pelo menos uma "vitória visível"**, mesmo que pequena.

### 3.3 Gameplay da Primeira Hora
- **0-5 min:** Tutorial integrado (não modal, sem paredes de texto). Apresenta compra, venda, viagem.
- **5-15 min:** Desbloqueia 2ª cidade. Aparece o sistema de notícias. Primeira negociação real.
- **15-30 min:** Desbloqueia inventário "Carrinho". Primeira missão de contrato simples.
- **30-45 min:** Primeiro NPC nomeado (Dona Bete, o tutorial humano). Apresenta afinidade.
- **45-60 min:** Primeiro evento ("Festival do Milho" em Cidade Rural). Jogador descobre que decisões de timing importam. Desbloqueia 3ª cidade.

**Promessa entregue ao final da Hora 1:** o jogador entendeu que esse jogo é sobre LEITURA + TIMING, não sobre cliques.

### 3.4 Gameplay da Primeira Semana
- **Dia 1:** 4 cidades, 1ª moto, 8-12 produtos descobertos, 2 funcionários.
- **Dia 2:** Sistema de contratos plenamente ativo. Primeiro item Raro.
- **Dia 3:** Desbloqueio do "Distrito Tecnológico". Primeira crise simulada (boa lição de gestão de risco).
- **Dia 4:** Van. Capacidade de rodar 2 rotas simultâneas.
- **Dia 5:** Primeira Temporada (Passe) é apresentada.
- **Dia 6:** Primeiro funcionário Raro. Apego emocional começa.
- **Dia 7:** Primeira meta de coleção semanal completada. Recompensa cosmética notável.

**Meta de retenção D7:** 22-28%.

### 3.5 Gameplay do Primeiro Mês
- **Semana 2:** Domínio das 8 cidades base. Caminhão. Rotas automatizadas via funcionários.
- **Semana 3:** Primeiro item Épico. Primeira raridade Lendária avistada (mas talvez não comprada). Player descobre o sistema de Investidores (NPCs que dão dicas pagas).
- **Semana 4:** Player se aproxima do primeiro **Prestígio**. Sistema mostra os bônus permanentes pela primeira vez.

**Meta de retenção D30:** 8-12%.

### 3.6 Progressão Infinita
A progressão é estruturada em três horizontes simultâneos:

| Horizonte | Driver Principal | Cap |
|-----------|------------------|-----|
| Curto (sessão) | Lucro imediato, missões diárias | Soft, renovável diariamente |
| Médio (semanas) | Coleção, funcionários, frota | Cap ~500h por loop |
| Longo (meses+) | Prestígio, multiplicadores, títulos | **Infinito** |

A progressão infinita é matematicamente sustentada pela curva exponencial de patrimônio (ver 17.3) cruzada com uma curva logarítmica de bônus de prestígio, garantindo que cada novo prestígio dure ~70-80% do tempo do anterior.

### 3.7 Objetivos de Curto, Médio e Longo Prazo

**Curto (minutos/horas):**
- Concluir 3 vendas lucrativas.
- Encontrar 1 produto novo.
- Subir 1 nível de funcionário.
- Bater meta diária de patrimônio.

**Médio (dias/semanas):**
- Desbloquear todas as cidades base.
- Completar 1 família de coleção (ex: "Todos os queijos artesanais").
- Adquirir 1ª frota Lendária.
- Concluir passe da temporada.

**Longo (meses):**
- 1º, 5º, 25º Prestígio.
- Coleção 100% completa por categoria.
- Títulos lendários (ex: "Magnata Global").
- Top 1.000 de leaderboard sazonal.

### 3.8 Sistema de Retenção Diária (visão geral, detalhes em §18)
- Login diário com calendário de 30 dias rotativo.
- 3 missões diárias + 1 semanal.
- 1 "Oferta Misteriosa" diária (NPC ambulante).
- 1 evento global de fim de semana.
- Notificação push contextual (não spammy): "Você tem 12 itens raros prontos para venda no Porto."

---

## 4. ESTRUTURA GERAL DE PROGRESSÃO

### 4.1 Camadas
```
Patrimônio (R$)
   ↓ alimenta
Inventário/Logística (capacidade)
   ↓ alimenta
Rotas Possíveis (cidades x produtos)
   ↓ alimenta
Funcionários (automatização)
   ↓ alimenta
Idle (ganhos offline)
   ↓ alimenta
Prestígio (multiplicadores)
   ↓ realimenta Patrimônio (loop infinito)
```

### 4.2 Curva de Patrimônio Alvo (não-prestígio, ritmo médio)
- Dia 1: R$ 1.000
- Dia 3: R$ 25.000
- Dia 7: R$ 500.000
- Dia 14: R$ 10.000.000
- Dia 30: R$ 1 bilhão
- Dia 60: pronto para 1º Prestígio (~R$ 1 trilhão)

Após Prestígio, a curva é acelerada pelos multiplicadores acumulados.

---

## 5. SISTEMA ECONÔMICO

### 5.1 Princípios
1. **Toda cidade é um agente econômico independente.**
2. **Preços não são tabelados; são calculados a cada tick.**
3. **Ações do jogador influenciam o mercado** (vender 1000 maçãs em uma cidade derruba o preço local).
4. **Eventos e notícias são choques.**
5. **Há ciclos, mas não previsíveis demais** — variância controlada.

### 5.2 Fórmula Base de Preço

Para cada par (cidade `c`, produto `p`):

```
Preço(c, p, t) = PreçoBase(p)
              × Modificador_Cidade(c, p)
              × Modificador_Demanda(c, p, t)
              × Modificador_Oferta(c, p, t)
              × Modificador_Evento(c, p, t)
              × Modificador_Notícia(c, p, t)
              × Modificador_Sazonal(t)
              × (1 + Ruído_Gaussiano(σ=0.05))
```

Cada modificador é um multiplicador em torno de 1.0:

- **Modificador_Cidade**: característica fixa (ex: Distrito Tecnológico tem 0.6 para Eletrônicos e 1.4 para Antiguidades).
- **Modificador_Demanda**: cresce quando estoque local cai e atividade de NPCs aumenta. Faixa típica [0.7, 1.6].
- **Modificador_Oferta**: cresce quando estoque local sobe. Faixa típica [0.5, 1.3].
- **Modificador_Evento**: ativo só durante eventos. Pode chegar a [0.3, 3.5].
- **Modificador_Notícia**: pulsos que decaem exponencialmente após o anúncio. Pico [0.5, 2.5], meia-vida 4-12h.
- **Modificador_Sazonal**: ciclos longos (semana, mês, estação no mundo do jogo).
- **Ruído**: garante imprevisibilidade leve.

### 5.3 Tick Econômico
- A simulação roda a cada **15 minutos de tempo real** (cliente puxa do servidor, idle calcula localmente até reconexão).
- Em segundo plano, eventos podem disparar a qualquer momento (notícias).

### 5.4 Demanda e Oferta — Modelo Simplificado

```
Demanda(c, p, t+1) = Demanda(c, p, t) × (1 - taxa_consumo)
                   + Demanda_Natural(c, p)
                   + Demanda_Evento(c, p, t)

Oferta(c, p, t+1)  = Oferta(c, p, t) × (1 - taxa_escoamento)
                   + Produção_Natural(c, p)
                   - Vendas_Jogador(c, p, t)
                   + Importações_NPC(c, p, t)
```

Quando `Demanda > Oferta`, preço sobe. Quando `Oferta > Demanda`, preço cai. A taxa de ajuste é amortecida para evitar oscilação caótica.

### 5.5 Exemplos Práticos

**Festival local em Cidade Histórica**
- Bebidas: Mod_Evento = 1.8 por 6h.
- Comidas regionais: Mod_Evento = 2.1 por 8h.
- Antiguidades: Mod_Evento = 1.3 por 12h.
- Pré-anúncio 2h antes via feed de notícias (recompensa a leitura atenta).

**Crise tecnológica**
- Eletrônicos globais: Mod_Notícia = 0.55 por 48h.
- Mas eletrônicos no Distrito Tecnológico, que tem produção própria, caem só para 0.7 (resiliência local).
- Oportunidade: comprar barato globalmente, esperar a recuperação, revender.

**Feira internacional no Mercado Internacional**
- Itens importados: Mod_Evento = 1.6 por 24h.
- Itens nacionais: 0.9 (suprimento aumenta de exportações concorrentes).

### 5.6 Memória de Mercado (Histórico)
Cada par (cidade, produto) guarda um histórico rolante de 7 dias com:
- Preço mín/máx/médio.
- Volatilidade.
- Volume tradado pelo jogador.

Exibido no UI como gráfico de linha simples — fundamental para o pilar "Leio o mercado, logo lucro".

### 5.7 Limites Antiabuso
- Caps de quantidade vendável por hora por cidade (evita "dumping" infinito).
- Cooldown de viagem rápida (ou custo logístico).
- "Saturação de mercado": vender 500x acima da demanda diária local zera o lucro marginal.

---

## 6. CIDADES

### 6.1 Cidades Base (8 cidades de lançamento)

| Cidade | Identidade Visual | Especialização | Produtos Exclusivos | Eventos Característicos |
|--------|------------------|----------------|---------------------|------------------------|
| **Centro Comercial** | Néons, vitrines, alta densidade urbana | Hub central, vende um pouco de tudo | Roupas de marca, perfumes urbanos | Black Friday, Liquidações |
| **Porto** | Containers, gaivotas, paleta azul-cinza | Importados, peixes, especiarias | Bacalhau seco, especiarias raras, contêineres surpresa | Chegada de Navios, Greves Portuárias |
| **Distrito Tecnológico** | Vidro, LED, paleta ciano-roxa | Eletrônicos, componentes | Chips raros, protótipos, GPUs | Lançamentos, Crises de Chip |
| **Zona Industrial** | Fumaça, ferro, paleta laranja-fumê | Matérias-primas, ferramentas | Aço, máquinas, peças pesadas | Paradas de Fábrica, Boom Industrial |
| **Mercado Internacional** | Bandeiras, multilíngue, paleta dourada | Itens importados de alto valor | Cosméticos importados, vinhos europeus | Feiras Internacionais, Tarifas |
| **Cidade Histórica** | Pedra, lampiões, paleta sépia | Antiguidades, artefatos | Moedas antigas, manuscritos, relíquias | Escavações, Festivais Históricos |
| **Cidade Turística** | Praia/montanha, paleta vibrante | Souvenirs, comidas regionais, luxo | Artesanato local, joalheria de praia | Alta Temporada, Carnaval |
| **Região Rural** | Plantações, paleta verde-terra | Alimentos frescos, animais, ferramentas agrícolas | Queijos artesanais, mel raro, frutas exóticas | Festival da Colheita, Seca |

Cada cidade tem:
- **Skyline única** em arte 2D side-scroll horizontal.
- **Música ambiente** com motivo melódico próprio.
- **NPCs típicos** (ver §11).
- **Coeficientes econômicos** próprios (matriz 8 cidades × 8 categorias).

### 6.2 Cidades Pós-Lançamento (Roadmap)
- Cidade Subterrânea (mercado paralelo de raridades).
- Capital Política (eventos de regulação).
- Cidade Universitária (livros, tecnologia educacional).
- Cidade Fronteira (contrabando regulamentado).
- Ilha Resort.
- Megacidade Estrangeira (DLC sazonal).

### 6.3 Desbloqueio
- Cidades 1-2: tutorial.
- Cidades 3-4: nível 5 e 10 do jogador.
- Cidades 5-6: patrimônio + reputação.
- Cidades 7-8: missão narrativa.
- Cidades futuras: temporadas e prestígio.

---

## 7. PRODUTOS

### 7.1 Catálogo
Mínimo de **500 produtos** divididos em 8 categorias principais. Cada categoria tem 5-7 subcategorias, e cada subcategoria 10-15 itens, garantindo cobertura ampla.

| Categoria | Subcategorias (exemplos) | Total alvo |
|-----------|--------------------------|-----------|
| Alimentos | Frutas, Queijos, Especiarias, Bebidas, Doces, Carnes, Grãos | 80 |
| Eletrônicos | Smartphones, Componentes, Wearables, Áudio, Periféricos | 70 |
| Colecionáveis | Cards, Figuras, Selos, Moedas modernas, Brinquedos | 70 |
| Antiguidades | Moedas antigas, Manuscritos, Mobiliário, Joias antigas | 60 |
| Ferramentas | Manuais, Elétricas, Industriais, Agrícolas, Especializadas | 50 |
| Veículos (mercadoria, não próprios) | Bicicletas, Motos pequenas, Peças, Acessórios | 40 |
| Artefatos Raros | Religiosos, Místicos, Arqueológicos, Curiosidades | 60 |
| Itens de Luxo | Joias modernas, Relógios, Perfumes, Moda, Vinhos | 70 |

### 7.2 Ficha Técnica de Cada Item
```yaml
id: "queijo_canastra_artesanal"
nome: "Queijo Canastra Artesanal"
categoria: "Alimentos"
subcategoria: "Queijos"
preco_base: 45.00
raridade: "Incomum"
peso_kg: 1.2
volume_l: 1.0
perecivel: true
shelf_life_horas: 72
demanda_natural: { rural: 0.6, turistica: 1.4, historica: 1.2, internacional: 1.5 }
producao_natural: { rural: 1.5 }
historico_mercado: <gerado em runtime>
descricao_lore: "Maturado por 60 dias em queijarias familiares..."
icone_2d: "items/food/queijo_canastra.png"
unlocked_in: ["rural"]
```

### 7.3 Perecibilidade
Itens perecíveis (alimentos, alguns artefatos) têm shelf-life. Forçam decisões de roteamento e criam tensão. Funcionários "Logística" e veículos refrigerados aumentam shelf-life.

### 7.4 Peso e Volume
Inventário considera **duas restrições simultâneas** (peso e volume), criando puzzles de empacotamento naturais — antiguidades pesam pouco mas ocupam volume, especiarias caras pesam quase nada.

---

## 8. SISTEMA DE RARIDADE

### 8.1 Níveis e Distribuição
| Raridade | Cor UI | % Drop Base | Mod. Preço | Mod. XP | Stack |
|----------|--------|-------------|------------|---------|-------|
| Comum | Cinza | 70% | 1.0x | 1.0x | 999 |
| Incomum | Verde | 22% | 1.6x | 1.4x | 500 |
| Raro | Azul | 6% | 3.5x | 2.0x | 100 |
| Épico | Roxo | 1.6% | 9x | 3.5x | 50 |
| Lendário | Laranja | 0.35% | 30x | 7x | 10 |
| Mítico | Vermelho/Holo | 0.05% | 120x | 20x | 1 |

### 8.2 Impacto da Raridade
- **Preço base**: multiplicado conforme tabela.
- **Volatilidade**: itens mais raros têm volatilidade maior (até ±60% no mercado livre).
- **NPCs Colecionadores**: pagam 2-5x acima do mercado por itens Épicos+.
- **Apresentação visual**: efeitos de partícula, animação especial ao adquirir Lendário+.
- **Coleção**: itens Lendários e Míticos têm entradas dedicadas com lore expandido.
- **Drop em cidades**: cada raridade tem cidades-fonte preferidas (Míticos surgem com 0.02% em qualquer cidade, mas com 0.4% em eventos especiais).

### 8.3 Pity System Sutil
Para evitar frustração crônica, há um soft pity: a cada N transações sem item Raro+, a chance é aumentada progressivamente até cap. Reseta ao obter. **Não comunicado explicitamente ao jogador** (preserva o mistério).

---

## 9. SISTEMA DE COLEÇÃO (ENCICLOPÉDIA)

### 9.1 Conceito
A "Enciclopédia do Mercado" é a memória do jogador. Cada produto, NPC, evento e relíquia descobertos é catalogado.

### 9.2 Tipos de Registro
- **Produtos** (500+): cada item descoberto é registrado com lore, gráfico de preço histórico pessoal, melhores rotas conhecidas.
- **NPCs**: ficha com personalidade, afinidade atual, preferências aprendidas.
- **Eventos**: cada evento vivido é registrado com data, cidade, impacto.
- **Locais**: distritos secretos dentro das cidades (ex: "Beco do Antiquário" em Cidade Histórica).
- **Relíquias raras**: subcategoria especial — 50 itens icônicos com lore profundo e arte ilustrada.

### 9.3 Bônus de Coleção
- Cada subcategoria 100% completa: +5% lucro permanente naquela subcategoria.
- Cada categoria 100% completa: +10% lucro + cosmético exclusivo.
- 100% global: título "Cronista do Mercado" + skin de mochila lendária.
- **Coleções não dão poder de combate** (não há combate), apenas otimização de margens e prestígio social.

### 9.4 Por Que Funciona
Colecionismo gera o que a literatura de design chama de "completion drive": uma vez que o jogador vê 87/100 numa categoria, o cérebro pede os 13 faltantes. É retenção sem grind, porque cada item novo é um descobrimento.

---

## 10. SISTEMA DE INVENTÁRIO E LOGÍSTICA

### 10.1 Progressão da Frota

| Tier | Item | Capacidade (peso) | Capacidade (volume) | Velocidade rota | Custo/viagem | Idle slots |
|------|------|-------------------|---------------------|----------------|-------------|------------|
| 1 | Mochila | 15 kg | 20 L | 1.0x | 0 | 1 |
| 2 | Carrinho | 60 kg | 100 L | 1.1x | R$ 5 | 1 |
| 3 | Motocicleta | 120 kg | 150 L | 1.6x | R$ 25 | 2 |
| 4 | Van | 500 kg | 800 L | 1.4x | R$ 80 | 3 |
| 5 | Caminhão | 2.500 kg | 6.000 L | 1.2x | R$ 250 | 5 |
| 6 | Frota Logística | ilimitado modular | ilimitado modular | 1.0-2.0x | variável | 10+ |

### 10.2 Como Cada Upgrade Muda o Jogo
- **Mochila → Carrinho**: aprendizado de roteamento.
- **Carrinho → Moto**: primeira sensação de velocidade.
- **Moto → Van**: surgem rotas multiproduto.
- **Van → Caminhão**: arbitragem em massa, foco em commodities.
- **Caminhão → Frota**: jogador vira gestor; funcionários assumem rotas.

### 10.3 Frota Logística (endgame)
- Compre veículos individuais (até dezenas).
- Cada veículo tem motorista (NPC funcionário).
- Designe rotas automáticas (cidade A → cidade B com produto X quando preço > Y).
- O jogador vira "tower defense" do dinheiro: monta o sistema, ajusta parâmetros, colhe lucros.

### 10.4 Manutenção
- Veículos têm "condição" 0-100.
- Cai com uso. Reparo custa R$.
- Veículos premium (skins de monetização) **NÃO** têm condição melhor — só são bonitos. (Anti P2W.)

---

## 11. SISTEMA DE NPCs

### 11.1 Volume
- **300+ NPCs nomeados** no lançamento.
- 30-50 NPCs novos por temporada (4 temporadas/ano).
- Cada cidade tem 25-50 NPCs "moradores" + NPCs ambulantes que viajam.

### 11.2 Ficha do NPC
```yaml
id: "dona_bete"
nome: "Dona Bete"
cidade_base: "rural"
arquetipo: "Negociante Tradicional"
personalidade: { paciencia: 0.7, ganancia: 0.3, humor: 0.8 }
preferencias: { gosta: ["queijos","mel"], odeia: ["eletronicos_baratos"] }
historico_negociacoes: <runtime>
afinidade: 0..100
arco_relacionamento: ["Estranho","Conhecido","Cliente","Amigo","Parceiro","Mentor"]
falas_chave: <pool por nível de afinidade>
oferta_especial_recorrente: "Queijo Canastra a 30% abaixo do mercado, 1x/semana"
```

### 11.3 Arquétipos de NPC (mínimo 12)
1. **Colecionador** — paga premium por raridade.
2. **Investidor** — vende dicas antecipadas de mercado.
3. **Turista** — quer souvenirs, paga acima por exclusividade local.
4. **Atacadista** — desconto se você compra em volume.
5. **Sucateiro** — interessado em itens danificados, raros artefatos.
6. **Curador de Museu** — Antiguidades e Artefatos Raros.
7. **Foodie** — comidas, preferência por perecíveis frescos.
8. **Tech Influencer** — Eletrônicos novos, paga mais por "primeira mão".
9. **Burocrata** — contratos oficiais (alta margem, baixa frequência).
10. **Contrabandista** (regulamentado, pós-lançamento) — itens raros, alto risco-recompensa.
11. **Mentor Aposentado** — não compra/vende, dá missões narrativas.
12. **Rival** — outro comerciante NPC que compete por estoque (jogador pode formar alianças).

### 11.4 Afinidade
- 0-20: Estranho. Preços brutos, sem ofertas especiais.
- 21-40: Conhecido. +2% margem.
- 41-60: Cliente. Ofertas semanais, +5% margem.
- 61-80: Amigo. Dicas grátis ocasionais, +8% margem.
- 81-95: Parceiro. Acesso a estoque exclusivo do NPC, +12% margem.
- 96-100: Mentor. Bônus passivo permanente naquela categoria.

Afinidade sobe com volume de comércio justo e cumprimento de contratos. Cai com tentativas de enganação detectadas (ver §12).

### 11.5 NPCs Móveis
Alguns NPCs viajam entre cidades em rotas conhecidas. O jogador aprende quando e onde encontrá-los — outra camada de "ler o mundo".

---

## 12. SISTEMA DE NEGOCIAÇÃO

### 12.1 Visão Geral
Quando o jogador interage com um NPC para vender (ou comprar) acima de um certo volume, entra um **minigame de barganha** em pop-up. Para transações pequenas é opcional (atalho "Vender direto").

### 12.2 UI do Minigame
- Slider de preço com indicador visual de "conforto" do NPC (verde/amarelo/vermelho).
- 3 botões: **Aceitar oferta atual** / **Contraproposta** / **Pressionar** (risco).
- Timer de 8s por turno (clima de negociação).
- Personalidade do NPC influencia tudo.

### 12.3 Modelo Matemático

Cada NPC tem um **preço-alvo interno** `P_alvo` baseado em:
```
P_alvo = PrecoMercado(c, p, t) × (1 + viés_NPC)
```
onde `viés_NPC` é função de:
- Arquétipo (Colecionador: +0.3 ao comprar raros).
- Preferências.
- Afinidade.
- Humor atual (estado do dia).
- Histórico recente com o jogador.

E uma **zona de aceitação**:
```
Aceitação = [P_alvo × (1 - tolerância), P_alvo × (1 + tolerância)]
```

`tolerância` depende da paciência do NPC (0.05 a 0.25).

### 12.4 Ações do NPC
- **Aceita** se a oferta cai dentro da zona, com probabilidade proporcional a quão central está.
- **Contrapropõe** se está perto mas fora: oferta = ponto médio entre proposta e P_alvo.
- **Recusa** se está muito fora; cooldown de 1h para renegociar.
- **Tenta enganar** (NPCs específicos, baixa confiança): oferece P_alvo escondendo que sabe que o produto é raro. Jogador pode descobrir via skill "Olho Clínico" de funcionário ou bônus de coleção.
- **Pede desconto** se oferta inicial é absurda — abre janela de barganha.

### 12.5 Mecânicas de Pressão
- "Pressionar" empurra preço a favor do jogador mas reduz humor do NPC (-3 afinidade por uso).
- Funcionários Negociadores reduzem essa penalidade.
- Item de monetização "Charme do Comerciante" (cosmético) **não altera resultados** — apenas anima a fala.

### 12.6 Detecção de Engano
Se o jogador tenta vender Comum como se fosse Raro, NPCs Experientes (afinidade > 60) detectam e cobram em afinidade. Funcionários Analistas reduzem chance de o NPC detectar... mas isso é eticamente cinzento e a versão "honesta" rende mais a longo prazo. Sistema permite estilo de jogo "sombrio" sem premiá-lo desproporcionalmente.

---

## 13. SISTEMA DE FUNCIONÁRIOS

### 13.1 Categorias
| Categoria | Função | Atributo-chave |
|-----------|--------|----------------|
| Comprador | Compra automática em rotas | Olho de Mercado |
| Vendedor | Vende automaticamente respeitando preço-mínimo | Negociação |
| Motorista | Conduz rotas, reduz tempo/custo | Velocidade, Confiabilidade |
| Analista | Gera relatórios, prevê tendências, detecta enganações | Inteligência |
| Gerente | Multiplica eficiência de outros funcionários sob sua filial | Liderança, Lealdade |

### 13.2 Atributos Base (escala 1-100)
- **Negociação**: melhora margem média em transações automáticas.
- **Velocidade**: reduz tempo de rota.
- **Inteligência**: precisão de previsões, qualidade de relatórios.
- **Lealdade**: reduz custo de salário, reduz risco de "renúncia" em prestígio.
- **Resistência**: trabalha mais turnos sem queda de performance.
- **Carisma** (Vendedores): bônus em preço de venda.

### 13.3 Raridade de Funcionários
Funcionários têm raridade própria (paralela à de itens). Lendários têm sinergias únicas (ex: "Quando trabalha no Porto, todos os Pescados vendem +25%").

### 13.4 Evolução
- **XP** por tarefa cumprida.
- **Treinamento** pago (R$ ou tokens raros).
- **Mentoria**: Funcionário sênior treina junior por 24h, transfere 30% do nível.
- **Equipamento**: ferramentas (mochila do Comprador, GPS do Motorista) dão +atributo. Algumas vêm de eventos.

### 13.5 Salário e Moral
- Salário diário automatizado.
- Moral cai se trabalha mais que turno; sobe com bônus.
- Moral baixa reduz performance, não causa "demissão" abrupta (queremos apego, não frustração).

### 13.6 Apego Emocional
- Nomes próprios, retratos 2D estilizados.
- Frases ambientais ("Hoje os preços tão estranhos no Porto, patrão.").
- Quando o jogador prestigía, funcionários favoritos podem ser "salvos" com cosmético comemorativo.

---

## 14. SISTEMA IDLE (OFFLINE)

### 14.1 Princípio
O idle existe para respeitar a vida do jogador, **não** para substituir a presença consciente. Voltar ao jogo deve ser empolgante, não obrigatório.

### 14.2 Como Funciona
Quando o jogador fecha o app, o servidor (ou cliente em modo offline) simula:
- Funcionários executando suas rotas atribuídas.
- Estoque vendendo conforme preço-mínimo.
- Eventos econômicos progredindo.
- Mercados oscilando.

### 14.3 Limites
- **Cap de 12h de idle ativo** (cresce com upgrades até 24h e, pós-prestígio, até 48h).
- Após o cap, lucros são reduzidos em 80% (mas mercados continuam evoluindo).
- Anúncio recompensado pode **dobrar** ganhos das últimas X horas (opt-in, ver §19.1).

### 14.4 Relatório de Retorno
Pop-up "Boas-vindas de volta!" com:
- Resumo de lucros totais.
- Top 3 vendas (com NPCs).
- 1-2 alertas ("Festival começou em Cidade Histórica! +6h restantes").
- 1 "Oportunidade perdida" honesta ("Você poderia ter ganhado +R$ 12k se tivesse 2 vans extras") — empurra leve para upgrade, sem culpar.
- Botão "Coletar tudo" com animação satisfatória.

### 14.5 Auto-Optimização (toggleável)
Funcionários Analistas com nível alto sugerem ajustes de rota offline. Não executam automaticamente — sugerem, para preservar agência.

---

## 15. SISTEMA DE CONTRATOS

### 15.1 Tipos de Missão
1. **Entrega**: Levar produto X de cidade A para cidade B em tempo T.
2. **Coleta**: Obter N unidades de produto Y, qualquer fonte.
3. **Venda dirigida**: Vender produto Z a um NPC específico por preço mínimo.
4. **Investigação**: Visitar 3 cidades e relatar preços de uma categoria (gera bônus de info).
5. **Aquisição rara**: Encontrar 1 item de raridade ≥X.
6. **Negociação difícil**: Fechar negócio com NPC hostil (afinidade < 20).
7. **Frete em comboio**: Múltiplos veículos coordenados.
8. **Sazonal**: Contratos especiais durante eventos.

### 15.2 Estrutura de Recompensa
- R$ base + % de margem da operação.
- XP.
- Tokens da temporada (passe).
- Chance de cosmético raro (em contratos lendários).
- Aumento de reputação na cidade emissora.

### 15.3 Cadência
- **3 contratos diários** disponíveis (renovam meia-noite local).
- **1 contrato semanal** de longo prazo (alta recompensa).
- **1 contrato mensal** narrativo (avanço de história).
- Contratos extras desbloqueáveis via reputação alta com NPCs específicos.

### 15.4 Curva de Dificuldade Adaptativa
A dificuldade dos contratos diários escala com patrimônio do jogador e nível, garantindo desafio sem ser punitivo.

---

## 16. SISTEMA DE EVENTOS

### 16.1 Tipos
- **Eventos Locais** (cidade-específicos): Festival, Feira, Liquidação.
- **Eventos Regionais** (2-3 cidades): Convenção, Exposição.
- **Eventos Globais** (todas as cidades): Crise, Boom, Carnaval.
- **Eventos Sazonais** (temporada): Natal, Halloween, Festa Junina (em mercados latinos).
- **Eventos Surpresa** (raros, 1 por semana média): "Caravana Misteriosa Chegou ao Porto" — janela de 2h.

### 16.2 Catálogo Inicial (mínimo 60 eventos no lançamento)
Festival do Milho, Carnaval Portuário, Black Friday, Crise de Chip, Descoberta Arqueológica, Greve Geral, Boom Imobiliário, Eclipse Cultural, Convenção de Antiguidades, Exposição Tech, Feira Internacional de Vinhos, etc.

Roadmap: +20 eventos por temporada.

### 16.3 Anatomia de um Evento
```yaml
id: "festival_milho"
cidades_afetadas: ["rural","historica"]
duracao_horas: 48
pre_aviso_horas: 12
mod_demanda: { alimentos.graos: 2.0, bebidas: 1.6 }
mod_oferta: { artesanato_local: 1.3 }
npcs_especiais_spawn: ["seu_pedro_o_pamonheiro"]
contratos_especiais: ["entrega_milho_express"]
visual: { fundo_cidade: "festival_milho.png", musica: "festival.ogg" }
chance_drop_raro_bonus: 1.5x
```

### 16.4 Calendário e Visibilidade
- Calendário no UI mostra eventos próximos (até 7 dias à frente).
- Notícias pré-anunciam com vantagem para quem checa.
- Push notification opcional 30min antes.

### 16.5 Impacto Econômico
- Eventos podem mover o mercado em ±50-200% em produtos-chave.
- Eventos negativos (crises) também são oportunidades — comprar barato, esperar recuperação.

---

## 17. SISTEMA DE PRESTÍGIO

### 17.1 Conceito
Após atingir certo patrimônio (ex: R$ 1 trilhão no 1º ciclo), o jogador pode **"Refundar o Império"**. Reseta dinheiro, inventário, frota e funcionários básicos, mas ganha bônus permanentes.

### 17.2 O Que Permanece
- **Pontos de Prestígio (PP)**: moeda meta para a Árvore de Talentos.
- **Multiplicadores Permanentes**: +X% lucro global, +Y% velocidade idle, etc.
- **Títulos**: "Magnata", "Mercador Lendário", "Imperador do Comércio".
- **Cosméticos** desbloqueados.
- **Enciclopédia** (coleção é eterna).
- **NPCs Mentores** (afinidade 96+) ressurgem ao nível "Conhecido" automaticamente.
- **Cofre do Prestígio**: 5 itens podem ser preservados (escolha do jogador) — apego emocional ao primeiro Lendário etc.

### 17.3 O Que Reseta
- Patrimônio em moeda corrente.
- Inventário comum.
- Frota acima do tier base.
- Funcionários comuns.
- Reputação de cidades volta a 0 (mas reconquista é 2x mais rápida).

### 17.4 Árvore de Talentos (Permanente)
- **Galho Mercador**: bônus de margem, negociação, detecção.
- **Galho Logístico**: capacidade, velocidade, redução de custos.
- **Galho Idle**: tempo cap, eficiência offline.
- **Galho Coleção**: bônus por categoria descoberta, sorte de raros.
- **Galho Social**: NPCs, afinidade acelerada, eventos rentáveis.

### 17.5 Cadência de Prestígio
- 1º Prestígio: 30-60 dias de jogo.
- 2º-5º: 7-21 dias cada.
- 6º+: cada vez mais rápido até estabilizar em ~3-5 dias por ciclo no endgame.

### 17.6 Progressão Infinita
Sem teto matemático em PP. Mas após nível 100 da árvore, novos prestígios desbloqueiam **cidades secretas, NPCs míticos, eventos lendários** — extensão de conteúdo, não apenas números.

---

## 18. SISTEMA DE RETENÇÃO

### 18.1 Missões Diárias
- 3 missões diárias, mix automático:
  - 1 fácil (engajamento garantido).
  - 1 média (esforço).
  - 1 com escolha de categoria (agência).
- Recompensa em R$, XP e tokens do passe.
- **Por que retém:** pequeno compromisso diário, sentimento de progresso.

### 18.2 Missões Semanais
- 5 metas semanais com barra cumulativa.
- Recompensa final grande (cosmético raro ou item de fusão de prestígio).
- **Por que retém:** investimento de tempo cria sunk-cost saudável; jogador volta para "não perder".

### 18.3 Calendário de Login
- 30 dias rotativos.
- Dias 7, 15, 22, 30: recompensa premium (cosmético, funcionário raro, multiplicador 24h).
- Perder dia não reseta progresso, apenas pula recompensa. (Saudável, não punitivo.)
- **Por que retém:** ritual de abrir o app. Familiar, previsível, satisfatório.

### 18.4 Eventos Sazonais
- 4 temporadas anuais de 60-90 dias cada.
- Cada temporada: tema (Verão Tropical, Festa Junina, Halloween, Natal).
- Cidade temática "decorada".
- 10-15 itens exclusivos.
- Passe de Temporada (ver monetização).
- **Por que retém:** medo de perder algo único — FOMO ético (cosméticos, não poder).

### 18.5 Recompensas Surpresa
- "Sorte do Comerciante": chance diária de 1 NPC visitante oferecer deal absurdamente bom.
- "Caixa Esquecida no Porto" semanal.
- Pop-up surpresa de R$ por sessões longas (>15min).
- **Por que retém:** reforço de razão variável (Skinner) sem ser predatório, porque não exige pagar.

### 18.6 Objetivos de Coleção
Ver §9. **Por que retém:** completion drive cognitivo, recompensa cosmética + bônus marginal.

### 18.7 Objetivos de Prestígio
Cada prestígio gera novas metas (Árvore de Talentos, novos cosméticos, novos títulos). **Por que retém:** o jogador SEMPRE tem próximo grande objetivo a 1-3 semanas de distância.

### 18.8 Princípios Norteadores
- **Nenhuma streak é punitiva.** Perder dia ≠ perder progresso global.
- **Nenhuma timer pressiona a vida real** ("Volte em 8h ou perde!" → NÃO).
- **Nenhuma push é genérica.** Toda notificação carrega contexto real do jogo do usuário.

---

## 19. MONETIZAÇÃO

### 19.1 Princípio Central
**Pagar deve melhorar a experiência do pagante sem piorar a do não-pagante.** Sem energia/vidas pagas. Sem itens de poder. Sem leilões para vencer outros jogadores com cartão de crédito.

### 19.2 Anúncios Recompensados
Sempre **opcionais**, ativados pelo jogador, jamais interrompem a jogabilidade.

Lista de usos:
- 🎬 Dobrar ganhos offline (uma vez por sessão).
- 🎬 Receber 1 dica de mercado premium (24h).
- 🎬 +50% chance de raro na próxima viagem.
- 🎬 Abrir caixa misteriosa diária extra.
- 🎬 Acelerar treinamento de funcionário em 1h.
- 🎬 Reroll de 1 missão diária.
- 🎬 Skin temporária 24h.

Tetos:
- Máximo de 8 anúncios opt-in por dia.
- Cooldown de 3min entre anúncios (anti-abuso).
- **Nunca interstitial forçado.** Nunca.

### 19.3 Passe de Temporada
- **Trilha Gratuita** (50 níveis): cosméticos básicos, R$ extra, 1 funcionário comum exclusivo.
- **Trilha Premium** (R$ 24,90/temporada): cosméticos premium, temas visuais, avatares, veículos cosméticos, decorações, 1 funcionário lendário cosmético, **+10% XP do passe**.
- **Premium+ "Magnata"** (R$ 49,90): tudo do premium + 25 níveis de boost + cosmético exclusivo + emblema permanente.

Cada nível dá XP a partir de:
- Missões diárias/semanais.
- Contratos.
- Conquistas.
- (Não é possível comprar XP do passe à parte — só níveis individuais "skip" se a temporada está acabando.)

**Sem venda de poder.** Funcionários do passe são reskins de comuns/incomuns com atributos equivalentes.

### 19.4 Loja de Cosméticos
- Mochilas especiais (50+ designs).
- Caminhões personalizados (100+ skins).
- Temas de cidades (chuva, neon, sépia, cyber).
- Efeitos visuais (rastro de moedas, partículas de raridade).
- Mascotes (gato, capivara, cachorro — ficam no canto da tela, dão pequenas falas, **sem efeito gameplay**).
- Animações exclusivas (de venda, de chegada na cidade).

Preços: R$ 4,90 a R$ 39,90 por item. Pacotes promocionais sazonais.

### 19.5 Assinatura Premium ("Clube do Magnata")
**R$ 19,90/mês** (ou R$ 199/ano):
- 📊 Estatísticas avançadas (gráficos de 30 dias, comparativos por cidade).
- 📰 Relatórios de mercado expandidos (previsões com mais antecedência — mas as mesmas informações que o jogo já dá publicamente; aqui é UX, não vantagem oculta).
- 🎨 1 cosmético exclusivo mensal.
- 🧰 Filtros e atalhos avançados na UI.
- 🚛 +1 slot de rota auto.
- 🪙 Daily bônus de R$ + tokens do passe.
- 🎬 Anúncios opcionais removidos.
- 🎒 +20% capacidade de inventário (conveniência; jogadores free atingem o mesmo com upgrades de prestígio em ~3 dias).

A assinatura **não acelera prestígio**, **não dá itens raros exclusivos do jogo**, **não desbloqueia cidades**.

### 19.6 Eventos Monetizados
- Eventos sazonais ofertam **bundles cosméticos** (R$ 9,90 a R$ 59,90) com itens decorativos.
- Coleções limitadas — após expiradas, NÃO retornam por 12 meses (FOMO ético; eventual rerun garante justiça).
- Skins, decorações para "Sede do Império" (espaço social cosmético).

### 19.7 O Que NUNCA Será Vendido
- 🚫 Dinheiro do jogo em quantias relevantes (pequenas convenience packs OK até R$ 9,90; nunca packs grandes).
- 🚫 Itens raros do mercado.
- 🚫 Funcionários com atributos superiores.
- 🚫 Vagas exclusivas em leaderboards.
- 🚫 Diminuição de cooldowns críticos de gameplay.
- 🚫 Caixas com loot aleatório de poder ("gacha P2W").

### 19.8 ARPPU e ARPDAU Alvo
- ARPDAU alvo: US$ 0,12-0,25 (saudável para Tycoon casual).
- Taxa de conversão paga alvo: 4-7%.
- LTV/CAC alvo: > 1.5x em 90 dias.

---

## 20. PSICOLOGIA DE RETENÇÃO

### 20.1 Gatilhos de Progressão
Cada sessão gera 2-5 micro-progressões visíveis (XP, R$, item novo, afinidade, level de funcionário). Isso ativa **dopaminérgico de antecipação**. O design garante que **nunca se sai do app sem ter avançado algo**.

### 20.2 Colecionismo
A enciclopédia explora o "Zeigarnik effect" — tarefas incompletas geram tensão cognitiva. Ver "473/500 itens" é virtualmente impossível de ignorar.

### 20.3 Curiosidade
Notícias misteriosas ("Estranhos contêineres avistados no Porto"), NPCs ambulantes raros, eventos surpresa criam **lacunas de informação**. O cérebro humano busca fechar lacunas — o jogador volta para descobrir.

### 20.4 Descoberta
Cada nova cidade, raridade, NPC é uma "primeira vez". Designamos **primeiras vezes ao longo de meses** para que sempre haja algo novo a alguns dias de distância.

### 20.5 Recompensas Variáveis
O sistema de raridade, eventos surpresa e drops de NPC oferecem **reforço de razão variável**, o esquema de aprendizagem mais resistente à extinção (literatura behaviorista). Calibramos para satisfação, jamais para vício compulsivo (caps diários, ausência de mecanismos predatórios).

### 20.6 Construção de Patrimônio
Ver o número subir é primitivamente satisfatório. Curvas exponenciais bem calibradas geram a sensação de "estou ficando rico de verdade". Notação curta (K, M, B, T, Q...) ajuda a manter números legíveis.

### 20.7 Apego Emocional aos Funcionários
- Retratos únicos.
- Frases ambientais contextuais.
- Histórias pessoais reveladas ao subir afinidade.
- Sistema "Memorial" no prestígio: foto dos funcionários favoritos do ciclo anterior.

### 20.8 Apego Emocional aos Veículos
- Nomes personalizáveis.
- Adesivos cosméticos.
- "Quilometragem" exibida.
- "Velha amiga" — sua primeira moto pode ser preservada em todos os prestígios como cosmético.

### 20.9 Apego Emocional às Coleções
- Galeria visual.
- "Primeira aquisição" timestamp.
- Histórias por trás de cada Lendário/Mítico.
- Foto/animação especial ao redescobrir em prestígio.

### 20.10 Saúde Mental
- Lembrete opcional de pausa após 60min contínuos.
- "Você já jogou bastante hoje, parabéns!" — confronta narrativa de "mais é sempre melhor".
- Ausência total de mecânicas de FOMO punitivo.
- Eventos sazonais re-rodam em até 12 meses (ninguém perde para sempre).

---

## 21. ESCALABILIDADE E ROADMAP PÓS-LANÇAMENTO

### 21.1 Arquitetura de Conteúdo
Todo conteúdo (cidades, produtos, NPCs, eventos) é **data-driven** via arquivos de configuração (JSON/YAML) e tabelas balanceadas via planilhas. Adicionar cidade nova não exige redeploy do binário — basta atualizar conteúdo no servidor (live ops).

### 21.2 Sistemas Extensíveis
- **Novas cidades**: pluga-se uma nova entidade com matriz econômica própria.
- **Novos produtos**: adicionar ficha YAML + ícone + balanceamento.
- **Novos eventos**: criar arquivo de evento, agendar no calendário live ops.
- **Novas profissões de funcionário**: definir atributos e sinergias.
- **Novas temporadas**: criar passe, eventos sazonais, cosméticos (60-90 dias de ciclo).
- **Novos sistemas econômicos** (DLCs): câmbio entre regiões (moedas locais), bolsa de valores in-game, leilões.

### 21.3 Roadmap Sugerido

**Lançamento (Mês 0):** 8 cidades, 500 itens, 300 NPCs, 60 eventos, 4 frotas.

**T1 — Mês 1-3 ("Verão do Comerciante"):**
- Cidade Subterrânea.
- +60 itens (foco em Artefatos).
- 1ª temporada sazonal.
- Sistema de "Rivais" (NPC competidor inteligente).

**T2 — Mês 4-6 ("Olhos no Horizonte"):**
- Cidade Universitária.
- Sistema de pesquisa/produção própria (em escala pequena).
- Bolsa de Valores de commodities.

**T3 — Mês 7-9 ("A Capital"):**
- Capital Política, eventos regulatórios (tarifas, impostos), sistema de lobby de NPCs.
- 2º Prestígio Profundo (segunda árvore).

**T4 — Mês 10-12 ("Travessias"):**
- Ilha Resort + Megacidade Estrangeira.
- Câmbio entre moedas regionais.
- Modo cooperativo opcional (alianças de comerciantes, sem PvP direto).

**Ano 2:** Conteúdo trimestral consistente, eventos cross-temporada, primeiro grande sistema novo (ex: imóveis comerciais como ativos passivos).

### 21.4 Live Ops Calendar Tipo
- Diário: missões, ofertas surpresa.
- Semanal: contrato lendário, evento de fim de semana.
- Mensal: mini-temporada / evento global.
- Trimestral: nova temporada + passe.
- Anual: aniversário do jogo (cosméticos exclusivos comemorativos).

---

## 22. ARQUITETURA TÉCNICA RESUMIDA

### 22.1 Stack Sugerida
- **Engine**: Unity 2D ou Godot 4 (preferência por Godot se o time aceitar — open-source, sem royalties, peso baixo).
- **Backend**: Node.js/Go com PostgreSQL (transações) + Redis (cache de mercado).
- **Live ops**: PlayFab, Nakama ou solução proprietária.
- **Analytics**: GameAnalytics + custom events para economia.
- **A/B testing**: Firebase Remote Config ou similar.

### 22.2 Tamanho de App Alvo
- Lançamento: < 150 MB (asset bundles sob demanda).
- Pós-conteúdo: app base + downloads incrementais por cidade/temporada.

### 22.3 Performance Alvo
- 60 FPS estáveis em dispositivos de gama média (Snapdragon 6xx, Apple A12+).
- 30 FPS aceitável em dispositivos de baixa gama.
- Modo "Bateria" reduz partículas e FPS para 30.

### 22.4 Offline-First com Sync
- Jogo funcional totalmente offline para sessões individuais.
- Sync ao retornar à conexão, com resolução determinística (server authoritative em economia macro).

### 22.5 Anti-Cheat
- Validações server-side de todas transações > X.
- Detecção de "time travel" no idle.
- Banimentos suaves (shadow nerf de drops) antes de banimento definitivo.

---

## 23. KPIs E MÉTRICAS DE SUCESSO

### 23.1 Métricas de Engajamento
| Métrica | Meta D1 | Meta D7 | Meta D30 | Meta D90 |
|---------|---------|---------|----------|----------|
| Retenção | 45-55% | 22-28% | 8-12% | 4-7% |
| Sessões/dia | 4-6 | 3-5 | 2-4 | 2-3 |
| Min/sessão | 6-9 | 5-8 | 4-7 | 4-6 |

### 23.2 Métricas Econômicas In-Game
- Distribuição saudável de raridade na enciclopédia dos jogadores ativos.
- Gini do patrimônio entre jogadores no mesmo nível (evita acumulação desproporcional).
- Cidades visitadas por sessão (alvo: 2-3+).

### 23.3 Métricas de Monetização
- ARPDAU US$ 0,12-0,25.
- Taxa de conversão 4-7%.
- Taxa de retenção de assinaturas > 70% mês a mês.
- Taxa de conclusão do passe (free) > 35%, (paid) > 70%.

### 23.4 Métricas de Saúde
- Reviews ≥ 4.5/5 sem padrão de queixa de monetização predatória.
- Tempo médio de sessão **não excedendo** 25min consistentemente (preocupação ética com overuse).
- Reclamações de "pay-to-win" < 2% das reviews negativas.

### 23.5 Sinais de Alarme
- Queda > 8% de retenção D7 semana sobre semana: reavaliar conteúdo da temporada.
- Spike de churn em jogadores de prestígio > 5: rebalancear curva exponencial tardia.
- Mais de 1% dos jogadores gastando > US$ 200/mês: investigar potenciais "whales" em estado vulnerável (aplicar limites suaves, oferecer suporte).

---

## ANEXOS

### A. Glossário
- **Prestígio**: reset voluntário com bônus permanentes.
- **PP**: Pontos de Prestígio.
- **Tick**: ciclo de atualização do mercado (15 min).
- **Mod**: multiplicador econômico aplicado a um preço.
- **Idle slot**: vaga de rota automática durante offline.

### B. Princípios Éticos Resumidos
1. Nunca crie sensação de obrigação punitiva.
2. Nunca venda poder.
3. Sempre dê ao jogador free uma versão completa do jogo.
4. Sempre respeite o tempo do jogador.
5. Sempre considere o jogador mais vulnerável ao projetar uma feature.

### C. Inspirações Declaradas
- **Adventure Capitalist** (idle clean, prestígio).
- **Egg, Inc.** (idle profundo, respeito ao tempo).
- **Tiny Tower / Pocket Trains** (charme 2D, gestão).
- **Sid Meier's Pirates / Patrician** (comércio entre cidades, fonte clássica do core loop).
- **Stardew Valley** (apego emocional a NPCs/economia, qualidade de UX mobile).
- **Travel Town** (live ops e eventos sazonais bem implementados).

### D. Próximos Passos para o Estúdio
1. Prototipar core loop (compra/venda 3 cidades, 30 produtos) em 4 semanas.
2. Validar fun-factor com playtest fechado (50 usuários, 7 dias).
3. Balancear curva econômica até estabilidade.
4. Soft-launch em mercados pequenos (Filipinas, Brasil) por 8 semanas.
5. Iterar em retenção D1/D7 até atingir metas.
6. Global launch.

---

**FIM DO DOCUMENTO**
*Versão 1.0 — Mercado Paralelo GDD*
*Documento vivo: revisar a cada sprint maior e a cada nova temporada de live ops.*
