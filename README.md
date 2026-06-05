# Mercado Negro

Jogo mobile 2D feito em **Godot 4.6** — um *idle/trading tycoon* ambientado no submundo,
com tema visual dark "Neon Submundo".

## Como rodar
Abra esta pasta no Godot 4.6+ e pressione **F5**. A cena inicial é `scenes/Title.tscn`.

## Visão geral
- **Painel "Império"**: postos de comércio por cidade que enchem e pagam ao toque; melhore,
  desbloqueie novos postos e contrate Gerentes para automatizar (renda offline).
- **Mercado / Negociação**: compre e venda entre cidades; barganhe com NPCs que têm rosto,
  arquétipo e especialidade.
- **Funcionários**: turbinam a renda dos postos (multiplicador global).
- **Coleção, Contratos, Eventos/Notícias, Idle/Save, Gemas**.

## Estrutura
- `scripts/` — sistemas (`Economy`, `Posts`, `NPCs`, `Employees`, `Contracts`, `Collection`,
  `News`, `SaveSystem`, `GameState`) e telas (`Main`, `Title`, `NegotiationPopup`)
- `ui/` — design system (`Style.gd`) + fontes (Baloo 2, Nunito)
- `art/` — arte vetorial SVG (mascote, ícone, avatares de NPCs/funcionários, ícones de UI)
- `scenes/` — cenas
- `GDD.md` — game design document
